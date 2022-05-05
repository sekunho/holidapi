defmodule HolidefsApi.Holidefs.Cache do
  @moduledoc """
  """
  alias HolidefsApi.Repo
  alias Ecto.Multi

  @doc """
  Fetches the uncached range(s).
  """
  @spec fetch_uncached_ranges(Date.t(), Date.t(), Holidefs.locale_code())
    :: {:ok, any} | {:error, any}
  def fetch_uncached_ranges(from, to, country_code) do
    country_code = Atom.to_string(country_code)
    query_str = "SELECT * FROM cache.check_dates($1, $2, $3)"

    case Repo.query(query_str, [from, to, country_code]) do
      {:ok, %{rows: []}} ->
        {:ok, :all_cached}

      {:ok, %{rows: rows}} ->
        {:ok, Enum.map(rows, fn [from, to] -> %{from: from, to: to} end)}

      {:error, _} -> {:error, :db_error}
    end
  end

  @doc """
  Caches a list of holidays in the DB to avoid recomputation.

  This is meant to be used for caching holidays that were retrieved,
  and this only solves a portion of that problem.

  This is mainly focused on receiving a list of holidays meant to be
  cached, and then this updates the date ranges stored in the cache,
  as well as the holidays themselves.

  `Cache.put/4` expects 4 arguments: list of holidays, country code, start date,
  and from date. This start and from date is the date range that is being
  requested by whoever is querying the API.

  It works this way:

    1. Check if there's an exact range, or a superset range that has
    already been cached in the database.
        a. If it exists, then there's no point in continuing. So it skips the
        caching process.
        b. If it doesn't exist, then continue.
    2. Check if there's at least one range that intersects with the requested
    date range.
        a. If it exists, take their IDs, and continue.
        b. If it doesn't, just continue.
    3. Find exactly which holidays (from the holiday list), need to be cached.
    There's a chance that it could've been cached by the time we reach the `put`
    function, so this is just a safety measure. The ones cached are dropped from
    the list. This just checks every single date in the ranges taken from the
    previous step, and drops the ones that match one of them.
    4. Fuse intersecting date ranges to one. But it's really more like: get rid
    of them since the new one fuses them all together. The holidays with said
    ranges (that have already been cached and intersect with the new range) are
    updated to reference the new range.
    5. Insert the remaining uncached holidays with the new range ID.

  All date ranges here are specific to a region.
  """
  @spec put([Holidefs.Holiday.t()], Date.t(), Date.t(), Holidefs.locale_code())
    :: {:ok, any} | {:error, atom}
  def put(holidays, from, to, country_code) do
    # TODO: Refactor this. Please.
    country_code = Atom.to_string(country_code)

    Multi.new()
    |> Multi.run(:check_subset_range, fn repo, _ ->
      # Check if the date range exists in the database in an exact manner, or
      # even a subset. If it does, then there's no need to cache.

      query_str = """
        SELECT date_range_id
          FROM cache.date_ranges
          WHERE $1 >= date_ranges.start_date
            AND $2 <= date_ranges.end_date
            AND date_ranges.code = $3 :: TEXT
      """

      case repo.query(query_str, [from, to, country_code]) do
        {:ok, %{rows: [_|_]}} -> {:ok, :skip_cache}
        {:ok, _} -> {:ok, :do_cache}
        e = {:error, _} -> e
      end
    end)
    |> Multi.run(:find_uncached_holidays, fn repo, prev_result ->
      query_str = """
        SELECT *
          FROM cache.get_intersecting_date_ranges($1 :: DATE, $2 :: DATE, $3 :: TEXT)
      """

      with %{check_subset_range: :do_cache} <- prev_result,
           {:ok, %{rows: cached_date_ranges}} <- repo.query(query_str, [from, to, country_code]) do

        {cached_date_ids, cached_dates}=
          Enum.reduce(cached_date_ranges, {[], []}, fn
            [id, from, to], {id_acc, date_acc }->
              {[id | id_acc], [Enum.to_list(Date.range(from, to)) | date_acc]}
          end)

        cached_dates = List.flatten(cached_dates)

        uncached_holidays =
          Enum.filter(holidays, fn holiday ->
            holiday.date not in cached_dates
          end)

        {:ok, %{"cached_date_ids" => cached_date_ids, "uncached_holidays" => uncached_holidays}}
      else
        %{check_subset_range: :skip_cache} -> {:ok, :skip_cache}
        e = {:error, _} -> e
      end
    end)
    |> Multi.run(:fuse_date_range, fn repo, %{find_uncached_holidays: prev_result}->
      case prev_result do
        :skip_cache -> {:ok, :skip_cache}

        %{
          "cached_date_ids" => cached_date_ids,
          "uncached_holidays" => uncached_holidays
        } ->
          result =
            repo.query(
             """
              SELECT *
                FROM cache.fuse_date_ranges(
                  $1 :: UUID[],
                  $2 :: DATE,
                  $3 :: DATE,
                  $4 :: TEXT
                )
             """,
             [cached_date_ids, from, to, country_code]
            )

          case result do
            {:ok, %{rows: [[id | _]]}} ->
              {:ok, %{"new_id" => id, "uncached_holidays" => uncached_holidays}}

            {:ok, %{rows: []}} -> {:error, :no_return}
            {:error, _} -> {:error, :insert_date_range_error}
          end
        end
    end)
    |> Multi.run(:insert_holidays, fn repo, %{fuse_date_range: prev_result} ->
      case prev_result do
        %{"new_id" => new_range_id, "uncached_holidays" => uncached_holidays} ->
          if uncached_holidays != [] do
            {query_str, args} = build_bulk_insert_holidays_query(uncached_holidays, new_range_id)

            repo.query(query_str, args)
          else
            {:ok, :empty_holidays}
          end

        {:error, _} -> prev_result
      end
    end)
    |> Repo.transaction()
  end

  @spec build_bulk_insert_holidays_query([Holidefs.Holiday.t()], String.t()) :: {String.t(), [any]}
  def build_bulk_insert_holidays_query(holidays, date_range_id) do
    # Build the query string
    str = "INSERT INTO cache.holidays(date_range_id, name, informal, date, observed_date, raw_date) VALUES"

    {query_chunks, args, _} =
      Enum.reduce(holidays, {[], [], 1}, fn holiday, {query_chunks, args, arg_counter} ->
        new_chunk =
          Enum.reduce(arg_counter..arg_counter + 5, [], fn count, acc ->
            ["$#{count}" | acc]
          end)
          |> Enum.reverse()
          |> Enum.intersperse(", ")
          |> List.to_string()

        args =
          [holiday.raw_date | [holiday.observed_date | [holiday.date | [holiday.informal? | [holiday.name | [date_range_id | args]]]]]]

        {["(#{new_chunk})" | query_chunks], args, arg_counter + 6}
      end)

    value_part =
      query_chunks
      |> Enum.reverse()
      |> Enum.intersperse(", ")
      |> List.to_string()

    {"#{str} #{value_part} RETURNING holiday_id", Enum.reverse(args)}
  end
end

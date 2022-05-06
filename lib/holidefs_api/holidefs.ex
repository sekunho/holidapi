defmodule HolidefsApi.Holidefs do
  @moduledoc """
  Wrapper around the `holidefs` library. This wrapper adds some conveniences
  like caching, and an alternative way to load a locale definition.
  """

  alias Holidefs, as: Holib
  alias HolidefsApi.Request.RetrieveHolidays
  alias HolidefsApi.Holidefs.Db
  alias HolidefsApi.Repo
  alias Ecto.Multi

  @doc """
  Fetches the holidays given a retrieve request.

  The naive implementation.
  """
  @spec between(RetrieveHolidays.t())
    :: {:ok, [Holidefs.Holiday.t()]} | {:error, atom()}
  def between(%{country: country_code, from: from, to: to, opts: opts}) do
    Holib.between(
      country_code,
      from,
      to,
      &Holib.Definition.Store.get_definition/1,
      opts
    )
  end

  @doc """
  Convenience function for wrapping `Holidefs.between/5` with the DB store rather
  than the default one.
  """
  @spec between_db(RetrieveHolidays.t())
    :: {:ok, [Holidefs.Holiday.t()]} | {:error, atom()}
  def between_db(%{country: country_code, from: from, to: to, opts: opts}) do
    Holib.between(
      country_code,
      from,
      to,
      &Db.get_definition!/1,
      opts
    )
  end

  @spec between_db_with_cache(RetrieveHolidays.t())
    :: {:ok, [Holidefs.Holiday.t()]} | {:error, atom()}
  def between_db_with_cache(%{country: country_code, from: from, to: to, opts: opts}) do
    # Get cached years from DB
    years = from.year..to.year |> Enum.to_list() |> IO.inspect()

    Multi.new()
    |> Multi.run(:get_cache, fn repo, _ ->
      Db.get_holidays_from_years(repo, years, country_code)
      |> IO.inspect(label: "FROM YEARS")
    end)
    |> Multi.run(:get_definition, fn repo, %{get_cache: prev_result} ->
      IO.inspect(prev_result, label: "CACHE")
      definition = Db.get_definition!(repo, country_code)
      {:ok, %{"definition" => definition, "cache" => prev_result}}
    end)
    |> Multi.run(:maybe_cache, fn _repo, %{get_definition: prev_result} ->
      cached_years = Map.get(prev_result, "cache", %{})
      country_definition = Map.get(prev_result, "definition")

      {uncached_data, holidays} =
        from.year..to.year
        |> Enum.reduce({%{}, []}, fn year, {uncached_data, acc} ->
          case Map.fetch(cached_years, Integer.to_string(year)) do
            {:ok, holidays} ->
              IO.puts "Found year #{year} in cache."
              # TODO: Parse this to the holiday type
              holidays =
                Enum.map(holidays, fn holiday ->
                  %Holidefs.Holiday{
                    date: Date.from_iso8601!(holiday["date"]),
                    observed_date: Date.from_iso8601!(holiday["observed_date"]),
                    raw_date: Date.from_iso8601!(holiday["raw_date"]),
                    uid: holiday["holiday_uid"],
                    informal?: holiday["informal"],
                    name: holiday["name"],
                  }
                end)

              {uncached_data, [holidays | acc]}
            :error ->
              IO.puts "Didn't find year #{year} in cache. Computing.."
              holidays = all_year_holidays(country_definition, year, opts)

              {Map.put(uncached_data, Integer.to_string(year), holidays), [holidays | acc]}
          end
        end)

        holidays =
          holidays
          |> Enum.reverse()
          |> List.flatten()
          |> Enum.drop_while(&(Date.compare(&1.date, from) == :lt))
          |> Enum.take_while(&(Date.compare(&1.date, to) != :gt))
          |> IO.inspect()

      {:ok, %{"all_holidays" => holidays, "uncached_data" => uncached_data}}
      |> IO.inspect(label: "COL")
    end)
    |> Multi.run(:cache_years, fn repo, %{maybe_cache: prev_result} ->
      years =
        prev_result
        |> Map.get("uncached_data", %{})
        |> Map.keys()
        |> Enum.map(fn year_str -> String.to_integer(year_str) end)

      if years == [] do
        {:ok, {prev_result, :skip_cache}}
      else
        case Db.cache_years_query(repo, years, country_code) do
          {:ok, year_caches} -> {:ok, {prev_result, year_caches}}
          e = {:error, _} -> e
        end
      end
    end)
    |> Multi.run(:cache_holidays, fn
      _repo, %{cache_years: {prev_result, :skip_cache}} ->
        {:ok, prev_result}

      repo, %{cache_years: {prev_result = %{"uncached_data" => uncached_data}, year_caches}} ->

        # years =
        #   prev_result
        #   |> Map.get("uncached_data", %{})
        #   |> Map.keys()
        #   |> Enum.map(fn year_str -> String.to_integer(year_str) end)

        result =
          for %{"id" => id, "year" => year} <- year_caches do
            holidays = uncached_data[Integer.to_string(year)]

            Db.cache_holidays_query(repo, holidays, id)
          end

        case seq(result) do
          {:ok, _} -> {:ok, prev_result["all_holidays"]}
          e = {:error, _} -> e
        end
        |> IO.inspect(label: "last step")
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{cache_holidays: %{"all_holidays" => holidays}}} -> {:ok, holidays}
      e = {:error, _} -> e
    end
  end

  # I yoinked from the library cause I didn't want to bump it again
  @spec all_year_holidays(Holidefs.Definition.t(), integer, Holidefs.Options.attrs()) :: [
          Holidefs.Holiday.t()
        ]
  defp all_year_holidays(
         %Holidefs.Definition{code: code, rules: rules},
         year,
         %Holidefs.Options{include_informal?: include_informal?, regions: regions} = opts
       ) do
    rules
    |> Stream.filter(&(include_informal? or not &1.informal?))
    |> Stream.filter(&(regions -- &1.regions != regions))
    |> Stream.flat_map(&Holidefs.Holiday.from_rule(code, &1, year, opts))
    |> Enum.sort_by(&Date.to_erl(&1.date))
  end

  defp all_year_holidays(definition, year, opts) when is_list(opts) or is_map(opts) do
    all_year_holidays(definition, year, Holidefs.Options.build(opts, definition))
  end

  @spec seq([{:ok, any} | {:error, atom}]) :: {:ok, [any]} | {:error, atom}
  defp seq(list) do
    Enum.reduce_while(list, {:ok, []}, fn el, {:ok, acc_list} ->
      case el do
        {:ok, el} -> {:cont, {:ok, [el | acc_list]}}
        {:error, _} -> {:halt, el}
      end
    end)
  end
end

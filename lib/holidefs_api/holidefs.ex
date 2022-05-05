defmodule HolidefsApi.Holidefs do
  @moduledoc """
  Wrapper around the `holidefs` library. This wrapper adds some conveniences
  like caching, and an alternative way to load a locale definition.
  """

  alias HolidefsApi.Repo
  alias Holidefs, as: Holib
  alias HolidefsApi.Request.RetrieveHolidays
  alias HolidefsApi.Holidefs.Cache
  alias Ecto.Multi

  @doc """
  Fetches the holidays given a retrieve request.

  The naive implementation.
  """
  @spec between(RetrieveHolidays.t())
    :: {:ok, [Holidefs.Holiday.t()]} | {:error, atom()}
  def between(request) do
    fetch_holidays = fn
      %{type: {:formal, %{country: country_code, from: from, to: to}}} ->
        Holib.between(country_code, from, to)

      %{type: {:include_informal, %{country: country_code, from: from, to: to}}} ->
        Holib.between(
          country_code,
          from,
          to,
          &Holib.Definition.Store.get_definition/1,

          # FIXME: Use the query param to set this
          include_informal?: true,
          observed?: true
        )
    end

    fetch_holidays.(request)
  end

  @spec between_db(RetrieveHolidays.t())
    :: {:ok, [Holidefs.Holiday.t()]} | {:error, atom()}
  def between_db(request = %{type: {_, %{country: country_code, from: from, to: to}}}) do
    Multi.new()
    |> Multi.run(:fetch_ranges_from_cache, fn repo, _ ->
      Cache.fetch_ranges_from_cache(repo, from, to, country_code)
    end)
    |> Multi.run(:between_cache, fn repo, %{fetch_ranges_from_cache: range_cache_result}->
      with %{"cached" => cached, "uncached" => uncached} <- range_cache_result,
           {:ok, uncached_holidays} <- bulk_uncached_between(request, uncached),
           {:ok, cached_holidays} <- bulk_cached_between(repo, request, cached) do

        {:ok, List.flatten(uncached_holidays) ++ List.flatten(cached_holidays)}
      else
        e -> e
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{between_cache: holidays}} -> {:ok, holidays}
      e = {:error, _} -> e
    end
  end

  # Put this in its own module
  @spec seq([{:ok, any} | {:error, atom}]) :: {:ok, [any]} | {:error, atom}
  defp seq(list) do
    Enum.reduce_while(list, {:ok, []}, fn el, {:ok, acc_list} ->
      case el do
        {:ok, el} -> {:cont, {:ok, [el | acc_list]}}
        {:error, _} -> {:halt, el}
      end
    end)
  end

  defp bulk_cached_between(
    repo,
    %{type: {formality, %{country: country_code}}},
    cached
  ) do
    cached
    |> Enum.map(fn %{"start_date" => from, "end_date" => to} ->
      from = Date.from_iso8601!(from)
      to = Date.from_iso8601!(to)

      Cache.between(
        repo,
        from,
        to,
        country_code,
        include_informal?: formality == :include_informal,
        observed: false
      )
    end)
    |> seq()
  end

  defp bulk_uncached_between(
    %{type: {formality, %{country: country_code}}},
    uncached
  ) do
    uncached
    |> Enum.map(fn %{"start_date" => from, "end_date" => to} ->
      from = Date.from_iso8601!(from)
      to = Date.from_iso8601!(to)

      holidays =
        Holib.between(
          country_code,
          from,
          to,
          &__MODULE__.Db.get_definition!/1,
          include_informal?: formality == :include_informal
        )

      with {:ok, holidays} <- holidays,
           {:ok, _} <- Cache.put(holidays, from, to, country_code) do
        {:ok, holidays}
      else
        e -> e
      end
    end)
    |> seq()
  end
end

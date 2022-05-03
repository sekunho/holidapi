defmodule HolidefsApi.Holidefs do
  alias Holidefs, as: Holib
  alias HolidefsApi.Request.RetrieveHolidays

  @doc """
  Fetches the holidays given a retrieve request.

  The naive implementation.
  """
  @spec between(RetrieveHolidays.t())
    :: {:ok, [Holidefs.Holiday.t()]} | {:error, atom()}
  def between(request = %{type: {_, %{countries: countries}}}, opts \\ []) do
    fetch_holidays =
      if Keyword.get(opts, :cache, false) do
        # Retrieves the holidays with caching.
        fn
          country_code, {:formal, details} ->
            Holib.between(country_code, details.from, details.to)

          country_code, {:include_informal, details} ->
            Holib.between(country_code, details.from, details.to, informal?: true)
        end
      else
        # No caching involved here
        fn
          country_code, {:formal, details} ->
            Holib.between(country_code, details.from, details.to)

          country_code, {:include_informal, details} ->
            Holib.between(country_code, details.from, details.to, informal?: true)
        end
      end

    # NOTE: Ok, yeah I know it's expensive.
    Enum.reduce_while(countries, {:ok, %{}}, fn
      country_code, {:ok, acc_country_holidays} ->
        case fetch_holidays.(country_code, request.type) do
          {:ok, holidays} ->
            country_holidays = Map.put(acc_country_holidays, country_code, holidays)
            {:cont, {:ok, country_holidays}}

          {:error, reason} -> {:halt, {:error, reason}}
        end

      # I don't think it's ever gonna reach here though.
      _, {:error, reason} -> {:halt, {:error, reason}}
    end)
  end
end

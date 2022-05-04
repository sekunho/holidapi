defmodule HolidefsApi.Holidefs do
  alias Holidefs, as: Holib
  alias HolidefsApi.Request.RetrieveHolidays

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
        Holib.between(country_code, from, to, informal?: true)
    end

    fetch_holidays.(request)
  end
end

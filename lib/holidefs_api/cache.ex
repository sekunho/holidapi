defmodule HolidefsApi.Cache do
  import Ecto.Adapters.SQL, only: [query: 3]

  @doc """
  Fetches the holidays of a locale between a range.

  ## Examples

      iex> HolidefsApi.Cache.fetch(["ph", :us], ~D[2020-05-03], ~D[2022-05-04])

  """
  @spec fetch([Holidef.locale_code()], Date.t(), Date.t())
    :: {:ok, map()} | {:error, :query_failed}
  def fetch(regions, from, to) do
    regions =
      Enum.map(regions, fn
        region when is_atom(region) -> Atom.to_string(region)
        region when is_binary(region) -> region
      end)

    result =
      query(
        HolidefsApi.Repo,
        "SELECT * FROM app.get_holidays($1::app.REGION[], $2, $3)",
        [regions, from, to]
      )

    case result do
      {:ok, %{rows: [[data]]}} -> {:ok, data}
      {:error, _} -> {:error, :query_failed}
    end
  end
end

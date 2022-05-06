defmodule HolidefsApi.Request.RetrieveHolidays do
  @moduledoc """
  A parsed request to retrieve a list of holidays.

  It is assumed that the `Date` entries in this struct are set to the local
  date of the country being requested.
  """

  @typedoc "Represents the potential error that may occur in `from_map/1`."
  @type error
    :: :invalid_params
     | :invalid_date
     | :invalid_country_code
     | :invalid_holiday_type

  use TypedStruct
  alias __MODULE__.Type

  typedstruct do
    @typedoc "A request for retrieving holidays encoded as a struct"

    field :country, Holidefs.locale_code(), enforce: true
    field :from, Date.t(), enforce: true
    field :to, Date.t(), enforce: true
    field :opts, Keyword.t(), enforce: true, default: []
  end

  @doc """
  Converts a map to a `RetrieveHolidays` request.
  list.

  ## Examples

  Defaults to `"formal"` if the key `holiday_type` does not exist.

      iex> from_map(%{
      ...>  "country" => "ph",
      ...>  "start" => "2022-01-01",
      ...>  "end" => "2022-04-03",
      ...> })
      {
        :ok,
        %RetrieveHolidays{
          country: :ph,
          from: ~D[2022-01-01],
          to: ~D[2022-04-03],
          opts: []
        }
      }

  You can also explicitly provide it, if you want.

      iex> from_map(%{
      ...>  "country" => "ph",
      ...>  "start" => "2022-01-01",
      ...>  "end" => "2022-04-03",
      ...>  "holiday_type" => "formal"
      ...> })
      {
        :ok,
        %RetrieveHolidays{
          country: :ph,
          from: ~D[2022-01-01],
          to: ~D[2022-04-03],
          opts: []
        }
      }

  You can include informal holidays in the retrieval as well.

      iex> from_map(%{
      ...>   "country" => "ph",
      ...>   "start" => "2022-01-01",
      ...>   "end" => "2022-04-03",
      ...>   "holiday_type" => "include_informal"
      ...> })
      {
        :ok,
        %RetrieveHolidays{
          country: :ph,
          from: ~D[2022-01-01],
          to: ~D[2022-04-03],
          opts: []
        }
      }

  ## Errors

  Fails if one of the country codes are invalid

      iex> from_map(%{
      ...>   "country" => "wtf",
      ...>   "start" => "2022-01-01",
      ...>   "end" => "2022-04-03",
      ...>   "holiday_type" => "include_informal"
      ...> })
      {:error, :invalid_country_code}


  If it's an invalid date

      iex> from_map(%{
      ...>   "country" => "ph",
      ...>   "start" => "2022-01--01",
      ...>   "end" => "2022-04-03",
      ...>   "holiday_type" => "formal"
      ...> })
      {:error, :invalid_date}

  ## Panics

  `from_map/1` will panic in the ff scenarios:

    1) The input is not a map; or
    2) It is a map but has missing keys. Of course, with the exception of
    `"holiday_type"`.
  """
  @spec from_map(map()) :: {:ok, t()} | {:error, error()}
  def from_map(req = %{
    "country" => country,
    "start" => from,
    "end" => to,
  }) do
    holiday_type = Map.get(req, "holiday_type", "formal")
    opts = HolidefsApi.Request.parse_opts(req)

    with {:ok, from} <- Date.from_iso8601(from),
         {:ok, to} <- Date.from_iso8601(to),
         {:ok, country} <- parse_country_code(country) do
         # {:ok, type} <- Type.from(country, from, to, holiday_type) do
      {:ok, %__MODULE__{opts: opts, country: country, from: from, to: to}}
    else
      {:error, :invalid_format} -> {:error, :invalid_date}
      {:error, :incompatible_calendars} -> {:error, :invalid_date}
      {:error, :invalid_date} -> {:error, :invalid_date}
      {:error, :invalid_country_code} -> {:error, :invalid_country_code}

      _ -> {:error, :invalid_params}
    end
  end

  @spec parse_country_code(String.t())
    :: {:ok, Holidefs.locale_code()} | {:error, :invalid_country_code}
  defp parse_country_code(country_code) do
    case country_code do
      "br" -> {:ok, :br}
      "us" -> {:ok, :us}
      "hr" -> {:ok, :hr}
      "at" -> {:ok, :at}
      "au" -> {:ok, :au}
      "be" -> {:ok, :be}
      "ca" -> {:ok, :ca}
      "ch" -> {:ok, :ch}
      "co" -> {:ok, :co}
      "cz" -> {:ok, :cz}
      "de" -> {:ok, :de}
      "dk" -> {:ok, :dk}
      "ee" -> {:ok, :ee}
      "es" -> {:ok, :es}
      "fi" -> {:ok, :fi}
      "fr" -> {:ok, :fr}
      "gb" -> {:ok, :gb}
      "hu" -> {:ok, :hu}
      "ie" -> {:ok, :ie}
      "it" -> {:ok, :it}
      "mx" -> {:ok, :mx}
      "my" -> {:ok, :my}
      "nl" -> {:ok, :nl}
      "no" -> {:ok, :no}
      "nz" -> {:ok, :nz}
      "ph" -> {:ok, :ph}
      "pl" -> {:ok, :pl}
      "pt" -> {:ok, :pt}
      "rs" -> {:ok, :rs}
      "ru" -> {:ok, :ru}
      "se" -> {:ok, :se}
      "sg" -> {:ok, :sg}
      "si" -> {:ok, :si}
      "sk" -> {:ok, :sk}
      "za" -> {:ok, :za}
      _ -> {:error, :invalid_country_code}
    end
  end
end

defmodule HolidefsApi.Request.RetrieveHolidays do
  @moduledoc """
  A parsed request to retrieve a list of holidays.

  e.g `%RetrieveHolidays{country_code: :ph, from: _, to: _}` for the country
  code `ph`.

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

    field :type, Type.type(), enforce: true
  end

  @doc """
  Converts a map to a `RetrieveHolidays` request. It also dedups the countries
  list.

  ## Examples

      iex> from_map(%{
      ...>  "countries" => "ph,au,us",
      ...>  "start" => "2022-01-01",
      ...>  "end" => "2022-04-03",
      ...>  "holiday_type" => "formal"
      ...> })
      {
        :ok,
        %RetrieveHolidays{
          type: {
            :formal,
            %RetrieveHolidays.Type{
              countries: [:us, :au, :ph],
              from: ~D[2022-01-01],
              to: ~D[2022-04-03]
            }
          }
        }
      }

      iex> from_map(%{
      ...>   "countries" => "ph,au,us",
      ...>   "start" => "2022-01-01",
      ...>   "end" => "2022-04-03",
      ...>   "holiday_type" => "include_informal"
      ...> })
      {
        :ok,
        %RetrieveHolidays{
          type: {
            :include_informal,
            %RetrieveHolidays.Type{
              countries: [:us, :au, :ph],
              from: ~D[2022-01-01],
              to: ~D[2022-04-03]
            }
          }
        }
      }

  ## Errors

  Fails if one of the country codes are invalid

      iex> from_map(%{
      ...>   "countries" => "wtf,ph,au",
      ...>   "start" => "2022-01-01",
      ...>   "end" => "2022-04-03",
      ...>   "holiday_type" => "include_informal"
      ...> })
      {:error, :invalid_country_code}


  If the holiday type is neither "formal" or "include_informal"

      iex> from_map(%{
      ...>   "countries" => "ph,au,us",
      ...>   "start" => "2022-01-01",
      ...>   "end" => "2022-04-03",
      ...>   "holiday_type" => "what_is_this"
      ...> })
      {:error, :invalid_holiday_type}

  If it's an invalid date

      iex> from_map(%{
      ...>   "countries" => "ph,au,us",
      ...>   "start" => "2022-01--01",
      ...>   "end" => "2022-04-03",
      ...>   "holiday_type" => "formal"
      ...> })
      {:error, :invalid_date}

  ## Panics

  `from_map/1` will panic in the ff scenarios:

  1) the input is not a map; or 2) it is a map but has missing keys.
  """
  @spec from_map(map()) :: {:ok, t()} | {:error, error()}
  def from_map(%{
    "countries" => countries,
    "start" => from,
    "end" => to,
    "holiday_type" => holiday_type
  }) do
    cc =
      countries
      |> String.split(",", trim: true)
      |> MapSet.new()
      |> Enum.map(&parse_country_code/1)
      |> cc_seq()

    with {:ok, from} <- Date.from_iso8601(from),
         {:ok, to} <- Date.from_iso8601(to),
         {:ok, countries} <- cc,
         {:ok, type} <- Type.from(countries, from, to, holiday_type) do
      {:ok, %__MODULE__{type: type}}
    else
      {:error, :invalid_format} -> {:error, :invalid_date}
      {:error, :incompatible_calendars} -> {:error, :invalid_date}
      {:error, :invalid_date} -> {:error, :invalid_date}
      {:error, :invalid_country_code} -> {:error, :invalid_country_code}
      {:error, :invalid_holiday_type} -> {:error, :invalid_holiday_type}

      _ -> {:error, :invalid_params}
    end
  end

  @doc """
  `seq/1` transforms a list of country code `Results` (or a tuple representation
  of it), to a Result with a list if it goes well, otherwise an error. This is
  useful for having a sequence of operations depend on everything succeeding.

  I'm only using it for this case, hence why I didn't put it in its own module.
  """
  @spec cc_seq([{:ok, any} | {:err, atom}]) :: {:ok, [any]} | {:error, atom}
  defp cc_seq(list) do
    Enum.reduce_while(list, {:ok, []}, fn
      {:ok, el}, {:ok, acc} ->
        {:cont, {:ok, [el | acc]}}

      {:error, e}, _ -> {:halt, {:error, e}}
    end)
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

  def export() do
  end
end

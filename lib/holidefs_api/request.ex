defmodule HolidefsApi.Request do
  @moduledoc """
  There are several requests that can be done:

  - `Request.RetrieveHolidays`: Retrieve holidays between a range.
  - `Request.AddCustomHoliday`: Add a custom holiday to the service.
  - `Request.GenerateICS`: Produces a `.ics` file.

  These actions are meant to be produced at the boundary of the application.
  Ideally, in the controller where the request data is parsed into this. The
  reason why this is the case is so that the data will be so much easier to handle
  as it travels deeper in the application.
  """

  @doc """
  Parses the `opts` key in a request parameter. If there's none, then it
  evaluates to an empty keyword list. This silently ignores all unsupported
  options.

  Currently supports the ff:

    * `include_informal`: Include informal holidays in the list
    * `observed`: If true, then it uses the `observed_date` as the date of comparison.
    * `regions`: List of regions

  ## Examples

      iex> parse_opts(%{"opts" => "include_informal", "country" => "ph"})
      %Holidefs.Options{include_informal?: true, regions: ["ph"], observed?: false}

      iex> parse_opts(%{"opts" => "observed", "country" => "ph"})
      %Holidefs.Options{include_informal?: false, regions: ["ph"], observed?: true}

      iex> parse_opts(%{"opts" => "include_informal,observed", "country" => "ph"})
      %Holidefs.Options{include_informal?: true, regions: ["ph"], observed?: true}

      iex> parse_opts(%{"country" => "gb", "regions" => "sct,eng", "opts" => "include_informal,observed"})
      %Holidefs.Options{include_informal?: true, regions: ["sct", "eng"], observed?: true}
  """
  @spec parse_opts(map) :: Holidefs.Options.t()
  def parse_opts(params = %{"country" => country_code}) do
    opts =
      params
      |> Map.get("opts", "")
      |> String.split(",", trim: true)
      |> Enum.reduce(%Holidefs.Options{}, fn flag, opts ->
        case flag do
          "include_informal" -> %{opts | include_informal?: true}
          "observed" -> %{opts | observed?: true}
          _ -> opts
        end
      end)

    opts =
      params
      |> Map.get("regions")
      |> case do
        nil -> %{opts | regions: [country_code]}
        str ->
          case String.split(str, ",", trim: true) do
            [] -> %{opts | regions: [country_code]}
            regions -> %{opts | regions: regions}
          end
      end

    opts
  end
end

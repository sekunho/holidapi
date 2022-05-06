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
    * `observed`: New holiday entry in its observed date

  ## Examples

      iex> Keyword.get(parse_opts(%{"opts" => "include_informal"}), :include_informal?)
      true

      iex> Keyword.get(parse_opts(%{"opts" => ""}), :include_informal?, false)
      false

      iex> Keyword.get(parse_opts(%{"opts" => "observed,include_informal"}), :observed?, false)
      true
  """
  @spec parse_opts(map) :: Keyword.t()
  def parse_opts(params) do
    case Map.fetch(params, "opts") do
      {:ok, flags} ->
        flags
        |> String.split(",", trim: true)
        |> Enum.reduce([], fn flag, acc ->
          case flag do
            "include_informal" -> [{:include_informal?, true} | acc]
            "observed" -> [{:observed?, true} | acc]
            _ -> acc
          end
        end)
      :error -> []
    end
  end
end

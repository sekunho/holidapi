defmodule HolidefsApi.Holidefs.Export do
  alias HolidefsApi.Request.RetrieveHolidays
  import HolidefsApi.Holidefs, only: [between_db: 1]

  @spec export(RetrieveHolidays.t())
    :: {:ok, [Holidefs.Holiday.t()]} | {:error, atom()}
  def export(request) do
    events =
      request
      |> between_db()
      |> case do
        {:ok, holidays} ->
          Enum.map(holidays, fn holiday ->
            %ICalendar.Event{
              summary: holiday.name,
              dtstart: holiday.date,
              description: "",
              location: ""
            }
          end)

        {:error, reason} -> {:error, reason}
      end

    ICalendar.to_ics(%ICalendar{events: events})
  end
end

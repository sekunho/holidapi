defmodule HolidefsApiWeb.HolidaysController do
  use HolidefsApiWeb, :controller

  alias HolidefsApi.Request.RetrieveHolidays

  def index(conn, params) do
    with {:ok, retrieve_request} <- RetrieveHolidays.from_map(params),
         {:ok, countries_holidays} <- HolidefsApi.Holidefs.between(retrieve_request) do

      render(conn, "index.json", countries_holidays: countries_holidays)
    else
      {:error, e} ->
        conn
        |> put_status(:bad_request)
        |> render("400.json", error: e)
    end
  end

  def create(conn, params) do
    IO.inspect(params)

    render(conn, "holiday.json", holiday: %{})
  end

  def generate_ics(conn, params) do
    IO.inspect(params)

    render(conn, "calendar.ics", ics_data: "")
  end
end

defmodule HolidefsApiWeb.HolidaysController do
  use HolidefsApiWeb, :controller

  def index(conn, params) do
    IO.inspect(params)

    render(conn, "index.json", holidays: [])
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

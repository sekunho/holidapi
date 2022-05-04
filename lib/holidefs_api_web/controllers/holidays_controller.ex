defmodule HolidefsApiWeb.HolidaysController do
  use HolidefsApiWeb, :controller

  alias HolidefsApi.Request.RetrieveHolidays
  import HolidefsApi.Holidefs, only: [between: 1]
  import HolidefsApi.Holidefs.Export, only: [export: 1]

  def index(conn, params) do
    with {:ok, retrieve_request} <- RetrieveHolidays.from_map(params),
         {:ok, country_holidays} <- between(retrieve_request) do

      render(conn, "index.json", country_holidays: country_holidays)
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
    case RetrieveHolidays.from_map(params) do
      {:ok, retrieve_request} ->
        render(
          conn,
          "calendar.ics",
          ics_data: export(retrieve_request)
        )

      {:error, e} ->
        conn
        |> put_status(:bad_request)
        |> render("400.json", error: e)
    end
  end
end

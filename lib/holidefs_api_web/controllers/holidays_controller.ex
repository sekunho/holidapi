defmodule HolidefsApiWeb.HolidaysController do
  use HolidefsApiWeb, :controller

  alias HolidefsApi.Request.RetrieveHolidays
  alias HolidefsApi.Request.AddCustomHoliday
  alias HolidefsApi.Holidefs.Db

  import HolidefsApi.Holidefs, only: [between_db: 1]
  import HolidefsApi.Holidefs.Export, only: [export: 1]

  def index(conn, params) do
    with {:ok, retrieve_request} <- RetrieveHolidays.from_map(params),
         {:ok, country_holidays} <- between_db(retrieve_request) do

      render(conn, "index.json", country_holidays: country_holidays)
    else
      {:error, e} ->
        conn
        |> put_status(:bad_request)
        |> render("400.json", error: e)
    end
  end

  def create(conn, params) do
    with {:ok, add_holiday_request} <- AddCustomHoliday.from_map(params),
         {:ok, _} <- Db.Rule.save(add_holiday_request) do
      # TODO: Return the new rule data that was just added
      # IO.inspect(add_holiday_request)
    else
      {:error, e} ->
        conn
        |> put_status(:bad_request)
        |> render("400.json", error: e)

      {:internal_server_error, e} ->
        conn
        |> put_status(:internal_server_error)
        |> render("500.json", error: e)
    end

    # NOTE: This is only one holiday. Just that Phoenix does magic in the naming.
    render(conn, "holiday.json", holidays: %{})
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

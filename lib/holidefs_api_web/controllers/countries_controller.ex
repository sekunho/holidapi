defmodule HolidefsApiWeb.CountriesController do
  use HolidefsApiWeb, :controller

  alias Holidefs, as: Holib

  @countries Holib.locales()
    |> Enum.map(fn {code, name} ->
      {:ok, regions} = Holib.get_regions(code)

      %{code: code, name: name, regions: regions}
    end)

  def index(conn, _params) do
    render(conn, "countries.json", countries: @countries)
  end

  def show(conn, %{"country" => country_code}) do
    country_code = String.trim(country_code)

    case Holib.get_regions(country_code) do
      {:ok, regions} ->
        country_code = String.to_existing_atom(country_code)
        name = Map.get(Holib.locales, country_code)
        country = %{code: country_code, name: name, regions: regions}

        render(conn, "country.json", countries: country)

      {:error, :no_def} ->
        conn
        |> put_status(:not_found)
        |> render("404.json", message: "#{country_code} does not exist")
    end
  end
end

defmodule HolidefsApiWeb.CountriesView do
  use HolidefsApiWeb, :view

  def render("countries.json", data) do
    %{data: render_many(data.countries, __MODULE__, "country.json")}
  end

  def render("country.json", data) do
    data.countries
  end

  def render("404.json", data) do
    %{errors: %{detail: data.message}}
  end
end

defmodule HolidefsApiWeb.FunctionsView do
  use HolidefsApiWeb, :view

  def render("functions.json", data) do
    data.names
  end
end

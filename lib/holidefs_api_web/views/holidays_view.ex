defmodule HolidefsApiWeb.HolidaysView do
  use HolidefsApiWeb, :view

  def render(file, data) do
    case file do
      "index.json" -> %{data: render_many(data, __MODULE__, "holiday.json")}

      "holiday.json" -> %{
         date: ~D[2022-01-01],
         informal?: false,
         name: "New Year’s Day",
         observed_date: ~D[2022-01-01],
         raw_date: ~D[2022-01-01],
         uid: "ph-2022-bee958081e35f0823bfab5ce252916a1"
      }

      "calendar.ics" -> "foobarbaz"
    end
  end
end

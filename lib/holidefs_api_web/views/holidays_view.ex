defmodule HolidefsApiWeb.HolidaysView do
  use HolidefsApiWeb, :view

  def render(file, data) do
    case file do
      "index.json" -> data.countries_holidays

      "holiday.json" -> %{
         date: ~D[2022-01-01],
         informal?: false,
         name: "New Year’s Day",
         observed_date: ~D[2022-01-01],
         raw_date: ~D[2022-01-01],
         uid: "ph-2022-bee958081e35f0823bfab5ce252916a1"
      }

      "calendar.ics" -> "foobarbaz"

      "400.json" ->
        msg =
          case data.error do
            :invalid_holiday_type -> """
              E001: I did not expect this type of holiday.

              Here are the types I know of:

                - "include_informal"
                - "formal"
              """

            :invalid_params -> "E002: Something terribly wrong happened while parsing."
            :invalid_date -> "E003: This is not a valid date string. e.g  \"2022-01-01\" "
            :invalid_country_code -> """
              E004: At least one of the country codes provided is unexpected.
              """
          end

        %{errors: %{detail: msg}}
    end
  end
end

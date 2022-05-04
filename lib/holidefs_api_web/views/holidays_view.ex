defmodule HolidefsApiWeb.HolidaysView do
  use HolidefsApiWeb, :view

  def render(file, data) do
    case file do
      "index.json" ->
        %{data: render_many(data.country_holidays, __MODULE__, "holiday.json")}

      "holiday.json" -> data.holidays
      "calendar.ics" -> data.ics_data

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
              E004: Unexpected country code
              """
          end

        %{errors: %{detail: msg}}
    end
  end
end

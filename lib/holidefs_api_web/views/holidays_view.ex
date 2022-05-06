defmodule HolidefsApiWeb.HolidaysView do
  use HolidefsApiWeb, :view

  def render(file, data) do
    case file do
      "index.json" ->
        %{data: render_many(data.country_holidays, __MODULE__, "holiday.json")}

      "holiday.json" -> data.holidays
      "calendar.ics" -> data.ics_data

      "rule.json" -> Map.from_struct(data.rule)

      "500.json" ->
        msg =
          case data.error do
            _ -> "Oh no."
          end

        %{errors: %{detail: msg}}

      "400.json" ->
        msg =
          case data.error do
            :invalid_holiday_type -> """
              E001: I did not expect this type of holiday.

              Here are the types that I know of:

                - "include_informal"
                - "formal"
              """

            :invalid_params -> "E002: Something terribly wrong happened while parsing."
            :invalid_date -> "E003: This is not a valid date string. e.g  \"2022-01-01\" "

            :invalid_country_code -> """
              E004: Unexpected country code
              """

            :invalid_year_selector -> """
              E005: This is an invalid year selector.

              Here are the types that I know of:

              - "limited" which supports a list of years
              - "after" which supports a single year
              - "before" which supports a single year
            """

            :invalid_month -> """
              E006: Invalid month value. `"month"` should either be an integer
              1 to 12, or a null value to represent that the holiday is not a
              fixed month.
            """

            :invalid_day -> """
              E007: Invalid day value. `"day"` should either be an integer
              1 to 31, or a null value.
            """

            :day_should_be_nil ->
              "E008: Day should be null if month is also null."
          end

        %{errors: %{detail: msg}}
    end
  end
end

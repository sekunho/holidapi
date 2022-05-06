defmodule HolidefsApiWeb.FunctionsController do
  use HolidefsApiWeb, :controller

  @function_names ["to_monday_if_weekend", "fi_pyhainpaiva", "se_alla_helgons_dag",
     "qld_labour_day_may", "pl_trzech_kroli_informal", "christmas_eve_holiday",
     "ch_ge_jeune_genevois", "ph_heroes_day", "easter", "election_day",
     "to_weekday_if_boxing_weekend_from_year", "se_midsommardagen", "rosh_hashanah",
     "yom_kippur", "afl_grand_final", "ch_vd_lundi_du_jeune_federal",
     "orthodox_easter", "may_pub_hol_sa", "georgia_state_holiday",
     "pl_trzech_kroli", "day_after_thanksgiving", "de_buss_und_bettag",
     "fi_juhannusaatto", "qld_labour_day_october", "hobart_show_day",
     "march_pub_hol_sa", "lee_jackson_day", "ch_gl_naefelser_fahrt",
     "fi_juhannuspaiva", "qld_queens_bday_october",
     "to_weekday_if_boxing_weekend_from_year_or_to_tuesday_if_monday",
     "qld_queens_birthday_june", "ca_victoria_day", "us_inauguration_day",
     "to_weekday_if_weekend", "g20_day_2014_only"]

  @observed_names [
    "closest_monday", "next_week", "previous_friday",
    "to_following_monday_if_not_monday", "to_monday_if_sunday",
    "to_monday_if_weekend", "to_tuesday_if_sunday_or_monday_if_saturday",
    "to_weekday_if_boxing_weekend", "to_weekday_if_weekend"
  ]
  def index(conn, %{"type" => function_type}) do
    data =
      case function_type do
        "observed" -> @observed_names
        "date" -> @function_names
      end

    render(conn, "functions.json", names: data)
  end
end


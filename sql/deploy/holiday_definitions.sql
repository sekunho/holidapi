-- Deploy holidefs_api:holiday_definitions to pg

BEGIN;

  CREATE SCHEMA app;

  CREATE TYPE app.FUN AS ENUM (
    'to_monday_if_weekend', 'fi_pyhainpaiva', 'se_alla_helgons_dag',
     'qld_labour_day_may', 'pl_trzech_kroli_informal', 'christmas_eve_holiday',
     'ch_ge_jeune_genevois', 'ph_heroes_day', 'easter', 'election_day',
     'to_weekday_if_boxing_weekend_from_year', 'se_midsommardagen', 'rosh_hashanah',
     'yom_kippur', 'afl_grand_final', 'ch_vd_lundi_du_jeune_federal',
     'orthodox_easter', 'may_pub_hol_sa', 'georgia_state_holiday',
     'pl_trzech_kroli', 'day_after_thanksgiving', 'de_buss_und_bettag',
     'fi_juhannusaatto', 'qld_labour_day_october', 'hobart_show_day',
     'march_pub_hol_sa', 'lee_jackson_day', 'ch_gl_naefelser_fahrt',
     'fi_juhannuspaiva', 'qld_queens_bday_october',
     'to_weekday_if_boxing_weekend_from_year_or_to_tuesday_if_monday',
     'qld_queens_birthday_june', 'ca_victoria_day', 'us_inauguration_day',
     'to_weekday_if_weekend', 'g20_day_2014_only'
  );

  CREATE TYPE app.YEAR_SELECTOR AS ENUM ('limited', 'after', 'before');

  CREATE TABLE app.definitions(
    definition_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,

    -- Country code & name
    -- e.g code: 'au', name: 'Australia'
    code TEXT NOT NULL,
    name TEXT NOT NULL
  );

  CREATE UNIQUE INDEX code_index ON app.definitions(code);

--------------------------------------------------------------------------------

  CREATE TABLE app.rules(
    rule_id       BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,

    informal      BOOLEAN NOT NULL DEFAULT false,
    name          TEXT NOT NULL,
    fun_observed  app.FUN,

    -- TYPES OF HOLIDAYS
    ----------------------
    -- 1) Month-based holiday
    -- 2) Week-based holiday
    -- 3) Custom; determined by a function

    -- A holiday can either be month-based. You need to specify what day of
    -- the month the holiday falls on.
    -- e.g New Years is on 01/01 (mm-dd)
    month         SMALLINT,
    month_day     SMALLINT,

    -- Or it can be based on a specific day of the first, second, or last week
    -- of the month.
    week          SMALLINT,
    week_day      SMALLINT,

    -- Or for more complex holidays, you can use existing functions to compute.
    -- With a function modifier to offset by a number of days.
    fun           app.FUN,
    fun_modifier  INT,

    -- YEAR SELECTORS
    -------------------
    -- There are 3 kinds of year selectors supported by `holidefs`:
    --
    --   1) limited
    --   2) before
    --   3) after
    selector_type app.YEAR_SELECTOR,

    -- A list of years when this holiday is a thing
    limited_years SMALLINT[],

    -- This holiday is only a thing after this year
    after_year    SMALLINT,

    -- This holiday is only a thing before this year
    before_year   SMALLINT,

    -- Since a holiday can only be one of 3 holiday types, this check ensures
    -- that the other irrelevant fields aren't set.
    CONSTRAINT valid_rule CHECK (
      (
        month IS NOT NULL AND
        month_day IS NOT NULL AND
        week IS NULL AND
        week_day IS NULL AND
        fun IS NULL AND
        fun_modifier IS NULL
      ) OR (
        month IS NOT NULL AND
        month_day IS NULL AND
        week IS NOT NULL AND
        week_day IS NOT NULL AND
        fun IS NULL AND
        fun_modifier IS NULL
      ) OR (
        month IS NULL AND
        month_day IS NULL AND
        week IS NULL AND
        week_day IS NULL AND
        fun IS NOT NULL AND
        fun_modifier IS NOT NULL
      )
    )
  );

  -- DUPLICATION CHECKER
  ------------------------

  -- You can't have holidays with the same name, month, day of the month,
  -- and selector type. Although this does not check for overlaps in year range.
  CREATE UNIQUE INDEX month_holiday_index
    ON app.rules(name, month, month_day)
    WHERE month IS NOT NULL
      AND month_day IS NOT NULL;

  CREATE UNIQUE INDEX month_holiday_index_with_year_selector
    ON app.rules(name, informal, fun_observed, month, month_day, selector_type)
    WHERE month IS NOT NULL
      AND month_day IS NOT NULL
      AND selector_type IS NOT NULL;

  -- You can't have holidays with the same name, month, week, week day, and
  -- selector type. Although this does not check for overlaps in year range.
  CREATE UNIQUE INDEX week_holiday_index
    ON app.rules(name, month, week, week_day)
    WHERE month IS NOT NULL
      AND week IS NOT NULL
      AND week_day IS NOT NULL;

  CREATE UNIQUE INDEX week_holiday_index_with_year_selector
    ON app.rules(name, informal, fun_observed, month, week, week_day, selector_type)
    WHERE month IS NOT NULL
      AND week IS NOT NULL
      AND week_day IS NOT NULL
      AND selector_type IS NOT NULL;

  -- You can't have holidays with the same name, function, function modifier,
  -- and selector type.
  CREATE UNIQUE INDEX fun_holiday_index
    ON app.rules(name, fun, fun_modifier)
    WHERE fun IS NOT NULL
      AND fun_modifier IS NOT NULL;

  CREATE UNIQUE INDEX fun_holiday_index_with_year_selector
    ON app.rules(name, informal, fun_observed, fun, fun_modifier, selector_type)
    WHERE fun IS NOT NULL
      AND fun_modifier IS NOT NULL
      AND selector_type IS NOT NULL;

--------------------------------------------------------------------------------

  CREATE TABLE app.definitions_rules(
    id            BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,

    definition_id BIGINT REFERENCES app.definitions,
    rule_id       BIGINT REFERENCES app.rules
  );

--------------------------------------------------------------------------------
-- INSERT RULE FUNCTIONS

  CREATE FUNCTION app.insert_rule(
    definition_id BIGINT,
    informal      BOOLEAN,
    rule_name     TEXT,
    fun_observed  app.FUN,

    -- HOLIDAY TYPES
    ------------------

    -- Month day holiday
    month         SMALLINT,
    month_day     SMALLINT,

    -- Week day holiday
    week          SMALLINT,
    week_day      SMALLINT,

    -- Custom function holiday
    fun           app.FUN,
    fun_modifier  INT,

    -- YEAR SELECTORS
    -------------------
    selector_type app.YEAR_SELECTOR,
    limited_years SMALLINT[],
    after_year    SMALLINT,
    before_year   SMALLINT
  )
    RETURNS TABLE (id BIGINT, definition_id BIGINT, rule_id BIGINT)
    LANGUAGE SQL
    AS $$
      WITH rule_cte AS (
        INSERT
          INTO app.rules (
            informal,
            name,
            fun_observed,
            month,
            month_day,
            week,
            week_day,
            fun,
            fun_modifier,
            selector_type,
            limited_years,
            after_year,
            before_year
          )
          VALUES ($2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
          ON CONFLICT DO NOTHING
          RETURNING rule_id
      )
      INSERT
        INTO app.definitions_rules (definition_id, rule_id)
        SELECT $1 AS definition_id, rule_id
          FROM rule_cte
          RETURNING id, definition_id, rule_id;
    $$;
COMMIT;

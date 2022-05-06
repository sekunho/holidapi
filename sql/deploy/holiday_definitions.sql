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

  CREATE TYPE app.FUN_OBSERVED AS ENUM (
    'closest_monday', 'next_week', 'previous_friday',
    'to_following_monday_if_not_monday', 'to_monday_if_sunday',
    'to_monday_if_weekend', 'to_tuesday_if_sunday_or_monday_if_saturday',
    'to_weekday_if_boxing_weekend', 'to_weekday_if_weekend'
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

    definition_id BIGINT REFERENCES app.definitions,

    informal      BOOLEAN NOT NULL DEFAULT false,
    name          TEXT NOT NULL,
    fun_observed  app.FUN_OBSERVED,

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

    regions       TEXT[]

    -- Since a holiday can only be one of 3 holiday types, this check ensures
    -- that the other irrelevant fields aren't set.
    -- CONSTRAINT valid_rule CHECK (
    --   (
    --     month IS NOT NULL AND
    --     (month_day IS NOT NULL) AND
    --     week IS NULL AND
    --     week_day IS NULL AND
    --     (
    --       (fun IS NULL AND fun_modifier IS NULL) OR
    --       (fun IS NOT NULL AND (fun_modifier IS NULL OR fun_modifier IS NOT NULL))
    --     )
    --   ) OR (
    --     month IS NOT NULL AND
    --     month_day IS NULL AND
    --     week IS NOT NULL AND
    --     week_day IS NOT NULL AND
    --     fun IS NULL AND
    --     fun_modifier IS NULL
    --   ) OR (
    --     month IS NULL AND
    --     month_day IS NULL AND
    --     week IS NULL AND
    --     week_day IS NULL AND
    --     fun IS NOT NULL AND
    --     (fun_modifier IS NOT NULL OR fun_modifier IS NULL)
    --   )
    -- )
  );

  CREATE INDEX definition_id_index ON app.rules(definition_id);
  /* CREATE INDEX rules_index ON app.rules( */
  /*   definition_id */
  /* ); */

--------------------------------------------------------------------------------

  CREATE FUNCTION app.find_def_and_insert_rule(
    in_country       TEXT,
    in_informal      BOOLEAN,
    in_rule_name     TEXT,
    in_fun_observed  app.FUN_OBSERVED,

    -- HOLIDAY TYPES
    ------------------

    -- Month day holiday
    in_month         SMALLINT,
    in_month_day     SMALLINT,

    -- Week day holiday
    in_week          SMALLINT,
    in_week_day      SMALLINT,

    -- Custom function holiday
    in_fun           app.FUN,
    in_fun_modifier  INT,

    -- YEAR SELECTORS
    -------------------
    in_selector_type app.YEAR_SELECTOR,
    in_limited_years SMALLINT[],
    in_after_year    SMALLINT,
    in_before_year   SMALLINT,

    in_regions       TEXT[]
  )
  RETURNS TABLE (
    definition_id BIGINT,
    informal BOOLEAN,
    name TEXT,
    fun_observed app.FUN_OBSERVED,
    month SMALLINT,
    month_day SMALLINT,
    week SMALLINT,
    week_day SMALLINT,
    fun app.FUN,
    fun_modifier INT,
    selector_type app.YEAR_SELECTOR,
    limited_years SMALLINT[],
    after_year SMALLINT,
    before_year SMALLINT,
    regions TEXT[]
  )
  LANGUAGE PLPGSQL
  AS $$
    DECLARE
      def_id BIGINT;
    BEGIN
      SELECT definitions.definition_id INTO def_id
        FROM app.definitions
        WHERE code = $1;

      IF def_id IS NULL THEN
        raise EXCEPTION 'E001: Could not find definition %: %', $1, now();
      END IF;

      RETURN QUERY
      SELECT t.definition_id,
          t.informal,
          t.name,
          t.fun_observed,
          t.month,
          t.month_day,
          t.week,
          t.week_day,
          t.fun,
          t.fun_modifier,
          t.selector_type,
          t.limited_years,
          t.after_year,
          t.before_year,
          t.regions
        FROM app.insert_rule(def_id, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15) as t;
    END
  $$;

  CREATE FUNCTION app.insert_rule(
    definition_id BIGINT,
    informal      BOOLEAN,
    rule_name     TEXT,
    fun_observed  app.FUN_OBSERVED,

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
    before_year   SMALLINT,
    regions       TEXT[]
  )
    RETURNS TABLE (
      definition_id BIGINT,
      informal BOOLEAN,
      name TEXT,
      fun_observed app.FUN_OBSERVED,
      month SMALLINT,
      month_day SMALLINT,
      week SMALLINT,
      week_day SMALLINT,
      fun app.FUN,
      fun_modifier INT,
      selector_type app.YEAR_SELECTOR,
      limited_years SMALLINT[],
      after_year SMALLINT,
      before_year SMALLINT,
      regions TEXT[]
    )
    LANGUAGE SQL
    AS $$
      INSERT
        INTO app.rules (
          definition_id,
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
          before_year,
          regions
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
        RETURNING definition_id,
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
          before_year,
          regions;
    $$;

  CREATE FUNCTION app.get_definitions(locale TEXT)
    RETURNS JSON
    LANGUAGE SQL IMMUTABLE
    AS $$
      WITH definition_cte AS /* NOT MATERIALIZED */ (
        SELECT definition_id, name, code
          FROM app.definitions
          WHERE code = locale
      ), rules_cte AS /* NOT MATERIALIZED */ (
        SELECT
            rules.name,
            rules.informal,
            rules.fun AS function,
            rules.fun_modifier AS function_modifier,
            rules.month,
            rules.month_day AS day,
            rules.fun_observed AS observed,
            rules.regions AS regions,
            rules.week,
            rules.week_day AS weekday,
            CASE
              WHEN rules.selector_type = 'limited' THEN
                json_build_array(json_build_object(rules.selector_type, rules.limited_years))

              WHEN rules.selector_type = 'after' THEN
                json_build_array(json_build_object(rules.selector_type, rules.after_year))

              WHEN rules.selector_type = 'before' THEN
                json_build_array(json_build_object(rules.selector_type, rules.before_year))

              ELSE NULL
            END AS year_ranges
          FROM app.rules AS rules, definition_cte
          WHERE rules.definition_id = definition_cte.definition_id
      )
      SELECT json_build_object(
        'rules', json_agg(row_to_json(rules_cte)),
        'name', definition_cte.name,
        'code', definition_cte.code
      )
        FROM definition_cte, rules_cte
        GROUP BY definition_cte.name, definition_cte.code;
    $$;
COMMIT;

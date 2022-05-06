-- Deploy holidefs_api:cache_holidays to pg

BEGIN;

  CREATE SCHEMA cache;

  CREATE TABLE cache.years(
    year_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year SMALLINT NOT NULL,
    code TEXT NOT NULL
  );

  CREATE UNIQUE INDEX year_code_index ON cache.years(year, code);
  CREATE INDEX year_index ON cache.years(year);

  CREATE TABLE cache.holidays(
    holiday_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year_id       UUID REFERENCES cache.years,

    informal      BOOLEAN NOT NULL,
    name          TEXT NOT NULL,
    date          DATE NOT NULL,
    observed_date DATE NOT NULL,
    raw_date      DATE NOT NULL,
    holiday_uid   TEXT NOT NULL
  );

  CREATE INDEX year_id_index ON cache.holidays(year_id);

  CREATE OR REPLACE FUNCTION cache.get_holidays_from_year_range(
    years        SMALLINT[],
    country_code TEXT
  )
    RETURNS JSON
    LANGUAGE SQL
    AS $$
      WITH year_ids AS (
        SELECT year_id, year
          FROM cache.years
          WHERE years.year = ANY($1)
            AND code = country_code
      ), years_holidays AS (
        SELECT holidays.*, year_ids.year
          FROM cache.holidays
          JOIN year_ids
          ON holidays.year_id = year_ids.year_id
      ), group_holidays AS (
        SELECT years_holidays.year, json_agg(row_to_json(years_holidays))
          FROM years_holidays
          GROUP BY years_holidays.year
      )
      SELECT json_object_agg(group_holidays.year, group_holidays.json_agg)
        FROM group_holidays;
    $$;
COMMIT;

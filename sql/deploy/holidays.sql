-- Deploy holidefs_api:holidays to pg

BEGIN;

  CREATE SCHEMA app;

  CREATE TYPE app.REGION AS ENUM (
    'gb', 'se', 'pl', 'br', 'rs', 'de', 'au', 'ru', 'be', 'za', 'fi', 'pt', 'at',
    'ee', 'dk', 'no', 'cz', 'ch', 'nl', 'fr', 'sg', 'it', 'ie', 'ph', 'us', 'si',
    'co', 'hr', 'mx', 'my', 'sk', 'nz', 'ca', 'hu', 'es'
   );

  CREATE TABLE app.holidays(
    holiday_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT NOT NULL,
    event_id      TEXT NOT NULL,
    informal      BOOLEAN NOT NULL,
    date          DATE NOT NULL,
    observed_date DATE NOT NULL,
    raw_date      DATE NOT NULL
  );

  CREATE TABLE app.holidays_regions(
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    holiday_id    UUID REFERENCES app.holidays NOT NULL,
    region        app.REGION NOT NULL
  );

  CREATE INDEX region_date_index ON app.holidays_regions(region);
  CREATE INDEX date_index ON app.holidays(date);

  CREATE OR REPLACE FUNCTION app.get_holidays(
    regions   app.REGION ARRAY,
    from_date DATE,
    to_date   DATE
  )
    RETURNS JSONB
    LANGUAGE SQL
    AS $$
      WITH region_holidays AS (
        SELECT event_id, name, region, date, observed_date, raw_date, informal
          FROM app.holidays_regions
          JOIN app.holidays
          ON holidays_regions.holiday_id = holidays.holiday_id
          WHERE holidays_regions.region = any(regions)
            AND date >= $2
            AND date <= $3
      )
      SELECT jsonb_build_object(
        'data', coalesce(jsonb_agg(row_to_json(region_holidays)), '[]'::JSONB),
      )
        FROM region_holidays
    $$;
COMMIT;

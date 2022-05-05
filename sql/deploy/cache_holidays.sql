-- Deploy holidefs_api:cache_holidays to pg
BEGIN;
  CREATE SCHEMA cache;

  CREATE TABLE cache.date_ranges(
    date_range_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    start_date    DATE NOT NULL,
    end_date      DATE NOT NULL,

    -- Country code
    code          TEXT NOT NULL
  );

  CREATE INDEX start_range_index ON cache.date_ranges(start_date);
  CREATE INDEX end_range_index ON cache.date_ranges(end_date);
  CREATE INDEX code_index ON cache.date_ranges(code);

--------------------------------------------------------------------------------

  CREATE TABLE cache.holidays(
    holiday_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date_range_id UUID REFERENCES cache.date_ranges ON DELETE SET NULL,

    name          TEXT NOT NULL,
    informal      BOOLEAN NOT NULL,
    date          DATE NOT NULL,
    observed_date DATE NOT NULL,
    raw_date      DATE NOT NULL,

    UNIQUE (name, informal, date, observed_date, raw_date)
  );

  CREATE INDEX date_range_index ON cache.holidays(date_range_id);

--------------------------------------------------------------------------------

  CREATE OR REPLACE FUNCTION cache.get_intersecting_date_ranges(
    start_date  DATE,
    end_date    DATE,
    coutry_code TEXT
  )
    RETURNS TABLE (date_range_id UUID, start_date DATE, end_date DATE)
    LANGUAGE SQL
    AS $$
      -- Looks for intersections in cached date ranges
      SELECT date_range_id, start_date, end_date
        FROM cache.date_ranges
        WHERE (
          $1 <= date_ranges.start_date
          AND $2 >= date_ranges.start_date
          AND date_ranges.code = $3
        ) OR (
          $1 <= date_ranges.end_date
          AND $2 >= date_ranges.end_date
          AND date_ranges.code = $3
        );
    $$;

  CREATE FUNCTION cache.fuse_date_ranges(
    delete_def_ids UUID[],
    new_start_date DATE,
    new_end_date   DATE,
    country_code   TEXT
  )
    RETURNS TABLE (date_range_id UUID, start_date DATE, end_date DATE)
    LANGUAGE SQL
    AS $$
      -- 1. Insert new range
      -- 2. Update holidays with the old ranges to the new one
      -- 3. Delete old ranges
      WITH new_range AS (
        INSERT
          INTO cache.date_ranges(start_date, end_date, code)
          VALUES (new_start_date, new_end_date, country_code)
          RETURNING date_range_id, start_date, end_date
      ), updated_holidays AS (
        UPDATE cache.holidays
          SET date_range_id = new_range.date_range_id
          FROM new_range
          WHERE holidays.date_range_id = ANY(delete_def_ids)
      ), deleted_ranges AS (
        DELETE FROM cache.date_ranges
          WHERE date_ranges.date_range_id = ANY(delete_def_ids)
      )
      SELECT * FROM new_range;
    $$;
COMMIT;

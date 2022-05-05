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

    UNIQUE (date_range_id, name, informal, date, observed_date, raw_date)
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

  CREATE OR REPLACE FUNCTION cache.check_dates(
    start_date   DATE,
    end_date     DATE,
    country_code TEXT
  )
    /* RETURNS TABLE (start_date DATE, end_date DATE) */
    RETURNS JSON
    LANGUAGE SQL IMMUTABLE
    AS $$
      WITH requested_dates AS (
        SELECT day
          FROM generate_series(
            start_date,
            end_date,
            interval '1 day'
          ) AS day
      ), all_cached_dates AS (
        SELECT generate_series(start_date, end_date, interval '1 day') AS day
          FROM cache.date_ranges
          WHERE code = country_code
      ), uncached_dates AS (
        SELECT requested_dates.day :: DATE
          FROM requested_dates
          LEFT OUTER JOIN all_cached_dates
          ON all_cached_dates.day = requested_dates.day
          WHERE all_cached_dates.day IS NULL
      ), cached_dates AS (
        SELECT requested_dates.day :: DATE
          FROM requested_dates
          RIGHT OUTER JOIN all_cached_dates
          ON all_cached_dates.day = requested_dates.day
          WHERE requested_dates.day IS NOT NULL
      ), uncached_ranges AS (
        -- I'm so damn sleepy. I also need to practice partitions/windows more.
        -- https://stackoverflow.com/questions/26476717/aggregate-continuous-ranges-of-dates
        SELECT min(day) AS start_date, max(day) AS end_date
          FROM (
            SELECT day,
                day - row_number() OVER (ORDER BY day)::INT AS grp
              FROM uncached_dates
          ) sub
          GROUP  BY grp
          ORDER  BY grp
      ), cached_ranges AS (
        -- https://stackoverflow.com/questions/26476717/aggregate-continuous-ranges-of-dates
        SELECT min(day) AS start_date, max(day) AS end_date
          FROM (
            SELECT day,
                day - row_number() OVER (ORDER BY day)::INT AS grp
              FROM cached_dates
          ) sub
          GROUP  BY grp
          ORDER  BY grp
      ), cached_json AS (
        SELECT json_agg(row_to_json(cached_ranges))
          FROM cached_ranges
      ), uncached_json AS (
        SELECT json_agg(row_to_json(uncached_ranges))
          FROM uncached_ranges
      )
      SELECT json_build_object(
        'cached',
        coalesce(cached_json.json_agg, '[]'::JSON),
        'uncached',
        coalesce(uncached_json.json_agg, '[]'::JSON)
      )
        FROM cached_json, uncached_json;
    $$;

  CREATE FUNCTION cache.get_holidays(
    start_date DATE,
    end_date DATE,
    country_code TEXT,
    with_observed BOOLEAN,
    with_informal BOOLEAN
  )
    RETURNS TABLE (
      name          TEXT,
      informal      BOOLEAN,
      date          DATE,
      observed_date DATE,
      raw_date      DATE
    )
    LANGUAGE SQL
    AS $$
      WITH date_range AS (
        SELECT date_range_id
          FROM cache.date_ranges
          WHERE $1 >= date_ranges.start_date
            AND $2 <= date_ranges.end_date
            AND date_ranges.code = country_code
      ), left_bound AS (
        SELECT holidays.*
          FROM cache.holidays, date_range
          WHERE holidays.date_range_id = date_range.date_range_id
            AND $1 <= holidays.date
      ), right_bound AS (
        SELECT left_bound.*
          FROM left_bound, date_range
          WHERE left_bound.date_range_id = date_range.date_range_id
            AND $2 >= left_bound.date
      )
      SELECT name, informal, date, observed_date, raw_date FROM right_bound;
    $$;
COMMIT;

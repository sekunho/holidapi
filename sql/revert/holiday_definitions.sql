-- Revert holidefs_api:holiday_definitions from pg

BEGIN;

  DROP SCHEMA app CASCADE;

COMMIT;

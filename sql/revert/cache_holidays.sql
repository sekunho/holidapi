-- Revert holidefs_api:cache_holidays from pg

BEGIN;

  DROP SCHEMA cache CASCADE;

COMMIT;

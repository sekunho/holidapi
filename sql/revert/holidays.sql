-- Revert holidefs_api:holidays from pg

BEGIN;

  DROP SCHEMA app CASCADE;

COMMIT;

-- =============================================================================
-- PlanNight — add the user's UI language preference.
-- =============================================================================
-- The app ships in English, Russian and Tajik. The choice lives on the user row
-- (alongside `theme`) rather than only on the device, so it follows the account
-- to a reinstall or a second phone and syncs like any other setting.
--
-- 'en' is the default: it matches the source language of the ARB files, so a
-- pre-existing account keeps exactly the strings it had before this migration.
-- =============================================================================

ALTER TABLE users
  ADD COLUMN language TEXT NOT NULL DEFAULT 'en'
    CHECK (language IN ('en', 'ru', 'tg'));

-- =============================================================================
-- PlanNight — evening "plan tomorrow" reminder preference.
-- =============================================================================
-- The product's core ritual is planning tomorrow the night before, so the app
-- nudges with one daily local notification. Whether and when lives on the user
-- row (like theme/language) so the preference follows the account and syncs.
--
-- Defaults ON at 21:00: the nudge IS the feature, and Settings offers an
-- obvious switch off. Existing users get the same default, which matches how
-- the feature is announced.
-- =============================================================================

ALTER TABLE users
  ADD COLUMN evening_reminder_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN evening_reminder_time    TIME    NOT NULL DEFAULT '21:00';

-- =============================================================================
-- PlanNight — initial schema
-- =============================================================================
-- Design decisions reflected here:
--   * Times are stored as a local plan_date (DATE) + start_time (TIME) plus the
--     user's timezone, because this is a wall-clock daily planner ("07:30
--     tomorrow"), not a cross-timezone calendar.
--   * Recurring tasks are stored as TEMPLATES and materialised into concrete
--     `tasks` rows when a day is planned/opened. That keeps stats as a simple
--     count of task rows and lets the user tweak a single day without touching
--     the series.
--   * Every user-owned row carries updated_at + deleted_at (soft delete) so the
--     mobile client can do last-write-wins delta sync via `?since=<timestamp>`.
--   * Stats/streaks are computed on the fly from `tasks`, so there is no
--     denormalised stats table to keep in sync.
-- =============================================================================

-- gen_random_uuid() lives in pgcrypto. It is bundled with Postgres; we just
-- have to enable the extension. (On PG 13+ it is also available in core, but
-- enabling pgcrypto is portable and harmless.)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- A reusable trigger function that bumps updated_at on every UPDATE. Attaching
-- this to each table keeps last-write-wins sync honest even if a caller forgets
-- to set updated_at explicitly.
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- users
-- -----------------------------------------------------------------------------
CREATE TABLE users (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email                 TEXT NOT NULL,
  password_hash         TEXT NOT NULL,

  -- Settings (mirrored on the Settings screen).
  timezone              TEXT NOT NULL DEFAULT 'UTC',          -- IANA name, e.g. 'Asia/Karachi'
  theme                 TEXT NOT NULL DEFAULT 'system'
                          CHECK (theme IN ('light', 'dark', 'system')),
  -- A day counts as "successful" when completion_pct >= this threshold.
  streak_threshold_pct  SMALLINT NOT NULL DEFAULT 80
                          CHECK (streak_threshold_pct BETWEEN 1 AND 100),
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  -- Default lead time for reminders, in minutes before start_time (0 = on time).
  reminder_lead_minutes SMALLINT NOT NULL DEFAULT 0
                          CHECK (reminder_lead_minutes BETWEEN 0 AND 1440),

  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Case-insensitive unique email. We store whatever case the user typed but
-- forbid two accounts that differ only by case.
CREATE UNIQUE INDEX users_email_lower_key ON users (lower(email));

CREATE TRIGGER users_set_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- categories  (Work, Study, Health, ... with a colour)
-- -----------------------------------------------------------------------------
CREATE TABLE categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  color       TEXT NOT NULL DEFAULT '#6C63FF'
                CHECK (color ~ '^#[0-9A-Fa-f]{6}$'),          -- hex colour

  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ                                     -- soft delete
);

-- A user cannot have two live categories with the same name (case-insensitive).
-- Partial index so a deleted name can be reused.
CREATE UNIQUE INDEX categories_user_name_key
  ON categories (user_id, lower(name))
  WHERE deleted_at IS NULL;

CREATE INDEX categories_user_updated_idx ON categories (user_id, updated_at);

CREATE TRIGGER categories_set_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- recurring_task_templates
-- A blueprint that gets expanded into concrete `tasks` rows per matching date.
-- -----------------------------------------------------------------------------
CREATE TABLE recurring_task_templates (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id           UUID REFERENCES categories(id) ON DELETE SET NULL,

  title                 TEXT NOT NULL,
  notes                 TEXT,
  priority              TEXT NOT NULL DEFAULT 'medium'
                          CHECK (priority IN ('high', 'medium', 'low')),

  start_time            TIME NOT NULL,                        -- local wall-clock
  duration_minutes      INTEGER CHECK (duration_minutes IS NULL OR duration_minutes > 0),
  reminder_lead_minutes SMALLINT CHECK (reminder_lead_minutes IS NULL
                          OR reminder_lead_minutes BETWEEN 0 AND 1440),

  -- Recurrence rule.
  recurrence_type       TEXT NOT NULL
                          CHECK (recurrence_type IN ('daily', 'weekly', 'custom')),
  -- Days of week the task applies to (0=Sunday .. 6=Saturday). Required for
  -- 'weekly'/'custom'; ignored for 'daily'. Stored as a small int array.
  days_of_week          SMALLINT[] NOT NULL DEFAULT '{}',

  -- Window during which the recurrence is active.
  start_date            DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date              DATE,                                 -- NULL = open-ended
  active                BOOLEAN NOT NULL DEFAULT TRUE,

  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at            TIMESTAMPTZ,

  CONSTRAINT recurrence_days_valid CHECK (
    -- COALESCE guards the NULL that array_length returns for an empty array,
    -- so weekly/custom recurrences are forced to list at least one day.
    recurrence_type = 'daily' OR COALESCE(array_length(days_of_week, 1), 0) >= 1
  ),
  CONSTRAINT recurrence_date_order CHECK (
    end_date IS NULL OR end_date >= start_date
  )
);

CREATE INDEX templates_user_active_idx
  ON recurring_task_templates (user_id, active)
  WHERE deleted_at IS NULL;

CREATE INDEX templates_user_updated_idx
  ON recurring_task_templates (user_id, updated_at);

CREATE TRIGGER templates_set_updated_at
  BEFORE UPDATE ON recurring_task_templates
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- tasks  (the concrete, schedulable, checkable unit)
-- -----------------------------------------------------------------------------
CREATE TABLE tasks (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id           UUID REFERENCES categories(id) ON DELETE SET NULL,
  -- Which recurring template produced this row (NULL for one-off tasks). Used to
  -- avoid generating the same occurrence twice.
  template_id           UUID REFERENCES recurring_task_templates(id) ON DELETE SET NULL,

  title                 TEXT NOT NULL,
  notes                 TEXT,
  priority              TEXT NOT NULL DEFAULT 'medium'
                          CHECK (priority IN ('high', 'medium', 'low')),

  plan_date             DATE NOT NULL,                        -- the day this task belongs to
  start_time            TIME,                                 -- NULL = anytime that day
  duration_minutes      INTEGER CHECK (duration_minutes IS NULL OR duration_minutes > 0),
  reminder_lead_minutes SMALLINT CHECK (reminder_lead_minutes IS NULL
                          OR reminder_lead_minutes BETWEEN 0 AND 1440),

  status                TEXT NOT NULL DEFAULT 'planned'
                          CHECK (status IN ('planned', 'completed', 'skipped', 'rescheduled')),
  completed_at          TIMESTAMPTZ,                          -- set when status='completed'
  -- When status='rescheduled', the day it was moved to (a new task row is created
  -- there). Purely informational for history.
  rescheduled_to_date   DATE,

  -- Manual ordering within a day when start_time ties/absent.
  sort_order            INTEGER NOT NULL DEFAULT 0,

  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at            TIMESTAMPTZ,

  CONSTRAINT completed_at_matches_status CHECK (
    (status = 'completed' AND completed_at IS NOT NULL) OR
    (status <> 'completed' AND completed_at IS NULL)
  )
);

-- Primary access pattern: "give me user U's tasks for day D, in time order".
CREATE INDEX tasks_user_date_idx
  ON tasks (user_id, plan_date)
  WHERE deleted_at IS NULL;

-- Delta-sync scan: "everything for user U changed since T".
CREATE INDEX tasks_user_updated_idx ON tasks (user_id, updated_at);

-- Prevent a template from being expanded twice onto the same day.
CREATE UNIQUE INDEX tasks_template_day_key
  ON tasks (user_id, template_id, plan_date)
  WHERE template_id IS NOT NULL AND deleted_at IS NULL;

CREATE TRIGGER tasks_set_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

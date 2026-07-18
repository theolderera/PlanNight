# PlanNight — Architecture

> Companion to [CLAUDE.md](../CLAUDE.md). This describes **how the system fits
> together and why**. For per-file references see [BACKEND.md](BACKEND.md) and
> [MOBILE.md](MOBILE.md); for running/deploying see [OPERATIONS.md](OPERATIONS.md).

## 1. The product in one paragraph

PlanNight is built around an **evening ritual**: tonight you plan tomorrow's
day as a list of time-scheduled tasks (07:30 gym, 09:00 deep work…), partly
generated from recurring templates. Tomorrow you check tasks off; the app
computes a completion percentage, and a day whose percentage reaches the user's
threshold (default 80%) counts as "successful". Consecutive successful days form
a **streak** — the core motivational loop. Stats screens show weekly bars and a
30-day trend.

## 2. System diagram

```
┌─────────────── Android phone ────────────────┐        ┌────────── VPS / dev PC ──────────┐
│  Flutter app (offline-first)                 │        │                                  │
│                                              │  HTTP  │  Express API  ──►  PostgreSQL   │
│  UI (Riverpod) ◄── streams ── drift SQLite   │ ◄────► │  (stateless,       (source of   │
│        │                          ▲          │  JSON  │   JWT auth)         truth)      │
│        └── writes ──► cache + outbox         │        │                                  │
│                          │                   │        └──────────────────────────────────┘
│      SyncEngine: flush outbox ► pull deltas  │
└──────────────────────────────────────────────┘
```

Two databases by design:

- **PostgreSQL (server)** — the source of truth, one row-set per user.
- **drift/SQLite (device)** — a *cache* of the user's rows plus an **outbox**
  of not-yet-synced local writes. The UI reads **only** from this cache
  (reactively), so every screen works with zero connectivity.

## 3. Offline-first write path

Every mutation follows the same four steps (see `TaskRepository` et al.):

1. **Optimistic local write** — upsert into the drift cache. The watching
   stream fires and the UI updates instantly.
2. **Enqueue** — append `{entityType, entityId, op, payloadJson}` to the
   `outbox_entries` table (monotonic `seq` = replay order).
3. **Kick sync** — fire-and-forget `SyncEngine.syncNow()`.
4. **Server settles** — the outbox replays through the *normal REST endpoints*;
   the following delta pull writes the server's canonical rows back over the
   cache (last-write-wins).

### Outbox replay rules (critical — see `sync_engine_test.dart`)

Entries replay strictly in `seq` order. On failure of entry N:

| Failure | Action | Why |
|---|---|---|
| No response (offline/timeout) | keep entry, **stop** | retry when connectivity returns |
| 5xx / 408 / 429 / 401 / 403 | keep entry, **stop** | transient: server fault, rate limit, or token refresh in flight |
| create → 409 | drop, continue | the row already exists ⇒ the create already landed |
| update/delete/setStatus → 404 | drop, continue | target gone ⇒ outcome already achieved |
| other 4xx (400, 422…) | drop, continue | content is permanently invalid; retrying forever would wedge the queue behind a poison entry |

Stopping (not skipping) on transient failures preserves causal order: a
`create` followed by a `setStatus` on the same id must not be reordered.

### Delta pull

`GET /api/sync?since=<serverTime>` returns every row (categories, tasks,
templates, **and the user row**) whose `updated_at > since`, *including
soft-deleted ones* so deletions propagate. The response's `serverTime` (taken
from the DB clock, not the app server) becomes the next `since` watermark,
stored in the single-row `sync_meta` table. No `since` ⇒ full snapshot (first
login). The pulled `user` row is pushed into `AuthController` so settings
changed on another device (theme/language/threshold) reach the UI.

### Conflict model

Deliberately simple: **last write wins** on whole rows, using `updated_at`.
Flush-before-pull ordering means the device's writes land first, then it reads
back whatever the server now holds. Two devices editing the same task
concurrently: the later replay wins. Acceptable for a single-user personal
planner; revisit only if sharing/collaboration is ever added.

## 4. Identity & idempotency

The **client generates UUIDs** for tasks, categories and templates. So a task
created offline keeps its id after syncing (local references never dangle), and
a replayed create (flaky network, double flush) is idempotent server-side:
`INSERT … ON CONFLICT (id) DO NOTHING`, then fetch-existing scoped by
`user_id` so one user can never collide into another's row.

## 5. Recurring tasks = templates, materialized

Templates (`recurring_task_templates`) are *blueprints*: title, start time,
priority, recurrence (`daily` or `weekly`/`custom` + `days_of_week`
0=Sun..6=Sat), active window (`start_date`/`end_date`), `active` flag.

`POST /api/planning/generate {date}` expands all matching active templates into
real `tasks` rows for that date, in **one SQL statement** (INSERT…SELECT). The
partial unique index `tasks (user_id, template_id, plan_date) WHERE template_id
IS NOT NULL AND deleted_at IS NULL` makes generation idempotent — regenerating a
day is safe and returns only newly-created rows.

Consequences (all deliberate):
- Editing one day's generated task doesn't touch the series.
- Deleting a template stops *future* generation; history stays intact.
- Stats are a simple count over `tasks` — no recurrence math at read time.

## 6. Time model

- Calendar day: `plan_date DATE`, wire format `'YYYY-MM-DD'`.
- Start time: `start_time TIME`, wire format `'HH:MM'`, wall-clock local.
- No UTC instants for scheduling — a 07:30 task means 07:30 *wherever the user
  is*. The only timezone-aware piece is the **streak day rollover**: the server
  computes "today" in the user's IANA `timezone`
  (`todayInTimezone` in `backend/src/common/dates.js`).
- `updated_at`/`deleted_at`/`completed_at` are `TIMESTAMPTZ` (sync bookkeeping,
  not scheduling).
- Backend date arithmetic is done in UTC on `'YYYY-MM-DD'` strings so DST can
  never slip a day.

## 7. Stats & streaks (computed, never stored)

All stats aggregate live from `tasks` (`stats.service.js`):

- Per-day: `total` (excludes `rescheduled`), `completed`, `skipped`, `pending`,
  `completionPct = round(completed/total*100)`,
  `successful = total > 0 && pct >= streak_threshold_pct`.
- Streak: walk back day-by-day from today (in the user's timezone) over a
  365-day window. **Grace rule**: if *today* isn't successful yet (day still in
  progress), counting starts from yesterday, so an unfinished morning doesn't
  zero the streak.
- `rescheduled` tasks leave the origin day's denominator (they moved, they
  weren't failed); the client's Today progress header applies the same rule.

## 8. Auth

- Access JWT (15 min) + refresh JWT (30 d), **different secrets**, a `type`
  claim prevents cross-use.
- Refresh tokens are **stateful** (migration 003): each carries a `jti`
  tracked in `refresh_tokens`. Refresh *rotates* (old row revoked atomically,
  new pair issued); `POST /auth/logout` revokes, so signing out actually ends
  the session server-side. Reuse of a rotated token → 401, deliberately
  *without* a revoke-all cascade (a mobile client that lost the rotation
  response would otherwise nuke its other devices).
- bcryptjs (12 rounds). Login runs a real dummy-hash compare when the email is
  unknown to keep timing flat (user-enumeration defence).
- Mobile: tokens in `flutter_secure_storage` (Android Keystore). Dio
  interceptor attaches Bearer, and on 401 refreshes **once** (single-flight,
  concurrent 401s coalesce) then retries; refresh failure ⇒ forced logout.
- Rate limits: 20/15min on auth endpoints (brute-force), plus zod validation on
  every input; helmet security headers; CORS allowlist via `CORS_ORIGINS`.

## 9. Reschedule semantics

"Move task to another day" is a **transaction**: the original row becomes
`status='rescheduled'` + `rescheduled_to_date` (a breadcrumb kept for history),
and a *fresh* `planned` copy (new id, `template_id = NULL` so the
template/day unique index can't collide) is inserted on the target date. The
endpoint returns `{original, moved}`; the mobile outbox replay upserts both
into the cache immediately rather than waiting for the next pull.

## 10. Notifications (fully client-side)

No push infrastructure. The device schedules exact local notifications
(`flutter_local_notifications` + `timezone`) for the next 7 days of pending,
timed tasks at `start_time − reminderLead`, **plus one daily evening
"plan tomorrow" nudge** (per-user time, default 21:00, prefs on the user row —
migration 004 — so they sync; repeats via `matchDateTimeComponents: time`;
fixed id −1, payload deep-links to /plan). The scheduler provider re-runs
(cancel-all + reschedule, idempotent) whenever upcoming tasks or settings
change, and is keyed to the user's `language` so pending reminders are
rewritten when the language changes. Task notification ids are
`task.id.hashCode & 0x7fffffff` (collision-tolerant: worst case one reminder
overwrites another; never collides with the nudge's negative id).

## 11. Localization (en/ru/tg) — the two hard parts

Full details in [MOBILE.md](MOBILE.md) §l10n. The two things everyone trips on:

1. **Flutter ships no `tg` Material/Cupertino translations** — without the
   custom fallback delegates (`core/l10n.dart`, serving *Russian* framework
   strings for Tajik), any date/time picker crashes under locale `tg`.
2. **intl has no `tg` locale data** — `DateFormat(…, 'tg')` throws. All
   user-visible date text is built from ARB strings via `DateLabels`, which
   also handles Russian genitive-in-date («8 июля» vs «Июль 2026») and Tajik
   izofat («8 июли 2026»).

The language choice lives on the **user row** (`users.language`, `'en'|'ru'|'tg'`)
so it follows the account across devices via normal settings sync. Server error
messages are English developer prose; the client renders localized text mapped
from the machine-readable `error.code` instead.

## 12. Decision log (agreed with the owner — don't relitigate casually)

| Decision | Rationale |
|---|---|
| Templates materialized into real task rows | simple stats, per-day editability |
| Stats computed on the fly, no cache table | data volumes are tiny; no invalidation bugs |
| Last-write-wins sync, no CRDT/vector clocks | single-user app; complexity not warranted |
| Wall-clock local times, no UTC scheduling | it's a daily planner, not a cross-TZ calendar |
| Raw SQL, no ORM | teaching codebase; SQL stays visible and reviewable |
| Client-generated UUIDs | offline creation with stable ids |
| bcryptjs over native bcrypt | no native build step in alpine Docker |
| Language stored server-side on the user row | follows the account, syncs like theme |

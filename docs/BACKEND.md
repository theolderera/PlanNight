# PlanNight — Backend reference

> Node 20 (ESM) + Express 4 + PostgreSQL 16. Raw SQL via `pg`, zod validation,
> JWT auth, bcryptjs. No ORM, no TypeScript. **No automated tests yet** (top
> item in [IMPROVEMENTS.md](IMPROVEMENTS.md)) — verify by running against Docker.

## File map (`backend/src/`)

```
server.js                 entry: DB ping (fail fast) → listen → graceful SIGTERM/SIGINT shutdown
app.js                    express assembly: helmet, CORS, morgan, routes, 404, errorHandler
                          `trust proxy = 1` (real client IPs behind nginx)
config/
  env.js                  zod-validated process.env → frozen `env`; exits on invalid;
                          refuses equal access/refresh secrets
  db.js                   pg Pool; query(); withTransaction(fn) BEGIN/COMMIT/ROLLBACK; closePool()
common/
  dates.js                'YYYY-MM-DD' string math in UTC; todayInTimezone(IANA) for streaks
  schemas.js              shared zod: dateString (real-date check), timeString, uuid, daysOfWeek
  sql.js                  buildUpdateSet(columnMap, patch) → parameterised SET clause;
                          throws 400 EMPTY_PATCH on empty patch. ALL dynamic UPDATEs use this.
middleware/
  auth.js                 requireAuth: Bearer → verifyAccessToken → req.user = {id}
  validate.js             validate({body|query|params}); parsed query → req.validatedQuery
                          (req.query is getter-only on newer Express)
  errorHandler.js         notFoundHandler + errorHandler: ApiError → JSON; pg 23505 → 409
                          DUPLICATE; unknown → 500 (debug echoed only outside production)
utils/
  ApiError.js             ApiError(status, msg, {code, details}) + static helpers
  asyncHandler.js         wraps async handlers → next(err)
  jwt.js                  sign/verify access & refresh; separate secrets; `type` claim checked
  password.js             bcryptjs hash/verify, BCRYPT_ROUNDS work factor
db/
  migrate.js              tiny runner: applies db/migrations/*.sql in name order, once each,
                          in a transaction; records in schema_migrations. `up` | `status`
  migrations/001_init.sql        full schema (below)
  migrations/002_user_language.sql  users.language 'en'|'ru'|'tg' default 'en'
modules/<name>/           routes → service → serializer (+ validation)
```

Module pattern: **routes** are thin HTTP adapters; **services** hold logic and
throw `ApiError`; **serializers** map snake_case rows → camelCase JSON (user
serializer must never leak `password_hash`). Every query is scoped by
`user_id`. Deletes are soft (`deleted_at = now()`), so they propagate via sync.

## API reference

Base path `/api`; all routes except `/auth/*` require `Authorization: Bearer
<access>`. Errors: `{error: {message, code?, details?}}` — clients key off
`code`, never the prose. `/health` (no prefix, no auth) → `{status:'ok'}`.

### Auth (`/auth`, rate-limited 20/15min/IP)
| Method Path | Body | Returns |
|---|---|---|
| POST /register | `{email, password(8..128), timezone?, language?}` | 201 `{user, accessToken, refreshToken}`; 409 `EMAIL_TAKEN` |
| POST /login | `{email, password}` | 200 same shape; 401 `BAD_CREDENTIALS` (flat timing) |
| POST /refresh | `{refreshToken}` | 200 `{accessToken, refreshToken}` (new pair); 401 `REFRESH_INVALID` / `USER_GONE` |

### Users (`/users`)
| Method Path | Notes |
|---|---|
| GET /me | `{user}` |
| PATCH /me | any of `{timezone, language, theme, streakThresholdPct(1-100), notificationsEnabled, reminderLeadMinutes(0-1440)}`; ≥1 field |

### Categories (`/categories`) — id may be client-supplied (idempotent create)
GET / · POST / `{id?, name(≤60), color? #RRGGBB}` · PATCH /:id · DELETE /:id (204, soft)
Duplicate live name (case-insensitive, per user) → 409 `CATEGORY_EXISTS`.

### Tasks (`/tasks`)
| Method Path | Notes |
|---|---|
| GET /?date= or ?from=&to= | filters `categoryId, priority, status`; ordered plan_date, start_time NULLS LAST, sort_order, created_at |
| POST / | `{id?, title(≤200), notes?(≤2000), categoryId?, priority?, planDate, startTime?, durationMinutes?(1-1440), reminderLeadMinutes?(0-1440), sortOrder?}` |
| GET /:id · PATCH /:id · DELETE /:id | PATCH needs ≥1 field; foreign categoryId → 400 `CATEGORY_NOT_FOUND` |
| POST /:id/status | `{status: planned\|completed\|skipped}`; keeps `completed_at` consistent with the CHECK constraint |
| POST /:id/reschedule | `{date}` → `{original, moved}` in one transaction; same date → 400 `SAME_DATE` |

### Templates & planning
`/recurring-templates`: GET / · POST / · PATCH /:id · DELETE /:id (soft; past
generated tasks untouched). Create/update enforce non-empty `daysOfWeek`
(0=Sun..6=Sat) for `weekly`/`custom`; switching to `daily` force-clears it.
`/planning`: POST /generate `{date}` → `{created, count}` — idempotent
INSERT…SELECT expansion (see [ARCHITECTURE.md](ARCHITECTURE.md) §5).

### Stats (`/stats`) — semantics in [ARCHITECTURE.md](ARCHITECTURE.md) §7
GET /daily?date= · GET /summary?from=&to= (≤366 days; zero-filled days for
continuous chart axes) · GET /streak → `{current, longest, threshold, asOf}`

### Sync (`/sync`)
GET /?since=<ISO> → `{serverTime, user|null, categories[], tasks[],
templates[]}` — rows with `updated_at > since` **including soft-deleted**;
no `since` ⇒ full snapshot. `serverTime` comes from the DB clock.

## Database schema (after 001 + 002)

`users`: id uuid PK · email (unique on `lower(email)`) · password_hash ·
timezone (IANA, default UTC) · language ('en'|'ru'|'tg') · theme
('light'|'dark'|'system') · streak_threshold_pct 1-100 (default 80) ·
notifications_enabled · reminder_lead_minutes 0-1440 · created_at/updated_at.

`categories`: id · user_id FK CASCADE · name · color CHECK `^#[0-9A-Fa-f]{6}$` ·
timestamps + deleted_at. Unique `(user_id, lower(name)) WHERE deleted_at IS
NULL` — deleted names are reusable.

`recurring_task_templates`: id · user_id · category_id FK SET NULL · title ·
notes · priority CHECK high|medium|low · start_time TIME NOT NULL ·
duration/reminder minutes · recurrence_type CHECK daily|weekly|custom ·
days_of_week SMALLINT[] (CHECK: non-daily ⇒ ≥1 day) · start_date/end_date
(CHECK end ≥ start) · active · timestamps + deleted_at.

`tasks`: id · user_id · category_id SET NULL · template_id SET NULL (provenance
+ dedupe) · title · notes · priority · plan_date DATE NOT NULL · start_time
TIME NULL (= "anytime") · duration/reminder minutes · status CHECK
planned|completed|skipped|rescheduled · completed_at (CHECK: set iff
completed) · rescheduled_to_date · sort_order · timestamps + deleted_at.

Indexes: `(user_id, plan_date) WHERE deleted_at IS NULL` (day view) ·
`(user_id, updated_at)` on all three synced tables (delta scan) · partial
unique `(user_id, template_id, plan_date)` (idempotent generation). A
`set_updated_at()` trigger bumps `updated_at` on every UPDATE of every table —
this is what keeps last-write-wins sync honest.

## Gotchas

- `error.code === '23505'` is translated in two places: specific 409s in
  category/auth services, generic `DUPLICATE` in errorHandler.
- pg returns DATE columns as JS `Date`s — serializers must go through
  `toDateString()` or clients receive ISO timestamps with timezones.
- `validate` replaces `req.body`/`req.params` with **parsed** values (zod
  coercions applied); query lands on `req.validatedQuery`.
- The login dummy-hash is generated lazily via `hashPassword` at first use — a
  hand-written constant would fail in ~0ms and reopen the timing oracle.
- `express-rate-limit` counts per IP; `trust proxy = 1` makes that the real
  client IP behind exactly one proxy (nginx).

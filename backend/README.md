# PlanNight — Backend API

REST API for **PlanNight**, a time-scheduled daily task planner & discipline tracker.
Node.js + Express + PostgreSQL, containerised with Docker.

> This backend is intentionally written in a clear, layered style
> (`routes → controller/service → db`) with heavy comments, so it doubles as a
> teaching example.

---

## Architecture at a glance

```
src/
├── config/          env loading (validated) + PostgreSQL pool
├── common/          shared zod schemas + calendar-date helpers
├── db/
│   ├── migrations/  raw SQL migrations (001_init.sql, ...)
│   └── migrate.js   tiny migration runner (up | status)
├── middleware/      auth guard, request validation, error handler
├── utils/           ApiError, asyncHandler, password (bcrypt), jwt
├── modules/         one folder per feature: routes + validation + service + serializer
│   ├── auth/        register / login / refresh
│   ├── users/       profile + settings (GET/PATCH /users/me)
│   ├── categories/  CRUD (soft-delete)
│   ├── tasks/       CRUD, day/range listing, status, reschedule
│   ├── recurring/   templates CRUD + POST /planning/generate
│   ├── stats/       daily / summary / streak (computed on the fly)
│   └── sync/        GET /sync?since= delta pull
├── app.js           assembles Express (routes + middleware)
└── server.js        boots the process (DB check, listen, graceful shutdown)
```

### Key design decisions

| Concern | Decision |
| --- | --- |
| **Times** | Stored as `plan_date DATE` + `start_time TIME` (wall-clock) with the user's IANA `timezone`. It's a personal daily planner, not a cross-timezone calendar. |
| **Recurring tasks** | Stored as **templates**, materialised into real `tasks` rows via `POST /planning/generate` when a day is planned. Editing one day never touches the series. |
| **Stats & streaks** | **Computed on the fly** with SQL aggregates. No denormalised stats table to invalidate. |
| **Offline sync** | Every row has `updated_at` + `deleted_at`. Clients pull deltas via `GET /sync?since=` and replay queued writes through the normal REST endpoints on reconnect (last-write-wins). |
| **Auth** | JWT access (short-lived) + refresh (long-lived), signed with separate secrets. |

---

## Running locally with Docker (recommended)

Prerequisites: Docker + Docker Compose.

```bash
# 1. From the repo root, create the backend env file and set secrets.
cp backend/.env.example backend/.env
#    Edit backend/.env — at minimum set JWT_ACCESS_SECRET and JWT_REFRESH_SECRET
#    to two DIFFERENT strong values, e.g.:
#      openssl rand -hex 48

# 2. Build & start Postgres + migrations + API.
docker compose up --build

# 3. The API is now on http://localhost:4000
curl http://localhost:4000/health
# -> {"status":"ok","uptime":...}
```

The `migrate` service runs `001_init.sql` before the API starts. To re-run
migrations manually:

```bash
docker compose run --rm migrate
```

---

## Running locally without Docker

Prerequisites: Node 20+ and a PostgreSQL you can connect to. The easiest source
is the compose stack's own database:

```bash
docker compose up -d db        # from the repo root; publishes Postgres on :5433

cd backend
npm install
cp .env.example .env           # DB_PORT is already 5433; set the JWT secrets
npm run migrate                # apply migrations
npm run dev                    # start with auto-reload (node --watch)
```

> **Port 4000 can only have one owner.** `docker compose up` already runs the API
> there. Stop it (`docker stop plannight-api-1`) before `npm run dev`, or the
> host process fails to bind.

> **Why 5433 and not 5432?** If PostgreSQL is also installed natively on your
> machine it grabs 5432 when Windows boots, and Docker then fails to publish
> there *without printing an error* — `docker ps` still claims `5432->5432`. Every
> host connection silently reaches the wrong server, which answers
> `password authentication failed for user "plannight"` (SQLSTATE 28P01) for a
> database that is running perfectly. Publishing on 5433 sidesteps the collision.
> Check who owns a port with `Get-NetTCPConnection -LocalPort 5432 -State Listen`.

Useful scripts:

| Script | Purpose |
| --- | --- |
| `npm run dev` | Start API with file watching |
| `npm start` | Start API (production style) |
| `npm run migrate` | Apply pending migrations |
| `npm run migrate:status` | Show applied vs pending migrations |

---

## Deploying to a remote server (Hetzner / Ubuntu)

1. **Install Docker + Compose** on the server.
2. **Copy the repo** (git clone or rsync) to e.g. `/opt/plannight`.
3. **Create `backend/.env`** with production values:
   - strong, unique `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET`
   - a strong `DB_PASSWORD`
   - `NODE_ENV=production`
   - `CORS_ORIGINS` set to your app's origin(s) if you use it from the web
4. **Start it:**
   ```bash
   docker compose up -d --build
   ```
   The API listens on `127.0.0.1:4000`. In `docker-compose.yml` you may want to
   bind the port to localhost only (`"127.0.0.1:4000:4000"`) and remove the
   published `5432` on the `db` service so Postgres isn't internet-exposed.
5. **Put Nginx in front** for HTTPS. A ready-to-adapt config is in
   [`deploy/nginx.conf.example`](../deploy/nginx.conf.example):
   ```bash
   sudo cp deploy/nginx.conf.example /etc/nginx/sites-available/plannight
   # edit server_name to your domain, then:
   sudo ln -s /etc/nginx/sites-available/plannight /etc/nginx/sites-enabled/
   sudo certbot --nginx -d api.yourdomain.com     # provisions Let's Encrypt cert
   sudo nginx -t && sudo systemctl reload nginx
   ```

To update after code changes: `git pull && docker compose up -d --build`.

---

## API reference

Base path: `/api`. All authenticated routes require
`Authorization: Bearer <accessToken>`.

### Auth
| Method | Path | Body | Notes |
| --- | --- | --- | --- |
| POST | `/api/auth/register` | `{ email, password, timezone? }` | Returns `{ user, accessToken, refreshToken }` |
| POST | `/api/auth/login` | `{ email, password }` | Returns `{ user, accessToken, refreshToken }` |
| POST | `/api/auth/refresh` | `{ refreshToken }` | Returns `{ accessToken, refreshToken }` |

### Users / settings
| Method | Path | Body |
| --- | --- | --- |
| GET | `/api/users/me` | — |
| PATCH | `/api/users/me` | any of `{ timezone, language, theme, streakThresholdPct, notificationsEnabled, reminderLeadMinutes }` |

`language` is `'en' | 'ru' | 'tg'` — the UI language, kept on the user row so it
follows the account to a new device and reaches it through `GET /sync`.

### Categories
| Method | Path | Body |
| --- | --- | --- |
| GET | `/api/categories` | — |
| POST | `/api/categories` | `{ name, color? }` |
| PATCH | `/api/categories/:id` | `{ name?, color? }` |
| DELETE | `/api/categories/:id` | — (soft delete) |

### Tasks
| Method | Path | Body / Query |
| --- | --- | --- |
| GET | `/api/tasks?date=YYYY-MM-DD` | Today/day view (filters: `categoryId`, `priority`, `status`) |
| GET | `/api/tasks?from=&to=` | Range (history/calendar) |
| GET | `/api/tasks/:id` | — |
| POST | `/api/tasks` | `{ title, planDate, startTime?, notes?, categoryId?, priority?, durationMinutes?, reminderLeadMinutes?, sortOrder? }` |
| PATCH | `/api/tasks/:id` | any subset of the above |
| DELETE | `/api/tasks/:id` | — (soft delete) |
| POST | `/api/tasks/:id/status` | `{ status: "completed" \| "skipped" \| "planned" }` |
| POST | `/api/tasks/:id/reschedule` | `{ date }` → marks original `rescheduled`, creates a copy on the new day |

### Recurring templates & planning
| Method | Path | Body |
| --- | --- | --- |
| GET | `/api/recurring-templates` | — |
| POST | `/api/recurring-templates` | `{ title, startTime, recurrenceType, daysOfWeek?, ... }` |
| PATCH | `/api/recurring-templates/:id` | subset |
| DELETE | `/api/recurring-templates/:id` | — (soft delete) |
| POST | `/api/planning/generate` | `{ date }` → creates task rows for matching templates (idempotent) |

`recurrenceType` is `daily`, `weekly`, or `custom`. For `weekly`/`custom`,
`daysOfWeek` is an array of ints `0..6` (0 = Sunday).

### Stats
| Method | Path | Returns |
| --- | --- | --- |
| GET | `/api/stats/daily?date=` | `{ date, total, completed, skipped, pending, completionPct, successful }` |
| GET | `/api/stats/summary?from=&to=` | per-day breakdown + totals (weekly screen / monthly chart) |
| GET | `/api/stats/streak` | `{ current, longest, threshold, asOf }` |

### Sync
| Method | Path | Returns |
| --- | --- | --- |
| GET | `/api/sync?since=<ISO>` | `{ serverTime, user, categories[], tasks[], templates[] }` — rows changed since `since` (includes soft-deleted). Omit `since` for a full snapshot. |

### Error shape

All errors return a consistent JSON body:

```json
{ "error": { "message": "Validation failed", "code": "VALIDATION_ERROR", "details": [ ... ] } }
```

---

## Notes / future hardening

- **Refresh token revocation:** tokens are currently stateless. To support
  logout-everywhere, persist a per-user token version and check it on refresh.
- **Tests:** the layered structure (pure services + `createApp()` without a
  bound port) is set up so you can add supertest/vitest integration tests easily.

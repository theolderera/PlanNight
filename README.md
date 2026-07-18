# PlanNight

A time-scheduled **daily task planner & discipline tracker**. Plan tomorrow the
night before, follow the schedule the next day, check tasks off, and build
streaks through visible progress.

This is **not** a generic to-do app — the emphasis is on time-scheduled daily
planning, completion tracking, and discipline via streaks and weekly stats.

## Monorepo layout

```
PlanNight/
├── backend/     Node.js + Express + PostgreSQL REST API (Dockerised)
├── mobile/      Flutter app (Android) — offline-first, Riverpod, drift, fl_chart
├── deploy/      Nginx reverse-proxy reference config
├── docs/        Architecture, backend/mobile references, operations, backlog
└── docker-compose.yml   Postgres + migrations + API
```

## Documentation

| Doc | Contents |
| --- | --- |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | how the system fits together: offline sync protocol, time model, stats/streak semantics, decision log |
| [docs/BACKEND.md](docs/BACKEND.md) | backend file map, full API reference, DB schema, gotchas |
| [docs/MOBILE.md](docs/MOBILE.md) | Flutter file map, state rules, the en/ru/tg l10n system, tests |
| [docs/OPERATIONS.md](docs/OPERATIONS.md) | production layout, redeploying, building APKs, environment traps |
| [docs/IMPROVEMENTS.md](docs/IMPROVEMENTS.md) | prioritized backlog |
| [CLAUDE.md](CLAUDE.md) | condensed onboarding for AI-assisted sessions (invariants & conventions) |

## Status

| Area | State |
| --- | --- |
| Backend project structure | ✅ Done |
| PostgreSQL schema & migrations | ✅ Done |
| Auth (JWT register/login/refresh) | ✅ Done |
| Categories CRUD | ✅ Done |
| Tasks CRUD + status + reschedule | ✅ Done |
| Recurring templates + day generation | ✅ Done |
| Stats (daily / weekly summary / streak) | ✅ Done |
| Delta sync endpoint | ✅ Done |
| Flutter app (all screens) | ✅ Done |
| Offline-first cache + sync (drift + outbox) | ✅ Done |
| Local notifications | ✅ Done (needs on-device verification) |
| English / Russian / Tajik UI | ✅ Done — see [mobile/README](mobile/README.md#languages) |
| Release APK | ✅ Builds (~62 MB, debug-signed) — see [mobile/README](mobile/README.md#building-a-release-apk) |

## Quick start (backend)

```bash
cp .env.example .env                    # DB credentials, read by Docker Compose
cp backend/.env.example backend/.env    # set JWT secrets
docker compose up --build               # Postgres + migrations + API on :4000
curl http://localhost:4000/health
```

> The root `.env` is the single source of truth for the database credentials.
> Compose does not read `backend/.env` when expanding `${DB_PASSWORD}`, so
> setting a strong password only there would create Postgres with one password
> and connect the API with another.

See [`backend/README.md`](backend/README.md) for the full API reference, local
(non-Docker) setup, and remote deployment instructions.

## Core concepts

- **Templates → tasks:** recurring habits live as templates and are expanded into
  concrete, checkable task rows for a given day.
- **Wall-clock times:** tasks are a local `plan_date` + `start_time` plus the
  user's timezone, so "07:30 tomorrow" means 07:30 where the user is.
- **On-the-fly stats:** completion %, weekly summaries, and streaks are computed
  from the tasks themselves — always consistent.
- **Offline-first client:** the app caches locally, pulls deltas via `/sync`, and
  replays queued writes when back online (last-write-wins).
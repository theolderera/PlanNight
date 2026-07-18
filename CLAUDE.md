# PlanNight — agent onboarding

Time-scheduled daily task planner & discipline tracker (NOT a generic todo app):
evening planning of the next day's time-scheduled tasks, completion tracking,
streaks, weekly stats. Trilingual UI: **en / ru / tg**.

Detailed docs (read the relevant one BEFORE exploring source — they are accurate
and current; only fall back to reading code for line-level detail):

| Doc | Read when working on |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | data flow, offline sync protocol, design decisions |
| [docs/BACKEND.md](docs/BACKEND.md) | API endpoints, DB schema, backend file map |
| [docs/MOBILE.md](docs/MOBILE.md) | Flutter app: file map, state, l10n system, tests |
| [docs/OPERATIONS.md](docs/OPERATIONS.md) | running locally, deploying, APK builds, env gotchas |
| [docs/IMPROVEMENTS.md](docs/IMPROVEMENTS.md) | prioritized backlog of agreed future work |

## Layout & stack

- `backend/` — Node 20 ESM + Express 4 + PostgreSQL 16 (raw SQL via `pg`, zod
  validation, JWT auth). No ORM, no TypeScript, no backend tests (yet).
- `mobile/` — Flutter 3.44 Android app. Riverpod, go_router, drift (SQLite
  cache), dio, fl_chart, flutter_local_notifications. Offline-first.
- `docker-compose.yml` — db + one-shot migrate + api. `deploy/` — nginx example.

## Environments (state as of 2026-07-18)

- **Production**: LIVE on the user's MVPS VPS `91.227.40.11`, code at
  `/opt/plannight`. Public URL: **https://plannight.91-227-40-11.sslip.io**
  (nginx + Let's Encrypt, auto-renewing; API container is loopback-only on
  127.0.0.1:8080). Nightly pg_dump backups via cron. Ports 4000/3000 on that
  box belong to an unrelated "storeos" project — never touch.
- **Local dev**: `docker compose up -d` → API :4000, Postgres published on
  **5433** (native Postgres owns 5432 on this machine).
- **GitHub**: `github.com/theolderera/PlanNight` (private), branch `main`.

## Commands

```bash
# backend (local)
docker compose up -d --build      # from repo root; needs .env (cp .env.example .env)
curl localhost:4000/health

# mobile (run from mobile/)
flutter analyze && flutter test   # 42 tests, all must stay green
flutter build apk --release --dart-define=API_BASE_URL=<url>/api
dart run build_runner build       # only after editing lib/data/local/database.dart
```

## Invariants — do not break

1. **Outbox may only drop an entry** when the server provably applied it
   (create→409, update/delete/setStatus→404) or rejected its *content* (4xx
   except 401/403/408/429). Offline/5xx/429/401 ⇒ keep entry, stop flush,
   preserve order. Pinned by `mobile/test/sync_engine_test.dart`.
2. **Never use `DateFormat`/intl for user-visible dates** — intl has no Tajik
   data and throws. Use `DateLabels` (`mobile/lib/core/date_utils.dart`), which
   reads month/weekday names from ARB.
3. **Tajik needs the fallback delegates** in `mobile/lib/core/l10n.dart` (serves
   Russian *framework* strings) or `showDatePicker` crashes under locale `tg`.
4. **Server error prose is never shown to users** — map `error.code` via
   `mobile/lib/data/api/api_error.dart`. New backend `ApiError` code ⇒ add a
   mapping + ARB strings in all three languages.
5. All backend queries are scoped `user_id = $N`; deletes are soft
   (`deleted_at`); dynamic UPDATEs go through `buildUpdateSet`
   (`backend/src/common/sql.js`) — never hand-build SET clauses.
6. Client generates task/category/template UUIDs; creates are idempotent
   (`ON CONFLICT (id) DO NOTHING` + fetch-existing).
7. Keep `l10n_untranslated.json` equal to `{}` — every ARB key exists in en+ru+tg.
8. Pinned deps (`drift 2.33.0` pair, `sqlparser 0.44.0` override, `intl: any`)
   — see `mobile/NOTES.md` before touching pubspec.

## Conventions

- Backend module = `*.routes.js` (HTTP) → `*.service.js` (logic, throws
  `ApiError`) → `*.serializer.js` (snake_case row → camelCase JSON). Validation
  in `*.validation.js` (zod), wired via `validate({body|query|params})`;
  validated query lands on `req.validatedQuery`.
- Mobile screen files under `features/<area>/`; data via Riverpod providers in
  `data/ui_providers.dart` (reactive drift streams) — screens never call dio
  directly. All user-visible strings via `context.l10n.*` (ARB), never literals.
- Dates cross the wire as `'YYYY-MM-DD'`, times as `'HH:MM'`, wall-clock local;
  per-user IANA `timezone` drives streak day rollover server-side.
- Comments explain *why*, matching the existing density; English throughout code.

## User context

The user is a programming instructor (reuses this code as teaching material —
keep it clean and commented) and communicates in Tajik; reply in Tajik unless
asked otherwise. Verify claims by running things — don't assert "works" without
having exercised it.

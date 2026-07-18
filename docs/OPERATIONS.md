# PlanNight — Operations

> Running, deploying, building APKs, and every environment gotcha that has
> actually bitten this project. Production state: see the table below.

## Production (as of 2026-07-18)

| Thing | Value |
|---|---|
| Server | MVPS VPS-148541, Ubuntu 24.04, 1 core / 2 GB / 25 GB, IP **91.227.40.11** |
| API | `http://91.227.40.11:8080/api` · health `http://91.227.40.11:8080/health` |
| Code | `/opt/plannight` (backend/, docker-compose.yml, deploy/, .env, backend/.env) |
| Containers | plannight-api-1 (0.0.0.0:8080→4000), plannight-db-1 (**127.0.0.1**:5433→5432, hidden from internet) |
| Restart | `unless-stopped` + docker enabled ⇒ survives reboot |
| TLS | **None yet** — plain HTTP to an IP. Top improvement item. |
| Cohabitant | "storeos" project owns ports **3000 and 4000** + host nginx :80 + native Postgres 127.0.0.1:5432. **Never touch.** No ufw on the box — any published port is instantly public. |
| SSH | key-only (ed25519 deploy key in root's authorized_keys). Panel root password was reset once for bootstrap, then removed from disk. New agent session without the key: MVPS panel → REBOOT → "Attempt to reset" → new password → install a fresh key. |
| Server accounts | `ahmad@plannight.app` / `planNight2026` (language tg) — the owner's. Local `test@plannight.local` does NOT exist on the server. |

### Redeploy after code changes

```bash
# from repo root, KEY = the deploy key
tar --exclude='backend/node_modules' --exclude='backend/.env' --exclude='.git' \
    -czf - backend docker-compose.yml deploy \
  | ssh -i KEY root@91.227.40.11 'tar xzf - -C /opt/plannight'
ssh -i KEY root@91.227.40.11 'cd /opt/plannight && docker compose up -d --build'
ssh -i KEY root@91.227.40.11 'curl -s localhost:8080/health'
```

New SQL migration ⇒ the one-shot `migrate` service applies it automatically on
`up`. Server secrets live only in `/opt/plannight/.env` + `backend/.env`
(chmod 600, generated with `openssl rand -hex`, distinct from local dev).
**Never overwrite them with local files** — the tar command above excludes
`.env` for exactly that reason.

## Local development

```bash
cp .env.example .env                      # once; root .env is read by COMPOSE
cp backend/.env.example backend/.env      # once; set JWT secrets
docker compose up -d --build              # db (:5433) + migrate + api (:4000)
curl localhost:4000/health
```

- **Do not also run `npm run dev`** — the containerized API already owns :4000.
- Local test account: `test@plannight.local` / `test12345`.
- Local DB is published on **5433** because a *native* PostgreSQL owns 5432 on
  the dev machine; Docker fails to bind silently and host connections to 5432
  reach the wrong server. Inside the compose network it is always `db:5432`.

### The compose interpolation trap (root cause of a real prod-config bug)

`${DB_PASSWORD}` in docker-compose.yml is interpolated by Compose from the
**shell / root `.env` only — never from `backend/.env`**. The root `.env` is
therefore the single source of truth for DB credentials; compose re-injects the
same values into api/migrate as env vars (which override backend/.env). Setting
a strong password only in backend/.env ⇒ Postgres initializes with the default
while the API connects with the strong one ⇒ every query fails.

## Building APKs

```bash
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=<CHOICE>/api
# output: build/app/outputs/flutter-apk/app-release.apk (~64 MB)
```

| API_BASE_URL | Use case |
|---|---|
| `http://91.227.40.11:8080/api` | **production** — works from any network; ship this one |
| `http://localhost:4000/api` | USB + `adb reverse tcp:4000 tcp:4000` (immune to Wi-Fi/IP churn; reverse must be re-run after unplug/reboot) |
| `http://<PC-LAN-IP>:4000/api` | phone on same Wi-Fi — fragile, see below |
| `http://10.0.2.2:4000/api` | Android emulator only (the compiled-in default) |

**Cleartext allowlist** — Android 9+ blocks plain HTTP. Every non-HTTPS host
must be listed (literal hosts only, no wildcards) in
`mobile/android/app/src/main/res/xml/network_security_config.xml`, currently:
10.0.2.2, localhost, 192.168.28.137, 192.168.31.137, 91.227.40.11. New host ⇒
add + rebuild. XML comments must not contain `--` (breaks the resource build).
Once HTTPS exists, the server entry goes away entirely.

**Verify what an APK actually points at** (dart-defines are compiled into
`lib/*/libapp.so`; note Cyrillic strings sit there as UTF-16, so a naive UTF-8
grep misses them): unzip the APK, check `libapp.so` contains the expected URL
and `res/*.xml` the allowlisted IP — exact PowerShell snippets in the session
logs / git history.

**Wi-Fi LAN pitfalls** (each cost real debugging time): DHCP reassigns the PC's
IP per network (an APK built for the old IP dies with "cannot reach server");
guest networks (e.g. Softclub) often isolate clients from PCs entirely; Windows
Firewall needs an inbound TCP-4000 allow rule (admin); the phone must have
mobile data off or it may bypass the LAN. 5-second triage: open
`http://<ip>:<port>/health` in the **phone's browser** before blaming the app.
Preferred fixes: production APK, or USB + adb reverse.

## Dev environment quirks (this specific machine)

- **Flutter** `D:\ahmad\flutter`; **Android SDK** `D:\ahmad\Android\Sdk`;
  JDK via Android Studio (`D:\andrstudio\jbr`, Java 21) — auto-detected.
  `flutter doctor` still nags about unaccepted licenses; release builds work
  anyway. Never accept licenses on the owner's behalf.
- **Dart's HttpClient cannot reach GitHub release hosts** here (PowerShell
  can). The sqlite3 native-assets libs are pre-seeded into
  `mobile/.dart_tool/hooks_runner/shared/sqlite3/build/download-<sha8>/`
  (hash-validated, so they're reused not re-downloaded). If that cache is ever
  wiped, builds fail at "Building native assets" — re-seed per `mobile/NOTES.md`.
- Docker Desktop must be running for compose; `docker compose` v2 syntax.

## Git / GitHub

- Remote: `https://github.com/theolderera/PlanNight` (private), branch `main`,
  pushed via Git Credential Manager (browser auth).
- `.gitignore` excludes all real `.env`s, `.claude/`, keys/certs. **Before any
  commit touching config**: `git diff --cached --name-only | grep -iE
  '(^|/)\.env$|_key|\.pem'` must return nothing.
- Commit messages end with the `Co-Authored-By: Claude` trailer (repo
  convention).

## Rate limit while testing

Auth endpoints allow **20 attempts / 15 min / IP**. Scripted login tests can
lock you out (429) — space them or restart the api container to reset.

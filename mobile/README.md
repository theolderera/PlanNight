# PlanNight — Mobile App (Flutter)

The Android client for PlanNight: an offline-first, time-scheduled daily task
planner & discipline tracker. Riverpod for state, drift for the local cache,
dio for the API, fl_chart for stats, and flutter_local_notifications for
on-device reminders.

## Architecture

```
lib/
├── core/            config, theme, router, date helpers, l10n, DI providers, shared widgets
├── l10n/            app_en.arb / app_ru.arb / app_tg.arb + generated AppLocalizations
├── data/
│   ├── api/         dio client (JWT attach + refresh-on-401), localised error mapping
│   ├── local/       drift database (cache + outbox), token storage, mappers
│   ├── models/      plain DTOs (Task, Category, RecurringTemplate, UserProfile, Stats)
│   ├── repositories/ auth, task, category, recurring, stats
│   ├── sync/        SyncEngine (outbox replay + delta pull) + SyncCoordinator
│   └── ui_providers.dart   reactive StreamProviders the screens watch
└── features/        one folder per screen area
    ├── auth/  today/  planning/  tasks/  recurring/
    ├── stats/  history/  categories/  settings/  notifications/  home/
```

**Offline-first flow:** screens read reactively from the drift cache, so they
always work offline. A write updates the cache immediately (optimistic UI) and
appends to an **outbox**; the `SyncEngine` replays queued writes to the API and
pulls server deltas (`/sync?since=`) when online — last-write-wins. Task rows use
client-generated UUIDs so a locally-created task keeps its id after syncing.

A queued write is only ever **discarded** once the server has demonstrably
applied it (409 on a create, 404 on an update/delete) or definitively rejected
its content (400/422). Anything else — offline, 5xx, 429, a 401 mid-flush — keeps
the entry and stops the flush, preserving order for dependent writes. See
`test/sync_engine_test.dart`, which pins every one of those cases down.

## Languages

The app ships in **English, Russian and Tajik**. Strings live in
`lib/l10n/app_*.arb` and `flutter gen-l10n` (wired via `l10n.yaml` and
`generate: true`) turns them into `AppLocalizations`; screens read them through
`context.l10n`. `l10n_untranslated.json` must stay `{}` — a key missing from a
locale silently falls back to English.

Two things need care:

- **Flutter has no `tg` translations.** `GlobalMaterialLocalizations` would throw
  the moment a Tajik user opened a date picker. `lib/core/l10n.dart` registers a
  fallback delegate that serves the *Russian* Material/Cupertino strings for
  Tajik. Only framework labels are affected.
- **`intl` has no `tg` date symbols**, so `DateFormat(..., 'tg')` throws too. Month
  and weekday names come from the ARB files instead, via `DateLabels` in
  `lib/core/date_utils.dart`. That also lets Russian use the genitive month inside
  a date ("8 июля") but the nominative in a header ("Июль 2026"), and Tajik the
  izofat ("8 июли 2026").

The choice is stored on the user row (`users.language`, migration 002), so it
follows the account across devices and syncs like any other setting. Backend
error text is never shown raw: `lib/data/api/api_error.dart` maps the API's
stable `error.code` to a translated message.

## Prerequisites

- **Flutter** 3.44+ (Dart 3.12+)
- **A JDK 17** (Temurin/OpenJDK or the one bundled with Android Studio). Gradle
  needs it — set `JAVA_HOME`, or run `flutter config --jdk-dir <path>`.
- **Android SDK** with **cmdline-tools** installed and licenses accepted:
  ```
  sdkmanager --install "cmdline-tools;latest" "platform-tools" "platforms;android-35" "build-tools;35.0.0"
  flutter doctor --android-licenses      # accept all
  ```
- First build downloads the `sqlite3` native library from GitHub (via the
  `sqlite3` package's native-assets hook) — needs normal internet access.

Run `flutter doctor` until the Android section is a green check.

## Running against the backend

Start the backend first (from the repo root): `cp .env.example .env && docker compose up -d`. Then:

```bash
cd mobile
flutter pub get

# Android emulator (reaches your host's localhost via 10.0.2.2):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api

# Physical device on the same Wi-Fi (use your PC's LAN IP):
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000/api

# Against your deployed Hetzner server:
flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com/api
```

> **Plain HTTP on a real device:** Android 9+ blocks cleartext traffic. Production
> uses HTTPS, so the default stays on; the LAN exceptions live in
> `android/app/src/main/res/xml/network_security_config.xml`. Add your PC's LAN IP
> there (`ipconfig`) or the app's requests will fail with a connection error.

If you change `lib/data/local/database.dart`, regenerate drift code:
```
dart run build_runner build
```

## Building a release APK

```bash
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=https://api.yourdomain.com/api
# output: build/app/outputs/flutter-apk/app-release.apk
```

Install on a device: `flutter install` (with the device connected), or copy the
APK across and open it (enable "install unknown apps").

> The release build currently signs with the **debug** keystore (see
> `android/app/build.gradle.kts`) so it installs directly. For distribution,
> create a real keystore + `key.properties` and point the `release`
> `signingConfig` at it — see
> https://docs.flutter.dev/deployment/android#signing-the-app.

### Notifications

`flutter_local_notifications` needs the extras already configured here:
- core-library desugaring (`android/app/build.gradle.kts`)
- permissions + boot receivers (`android/app/src/main/AndroidManifest.xml`)

On first launch after login the app requests notification (and exact-alarm)
permission. Reminders are scheduled locally for the next 7 days of timed,
still-pending tasks, at each task's time minus its reminder lead.

## Testing

```bash
flutter analyze
flutter test
```

- `database_test.dart` — real-SQLite cache: ordering, soft-delete, outbox, watermark
- `sync_engine_test.dart` — exactly which outbox entries may be dropped vs retried
- `l10n_test.dart` — all three locales load, no English leakage, Tajik date pickers open
- `widget_test.dart` — model parsing

## Pinned dependencies

See [`NOTES.md`](NOTES.md) for why `drift`/`drift_dev` are pinned to `2.33.0` and
`sqlparser` is overridden to `0.44.0` (a broken upstream combination otherwise
breaks codegen).

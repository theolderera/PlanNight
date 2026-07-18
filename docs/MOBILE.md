# PlanNight — Mobile (Flutter) reference

> Flutter 3.44 / Dart 3.12, Android-first. Riverpod (state), go_router
> (navigation), drift (SQLite cache), dio (HTTP), fl_chart (charts),
> flutter_local_notifications (reminders). Offline-first throughout.
> Run `flutter analyze && flutter test` (53 tests) after any change.

## Design system — "Daylight" (light) / "Nocturne" (dark)

One visual language, defined in `core/theme.dart`:

- **Palette** lives on `AppColors` (a `ThemeExtension`), read via `context.colors`
  — warm `paper`, white `surface`, deep-navy hero cards `navy`, cobalt `accent`,
  gold `streakStart/End`, `success`, `textSecondary/Muted/Faint`, `border`,
  `divider`, `trackBg`, `danger*`. Light and dark are both hand-tuned; `lerp`
  animates theme switches.
- **Type**: two bundled variable fonts (`assets/fonts/`, OFL) — `PlusJakartaSans`
  (UI, the default family) + `SpaceGrotesk` (numbers/times/stats, via
  `context.mono(...)`). Don't introduce another font.
- **Icons are Material rounded/outlined only — NO emoji anywhere** (product rule).
  The brand mark is drawn: `AppLogo` (a `CustomPainter`, crescent + check).
- **Shared widgets** (`core/widgets/app_widgets.dart`): `AppLogo`, `ProgressRing`,
  `SurfaceCard` (standard shadowed card), `PillSegment` (sliding segmented
  control), `FieldTile`, `FieldLabel`, `SectionLabel`. Reuse these — don't
  hand-roll card `BoxDecoration`s. Component themes (buttons/inputs/nav/switch/
  slider/chips/dialogs/sheets/snackbars/popups) are all set in `theme.dart`.
- `test/design_test.dart` renders every block in both brightnesses (incl. the
  painters) as a regression guard.

When adding UI: colours from `context.colors`, text from the `TextTheme` or
`context.mono`, layout from the shared widgets. Keep the two-font and no-emoji
rules.

## File map (`mobile/lib/`)

```
main.dart                     ProviderContainer, notification init, runApp
app.dart                      MaterialApp.router: theme + LOCALE from user.language,
                              l10n delegates, keeps sync/notification providers alive,
                              notification-tap → /today (registered once in initState)
core/
  config.dart                 AppConfig.apiBaseUrl ← --dart-define=API_BASE_URL
                              (default http://10.0.2.2:4000/api = emulator)
  l10n.dart                   context.l10n ext · AppLocale enum (en/ru/tg + nativeName)
                              · l10nFor(code) for no-context call sites ·
                              TAJIK FALLBACK DELEGATES (see §l10n) · supportedLocales
  date_utils.dart             Dates (pure date math) + DateLabels (ALL user-visible
                              date text, ARB-driven — never DateFormat)
  reminder_options.dart       shared lead-time list [0,5,10,15,30,60] + labels
  device.dart                 getDeviceTimezone() / getDeviceLanguage() (null if unsupported)
  providers.dart              DI roots: tokenStorage, apiClient (session-expiry → forceLogout),
                              database, syncEngine
  router.dart                 GoRouter: /splash /login /register + editors +
                              StatefulShellRoute 5 tabs (/today /plan /stats /history /settings);
                              redirect derives from auth state (loading→splash,
                              signed-out→login, signed-in→today)
  theme.dart                  Material 3, seed #6C63FF, light/dark
  widgets/                    EmptyState, ErrorBanner
data/
  api/api_client.dart         dio wrapper: Bearer attach; on 401 single-flight refresh
                              then one retry (extra['retried']); refresh uses a bare
                              closed-after-use Dio; failure → onSessionExpired
  api/api_error.dart          apiErrorMessage(l10n, err, fallback?) — maps error.code →
                              localized text; server prose NEVER shown
  local/database.dart         drift schema v1: Categories/Tasks/Templates rows mirror API
                              ('YYYY-MM-DD'/'HH:MM' strings) + OutboxEntries + SyncMeta;
                              reactive watch* queries; upserts; clearAll() on logout
  local/database.g.dart       GENERATED — never hand-edit; `dart run build_runner build`
  local/mappers.dart          row↔model↔API-JSON conversions; *CompanionFromApi preserve
                              server updatedAt/deletedAt verbatim (sync correctness)
  local/token_storage.dart    flutter_secure_storage for JWTs
  models/                     Task (+Priority/TaskStatus enums; labels take l10n),
                              Category (hex→Color), RecurringTemplate (+RecurrenceType),
                              UserProfile (incl. language), stats DTOs
  repositories/               task/category/recurring: optimistic write + outbox + syncNow;
                              auth: register/login/getMe/token persistence;
                              stats: online-only API reads
  sync/sync_engine.dart       flushOutbox (ordered replay, KEEP-vs-DROP rules — see
                              ARCHITECTURE §3) + pull (delta upserts in one transaction,
                              onUserPulled hook, serverTime watermark)
  sync/sync_coordinator.dart  triggers: login→sync, logout→clearAll, connectivity
                              regained→sync; wires onUserPulled → authController.updateUser
  ui_providers.dart           StreamProviders screens watch: categories, tasksForDay(date),
                              tasksInRange(from,to), templates, pendingSyncCount
features/
  auth/auth_controller.dart   AsyncNotifier<UserProfile?>: session restore on build();
                              setSession/updateUser (ignored when logged out — a pull
                              racing logout must not resurrect the session);
                              updateSettings = optimistic + outbox('user','update');
                              logout/forceLogout
  auth/login_screen.dart      + register_screen.dart (sends device timezone+language)
  home/home_shell.dart        NavigationBar; destinations built per-build (localized)
  today/today_screen.dart     date bar, progress header (excludes rescheduled),
                              priority/category filter sheet, TaskTile list
  planning/planning_screen.dart  plan a day (default tomorrow), generate-from-templates
  tasks/task_edit_screen.dart    create/edit form; save errors surface in a SnackBar
  tasks/widgets/task_tile.dart   status control, time+category chip, actions menu
  recurring/templates_screen.dart + template_edit_screen.dart  weekday chips map
                              API 0=Sun..6=Sat ↔ Dart DateTime.weekday (Sunday: 0↔7)
  stats/stats_screen.dart     hero tiles (streak/week/good days), weekly bars,
                              30-day trend; stats_providers.dart (summary family, streak)
  history/history_screen.dart Mon-first month grid, per-day dot vs threshold, day list
  categories/categories_screen.dart  list + colour-picker dialog editor
  settings/settings_screen.dart      theme segButtons, LANGUAGE dropdown (nativeName),
                              threshold slider, notification prefs, links, logout
  notifications/notification_service.dart    tz init; permission requests;
                              scheduleForTasks(tasks, enabled, defaultLead, languageCode)
                              = cancelAll + reschedule next-7-days pending timed tasks
  notifications/notification_providers.dart  scheduler re-runs on task/settings/language change
l10n/  app_en.arb (TEMPLATE with @metadata) · app_ru.arb · app_tg.arb ·
       app_localizations*.dart (GENERATED by flutter gen-l10n via l10n.yaml)
```

## State management rules

- Screens watch **streams from the drift cache** (`ui_providers.dart`) — the
  UI never awaits network. Stats are the one exception (online `FutureProvider`s
  with a friendly offline error card).
- Repositories own all writes (optimistic + outbox). Screens never touch dio.
- `authControllerProvider` (`AsyncNotifier<UserProfile?>`): `null` = signed
  out; `AsyncLoading` = restoring session (router shows splash). Its `theme` /
  `language` fields drive `MaterialApp` directly, so those settings apply
  instantly and offline.
- Root-level `ref.watch(syncCoordinatorProvider)` + `notificationSchedulerProvider`
  in `app.dart` keep the background machinery alive for the app's lifetime.

## l10n system (en / ru / tg) — read before touching any user-visible string

- Strings live in `lib/l10n/app_*.arb`; `flutter gen-l10n` (config in
  `l10n.yaml`, runs on every build via `generate: true`) produces
  `AppLocalizations`. Screens use `context.l10n.key`; no-context code
  (notifications) uses `l10nFor(languageCode)`.
- **Every key must exist in all three files** — `l10n_untranslated.json` must
  stay `{}` (a missing key silently falls back to English).
- **Tajik has no Flutter framework translations.** `core/l10n.dart` registers
  fallback Material/Cupertino delegates that serve the *Russian* framework
  strings for locale `tg` (delegate order matters: they precede the Global*
  ones). Without them `showDatePicker`/`showTimePicker` crash under `tg`.
- **intl has no `tg` data** — `DateFormat` throws. All date text goes through
  `DateLabels`, whose ARB keys include TWO month sets: `monthStandalone*`
  (header: «Июль 2026») and `monthInDate*` (inside a date: ru genitive «8
  июля», tg izofat «8 июли»). Weekday keys are indexed 1..7 = Mon..Sun matching
  `DateTime.weekday`.
- Locale resolution: signed out → device locale (via `supportedLocales`
  matching); signed in → `user.language` forced. Register sends
  `getDeviceLanguage()` (null when unsupported → server defaults 'en').
- Server errors: add any new backend `ApiError` code to
  `api_error.dart::_messageForCode` + three ARB strings.
- Android notification-channel name/description are localized at schedule time,
  but Android caches channel metadata by id after first creation — stale until
  reinstall; deliberate (recreating the channel would reset user overrides).

## Tests (`mobile/test/`, 42 green — keep them green)

| File | Pins down |
|---|---|
| database_test.dart | real-SQLite cache: ordering (untimed last), soft-delete hiding, upsert LWW, outbox order, watermark |
| sync_engine_test.dart | the outbox KEEP-vs-DROP matrix + stop-at-first-transient ordering (fake `HttpClientAdapter` per status code). These failed when the old data-loss bug was reintroduced — that is their job |
| l10n_test.dart | locale mapping/fallbacks, no-English-leakage sampling, DateLabels grammar (ru genitive, tg izofat), Tajik `MaterialLocalizations` resolves and `showDatePicker` opens |
| widget_test.dart | model JSON parsing edge cases |

## Build & pins

APK: `flutter build apk --release --dart-define=API_BASE_URL=<url>/api` —
wrong/missing define = app pointing at the emulator default; see
[OPERATIONS.md](OPERATIONS.md) for URL choices, the cleartext allowlist, and
release signing (real keystore, git-ignored `key.properties`; debug fallback
on a fresh clone). Pinned deps (`drift`/`drift_dev` 2.33.0 matched pair,
`sqlparser 0.44.0` override, `intl: any` because flutter_localizations pins it
exactly): rationale in `mobile/NOTES.md` — do not bump blindly.

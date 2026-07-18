# Mobile build notes

## Pinned dependency versions (and why)

These pins in `pubspec.yaml` are deliberate — do not "upgrade" them without checking:

- **`drift: 2.33.0` + `drift_dev: 2.33.0`** — must be a matched pair. The pub
  resolver otherwise picks `drift 2.34.1` + `drift_dev 2.34.0`, a broken combo.
- **`dependency_overrides: sqlparser: 0.44.0`** — `sqlparser 0.44.6` removed a
  `DartPlaceholder.when(...)` helper that `drift_dev` still calls, which breaks
  `build_runner` codegen ("The method 'when' isn't defined for the type
  'DartPlaceholder'"). Pinning to `0.44.0` restores codegen. `sqlparser` is only
  used by `drift_dev` at build time, so this override has no runtime effect.

Regenerate drift code after editing `lib/data/local/database.dart`:

```
dart run build_runner build
```

## Environment quirks in this sandbox

- Dart's HttpClient can't reach **GitHub** release hosts, so the `sqlite3`
  native-assets download fails. The prebuilt libs are pre-seeded into
  `.dart_tool/hooks_runner/shared/sqlite3/build/download-<sha8>/`, where `<sha8>`
  is the first 8 hex chars of the file's sha256 — the hook validates by hash and
  reuses a matching file instead of re-downloading. Seeded and verified:
  Windows host `sqlite3.dll` plus `libsqlite3.so` for arm64-v8a, armeabi-v7a and
  x86_64. Fetch them with PowerShell's `Invoke-WebRequest` (which *can* reach
  GitHub) if the cache is ever wiped.
- The GitHub block is **GitHub-specific**, not a general network failure: other
  CDNs are fine. The JDK below downloaded from `corretto.aws` at full speed.
- **JDK 17** (Corretto) is installed at `D:\ahmad\jdk17` and registered with
  `flutter config --jdk-dir`. Android SDK is at `D:\ahmad\Android\Sdk` with
  `cmdline-tools` present and all licenses accepted.

With the above in place, `flutter build apk --release` succeeds here.

## Running

Backend must be up (`docker compose up` at repo root). Then:

```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api   # Android emulator
```

For a physical device, use your host machine's LAN IP instead of 10.0.2.2.

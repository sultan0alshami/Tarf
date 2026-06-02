# Phase 4 — Cloud Sync & Sign-in Scaffolding: Implementation Plan

> For agentic workers: implement task-by-task; steps use `- [ ]`.

**Goal:** Introduce an OPTIONAL cloud-sync + sign-in capability for Tarf without ever weakening the local-first, fully-offline guest experience. Concretely: (1) funnel every feature write through ONE persistence-repository interface that can later mirror to the cloud; (2) add an `AuthService` interface with a Firebase implementation (Google / Apple / Email-Password) gated behind a build flag, plus a `FakeAuthService` for unit tests and the Auth emulator for integration; (3) define the per-user Firestore document tree + tightened `firestore.rules` + a last-write-wins sync layer with an offline write queue and guest→cloud merge on sign-in; (4) wire CLOUD account deletion (Firestore subtree + Auth account) into the existing mandatory delete-all; (5) ship emulator-based integration tests and document the exact emulator workflow. Sign-in buttons stay disabled ("Coming soon") until a feature flag + config are present. Mandatory data export + delete-all stay reachable and must also clear the cloud copy when signed in. 58 tests stay green; `flutter analyze` stays clean.

**Architecture:** Everything new is additive and lives mostly in NEW files to minimise contention with Phase 1 (sound settings) and Phase 3 (multi-timer + prayer location), which touch the same domain models. The current persistence (six `tarf.*.v1` JSON blobs in `SharedPreferences`, read/written ad-hoc inside each Notifier) is abstracted behind a `TarfRepository` interface with a `PrefsRepository` default implementation that is byte-for-byte compatible with today's keys/format. A `CloudMirror` abstraction (no-op by default) lets the repository fan-out writes to Firestore later WITHOUT changing call sites again. `AuthService` + `SyncService` + `CloudAccount` are interfaces with Fake implementations for unit tests and Firebase implementations exercised against the Local Emulator Suite. A single `FirebaseFlags` object (compile-time `bool.fromEnvironment('TARF_CLOUD')` + presence of `firebase_options.dart`) decides whether sign-in is enabled; when off, the app is exactly today's app. The repository call-site refactor (high contention) is sequenced LAST (Task 9), after the abstraction, auth, schema, sync, and deletion land as isolated new files.

**Tech Stack:** Flutter 3.44 / Dart 3.12 · Riverpod 3 hand-written `Notifier`/`NotifierProvider` (NO codegen) · go_router 17 · `shared_preferences` (local-first default) · `firebase_core` / `firebase_auth` / `cloud_firestore` / `firebase_app_check` · `google_sign_in` · `sign_in_with_apple` (all added in Task 0, guarded so guest mode works with config absent) · Firebase Local Emulator Suite (Auth + Firestore) · `@firebase/rules-unit-testing` (Node) for rules tests · `fake_cloud_firestore` + `firebase_auth_mocks` for fast Dart unit tests · `flutter_test`. Flutter SDK at `C:\dev\flutter\bin` (prepend to PATH). l10n ARB → gen-l10n, Western digits default.

---

## File Structure

```
app/
  pubspec.yaml                                    (MODIFY — add firebase_* + google_sign_in + sign_in_with_apple + dev deps)
  lib/
    main.dart                                     (MODIFY — guarded Firebase.initializeApp + repository/flags overrides)
    firebase/
      firebase_flags.dart                         (NEW — compile-time + runtime cloud gate)
      firebase_bootstrap.dart                     (NEW — guarded Firebase init, returns FirebaseAvailability)
      firebase_options.dart                       (NOT created here; OWNER runs flutterfire configure; git-ignored)
    core/
      data/
        tarf_repository.dart                      (NEW — repository interface + StorageKey enum + RepositoryEvent)
        prefs_repository.dart                     (NEW — SharedPreferences-backed default impl)
        cloud_mirror.dart                         (NEW — CloudMirror interface + NoopCloudMirror)
        repository_providers.dart                 (NEW — tarfRepositoryProvider + cloudMirrorProvider)
        local_data_manager.dart                   (MODIFY — route export/delete through TarfRepository; add async cloud delete hook)
      settings/
        settings_controller.dart                  (MODIFY in Task 9 — read/write via repository)
      cloud/
        sync_models.dart                          (NEW — SyncStatus, PendingWrite, WriteQueue)
        sync_service.dart                         (NEW — SyncService interface + FakeSyncService)
        firestore_paths.dart                      (NEW — typed per-user document paths + JSON codecs)
        firestore_sync_service.dart               (NEW — Firestore impl: mirror writes, LWW, queue, merge-on-sign-in)
        firestore_cloud_mirror.dart               (NEW — CloudMirror impl wrapping FirestoreSyncService)
    features/
      account/
        application/
          auth_service.dart                       (NEW — AuthService interface, AuthUser, AuthState, FakeAuthService)
          firebase_auth_service.dart              (NEW — Firebase/Google/Apple/Email impl, guarded)
          account_controller.dart                 (NEW — Notifier exposing AuthState + sign-in/out/delete actions)
          cloud_account.dart                      (NEW — CloudAccount interface: deleteCloudData + deleteAccount; Fake + Firebase impls)
        presentation/
          account_screen.dart                     (MODIFY — enable buttons only when flag+config; wire sign-in/out; cloud-aware delete)
    l10n/
      app_en.arb, app_ar.arb                      (MODIFY — add sync/sign-in/error strings; re-run gen-l10n)
  firebase/
    firestore.rules                               (MODIFY — tighten: validate shapes, deny deletes-by-rule except via app, keep per-uid)
    firestore.indexes.json                        (NEW — composite indexes, empty to start)
    firebase.json                                 (NEW — emulator ports + rules/indexes wiring)
    .firebaserc                                   (NEW — demo project alias for the emulator)
    storage.rules                                 (NOT needed — no Cloud Storage in Phase 4)
    rules-tests/
      package.json                                (NEW — @firebase/rules-unit-testing harness)
      firestore.rules.test.js                     (NEW — uid isolation + shape validation tests)
  test/
    core/data/
      prefs_repository_test.dart                  (NEW)
      repository_compat_test.dart                 (NEW — byte-compat with legacy keys/format)
    core/cloud/
      write_queue_test.dart                       (NEW)
      firestore_paths_test.dart                   (NEW)
      sync_service_fake_test.dart                 (NEW — LWW + merge-on-sign-in semantics)
    features/account/
      auth_service_fake_test.dart                 (NEW)
      account_controller_test.dart                (NEW)
      account_screen_gating_test.dart             (NEW — buttons disabled when flag off, enabled when on)
      cloud_delete_test.dart                      (NEW — delete-all clears local + cloud)
  integration_test/
    emulator/
      auth_emulator_test.dart                     (NEW — real firebase_auth against Auth emulator)
      sync_emulator_test.dart                     (NEW — mirror + merge + delete against Firestore emulator)
docs/
  firebase-setup.md                               (MODIFY — add the emulator workflow + exact commands)
```

---

## Cross-phase dependencies & integration points

- **DEPENDS ON data-model stability.** Phase 1 adds **sound settings** and Phase 3 adds **multi-timer list + prayer location**. The current `EyeCareConfig` ALREADY carries the P1 sound fields (`soundEnabled`, `hapticEnabled`, `loudThroughSilence`) and the P3 prayer-location fields (`prayerLatitude`, `prayerLongitude`, `prayerMethod`, `prayerMadhab`, `prayerAlarmsEnabled`) — so the `settings/app` document and the repository's opaque-JSON-blob model already accommodate them. **No schema change is needed when P1/P3 land**, because the sync layer mirrors each `StorageKey`'s JSON blob verbatim (see Task 5 "blob-mirror" design) rather than enumerating individual fields. The ONE place that enumerates fields is the optional fine-grained `dailyProgress` counter mapping (Task 6) — additive only.
- **Multi-timer list (P3):** today `timer_controller.dart` holds a single `CountdownData` and persists nothing. If P3 introduces a persisted `tarf.timers.v1` blob, add a `StorageKey.timers` enum case + one row in `firestore_paths.dart` — both additive, no call-site churn. The plan reserves the key name `tarf.timers.v1` so P3 and P4 do not collide.
- **Sequencing to reduce contention:** Tasks 0–8 are almost entirely NEW files (`core/cloud/**`, `features/account/application/**`, `app/firebase/**`) → **worktree-safe**, can land while P1/P3 are in flight. **Task 9 (call-site refactor of the six controllers + `main.dart` + `settings_controller.dart`)** is the high-contention task and MUST merge AFTER P1 and P3 have settled those same files. Recommended merge order: **P1 → P3 → P4-tasks-0..8 (any time) → P4-task-9 (last) → P4-tasks-10..11**.
- **Integration with existing mandatory flows:** `LocalDataManager.exportJson` / `deleteAll` and `account_screen.dart`'s export/delete already exist and stay reachable for guests. Task 4 makes delete *also* clear the cloud when signed in; Task 9 routes them through the repository. Export remains local-only JSON (the cloud is a mirror of local, so the local export is already complete).
- **Feature flag contract:** `FirebaseFlags.cloudEnabled` = `const bool.fromEnvironment('TARF_CLOUD')` AND `FirebaseBootstrap` reported availability. Default build → `false` → identical to today. Emulator/integration builds pass `--dart-define=TARF_CLOUD=true` and point at the emulator.

---

### Task 0 — Add dependencies + guarded Firebase bootstrap + feature flag (NEW files; guest-safe)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\pubspec.yaml`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\firebase\firebase_flags.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\firebase\firebase_bootstrap.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\account\firebase_flags_test.dart`

Steps:

- [ ] Write the failing test `firebase_flags_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/firebase/firebase_flags.dart';

  void main() {
    test('cloud is disabled by default (no dart-define, no config)', () {
      const flags = FirebaseFlags(configPresent: false);
      expect(flags.cloudEnabled, isFalse);
      expect(flags.signInAvailable, isFalse);
    });

    test('cloud requires BOTH the compile flag and present config', () {
      // compileEnabled is injected for testability; in prod it reads
      // const bool.fromEnvironment('TARF_CLOUD').
      expect(const FirebaseFlags(configPresent: true, compileEnabled: false).cloudEnabled, isFalse);
      expect(const FirebaseFlags(configPresent: false, compileEnabled: true).cloudEnabled, isFalse);
      expect(const FirebaseFlags(configPresent: true, compileEnabled: true).cloudEnabled, isTrue);
      expect(const FirebaseFlags(configPresent: true, compileEnabled: true).signInAvailable, isTrue);
    });
  }
  ```
- [ ] Run (expect FAIL — `firebase_flags.dart` does not exist):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/features/account/firebase_flags_test.dart
  ```
  Expected: `Error: Couldn't resolve the package 'tarf' ... firebase_flags.dart` / compile error → FAIL.
- [ ] Add dependencies to `pubspec.yaml` under `dependencies:` (keep existing entries; pin conservatively, then `flutter pub get` resolves):
  ```yaml
    firebase_core: ^4.0.0
    firebase_auth: ^6.0.0
    cloud_firestore: ^6.0.0
    firebase_app_check: ^0.4.0
    google_sign_in: ^7.0.0
    sign_in_with_apple: ^7.0.0
  ```
  and under `dev_dependencies:`:
  ```yaml
    fake_cloud_firestore: ^4.0.0
    firebase_auth_mocks: ^0.15.0
    integration_test:
      sdk: flutter
  ```
- [ ] Implement `firebase_flags.dart` (minimal):
  ```dart
  /// Decides whether OPTIONAL cloud features are available. Cloud is OFF unless
  /// the app was compiled with `--dart-define=TARF_CLOUD=true` AND Firebase
  /// config is present (firebase_options.dart generated by the owner). Guest
  /// mode is the default and never depends on this being true.
  class FirebaseFlags {
    const FirebaseFlags({
      required this.configPresent,
      this.compileEnabled = const bool.fromEnvironment('TARF_CLOUD'),
    });

    /// Whether `Firebase.initializeApp` succeeded with real options.
    final bool configPresent;

    /// Compile-time master switch.
    final bool compileEnabled;

    bool get cloudEnabled => compileEnabled && configPresent;

    /// Sign-in UI is only enabled when cloud is fully available.
    bool get signInAvailable => cloudEnabled;
  }
  ```
- [ ] Implement `firebase_bootstrap.dart` (guarded init that NEVER throws into guest mode):
  ```dart
  import 'package:firebase_core/firebase_core.dart';

  /// Result of attempting to bring Firebase online at startup.
  class FirebaseAvailability {
    const FirebaseAvailability({required this.ready});
    final bool ready;
  }

  /// Initializes Firebase only if the master compile flag is on. Any failure
  /// (missing config, emulator down) degrades gracefully to guest mode.
  ///
  /// [optionsLoader] returns the generated FirebaseOptions; it is null until the
  /// owner runs `flutterfire configure`. We accept it as a parameter so this file
  /// compiles WITHOUT firebase_options.dart present.
  Future<FirebaseAvailability> bootstrapFirebase({
    required bool compileEnabled,
    Future<FirebaseOptions>? Function()? optionsLoader,
  }) async {
    if (!compileEnabled || optionsLoader == null) {
      return const FirebaseAvailability(ready: false);
    }
    try {
      final options = await optionsLoader();
      if (options == null) return const FirebaseAvailability(ready: false);
      await Firebase.initializeApp(options: options);
      return const FirebaseAvailability(ready: true);
    } catch (_) {
      return const FirebaseAvailability(ready: false);
    }
  }
  ```
- [ ] Run (expect PASS for the flag test; bootstrap is covered later by the emulator test):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter pub get; flutter test test/features/account/firebase_flags_test.dart
  ```
  Expected: `All tests passed!`
- [ ] Run the FULL suite + analyze to prove nothing regressed (deps added, no wiring yet):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter analyze; flutter test
  ```
  Expected: analyze clean; `All tests passed!` (58 + 2 new).
- [ ] Commit:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git add app/pubspec.yaml app/pubspec.lock app/lib/firebase/firebase_flags.dart app/lib/firebase/firebase_bootstrap.dart app/test/features/account/firebase_flags_test.dart
  git commit -m @'
  feat(cloud): add firebase deps + guarded bootstrap + cloud feature flag

  Adds firebase_core/auth/firestore/app_check + google_sign_in + sign_in_with_apple
  and test fakes. FirebaseFlags gates all cloud features behind TARF_CLOUD compile
  flag AND present config; guest mode is unaffected. No call sites wired yet.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  '@
  ```

---

### Task 1 — `TarfRepository` interface + `StorageKey` + `PrefsRepository` (NEW; byte-compatible)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\data\tarf_repository.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\data\prefs_repository.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\data\prefs_repository_test.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\data\repository_compat_test.dart`

Design notes: the repository stores **opaque JSON values per logical key**. This keeps it agnostic to field additions from P1/P3 — a settings/eyecare blob can grow new keys with zero repository changes. Keys mirror today's six `tarf.*.v1` strings exactly so `PrefsRepository` is a drop-in.

Steps:

- [ ] Write failing `prefs_repository_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/data/prefs_repository.dart';
  import 'package:tarf/core/data/tarf_repository.dart';

  void main() {
    late PrefsRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = PrefsRepository(await SharedPreferences.getInstance());
    });

    test('write then read round-trips a JSON map', () async {
      await repo.writeJson(StorageKey.settings, {'localeCode': 'ar', 'reduceMotion': true});
      expect(repo.readJson(StorageKey.settings), {'localeCode': 'ar', 'reduceMotion': true});
    });

    test('missing key reads as null', () {
      expect(repo.readJson(StorageKey.todos), isNull);
    });

    test('writes emit a RepositoryEvent for the cloud mirror', () async {
      final events = <RepositoryEvent>[];
      final sub = repo.changes.listen(events.add);
      await repo.writeJson(StorageKey.progress, {'2026-06-01': 1});
      await Future<void>.delayed(Duration.zero);
      expect(events.single.key, StorageKey.progress);
      await sub.cancel();
    });

    test('delete removes the value and emits a tombstone event', () async {
      await repo.writeJson(StorageKey.alarms, {'x': 1});
      final events = <RepositoryEvent>[];
      final sub = repo.changes.listen(events.add);
      await repo.delete(StorageKey.alarms);
      await Future<void>.delayed(Duration.zero);
      expect(repo.readJson(StorageKey.alarms), isNull);
      expect(events.single.deleted, isTrue);
      await sub.cancel();
    });

    test('clearAll wipes every known key', () async {
      await repo.writeJson(StorageKey.settings, {'a': 1});
      await repo.writeJson(StorageKey.todos, {'b': 2});
      await repo.clearAll();
      for (final k in StorageKey.values) {
        expect(repo.readJson(k), isNull, reason: k.name);
      }
    });
  }
  ```
- [ ] Write failing `repository_compat_test.dart` (PROVES the new layer is byte-identical to legacy storage so existing data and the existing `widget_test.dart` keep working):
  ```dart
  import 'dart:convert';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/data/prefs_repository.dart';
  import 'package:tarf/core/data/tarf_repository.dart';

  void main() {
    test('StorageKey ids exactly match the legacy prefs keys', () {
      expect(StorageKey.settings.id, 'tarf.app_settings.v1');
      expect(StorageKey.eyecareConfig.id, 'tarf.eyecare_config.v1');
      expect(StorageKey.focusConfig.id, 'tarf.focus_config.v1');
      expect(StorageKey.progress.id, 'tarf.progress.v1');
      expect(StorageKey.todos.id, 'tarf.todos.v1');
      expect(StorageKey.alarms.id, 'tarf.alarms.v1');
    });

    test('reads data written the OLD way (raw setString) unchanged', () async {
      SharedPreferences.setMockInitialValues({
        'tarf.app_settings.v1': jsonEncode({'localeCode': 'ar', 'onboardingComplete': true}),
      });
      final repo = PrefsRepository(await SharedPreferences.getInstance());
      expect(repo.readJson(StorageKey.settings)!['localeCode'], 'ar');
    });

    test('writes data the OLD code can still read (same key + json)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PrefsRepository(prefs);
      await repo.writeJson(StorageKey.todos, {'list': []});
      // Legacy reader path:
      expect(prefs.getString('tarf.todos.v1'), jsonEncode({'list': []}));
    });
  }
  ```
- [ ] Run (expect FAIL — files missing):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/core/data/
  ```
  Expected: compile errors / FAIL.
- [ ] Implement `tarf_repository.dart`:
  ```dart
  /// Logical storage keys. `id` is the EXACT SharedPreferences key used today, so
  /// the prefs-backed implementation is byte-compatible with existing data and the
  /// Firestore mirror can map each key to one document.
  enum StorageKey {
    settings('tarf.app_settings.v1'),
    eyecareConfig('tarf.eyecare_config.v1'),
    focusConfig('tarf.focus_config.v1'),
    progress('tarf.progress.v1'),
    todos('tarf.todos.v1'),
    alarms('tarf.alarms.v1'),
    // Reserved for Phase 3 multi-timer list; additive, no call-site churn here.
    timers('tarf.timers.v1');

    const StorageKey(this.id);
    final String id;

    static StorageKey? fromId(String id) {
      for (final k in values) {
        if (k.id == id) return k;
      }
      return null;
    }
  }

  /// Emitted on every write/delete so a [CloudMirror] can fan-out to the cloud.
  class RepositoryEvent {
    const RepositoryEvent(this.key, {this.deleted = false});
    final StorageKey key;
    final bool deleted;
  }

  /// The SINGLE persistence seam for every feature. All settings, eye-rests,
  /// focus/progress, todos, alarms (and future timers) go through here so a cloud
  /// mirror can be attached without touching call sites again. Values are opaque
  /// JSON maps — field additions from other phases need no repository change.
  abstract interface class TarfRepository {
    /// Synchronous read (data is loaded at startup). Null if absent.
    Map<String, Object?>? readJson(StorageKey key);

    /// Persists [value] and notifies [changes]. Local write is the source of truth.
    Future<void> writeJson(StorageKey key, Map<String, Object?> value);

    /// Removes [key] and emits a tombstone event.
    Future<void> delete(StorageKey key);

    /// Removes every known key (backs delete-all).
    Future<void> clearAll();

    /// Fires after each local write/delete (drives the optional cloud mirror).
    Stream<RepositoryEvent> get changes;

    /// A pretty-printed JSON snapshot of all keys (backs data export).
    String exportJson();
  }
  ```
- [ ] Implement `prefs_repository.dart`:
  ```dart
  import 'dart:async';
  import 'dart:convert';

  import 'package:shared_preferences/shared_preferences.dart';

  import 'tarf_repository.dart';

  /// Local-first default. Identical on-disk format to the pre-Phase-4 controllers.
  class PrefsRepository implements TarfRepository {
    PrefsRepository(this._prefs);

    final SharedPreferences _prefs;
    final _changes = StreamController<RepositoryEvent>.broadcast();

    @override
    Stream<RepositoryEvent> get changes => _changes.stream;

    @override
    Map<String, Object?>? readJson(StorageKey key) {
      final raw = _prefs.getString(key.id);
      if (raw == null) return null;
      try {
        return jsonDecode(raw) as Map<String, Object?>;
      } catch (_) {
        return null;
      }
    }

    @override
    Future<void> writeJson(StorageKey key, Map<String, Object?> value) async {
      await _prefs.setString(key.id, jsonEncode(value));
      _changes.add(RepositoryEvent(key));
    }

    @override
    Future<void> delete(StorageKey key) async {
      await _prefs.remove(key.id);
      _changes.add(RepositoryEvent(key, deleted: true));
    }

    @override
    Future<void> clearAll() async {
      for (final k in StorageKey.values) {
        await _prefs.remove(k.id);
        _changes.add(RepositoryEvent(k, deleted: true));
      }
    }

    @override
    String exportJson() {
      final out = <String, Object?>{};
      for (final k in StorageKey.values) {
        final raw = _prefs.getString(k.id);
        if (raw == null) continue;
        try {
          out[k.id] = jsonDecode(raw);
        } catch (_) {
          out[k.id] = raw;
        }
      }
      return const JsonEncoder.withIndent('  ').convert(out);
    }
  }
  ```
  > NOTE: this intentionally stores LISTS (todos/alarms) under a wrapper map? No — todos/alarms persist a JSON *array* today, not a map. To stay byte-compatible we must NOT force a map. Resolve in the next step.
- [ ] FIX the list-vs-map mismatch BEFORE finishing: todos/alarms persist a top-level JSON array (`[ {...} ]`), progress/settings/configs persist a JSON object. Change the repository value type to `Object?` (JSON value) rather than `Map`. Update `tarf_repository.dart`: rename `readJson`→`read(StorageKey): Object?`, `writeJson`→`write(StorageKey, Object?)`, and `RepositoryEvent` unchanged. Update `prefs_repository.dart` accordingly (decode/encode `Object?`). Update the two tests above to use arrays for todos/alarms (e.g. `await repo.write(StorageKey.todos, [{'id':'t1'}]); expect(repo.read(StorageKey.todos), [{'id':'t1'}]);`). This keeps the mirror generic and byte-compatible. (Re-run after editing.)
- [ ] Run (expect PASS):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/core/data/
  ```
  Expected: `All tests passed!`
- [ ] Run analyze:
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter analyze
  ```
  Expected: `No issues found!`
- [ ] Commit:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git add app/lib/core/data/tarf_repository.dart app/lib/core/data/prefs_repository.dart app/test/core/data/prefs_repository_test.dart app/test/core/data/repository_compat_test.dart
  git commit -m @'
  feat(data): add TarfRepository seam + byte-compatible PrefsRepository

  One persistence interface (opaque JSON per StorageKey) that all features will
  write through, with a change stream for an optional cloud mirror. StorageKey ids
  match the legacy tarf.*.v1 keys so existing data and tests are unaffected. No
  call sites refactored yet (sequenced late to reduce contention).

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  '@
  ```

---

### Task 2 — `CloudMirror` interface + `NoopCloudMirror` + repository providers (NEW; default no-op)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\data\cloud_mirror.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\data\repository_providers.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\data\cloud_mirror_test.dart`

Steps:

- [ ] Write failing `cloud_mirror_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/data/cloud_mirror.dart';
  import 'package:tarf/core/data/prefs_repository.dart';
  import 'package:tarf/core/data/tarf_repository.dart';

  void main() {
    test('NoopCloudMirror ignores events and never throws', () async {
      const mirror = NoopCloudMirror();
      await mirror.onChange(const RepositoryEvent(StorageKey.settings), null);
      // no-op: nothing to assert beyond "did not throw".
      expect(mirror.isActive, isFalse);
    });

    test('attachMirror forwards repository writes to the mirror', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = PrefsRepository(await SharedPreferences.getInstance());
      final spy = _SpyMirror();
      final detach = attachMirror(repo, spy);
      await repo.write(StorageKey.todos, [{'id': 't1'}]);
      await Future<void>.delayed(Duration.zero);
      expect(spy.seen.single.key, StorageKey.todos);
      await detach();
    });
  }

  class _SpyMirror implements CloudMirror {
    final seen = <RepositoryEvent>[];
    @override
    bool get isActive => true;
    @override
    Future<void> onChange(RepositoryEvent e, Object? value) async => seen.add(e);
  }
  ```
- [ ] Run (expect FAIL):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/core/data/cloud_mirror_test.dart
  ```
- [ ] Implement `cloud_mirror.dart`:
  ```dart
  import 'dart:async';

  import 'tarf_repository.dart';

  /// Receives each local write/delete so it can mirror to the cloud. Default
  /// implementation is a NO-OP, preserving local-first/offline behaviour.
  abstract interface class CloudMirror {
    bool get isActive;
    Future<void> onChange(RepositoryEvent event, Object? value);
  }

  /// The default: does nothing. Guest mode and disabled-cloud builds use this.
  class NoopCloudMirror implements CloudMirror {
    const NoopCloudMirror();
    @override
    bool get isActive => false;
    @override
    Future<void> onChange(RepositoryEvent event, Object? value) async {}
  }

  /// Subscribes [mirror] to [repo]'s change stream. Returns a detach callback.
  /// Reading the current value happens here so the mirror stays storage-agnostic.
  Future<void> Function() attachMirror(TarfRepository repo, CloudMirror mirror) {
    final sub = repo.changes.listen((event) {
      final value = event.deleted ? null : repo.read(event.key);
      // Fire-and-forget; mirror handles its own queueing/retries.
      unawaited(mirror.onChange(event, value));
    });
    return () async => sub.cancel();
  }
  ```
- [ ] Implement `repository_providers.dart` (Riverpod wiring; overridden in `main.dart` and tests):
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import 'cloud_mirror.dart';
  import 'tarf_repository.dart';

  /// The app's single repository. Overridden in main() with a PrefsRepository
  /// (and, when cloud is enabled, an attached CloudMirror).
  final tarfRepositoryProvider = Provider<TarfRepository>(
    (ref) => throw UnimplementedError('tarfRepositoryProvider must be overridden'),
  );

  /// The active cloud mirror. Defaults to a no-op; replaced when signed in.
  final cloudMirrorProvider = Provider<CloudMirror>((ref) => const NoopCloudMirror());
  ```
- [ ] Run (expect PASS) + analyze:
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/core/data/cloud_mirror_test.dart; flutter analyze
  ```
  Expected: `All tests passed!` / `No issues found!`
- [ ] Commit:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git add app/lib/core/data/cloud_mirror.dart app/lib/core/data/repository_providers.dart app/test/core/data/cloud_mirror_test.dart
  git commit -m @'
  feat(data): add CloudMirror seam (no-op default) + repository providers

  Local writes can fan-out to the cloud via attachMirror without call-site changes.
  Default NoopCloudMirror keeps guest/offline behaviour. Providers are overridden
  in main() and tests.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  '@
  ```

---

### Task 3 — `AuthService` interface + `FakeAuthService` + `AccountController` (NEW; no Firebase yet)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\account\application\auth_service.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\account\application\account_controller.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\account\auth_service_fake_test.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\account\account_controller_test.dart`

Steps:

- [ ] Write failing `auth_service_fake_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/features/account/application/auth_service.dart';

  void main() {
    test('starts signed-out and emits the guest state', () async {
      final auth = FakeAuthService();
      expect(auth.currentUser, isNull);
      expect(await auth.authState.first, const AuthState.signedOut());
    });

    test('Google sign-in produces a user and emits signedIn', () async {
      final auth = FakeAuthService();
      final states = <AuthState>[];
      final sub = auth.authState.listen(states.add);
      final user = await auth.signInWithGoogle();
      expect(user.uid, isNotEmpty);
      expect(auth.currentUser, isNotNull);
      await Future<void>.delayed(Duration.zero);
      expect(states.last, isA<AuthState>().having((s) => s.user?.uid, 'uid', user.uid));
      await sub.cancel();
    });

    test('email sign-in rejects a wrong password with AuthException', () async {
      final auth = FakeAuthService()..seedEmailUser('a@b.com', 'right');
      expect(
        () => auth.signInWithEmail('a@b.com', 'wrong'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.wrongPassword)),
      );
    });

    test('signOut returns to guest', () async {
      final auth = FakeAuthService();
      await auth.signInWithGoogle();
      await auth.signOut();
      expect(auth.currentUser, isNull);
    });

    test('deleteAccount clears the current user', () async {
      final auth = FakeAuthService();
      await auth.signInWithGoogle();
      await auth.deleteAccount();
      expect(auth.currentUser, isNull);
    });
  }
  ```
- [ ] Run (expect FAIL):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/features/account/auth_service_fake_test.dart
  ```
- [ ] Implement `auth_service.dart`:
  ```dart
  import 'dart:async';

  /// A signed-in identity (provider-agnostic).
  class AuthUser {
    const AuthUser({required this.uid, this.email, this.displayName, this.isAnonymous = false});
    final String uid;
    final String? email;
    final String? displayName;
    final bool isAnonymous;
  }

  /// Stream-friendly auth status.
  class AuthState {
    const AuthState._(this.user);
    const AuthState.signedOut() : user = null;
    const AuthState.signedIn(AuthUser this.user);
    final AuthUser? user;
    bool get isSignedIn => user != null;

    @override
    bool operator ==(Object other) =>
        other is AuthState && other.user?.uid == user?.uid;
    @override
    int get hashCode => user?.uid.hashCode ?? 0;
  }

  enum AuthErrorCode {
    cancelled,
    network,
    wrongPassword,
    userNotFound,
    emailAlreadyInUse,
    accountExistsWithDifferentCredential,
    requiresRecentLogin,
    unknown,
  }

  class AuthException implements Exception {
    const AuthException(this.code, [this.message]);
    final AuthErrorCode code;
    final String? message;
    @override
    String toString() => 'AuthException($code, $message)';
  }

  /// Provider-agnostic auth surface. Firebase impl and Fake impl both satisfy it.
  abstract interface class AuthService {
    AuthUser? get currentUser;
    Stream<AuthState> get authState;

    Future<AuthUser> signInWithGoogle();
    Future<AuthUser> signInWithApple();
    Future<AuthUser> signInWithEmail(String email, String password);
    Future<AuthUser> registerWithEmail(String email, String password);

    Future<void> signOut();

    /// Deletes the AUTH account (may throw requiresRecentLogin). Firestore data
    /// deletion is handled separately by CloudAccount.
    Future<void> deleteAccount();
  }

  /// In-memory fake for unit tests. No Firebase.
  class FakeAuthService implements AuthService {
    AuthUser? _user;
    final _controller = StreamController<AuthState>.broadcast();
    final _emailUsers = <String, String>{}; // email -> password
    int _seq = 0;

    void seedEmailUser(String email, String password) => _emailUsers[email] = password;

    @override
    AuthUser? get currentUser => _user;

    @override
    Stream<AuthState> get authState async* {
      yield _user == null ? const AuthState.signedOut() : AuthState.signedIn(_user!);
      yield* _controller.stream;
    }

    AuthUser _emit(AuthUser u) {
      _user = u;
      _controller.add(AuthState.signedIn(u));
      return u;
    }

    @override
    Future<AuthUser> signInWithGoogle() async =>
        _emit(AuthUser(uid: 'g${_seq++}', email: 'google@example.com', displayName: 'Google User'));

    @override
    Future<AuthUser> signInWithApple() async =>
        _emit(AuthUser(uid: 'a${_seq++}', email: 'apple@example.com'));

    @override
    Future<AuthUser> signInWithEmail(String email, String password) async {
      final stored = _emailUsers[email];
      if (stored == null) throw const AuthException(AuthErrorCode.userNotFound);
      if (stored != password) throw const AuthException(AuthErrorCode.wrongPassword);
      return _emit(AuthUser(uid: 'e${_seq++}', email: email));
    }

    @override
    Future<AuthUser> registerWithEmail(String email, String password) async {
      if (_emailUsers.containsKey(email)) {
        throw const AuthException(AuthErrorCode.emailAlreadyInUse);
      }
      _emailUsers[email] = password;
      return _emit(AuthUser(uid: 'e${_seq++}', email: email));
    }

    @override
    Future<void> signOut() async {
      _user = null;
      _controller.add(const AuthState.signedOut());
    }

    @override
    Future<void> deleteAccount() async {
      _user = null;
      _controller.add(const AuthState.signedOut());
    }
  }
  ```
- [ ] Write failing `account_controller_test.dart`:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/features/account/application/account_controller.dart';
  import 'package:tarf/features/account/application/auth_service.dart';

  void main() {
    test('controller mirrors the auth service state', () async {
      final auth = FakeAuthService();
      final container = ProviderContainer(overrides: [
        authServiceProvider.overrideWithValue(auth),
      ]);
      addTearDown(container.dispose);

      expect(container.read(accountControllerProvider).isSignedIn, isFalse);
      await container.read(accountControllerProvider.notifier).signInWithGoogle();
      expect(container.read(accountControllerProvider).isSignedIn, isTrue);
      await container.read(accountControllerProvider.notifier).signOut();
      expect(container.read(accountControllerProvider).isSignedIn, isFalse);
    });

    test('sign-in error is captured, not thrown to the UI', () async {
      final auth = FakeAuthService();
      final container = ProviderContainer(overrides: [
        authServiceProvider.overrideWithValue(auth),
      ]);
      addTearDown(container.dispose);
      await container.read(accountControllerProvider.notifier).signInWithEmail('x@y.com', 'nope');
      expect(container.read(accountControllerProvider).lastError, AuthErrorCode.userNotFound);
    });
  }
  ```
- [ ] Implement `account_controller.dart`:
  ```dart
  import 'dart:async';

  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import 'auth_service.dart';

  /// Overridden in main() with FirebaseAuthService when cloud is enabled,
  /// otherwise a FakeAuthService (sign-in stays disabled in the UI regardless).
  final authServiceProvider = Provider<AuthService>((ref) => FakeAuthService());

  /// UI-facing account state.
  class AccountState {
    const AccountState({this.user, this.busy = false, this.lastError});
    final AuthUser? user;
    final bool busy;
    final AuthErrorCode? lastError;
    bool get isSignedIn => user != null;

    AccountState copyWith({AuthUser? user, bool clearUser = false, bool? busy, AuthErrorCode? lastError, bool clearError = false}) =>
        AccountState(
          user: clearUser ? null : (user ?? this.user),
          busy: busy ?? this.busy,
          lastError: clearError ? null : (lastError ?? this.lastError),
        );
  }

  class AccountController extends Notifier<AccountState> {
    StreamSubscription<AuthState>? _sub;

    @override
    AccountState build() {
      final auth = ref.watch(authServiceProvider);
      _sub = auth.authState.listen((s) => state = state.copyWith(user: s.user, clearUser: !s.isSignedIn));
      ref.onDispose(() => _sub?.cancel());
      return AccountState(user: auth.currentUser);
    }

    AuthService get _auth => ref.read(authServiceProvider);

    Future<void> _run(Future<void> Function() action) async {
      state = state.copyWith(busy: true, clearError: true);
      try {
        await action();
      } on AuthException catch (e) {
        state = state.copyWith(lastError: e.code);
      } finally {
        state = state.copyWith(busy: false);
      }
    }

    Future<void> signInWithGoogle() => _run(_auth.signInWithGoogle);
    Future<void> signInWithApple() => _run(_auth.signInWithApple);
    Future<void> signInWithEmail(String email, String password) =>
        _run(() => _auth.signInWithEmail(email, password));
    Future<void> registerWithEmail(String email, String password) =>
        _run(() => _auth.registerWithEmail(email, password));
    Future<void> signOut() => _run(_auth.signOut);
  }

  final accountControllerProvider =
      NotifierProvider<AccountController, AccountState>(AccountController.new);
  ```
- [ ] Run (expect PASS) + analyze:
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/features/account/; flutter analyze
  ```
  Expected: `All tests passed!` / `No issues found!`
- [ ] Commit:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git add app/lib/features/account/application/auth_service.dart app/lib/features/account/application/account_controller.dart app/test/features/account/auth_service_fake_test.dart app/test/features/account/account_controller_test.dart
  git commit -m @'
  feat(account): add AuthService interface + FakeAuthService + AccountController

  Provider-agnostic auth surface (Google/Apple/Email) with an in-memory fake for
  unit tests and a Notifier that captures errors instead of throwing to the UI.
  No Firebase implementation wired yet; sign-in remains disabled in the UI.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  '@
  ```

---

### Task 4 — `CloudAccount` (delete cloud data + auth) + cloud-aware delete-all (NEW + small MODIFY)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\account\application\cloud_account.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\data\local_data_manager.dart` (MODIFY — add a repository-based path + async cloud hook; keep the legacy static API used by the current screen until Task 9)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\account\cloud_delete_test.dart`

Steps:

- [ ] Write failing `cloud_delete_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/data/prefs_repository.dart';
  import 'package:tarf/core/data/tarf_repository.dart';
  import 'package:tarf/features/account/application/cloud_account.dart';

  void main() {
    test('FakeCloudAccount records deletion of data then account', () async {
      final acct = FakeCloudAccount();
      await acct.deleteCloudData('uid1');
      await acct.deleteAccount();
      expect(acct.deletedData, contains('uid1'));
      expect(acct.accountDeleted, isTrue);
    });

    test('purgeEverything clears local repo and, when signed in, the cloud', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = PrefsRepository(await SharedPreferences.getInstance());
      await repo.write(StorageKey.todos, [{'id': 't1'}]);
      final acct = FakeCloudAccount();

      await purgeEverything(repo: repo, cloudAccount: acct, uid: 'uid1');

      expect(repo.read(StorageKey.todos), isNull);       // local cleared
      expect(acct.deletedData, contains('uid1'));         // cloud data cleared
      expect(acct.accountDeleted, isTrue);                // auth account removed
    });

    test('purgeEverything with uid==null clears ONLY local (guest)', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = PrefsRepository(await SharedPreferences.getInstance());
      await repo.write(StorageKey.alarms, [{'id': 'a1'}]);
      final acct = FakeCloudAccount();

      await purgeEverything(repo: repo, cloudAccount: acct, uid: null);

      expect(repo.read(StorageKey.alarms), isNull);
      expect(acct.deletedData, isEmpty);
      expect(acct.accountDeleted, isFalse);
    });
  }
  ```
- [ ] Run (expect FAIL):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/features/account/cloud_delete_test.dart
  ```
- [ ] Implement `cloud_account.dart`:
  ```dart
  import 'package:tarf/core/data/tarf_repository.dart';

  /// Deletes a user's CLOUD footprint: their Firestore subtree, then their auth
  /// account. Local clearing is the repository's job (see [purgeEverything]).
  abstract interface class CloudAccount {
    /// Recursively deletes /users/{uid}. Safe to call before deleteAccount.
    Future<void> deleteCloudData(String uid);

    /// Deletes the currently signed-in auth account.
    Future<void> deleteAccount();
  }

  /// In-memory fake for unit tests.
  class FakeCloudAccount implements CloudAccount {
    final deletedData = <String>[];
    bool accountDeleted = false;

    @override
    Future<void> deleteCloudData(String uid) async => deletedData.add(uid);

    @override
    Future<void> deleteAccount() async => accountDeleted = true;
  }

  /// The single mandatory "delete everything" routine wired to the Account screen.
  /// Always clears local. When [uid] is non-null (signed in), it ALSO deletes the
  /// cloud data and the auth account — in that order, so a failure mid-way still
  /// leaves the account able to retry. Guest ([uid] == null) clears local only.
  Future<void> purgeEverything({
    required TarfRepository repo,
    required CloudAccount cloudAccount,
    required String? uid,
  }) async {
    if (uid != null) {
      await cloudAccount.deleteCloudData(uid);
      await cloudAccount.deleteAccount();
    }
    await repo.clearAll();
  }
  ```
- [ ] MODIFY `local_data_manager.dart` — keep the existing static `keys`/`exportJson`/`deleteAll` (still used by the current screen until Task 9) and ADD a repository-aware delegating layer + a re-export of `purgeEverything`, so Task 9's screen edit is a one-line swap. Add at the bottom (do not delete existing members):
  ```dart
  // --- Phase 4 additions (repository-aware; legacy static API kept above) ---

  /// Repository-based export (identical output to the legacy prefs export).
  String exportJsonFromRepo(TarfRepository repo) => repo.exportJson();
  ```
  with `import 'tarf_repository.dart';` added at the top.
- [ ] Run (expect PASS) + analyze:
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/features/account/cloud_delete_test.dart; flutter analyze
  ```
  Expected: `All tests passed!` / `No issues found!`
- [ ] Commit:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git add app/lib/features/account/application/cloud_account.dart app/lib/core/data/local_data_manager.dart app/test/features/account/cloud_delete_test.dart
  git commit -m @'
  feat(account): add CloudAccount + purgeEverything (local + cloud delete-all)

  Mandatory delete-all now has a single routine that always clears local storage
  and, when signed in, deletes the Firestore subtree then the auth account. Guest
  path is local-only. Legacy LocalDataManager API kept; screen rewires in Task 9.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  '@
  ```

---

### Task 5 — Firestore paths + JSON codecs + offline write queue + `SyncService`/`FakeSyncService` (NEW; LWW + merge)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\cloud\firestore_paths.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\cloud\sync_models.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\cloud\sync_service.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\cloud\firestore_paths_test.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\cloud\write_queue_test.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\cloud\sync_service_fake_test.dart`

Design notes — **blob-mirror model:** each `StorageKey` maps to ONE Firestore location. Settings/configs/progress map to single documents under `settings/`; todos/alarms (JSON arrays) map to a single document holding the array under field `items` plus `updatedAt`. This deliberately mirrors the existing JSON blobs verbatim, so **P1 sound fields and P3 prayer/timer fields require no schema change**. (A finer-grained `dailyProgress/{day}` collection with `FieldValue.increment` is an optional optimisation — see Task 6.) Conflict policy: **last-write-wins by `updatedAt` timestamp** stored alongside each blob; on sign-in, **merge** keeps the newer side per key, with a special union/max merge for `progress` so guest activity is never lost.

Steps:

- [ ] Write failing `firestore_paths_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/core/cloud/firestore_paths.dart';
  import 'package:tarf/core/data/tarf_repository.dart';

  void main() {
    test('each StorageKey maps to a stable per-user path', () {
      final p = FirestorePaths('uidX');
      expect(p.docPathFor(StorageKey.settings), 'users/uidX/state/settings');
      expect(p.docPathFor(StorageKey.eyecareConfig), 'users/uidX/state/eyecareConfig');
      expect(p.docPathFor(StorageKey.progress), 'users/uidX/state/progress');
      expect(p.docPathFor(StorageKey.todos), 'users/uidX/state/todos');
      expect(p.docPathFor(StorageKey.alarms), 'users/uidX/state/alarms');
      expect(p.userRoot, 'users/uidX');
    });

    test('encodes a JSON blob into an envelope with payload + updatedAt', () {
      final env = SyncEnvelope.wrap([{'id': 't1'}], updatedAtMs: 1000);
      expect(env.toMap()['payload'], [{'id': 't1'}]);
      expect(env.toMap()['updatedAt'], 1000);
      final back = SyncEnvelope.fromMap(env.toMap());
      expect(back.payload, [{'id': 't1'}]);
      expect(back.updatedAtMs, 1000);
    });
  }
  ```
- [ ] Write failing `write_queue_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/core/cloud/sync_models.dart';
  import 'package:tarf/core/data/tarf_repository.dart';

  void main() {
    test('enqueue keeps only the latest write per key (coalesces)', () {
      final q = WriteQueue();
      q.enqueue(PendingWrite(StorageKey.progress, {'2026-06-01': 1}, atMs: 1));
      q.enqueue(PendingWrite(StorageKey.progress, {'2026-06-01': 2}, atMs: 2));
      q.enqueue(PendingWrite(StorageKey.todos, [{'id': 't1'}], atMs: 3));
      expect(q.length, 2);
      expect(q.peek(StorageKey.progress)!.value, {'2026-06-01': 2});
    });

    test('drain returns pending writes oldest-first and empties the queue', () {
      final q = WriteQueue()
        ..enqueue(PendingWrite(StorageKey.todos, [], atMs: 1))
        ..enqueue(PendingWrite(StorageKey.alarms, [], atMs: 2));
      final drained = q.drain();
      expect(drained.map((w) => w.key), [StorageKey.todos, StorageKey.alarms]);
      expect(q.length, 0);
    });

    test('serializes/deserializes for durable persistence', () {
      final q = WriteQueue()..enqueue(PendingWrite(StorageKey.settings, {'a': 1}, atMs: 5));
      final restored = WriteQueue.fromJson(q.toJson());
      expect(restored.peek(StorageKey.settings)!.value, {'a': 1});
    });
  }
  ```
- [ ] Write failing `sync_service_fake_test.dart` (the heart: LWW + merge semantics, no Firebase):
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/core/cloud/sync_service.dart';
  import 'package:tarf/core/data/tarf_repository.dart';

  void main() {
    group('mergeOnSignIn (last-write-wins per key; progress unions)', () {
      test('newer cloud blob wins over older local blob', () {
        final result = mergeOnSignIn(
          local: {StorageKey.settings: Versioned({'localeCode': 'en'}, 100)},
          cloud: {StorageKey.settings: Versioned({'localeCode': 'ar'}, 200)},
        );
        expect((result[StorageKey.settings]!.value as Map)['localeCode'], 'ar');
      });

      test('newer local blob wins over older cloud blob', () {
        final result = mergeOnSignIn(
          local: {StorageKey.settings: Versioned({'localeCode': 'en'}, 300)},
          cloud: {StorageKey.settings: Versioned({'localeCode': 'ar'}, 200)},
        );
        expect((result[StorageKey.settings]!.value as Map)['localeCode'], 'en');
      });

      test('progress merges per-day taking the MAX counters (no loss either way)', () {
        final result = mergeOnSignIn(
          local: {StorageKey.progress: Versioned({'2026-06-01': {'s': 2, 'fm': 50}}, 100)},
          cloud: {StorageKey.progress: Versioned({'2026-06-01': {'s': 1, 'fm': 75}, '2026-05-31': {'s': 3, 'fm': 60}}, 200)},
        );
        final p = result[StorageKey.progress]!.value as Map;
        expect((p['2026-06-01'] as Map)['s'], 2);   // max(2,1)
        expect((p['2026-06-01'] as Map)['fm'], 75);  // max(50,75)
        expect((p['2026-05-31'] as Map)['s'], 3);    // cloud-only day kept
      });

      test('key present on only one side is kept', () {
        final result = mergeOnSignIn(
          local: {StorageKey.todos: Versioned([{'id': 't1'}], 100)},
          cloud: const {},
        );
        expect(result[StorageKey.todos]!.value, [{'id': 't1'}]);
      });
    });

    group('FakeSyncService', () {
      test('pushPending writes the queue into the fake cloud store', () async {
        final sync = FakeSyncService();
        sync.queue.enqueue(PendingWrite(StorageKey.todos, [{'id': 't1'}], atMs: 1));
        await sync.pushPending();
        expect(sync.cloudStore[StorageKey.todos], [{'id': 't1'}]);
        expect(sync.queue.length, 0);
      });

      test('status transitions offline -> syncing -> synced', () async {
        final sync = FakeSyncService();
        final seen = <SyncStatus>[];
        final sub = sync.status.listen(seen.add);
        await sync.pushPending();
        await Future<void>.delayed(Duration.zero);
        expect(seen, containsAllInOrder([SyncStatus.syncing, SyncStatus.synced]));
        await sub.cancel();
      });
    });
  }
  ```
- [ ] Run (expect FAIL — files missing):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/core/cloud/
  ```
- [ ] Implement `firestore_paths.dart`:
  ```dart
  import 'package:tarf/core/data/tarf_repository.dart';

  /// Per-user document layout. Every StorageKey blob lives at
  /// `users/{uid}/state/{key}` so adding fields inside a blob (P1 sounds, P3
  /// prayer/timer) needs no path change. (See Task 6 for optional fine-grained
  /// dailyProgress.)
  class FirestorePaths {
    FirestorePaths(this.uid);
    final String uid;

    String get userRoot => 'users/$uid';
    String docPathFor(StorageKey key) => 'users/$uid/state/${key.name}';
  }

  /// Wraps a JSON blob with its last-write timestamp for LWW conflict resolution.
  class SyncEnvelope {
    const SyncEnvelope(this.payload, this.updatedAtMs);
    final Object? payload;
    final int updatedAtMs;

    SyncEnvelope.wrap(Object? payload, {required int updatedAtMs})
        : this(payload, updatedAtMs);

    Map<String, Object?> toMap() => {'payload': payload, 'updatedAt': updatedAtMs};

    factory SyncEnvelope.fromMap(Map<String, Object?> m) =>
        SyncEnvelope(m['payload'], (m['updatedAt'] as num?)?.toInt() ?? 0);
  }
  ```
- [ ] Implement `sync_models.dart` (status enum, pending write, durable queue):
  ```dart
  import 'dart:convert';

  import 'package:tarf/core/data/tarf_repository.dart';

  enum SyncStatus { offline, syncing, synced, error }

  /// One queued local write awaiting upload.
  class PendingWrite {
    PendingWrite(this.key, this.value, {required this.atMs});
    final StorageKey key;
    final Object? value;
    final int atMs;

    Map<String, Object?> toJson() => {'k': key.id, 'v': value, 't': atMs};
    static PendingWrite fromJson(Map<String, Object?> j) =>
        PendingWrite(StorageKey.fromId(j['k']! as String)!, j['v'], atMs: (j['t'] as num).toInt());
  }

  /// An offline write queue that coalesces by key (latest wins) and is durable.
  class WriteQueue {
    final _items = <StorageKey, PendingWrite>{};

    int get length => _items.length;

    void enqueue(PendingWrite w) {
      final existing = _items[w.key];
      if (existing == null || w.atMs >= existing.atMs) _items[w.key] = w;
    }

    PendingWrite? peek(StorageKey key) => _items[key];

    /// Oldest-first, then clears.
    List<PendingWrite> drain() {
      final list = _items.values.toList()..sort((a, b) => a.atMs.compareTo(b.atMs));
      _items.clear();
      return list;
    }

    String toJson() => jsonEncode(_items.values.map((w) => w.toJson()).toList());
    static WriteQueue fromJson(String raw) {
      final q = WriteQueue();
      for (final e in (jsonDecode(raw) as List).cast<Map<String, Object?>>()) {
        q.enqueue(PendingWrite.fromJson(e));
      }
      return q;
    }
  }
  ```
- [ ] Implement `sync_service.dart` (interface + pure merge + fake):
  ```dart
  import 'dart:async';

  import 'package:tarf/core/data/tarf_repository.dart';

  import 'sync_models.dart';

  /// A value with the timestamp it was last written at (for LWW).
  class Versioned {
    const Versioned(this.value, this.updatedAtMs);
    final Object? value;
    final int updatedAtMs;
  }

  /// Mirrors local writes to the cloud, queues them offline, and merges guest
  /// data into the cloud on sign-in. Firestore impl + Fake both satisfy it.
  abstract interface class SyncService {
    Stream<SyncStatus> get status;
    WriteQueue get queue;

    /// One-time merge of local guest data into the cloud when a user signs in.
    Future<void> mergeGuestIntoCloud(Map<StorageKey, Versioned> local);

    /// Uploads any queued writes (call on reconnect / after a local write).
    Future<void> pushPending();
  }

  /// Pure LWW merge. Per key the newer [updatedAtMs] wins, EXCEPT [progress],
  /// whose per-day counters are merged with MAX so neither side loses activity.
  Map<StorageKey, Versioned> mergeOnSignIn({
    required Map<StorageKey, Versioned> local,
    required Map<StorageKey, Versioned> cloud,
  }) {
    final keys = {...local.keys, ...cloud.keys};
    final out = <StorageKey, Versioned>{};
    for (final k in keys) {
      final l = local[k];
      final c = cloud[k];
      if (l == null) { out[k] = c!; continue; }
      if (c == null) { out[k] = l; continue; }
      if (k == StorageKey.progress) {
        out[k] = Versioned(_mergeProgress(l.value, c.value),
            l.updatedAtMs > c.updatedAtMs ? l.updatedAtMs : c.updatedAtMs);
      } else {
        out[k] = l.updatedAtMs >= c.updatedAtMs ? l : c;
      }
    }
    return out;
  }

  Map<String, Object?> _mergeProgress(Object? a, Object? b) {
    final ma = (a as Map?)?.cast<String, Object?>() ?? const {};
    final mb = (b as Map?)?.cast<String, Object?>() ?? const {};
    final days = {...ma.keys, ...mb.keys};
    final out = <String, Object?>{};
    for (final d in days) {
      final da = (ma[d] as Map?)?.cast<String, Object?>() ?? const {};
      final db = (mb[d] as Map?)?.cast<String, Object?>() ?? const {};
      final fields = {...da.keys, ...db.keys};
      out[d] = {
        for (final f in fields)
          f: _maxNum(da[f], db[f]),
      };
    }
    return out;
  }

  Object? _maxNum(Object? a, Object? b) {
    if (a is num && b is num) return a > b ? a : b;
    return a ?? b;
  }

  /// In-memory fake: a plain map "cloud", deterministic status transitions.
  class FakeSyncService implements SyncService {
    final cloudStore = <StorageKey, Object?>{};
    @override
    final WriteQueue queue = WriteQueue();
    final _status = StreamController<SyncStatus>.broadcast();

    @override
    Stream<SyncStatus> get status => _status.stream;

    @override
    Future<void> mergeGuestIntoCloud(Map<StorageKey, Versioned> local) async {
      _status.add(SyncStatus.syncing);
      final cloud = {
        for (final e in cloudStore.entries) e.key: Versioned(e.value, 0),
      };
      final merged = mergeOnSignIn(local: local, cloud: cloud);
      merged.forEach((k, v) => cloudStore[k] = v.value);
      _status.add(SyncStatus.synced);
    }

    @override
    Future<void> pushPending() async {
      _status.add(SyncStatus.syncing);
      for (final w in queue.drain()) {
        cloudStore[w.key] = w.value;
      }
      _status.add(SyncStatus.synced);
    }
  }
  ```
- [ ] Run (expect PASS) + analyze:
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/core/cloud/; flutter analyze
  ```
  Expected: `All tests passed!` / `No issues found!`
- [ ] Commit:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git add app/lib/core/cloud/firestore_paths.dart app/lib/core/cloud/sync_models.dart app/lib/core/cloud/sync_service.dart app/test/core/cloud/
  git commit -m @'
  feat(cloud): add Firestore paths, durable write queue, and SyncService merge

  Blob-per-StorageKey layout (users/{uid}/state/{key}) so P1/P3 field additions
  need no schema change. Pure last-write-wins merge with per-day MAX union for
  progress (no activity loss on sign-in). Coalescing offline write queue + a
  FakeSyncService for fast unit tests. No Firebase yet.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  '@
  ```

---

### Task 6 — Firestore security rules: tighten + shape-validate; rules unit tests (Node emulator)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\firebase\firestore.rules` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\firebase\firestore.indexes.json` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\firebase\firebase.json` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\firebase\.firebaserc` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\firebase\rules-tests\package.json` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\firebase\rules-tests\firestore.rules.test.js` (NEW)

Steps:

- [ ] Create `firebase.json` (emulator config — ports chosen to avoid clashes):
  ```json
  {
    "firestore": {
      "rules": "firestore.rules",
      "indexes": "firestore.indexes.json"
    },
    "emulators": {
      "auth": { "port": 9099 },
      "firestore": { "port": 8080 },
      "ui": { "enabled": true, "port": 4000 },
      "singleProjectMode": true
    }
  }
  ```
- [ ] Create `.firebaserc` (demo project — `demo-` prefix means the emulator needs NO real credentials):
  ```json
  { "projects": { "default": "demo-tarf" } }
  ```
- [ ] Create `firestore.indexes.json` (empty to start; reserved for future composite indexes):
  ```json
  { "indexes": [], "fieldOverrides": [] }
  ```
- [ ] Write the failing rules test `rules-tests/firestore.rules.test.js`:
  ```js
  const { initializeTestEnvironment, assertFails, assertSucceeds } =
    require('@firebase/rules-unit-testing');
  const { readFileSync } = require('fs');
  const { setDoc, getDoc, doc, deleteDoc } = require('firebase/firestore');

  let env;
  beforeAll(async () => {
    env = await initializeTestEnvironment({
      projectId: 'demo-tarf',
      firestore: { rules: readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
    });
  });
  afterAll(() => env.cleanup());
  beforeEach(() => env.clearFirestore());

  test('owner can write a valid state doc', async () => {
    const db = env.authenticatedContext('alice').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'users/alice/state/settings'), { payload: { localeCode: 'ar' }, updatedAt: 123 })
    );
  });

  test('a different user cannot read or write your data', async () => {
    const alice = env.authenticatedContext('alice').firestore();
    await assertSucceeds(setDoc(doc(alice, 'users/alice/state/todos'), { payload: [], updatedAt: 1 }));
    const mallory = env.authenticatedContext('mallory').firestore();
    await assertFails(getDoc(doc(mallory, 'users/alice/state/todos')));
    await assertFails(setDoc(doc(mallory, 'users/alice/state/todos'), { payload: [], updatedAt: 2 }));
  });

  test('unauthenticated access is denied', async () => {
    const anon = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(anon, 'users/alice/state/settings')));
  });

  test('state docs require updatedAt and a payload field (shape validation)', async () => {
    const db = env.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db, 'users/alice/state/settings'), { payload: { x: 1 } })); // no updatedAt
    await assertFails(setDoc(doc(db, 'users/alice/state/settings'), { updatedAt: 1 }));       // no payload
  });

  test('owner can delete their own doc (delete-all path)', async () => {
    const db = env.authenticatedContext('alice').firestore();
    await assertSucceeds(setDoc(doc(db, 'users/alice/state/alarms'), { payload: [], updatedAt: 1 }));
    await assertSucceeds(deleteDoc(doc(db, 'users/alice/state/alarms')));
  });

  test('writes to collections outside /users are denied', async () => {
    const db = env.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db, 'global/anything'), { x: 1 }));
  });
  ```
- [ ] Create `rules-tests/package.json`:
  ```json
  {
    "name": "tarf-rules-tests",
    "private": true,
    "scripts": {
      "test": "firebase emulators:exec --project=demo-tarf --only firestore \"jest\""
    },
    "devDependencies": {
      "@firebase/rules-unit-testing": "^4.0.0",
      "firebase": "^11.0.0",
      "jest": "^29.0.0"
    }
  }
  ```
- [ ] Run (expect FAIL — current rules have no shape validation, so the "require updatedAt/payload" test fails, proving the test is meaningful). From `app/firebase/rules-tests`:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20\app\firebase\rules-tests; npm install; npm test
  ```
  Expected: the shape-validation test FAILS (current rules accept any owner write).
  > Prereq: `npm i -g firebase-tools` (owner machine). If `firebase` is unavailable, this task's run steps are skipped in CI and documented as owner-run; the Dart fakes (Tasks 3–5) still fully cover sync logic offline.
- [ ] MODIFY `firestore.rules` to validate the envelope shape and keep strict per-uid isolation + explicit delete allowance:
  ```
  rules_version = '2';

  // Tarf Firestore security rules.
  // Every document is private to its owner. State docs are LWW envelopes:
  // { payload: <json>, updatedAt: <int millis> }.
  service cloud.firestore {
    match /databases/{database}/documents {

      function isOwner(uid) {
        return request.auth != null && request.auth.uid == uid;
      }

      function validEnvelope() {
        return request.resource.data.keys().hasAll(['payload', 'updatedAt'])
          && request.resource.data.updatedAt is int;
      }

      match /users/{uid} {
        // The user profile doc (optional metadata) — owner only.
        allow read, write: if isOwner(uid);

        // LWW state blobs: settings, eyecareConfig, focusConfig, progress,
        // todos, alarms, timers — one doc each.
        match /state/{key} {
          allow read: if isOwner(uid);
          allow create, update: if isOwner(uid) && validEnvelope();
          allow delete: if isOwner(uid);
        }

        // Any other future subcollection stays owner-locked.
        match /{document=**} {
          allow read, write: if isOwner(uid);
        }
      }

      // Deny everything else by default.
      match /{document=**} {
        allow read, write: if false;
      }
    }
  }
  ```
- [ ] Run (expect PASS — all six rules tests green now):
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20\app\firebase\rules-tests; npm test
  ```
  Expected: `Tests: 6 passed`.
- [ ] Add `app/firebase/rules-tests/node_modules` to git ignore (append to `app/.gitignore`): add the line `firebase/rules-tests/node_modules/`.
- [ ] Commit:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git add app/firebase/firestore.rules app/firebase/firestore.indexes.json app/firebase/firebase.json app/firebase/.firebaserc app/firebase/rules-tests/package.json app/firebase/rules-tests/firestore.rules.test.js app/.gitignore
  git commit -m @'
  feat(firebase): tighten Firestore rules with envelope shape validation + tests

  Per-uid isolation kept; state docs must be {payload, updatedAt:int} LWW
  envelopes; owners may delete (delete-all). Adds emulator config (auth 9099,
  firestore 8080, demo-tarf project) and a @firebase/rules-unit-testing suite
  (6 cases: isolation, unauth deny, shape validation, delete, outside-deny).

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  '@
  ```

---

### Task 7 — Firebase implementations: `FirebaseAuthService`, `FirestoreSyncService`, `FirestoreCloudMirror`, `FirestoreCloudAccount` (NEW; guarded, emulator-exercised)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\account\application\firebase_auth_service.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\cloud\firestore_sync_service.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\cloud\firestore_cloud_mirror.dart`
- (extends) `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\account\application\cloud_account.dart` (add `FirestoreCloudAccount`)

Notes: these wrap the SDKs. Pure logic is already tested via fakes (Tasks 3–5) and rules via Node (Task 6); these classes are then exercised end-to-end against the emulator in Task 10. No new pure-Dart unit test is added here (would just mock the SDK); correctness is proven by the emulator integration tests. Keep each class small and delegate conflict logic to the already-tested pure functions.

Steps:

- [ ] Implement `firebase_auth_service.dart` (maps Firebase/Google/Apple/Email to `AuthService`; translates errors to `AuthErrorCode`):
  ```dart
  import 'package:firebase_auth/firebase_auth.dart' as fb;
  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:sign_in_with_apple/sign_in_with_apple.dart';

  import 'auth_service.dart';

  /// Firebase-backed AuthService. Constructed only when cloud is enabled.
  class FirebaseAuthService implements AuthService {
    FirebaseAuthService(this._auth);
    final fb.FirebaseAuth _auth;

    AuthUser? _map(fb.User? u) => u == null
        ? null
        : AuthUser(uid: u.uid, email: u.email, displayName: u.displayName, isAnonymous: u.isAnonymous);

    @override
    AuthUser? get currentUser => _map(_auth.currentUser);

    @override
    Stream<AuthState> get authState => _auth.authStateChanges().map(
        (u) => u == null ? const AuthState.signedOut() : AuthState.signedIn(_map(u)!));

    AuthUser _require(fb.UserCredential c) => _map(c.user)!;

    @override
    Future<AuthUser> signInWithGoogle() async {
      try {
        final g = await GoogleSignIn.instance.authenticate();
        final t = g.authentication;
        final cred = fb.GoogleAuthProvider.credential(idToken: t.idToken);
        return _require(await _auth.signInWithCredential(cred));
      } on fb.FirebaseAuthException catch (e) {
        throw _translate(e);
      }
    }

    @override
    Future<AuthUser> signInWithApple() async {
      try {
        final a = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        );
        final cred = fb.OAuthProvider('apple.com').credential(
          idToken: a.identityToken, accessToken: a.authorizationCode);
        return _require(await _auth.signInWithCredential(cred));
      } on fb.FirebaseAuthException catch (e) {
        throw _translate(e);
      }
    }

    @override
    Future<AuthUser> signInWithEmail(String email, String password) async {
      try {
        return _require(await _auth.signInWithEmailAndPassword(email: email, password: password));
      } on fb.FirebaseAuthException catch (e) {
        throw _translate(e);
      }
    }

    @override
    Future<AuthUser> registerWithEmail(String email, String password) async {
      try {
        return _require(await _auth.createUserWithEmailAndPassword(email: email, password: password));
      } on fb.FirebaseAuthException catch (e) {
        throw _translate(e);
      }
    }

    @override
    Future<void> signOut() => _auth.signOut();

    @override
    Future<void> deleteAccount() async {
      try {
        await _auth.currentUser?.delete();
      } on fb.FirebaseAuthException catch (e) {
        throw _translate(e);
      }
    }

    AuthException _translate(fb.FirebaseAuthException e) => AuthException(
          switch (e.code) {
            'wrong-password' || 'invalid-credential' => AuthErrorCode.wrongPassword,
            'user-not-found' => AuthErrorCode.userNotFound,
            'email-already-in-use' => AuthErrorCode.emailAlreadyInUse,
            'account-exists-with-different-credential' =>
              AuthErrorCode.accountExistsWithDifferentCredential,
            'requires-recent-login' => AuthErrorCode.requiresRecentLogin,
            'network-request-failed' => AuthErrorCode.network,
            _ => AuthErrorCode.unknown,
          },
          e.message,
        );
  }
  ```
- [ ] Implement `firestore_sync_service.dart` (reads/writes envelopes; reuses pure `mergeOnSignIn`; uses `serverTimestamp`/cache as available; relies on Firestore's built-in offline persistence as the durable cache, with our `WriteQueue` as the explicit retry buffer):
  ```dart
  import 'dart:async';

  import 'package:cloud_firestore/cloud_firestore.dart';

  import 'package:tarf/core/data/tarf_repository.dart';
  import 'firestore_paths.dart';
  import 'sync_models.dart';
  import 'sync_service.dart';

  /// Firestore-backed SyncService for a single signed-in uid.
  class FirestoreSyncService implements SyncService {
    FirestoreSyncService(this._db, String uid) : _paths = FirestorePaths(uid);

    final FirebaseFirestore _db;
    final FirestorePaths _paths;
    @override
    final WriteQueue queue = WriteQueue();
    final _status = StreamController<SyncStatus>.broadcast();

    @override
    Stream<SyncStatus> get status => _status.stream;

    DocumentReference<Map<String, dynamic>> _ref(StorageKey k) =>
        _db.doc(_paths.docPathFor(k));

    @override
    Future<void> mergeGuestIntoCloud(Map<StorageKey, Versioned> local) async {
      _status.add(SyncStatus.syncing);
      try {
        final cloud = <StorageKey, Versioned>{};
        for (final k in StorageKey.values) {
          final snap = await _ref(k).get();
          final data = snap.data();
          if (data != null) {
            final env = SyncEnvelope.fromMap(data.cast<String, Object?>());
            cloud[k] = Versioned(env.payload, env.updatedAtMs);
          }
        }
        final merged = mergeOnSignIn(local: local, cloud: cloud);
        final batch = _db.batch();
        merged.forEach((k, v) => batch.set(
            _ref(k), SyncEnvelope.wrap(v.value, updatedAtMs: v.updatedAtMs).toMap()));
        await batch.commit();
        _status.add(SyncStatus.synced);
      } catch (_) {
        _status.add(SyncStatus.error);
        rethrow;
      }
    }

    @override
    Future<void> pushPending() async {
      _status.add(SyncStatus.syncing);
      try {
        for (final w in queue.drain()) {
          await _ref(w.key).set(
              SyncEnvelope.wrap(w.value, updatedAtMs: w.atMs).toMap());
        }
        _status.add(SyncStatus.synced);
      } catch (_) {
        _status.add(SyncStatus.error);
        rethrow;
      }
    }
  }
  ```
- [ ] Implement `firestore_cloud_mirror.dart` (the `CloudMirror` that enqueues + pushes on each repository change):
  ```dart
  import 'package:tarf/core/cloud/sync_models.dart';
  import 'package:tarf/core/cloud/sync_service.dart';
  import 'package:tarf/core/data/cloud_mirror.dart';
  import 'package:tarf/core/data/tarf_repository.dart';

  /// Bridges repository writes to the SyncService queue. Active only when signed in.
  class FirestoreCloudMirror implements CloudMirror {
    FirestoreCloudMirror(this._sync, this._nowMs);
    final SyncService _sync;
    final int Function() _nowMs;

    @override
    bool get isActive => true;

    @override
    Future<void> onChange(RepositoryEvent event, Object? value) async {
      _sync.queue.enqueue(PendingWrite(event.key, value, atMs: _nowMs()));
      await _sync.pushPending();
    }
  }
  ```
- [ ] Append `FirestoreCloudAccount` to `cloud_account.dart`:
  ```dart
  // ... existing CloudAccount + FakeCloudAccount + purgeEverything above ...

  // Firestore-backed CloudAccount appended via a separate file import in callers.
  ```
  and create the implementation inside `firestore_sync_service.dart`'s library OR a dedicated section; simplest: add to `firestore_cloud_mirror.dart` bottom:
  ```dart
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart' as fb;
  import 'package:tarf/core/cloud/firestore_paths.dart';
  import 'package:tarf/features/account/application/cloud_account.dart';

  /// Deletes a user's Firestore subtree (state docs) then their auth account.
  class FirestoreCloudAccount implements CloudAccount {
    FirestoreCloudAccount(this._db, this._auth);
    final FirebaseFirestore _db;
    final fb.FirebaseAuth _auth;

    @override
    Future<void> deleteCloudData(String uid) async {
      final paths = FirestorePaths(uid);
      final batch = _db.batch();
      for (final k in StorageKey.values) {
        batch.delete(_db.doc(paths.docPathFor(k)));
      }
      batch.delete(_db.doc(paths.userRoot)); // profile doc if any
      await batch.commit();
    }

    @override
    Future<void> deleteAccount() => _auth.currentUser?.delete() ?? Future.value();
  }
  ```
- [ ] Run analyze (no new unit tests here; logic is covered by fakes + emulator tests in Task 10):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter analyze; flutter test
  ```
  Expected: `No issues found!`; full suite still green (these files are not yet referenced by `main.dart`).
- [ ] Commit:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git add app/lib/features/account/application/firebase_auth_service.dart app/lib/core/cloud/firestore_sync_service.dart app/lib/core/cloud/firestore_cloud_mirror.dart app/lib/features/account/application/cloud_account.dart
  git commit -m @'
  feat(cloud): add Firebase implementations (auth, sync, mirror, account-delete)

  FirebaseAuthService (Google/Apple/Email, error-code translation),
  FirestoreSyncService (envelope read/write, reuses pure mergeOnSignIn, write
  queue), FirestoreCloudMirror (enqueue+push on each write), FirestoreCloudAccount
  (delete state subtree + auth account). Not wired into main yet; verified by the
  emulator tests in a later task.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  '@
  ```

---

### Task 8 — l10n strings + Account screen gating (enable sign-in ONLY when flag+config; cloud-aware delete)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\l10n\app_en.arb` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\l10n\app_ar.arb` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\account\presentation\account_screen.dart` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\account\account_screen_gating_test.dart` (NEW)

Steps:

- [ ] Add to `app_en.arb` (and Arabic equivalents to `app_ar.arb`): keys `signOut`, `syncStatusSynced`, `syncStatusSyncing`, `syncStatusError`, `accountSignedInAs`, `signInErrorGeneric`. Example EN entries:
  ```json
    "signOut": "Sign out",
    "syncStatusSynced": "Synced",
    "syncStatusSyncing": "Syncing…",
    "syncStatusError": "Sync error — will retry",
    "accountSignedInAs": "Signed in as {name}",
    "@accountSignedInAs": { "placeholders": { "name": {} } },
    "signInErrorGeneric": "Couldn't sign in. Please try again."
  ```
  AR (Western digits, Arabic text):
  ```json
    "signOut": "تسجيل الخروج",
    "syncStatusSynced": "متزامن",
    "syncStatusSyncing": "جارٍ المزامنة…",
    "syncStatusError": "خطأ في المزامنة — ستتم إعادة المحاولة",
    "accountSignedInAs": "مسجّل الدخول باسم {name}",
    "signInErrorGeneric": "تعذّر تسجيل الدخول. حاول مرة أخرى."
  ```
- [ ] Regenerate localizations:
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter gen-l10n
  ```
- [ ] Write failing `account_screen_gating_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/data/prefs_repository.dart';
  import 'package:tarf/core/data/repository_providers.dart';
  import 'package:tarf/core/data/tarf_repository.dart';
  import 'package:tarf/core/settings/settings_controller.dart';
  import 'package:tarf/features/account/application/account_controller.dart';
  import 'package:tarf/features/account/application/auth_service.dart';
  import 'package:tarf/features/account/presentation/account_screen.dart';
  import 'package:tarf/firebase/firebase_flags.dart';
  import 'package:tarf/l10n/app_localizations.dart';

  Future<Widget> _host({required bool cloud}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = PrefsRepository(prefs);
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tarfRepositoryProvider.overrideWithValue(repo),
        firebaseFlagsProvider.overrideWithValue(
            FirebaseFlags(configPresent: cloud, compileEnabled: cloud)),
        authServiceProvider.overrideWithValue(FakeAuthService()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: AccountScreen(),
      ),
    );
  }

  void main() {
    testWidgets('sign-in buttons are DISABLED when cloud flag is off', (tester) async {
      await tester.pumpWidget(await _host(cloud: false));
      await tester.pump();
      final google = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Continue with Google'), matching: find.byType(OutlinedButton)));
      expect(google.onPressed, isNull); // disabled
      expect(find.text('Coming soon'), findsOneWidget);
    });

    testWidgets('sign-in buttons are ENABLED when cloud flag is on', (tester) async {
      await tester.pumpWidget(await _host(cloud: true));
      await tester.pump();
      final google = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Continue with Google'), matching: find.byType(OutlinedButton)));
      expect(google.onPressed, isNotNull); // enabled
      expect(find.text('Coming soon'), findsNothing);
    });

    testWidgets('export + delete-all rows are present in BOTH states', (tester) async {
      await tester.pumpWidget(await _host(cloud: false));
      await tester.pump();
      expect(find.text('Export my data'), findsOneWidget);
      expect(find.text('Delete all data'), findsWidgets);
    });
  }
  ```
- [ ] Run (expect FAIL — `firebaseFlagsProvider` doesn't exist; screen ignores the flag):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/features/account/account_screen_gating_test.dart
  ```
- [ ] Add `firebaseFlagsProvider` to `firebase_flags.dart` (so the screen and main share one source):
  ```dart
  // append to firebase_flags.dart
  // ignore: depend_on_referenced_packages -- riverpod is a direct dep
  ```
  Actually place the provider in `repository_providers.dart` to avoid importing Riverpod into the pure flags file. Add:
  ```dart
  // in repository_providers.dart
  import 'package:tarf/firebase/firebase_flags.dart';
  final firebaseFlagsProvider = Provider<FirebaseFlags>(
    (ref) => const FirebaseFlags(configPresent: false),
  );
  ```
  and import `repository_providers.dart` in the test instead (update the test import if needed).
- [ ] MODIFY `account_screen.dart`: read `final flags = ref.watch(firebaseFlagsProvider);` and `final account = ref.watch(accountControllerProvider);`. Replace the three `OutlinedButton.icon(onPressed: null, ...)` with handlers gated by `flags.signInAvailable`:
  ```dart
  OutlinedButton.icon(
    onPressed: flags.signInAvailable
        ? () => ref.read(accountControllerProvider.notifier).signInWithGoogle()
        : null,
    icon: const Icon(Icons.login),
    label: Text(l10n.signInGoogle),
  ),
  // ...Apple -> signInWithApple, Email -> route to an email form (or signInWithEmail)
  ```
  Show the "Coming soon" caption ONLY when `!flags.signInAvailable`. When signed in, swap the guest card subtitle to `l10n.accountSignedInAs(account.user!.displayName ?? account.user!.email ?? '')`, the chip to a sync-status label, and add a "Sign out" row.
  Rewire delete: keep the existing confirm dialog, but on confirm call a cloud-aware purge. Since Task 9 finishes the repository swap, here keep the existing `LocalDataManager.deleteAll(prefs)` call AND add (guarded) cloud deletion:
  ```dart
  // inside _deleteAll, after confirmation:
  final account = ref.read(accountControllerProvider);
  if (account.isSignedIn) {
    final cloud = ref.read(cloudAccountProvider); // provider added in Task 9/main
    await cloud.deleteCloudData(account.user!.uid);
    await cloud.deleteAccount();
  }
  await LocalDataManager.deleteAll(ref.read(sharedPreferencesProvider));
  // ...existing invalidate(...) calls + navigate to onboarding
  ```
  > To keep this task self-contained, add a `cloudAccountProvider` to `repository_providers.dart` defaulting to `FakeCloudAccount()` (overridden in main when cloud is on). The gating test only checks button enablement + presence of export/delete rows, so it passes without exercising delete.
- [ ] Run (expect PASS) + analyze + FULL suite:
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/features/account/account_screen_gating_test.dart; flutter analyze; flutter test
  ```
  Expected: gating test green; `No issues found!`; full suite green.
- [ ] Commit:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git add app/lib/l10n/app_en.arb app/lib/l10n/app_ar.arb app/lib/features/account/presentation/account_screen.dart app/lib/core/data/repository_providers.dart app/test/features/account/account_screen_gating_test.dart
  git commit -m @'
  feat(account): gate sign-in on cloud flag; cloud-aware delete; sync strings

  Account screen enables Google/Apple/Email only when FirebaseFlags.signInAvailable
  (compile flag + config); otherwise the buttons stay disabled with "Coming soon".
  Delete-all also clears the cloud + auth account when signed in. Guest stays the
  default and export/delete-all remain reachable in both states.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  '@
  ```

---

### Task 9 — Route ALL persistence through the repository + wire providers in `main.dart` (HIGH-CONTENTION — merge LAST)

> **MERGE ORDER:** land this only AFTER Phase 1 and Phase 3 have settled `eyecare_config_controller.dart`, `focus_controller.dart`, `timer_controller.dart`, and the domain models. This task edits the six controllers, `settings_controller.dart`, `main.dart`, and `account_screen.dart`'s export path. It changes NO on-disk format (byte-compatible), so behaviour is identical — only the seam changes.

**Files (MODIFY):**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\main.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\settings\settings_controller.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\application\eyecare_config_controller.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\focus\application\focus_controller.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\todos\application\todos_controller.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\insights\application\progress_controller.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\alarm\application\alarms_controller.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\account\presentation\account_screen.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\data\persistence_integration_test.dart` (NEW)

Steps:

- [ ] Write a failing `persistence_integration_test.dart` that asserts each controller reads/writes through the repository AND that an attached spy mirror sees every feature write:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/data/cloud_mirror.dart';
  import 'package:tarf/core/data/prefs_repository.dart';
  import 'package:tarf/core/data/repository_providers.dart';
  import 'package:tarf/core/data/tarf_repository.dart';
  import 'package:tarf/core/settings/settings_controller.dart';
  import 'package:tarf/features/todos/application/todos_controller.dart';

  void main() {
    test('todos write goes through the repository and reaches the mirror', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PrefsRepository(prefs);
      final seen = <StorageKey>[];
      attachMirror(repo, _Spy(seen));

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tarfRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await container.read(todosControllerProvider.notifier).add('read Quran', nowMs: 1);
      await Future<void>.delayed(Duration.zero);

      // Persisted via repository (visible to a fresh read) AND mirrored.
      expect(repo.read(StorageKey.todos), isNotNull);
      expect(seen, contains(StorageKey.todos));
    });
  }

  class _Spy implements CloudMirror {
    _Spy(this.seen);
    final List<StorageKey> seen;
    @override
    bool get isActive => true;
    @override
    Future<void> onChange(RepositoryEvent e, Object? v) async => seen.add(e.key);
  }
  ```
- [ ] Run (expect FAIL — controllers still use `sharedPreferencesProvider` directly, no mirror event):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/core/data/persistence_integration_test.dart
  ```
- [ ] Refactor each controller to read/write via `ref.watch(tarfRepositoryProvider)`. Pattern (TodosController shown; apply the analogous change to settings, eyecareConfig, focusConfig, progress, alarms):
  ```dart
  // todos_controller.dart
  import '../../../core/data/repository_providers.dart';
  import '../../../core/data/tarf_repository.dart';

  class TodosController extends Notifier<List<Todo>> {
    @override
    List<Todo> build() {
      final raw = ref.watch(tarfRepositoryProvider).read(StorageKey.todos);
      if (raw is! List) return const [];
      return raw.cast<Map<String, Object?>>().map(Todo.fromJson).toList();
    }

    Future<void> _persist(List<Todo> next) async {
      state = next;
      await ref.read(tarfRepositoryProvider)
          .write(StorageKey.todos, next.map((t) => t.toJson()).toList());
    }
    // ...rest unchanged
  }
  ```
  Keep `sharedPreferencesProvider` only where still needed (none, after this task) — or leave it defined for the `widget_test.dart` override compatibility. (The repository is constructed FROM prefs in main, so prefs override still feeds the repo.)
- [ ] Wire `main.dart` (construct repository from prefs; attach cloud mirror only when enabled; override all providers):
  ```dart
  import 'package:firebase_auth/firebase_auth.dart' as fb;
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  import 'app.dart';
  import 'core/data/cloud_mirror.dart';
  import 'core/data/prefs_repository.dart';
  import 'core/data/repository_providers.dart';
  import 'core/settings/settings_controller.dart';
  import 'firebase/firebase_flags.dart';

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final repo = PrefsRepository(prefs);

    // Cloud is OFF unless compiled with --dart-define=TARF_CLOUD=true.
    const compileCloud = bool.fromEnvironment('TARF_CLOUD');
    // firebase_options.dart is owner-generated; absent by default -> guest mode.
    const configPresent = false; // flip to true after flutterfire configure wires options
    final flags = FirebaseFlags(configPresent: configPresent, compileEnabled: compileCloud);

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tarfRepositoryProvider.overrideWithValue(repo),
          firebaseFlagsProvider.overrideWithValue(flags),
          // Auth + mirror + cloudAccount providers are overridden with Firebase
          // impls only when flags.cloudEnabled (see docs/firebase-setup.md). The
          // emulator/integration build supplies those overrides.
        ],
        child: const TarfApp(),
      ),
    );
  }
  ```
  > NOTE: the actual Firebase initialization + provider overrides for the live/emulator path are assembled in the integration test harness (Task 10) and documented for the owner; `main.dart` stays guest-safe with `configPresent=false` until the owner flips it after `flutterfire configure`.
- [ ] Update `account_screen.dart` export to use the repository: `LocalDataManager.exportJsonFromRepo(ref.read(tarfRepositoryProvider))` (replacing the prefs-based call).
- [ ] Run (expect PASS) + analyze + FULL suite (this is the big regression gate):
  ```powershell
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app; flutter test test/core/data/persistence_integration_test.dart; flutter analyze; flutter test
  ```
  Expected: integration test green; `No issues found!`; ALL prior tests green (byte-compatible refactor — `widget_test.dart` etc. unaffected because the repo is built from the same prefs).
- [ ] Commit:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git add app/lib/main.dart app/lib/core/settings/settings_controller.dart app/lib/features/eyecare/application/eyecare_config_controller.dart app/lib/features/focus/application/focus_controller.dart app/lib/features/todos/application/todos_controller.dart app/lib/features/insights/application/progress_controller.dart app/lib/features/alarm/application/alarms_controller.dart app/lib/features/account/presentation/account_screen.dart app/test/core/data/persistence_integration_test.dart
  git commit -m @'
  refactor(data): route all feature persistence through TarfRepository

  Settings, eyecare config, focus config, progress, todos, and alarms now read/
  write via tarfRepositoryProvider instead of SharedPreferences directly, so the
  optional CloudMirror sees every write. On-disk format is byte-identical (same
  tarf.*.v1 keys/JSON), so guest behaviour and all existing tests are unchanged.
  Sequenced last to minimise contention with Phase 1/Phase 3.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  '@
  ```

---

### Task 10 — Emulator-based integration tests (Auth + Firestore) end-to-end

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\integration_test\emulator\auth_emulator_test.dart` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\integration_test\emulator\sync_emulator_test.dart` (NEW)

Notes: these run against the Local Emulator Suite (no live project). They use `useAuthEmulator`/`useFirestoreEmulator` so no real credentials are needed (project id `demo-tarf`). Email/password is fully exercisable on the Auth emulator; Google/Apple are NOT (they need real OAuth), so those are covered only by the `FakeAuthService` unit tests + manual owner verification — documented honestly.

Steps:

- [ ] Write `auth_emulator_test.dart`:
  ```dart
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:integration_test/integration_test.dart';
  import 'package:tarf/features/account/application/auth_service.dart';
  import 'package:tarf/features/account/application/firebase_auth_service.dart';

  void main() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    setUpAll(() async {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'demo', appId: 'demo', messagingSenderId: 'demo', projectId: 'demo-tarf',
        ),
      );
      await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    });

    setUp(() async {
      // Clear emulator users between tests via REST is optional; use unique emails.
    });

    testWidgets('register + sign-in + delete against the Auth emulator', (tester) async {
      final auth = FirebaseAuthService(FirebaseAuth.instance);
      final email = 'u${DateTime.now().microsecondsSinceEpoch}@example.com';

      final created = await auth.registerWithEmail(email, 'pw-123456');
      expect(created.uid, isNotEmpty);

      await auth.signOut();
      expect(auth.currentUser, isNull);

      final back = await auth.signInWithEmail(email, 'pw-123456');
      expect(back.uid, created.uid);

      await auth.deleteAccount();
      expect(auth.currentUser, isNull);
    });

    testWidgets('wrong password surfaces AuthErrorCode.wrongPassword', (tester) async {
      final auth = FirebaseAuthService(FirebaseAuth.instance);
      final email = 'u${DateTime.now().microsecondsSinceEpoch}@example.com';
      await auth.registerWithEmail(email, 'right-123456');
      await auth.signOut();
      await expectLater(
        () => auth.signInWithEmail(email, 'wrong-123456'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code',
            anyOf(AuthErrorCode.wrongPassword, AuthErrorCode.userNotFound))),
      );
    });
  }
  ```
- [ ] Write `sync_emulator_test.dart` (mirror a write, merge guest→cloud, then delete the subtree):
  ```dart
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:integration_test/integration_test.dart';
  import 'package:tarf/core/cloud/firestore_paths.dart';
  import 'package:tarf/core/cloud/firestore_cloud_mirror.dart';
  import 'package:tarf/core/cloud/firestore_sync_service.dart';
  import 'package:tarf/core/cloud/sync_service.dart';
  import 'package:tarf/core/data/tarf_repository.dart';

  void main() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    late FirebaseFirestore db;
    late String uid;

    setUpAll(() async {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'demo', appId: 'demo', messagingSenderId: 'demo', projectId: 'demo-tarf',
        ),
      );
      await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      db = FirebaseFirestore.instance..useFirestoreEmulator('127.0.0.1', 8080);
      final cred = await FirebaseAuth.instance.signInAnonymously();
      uid = cred.user!.uid;
    });

    testWidgets('mirror push writes an envelope readable at the per-user path', (tester) async {
      final sync = FirestoreSyncService(db, uid);
      final mirror = FirestoreCloudMirror(sync, () => 1000);
      await mirror.onChange(const RepositoryEvent(StorageKey.todos), [{'id': 't1'}]);

      final snap = await db.doc(FirestorePaths(uid).docPathFor(StorageKey.todos)).get();
      expect(snap.exists, isTrue);
      expect((snap.data()!['payload'] as List).single['id'], 't1');
      expect(snap.data()!['updatedAt'], 1000);
    });

    testWidgets('mergeGuestIntoCloud preserves progress via per-day MAX', (tester) async {
      final paths = FirestorePaths(uid);
      // Seed cloud progress (older + a cloud-only day).
      await db.doc(paths.docPathFor(StorageKey.progress)).set({
        'payload': {'2026-06-01': {'s': 1, 'fm': 75}, '2026-05-31': {'s': 3}},
        'updatedAt': 100,
      });
      final sync = FirestoreSyncService(db, uid);
      await sync.mergeGuestIntoCloud({
        StorageKey.progress: Versioned({'2026-06-01': {'s': 2, 'fm': 50}}, 200),
      });
      final merged = (await db.doc(paths.docPathFor(StorageKey.progress)).get()).data()!['payload'] as Map;
      expect((merged['2026-06-01'] as Map)['s'], 2);    // max(2,1)
      expect((merged['2026-06-01'] as Map)['fm'], 75);  // max(50,75)
      expect((merged['2026-05-31'] as Map)['s'], 3);    // cloud-only day kept
    });

    testWidgets('FirestoreCloudAccount deletes the whole state subtree', (tester) async {
      final paths = FirestorePaths(uid);
      await db.doc(paths.docPathFor(StorageKey.alarms)).set({'payload': [], 'updatedAt': 1});
      final acct = FirestoreCloudAccount(db, FirebaseAuth.instance);
      await acct.deleteCloudData(uid);
      expect((await db.doc(paths.docPathFor(StorageKey.alarms)).get()).exists, isFalse);
    });
  }
  ```
- [ ] Start the emulators (one terminal), then run the integration tests (another):
  ```powershell
  # Terminal 1 — emulators (Auth + Firestore), no live project needed:
  cd C:\Users\sulta\Claude_Code\EyeCure_20\app\firebase; firebase emulators:start --project=demo-tarf --only auth,firestore

  # Terminal 2 — run integration tests against a headless device (Chrome shown; or windows):
  $env:Path = "C:\dev\flutter\bin;$env:Path"; cd C:\Users\sulta\Claude_Code\EyeCure_20\app
  flutter test integration_test/emulator/auth_emulator_test.dart --dart-define=TARF_CLOUD=true -d chrome
  flutter test integration_test/emulator/sync_emulator_test.dart --dart-define=TARF_CLOUD=true -d chrome
  ```
  Expected: both files PASS (register/sign-in/delete on Auth emulator; mirror/merge/delete on Firestore emulator).
  > Alternative single-shot (CI-friendly), which boots + tears down the emulators around the run:
  > ```powershell
  > cd C:\Users\sulta\Claude_Code\EyeCure_20\app\firebase; firebase emulators:exec --project=demo-tarf --only auth,firestore "cd .. && flutter test integration_test/emulator -d chrome --dart-define=TARF_CLOUD=true"
  > ```
- [ ] Commit:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git add app/integration_test/emulator/auth_emulator_test.dart app/integration_test/emulator/sync_emulator_test.dart
  git commit -m @'
  test(cloud): emulator integration tests for auth, sync mirror, merge, delete

  Exercises FirebaseAuthService (register/sign-in/delete + wrong-password) on the
  Auth emulator and FirestoreSyncService/Mirror/CloudAccount (envelope write,
  guest->cloud progress MAX-merge, subtree delete) on the Firestore emulator. No
  live project required (demo-tarf). Google/Apple need real OAuth -> covered by
  fakes + documented manual owner verification.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  '@
  ```

---

### Task 11 — Document the emulator workflow in `docs/firebase-setup.md`

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\docs\firebase-setup.md` (MODIFY)

Steps:

- [ ] Fix the one stale sentence ("all data in the local Drift store") to reflect reality ("all data in the local `shared_preferences` JSON store, behind the `TarfRepository` seam"). Add a new section before "## Data model":
  ```markdown
  ## Local Emulator Suite (no live project needed for development/CI)

  Everything in Phase 4 is buildable and testable WITHOUT creating the real
  Firebase project. Use the emulators (project id `demo-tarf` — the `demo-`
  prefix means no credentials are required).

  ### One-time tooling
  ```bash
  npm i -g firebase-tools          # provides the emulators
  # (optional) rules tests deps:
  cd app/firebase/rules-tests && npm install
  ```

  ### Start the emulators
  ```bash
  cd app/firebase
  firebase emulators:start --project=demo-tarf --only auth,firestore
  # Auth: 127.0.0.1:9099 · Firestore: 127.0.0.1:8080 · UI: 127.0.0.1:4000
  ```

  ### Run the tests
  ```bash
  # Fast Dart unit tests (no emulator) — fakes cover all sync/merge/auth logic:
  cd app && flutter test

  # Firestore security-rules tests (Node; boots its own emulator):
  cd app/firebase/rules-tests && npm test

  # Flutter integration tests against the running emulators:
  cd app
  flutter test integration_test/emulator -d chrome --dart-define=TARF_CLOUD=true

  # Or one-shot (boots + tears down emulators around the run):
  cd app/firebase
  firebase emulators:exec --project=demo-tarf --only auth,firestore \
    "cd .. && flutter test integration_test/emulator -d chrome --dart-define=TARF_CLOUD=true"
  ```

  ### Enabling cloud in the app
  - Cloud is OFF by default (`FirebaseFlags`). Sign-in buttons stay disabled
    ("Coming soon") until BOTH are true: built with `--dart-define=TARF_CLOUD=true`
    AND `firebase_options.dart` is generated (owner runs `flutterfire configure`).
  - After `flutterfire configure`, set `configPresent = true` in `main.dart` and
    wire the Firebase provider overrides (FirebaseAuthService, FirestoreCloudMirror,
    FirestoreCloudAccount) as shown in `integration_test/emulator/`.
  - What the emulator CANNOT do: Google/Apple OAuth (need real client config) and
    App Check enforcement. Verify those manually on a real project before release;
    Email/Password is fully emulator-testable.
  ```
- [ ] Run a docs sanity check (no build needed) and verify the file renders (manual read):
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git diff --stat docs/firebase-setup.md
  ```
- [ ] Commit:
  ```powershell
  cd C:\Users\sulta\Claude_Code\EyeCure_20; git add docs/firebase-setup.md
  git commit -m @'
  docs(firebase): document the Local Emulator Suite workflow + exact commands

  Adds emulator start/test commands (auth 9099, firestore 8080, demo-tarf),
  rules-test + integration-test invocations, the TARF_CLOUD enabling contract, and
  an honest note on what the emulator cannot cover (Google/Apple OAuth, App Check).
  Corrects the stale "Drift store" wording to the shared_preferences/TarfRepository
  reality.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  '@
  ```

---

## Verification

Run from `C:\Users\sulta\Claude_Code\EyeCure_20\app` with Flutter on PATH (`$env:Path = "C:\dev\flutter\bin;$env:Path"`).

- [ ] **Analyze clean:** `flutter analyze` → `No issues found!`
- [ ] **Full unit/widget suite green (guest path, no emulator):** `flutter test` → all pass (the original 58 + the new fakes/gating/compat/integration-seam tests). This is the local-first regression gate and must stay green at every commit.
- [ ] **Byte-compatibility:** `repository_compat_test.dart` proves `StorageKey` ids equal the legacy `tarf.*.v1` keys and that old↔new reads/writes interoperate, so existing user data and `widget_test.dart` are unaffected.
- [ ] **Guest mode unchanged:** with no `--dart-define=TARF_CLOUD`, the app behaves exactly as today — sign-in buttons disabled ("Coming soon"), export + delete-all work locally. Confirmed by `account_screen_gating_test.dart` (cloud=false) + `flutter run` smoke.
- [ ] **Rules tests:** `cd app/firebase/rules-tests && npm test` → 6 passed (uid isolation, unauth deny, envelope shape validation, owner delete, outside-deny).
- [ ] **Auth emulator:** `firebase emulators:start --only auth,firestore` then `flutter test integration_test/emulator/auth_emulator_test.dart --dart-define=TARF_CLOUD=true -d chrome` → register/sign-in/sign-out/delete + wrong-password pass.
- [ ] **Sync emulator:** `flutter test integration_test/emulator/sync_emulator_test.dart --dart-define=TARF_CLOUD=true -d chrome` → envelope write at `users/{uid}/state/todos`, guest→cloud progress MAX-merge, full subtree delete pass.
- [ ] **Mandatory export/delete reach the cloud:** `cloud_delete_test.dart` (unit) + the emulator delete test prove delete-all clears local AND, when signed in, the Firestore subtree + auth account; export still produces complete local JSON.
- [ ] **Merge-order safety:** confirm Task 9 (call-site refactor) is the last code change merged, after P1/P3 settle the shared controllers/models.

## Self-review

- **Local-first / offline integrity:** The default build never initializes Firebase (`compileCloud=false`, `configPresent=false`); `tarfRepositoryProvider` is a `PrefsRepository` and `cloudMirrorProvider` is a `NoopCloudMirror`. Guest mode keeps working with ZERO cloud. ✔
- **Honesty (no live project required):** All sync/auth/merge logic is unit-tested with `FakeAuthService`/`FakeSyncService`/`FakeCloudAccount`; rules via `@firebase/rules-unit-testing`; end-to-end via the Auth+Firestore emulators on `demo-tarf`. The plan states plainly that Google/Apple OAuth and App Check enforcement are NOT emulator-coverable and need owner verification on a real project. Sign-in stays disabled until flag+config. ✔
- **Mandatory export + delete-all:** Always reachable in both guest and signed-in states (gating test asserts presence); `purgeEverything` clears local always and cloud+auth when signed in; export remains complete local JSON (cloud is a mirror). ✔
- **Offline sync conflicts:** Last-write-wins by `updatedAt` per blob, with a special per-day MAX union for `progress` so neither guest nor cloud activity is lost on sign-in; a coalescing, durable `WriteQueue` buffers offline writes; Firestore's built-in offline persistence is the secondary cache. All covered by pure-function tests + an emulator merge test. ✔
- **Schema accommodates P1/P3:** The blob-per-`StorageKey` model mirrors each JSON blob verbatim, so the P1 sound fields (already in `EyeCareConfig`) and P3 prayer-location fields (already in `EyeCareConfig`) need NO schema change; the reserved `StorageKey.timers` covers P3's multi-timer list additively. ✔
- **Contention management:** Tasks 0–8, 10–11 are new files / docs (worktree-safe, can land anytime). The single high-contention task (9 — six controllers + main + settings) is explicitly sequenced LAST with a stated merge order (P1 → P3 → P4 0–8 → P4 9 → P4 10–11) and is byte-compatible so it cannot change behaviour. ✔
- **TDD discipline:** Every code task is failing-test → run(FAIL) → minimal impl → run(PASS) → commit, with exact PowerShell commands, expected output, and Co-Authored-By trailer. Rules + emulator tasks show the exact `firebase emulators:start` / `emulators:exec` invocations. ✔
- **Keep tests green + analyze clean:** Every task ends by running the targeted test and (for code) `flutter analyze` + the full suite; the original 58 tests are never broken because the refactor preserves the on-disk format. ✔
- **Open risk flagged for the worker:** exact dependency version constraints (firebase_* / google_sign_in 7 / sign_in_with_apple 7) may need `flutter pub get` resolution adjustments on the day; if a major API differs (e.g. `GoogleSignIn.instance.authenticate()` shape), adapt the thin `FirebaseAuthService` wrapper only — pure logic and tests are unaffected.

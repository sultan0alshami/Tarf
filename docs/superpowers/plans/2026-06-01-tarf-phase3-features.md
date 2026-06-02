# Phase 3 — In-App Feature Completeness: Implementation Plan

> For agentic workers: implement task-by-task; steps use `- [ ]`.
> REQUIRED SUB-SKILL: use `superpowers:subagent-driven-development` (preferred) or `superpowers:executing-plans`.
> TDD is mandatory: write the failing test, run it and SEE it fail, write the minimal impl, run it and SEE it pass, then commit. Never write impl before a red test.

**Goal:** Ship four independent, reverent, RTL-correct, Western-digit features that complete Tarf's in-app surface: (1) a calm **prayer-time location + method/madhab picker** wired to the existing Prayer-mode pill; (2) **multi-timer / saved timers** (named, duration, per-timer sound) layered on the existing single-runner engine; (3) a reusable, honest, warning-tinted **degraded-permission banner**; and (4) an opt-in, reverent **tasbih counter** on the dhikr break that never touches the sacred line. All persist via `shared_preferences` JSON, reuse `tarf_widgets` + `TarfTokens`, honor WCAG AA / ≥44px / reduce-motion / never-color-alone, and keep the 58 existing tests green + `flutter analyze` clean.

**Architecture:** Unchanged feature-first layout under `app/lib/features/*`. Riverpod 3 **hand-written** `Notifier`/`NotifierProvider` (NO codegen — match `AlarmsController`, `EyeCareConfigController`). go_router 17 with one new pushed route for the location picker. Persistence mirrors the established pattern: a `Notifier<T>` whose `build()` reads `sharedPreferencesProvider.getString(key)` and whose mutators call `_persist()` → `state = next; prefs.setString(key, jsonEncode(...))`. Pure domain models are `@immutable` with `copyWith`/`toJson`/`fromJson`. UI composes only existing `tarf_widgets` (`TarfGroup`, `TarfListRow`, `TarfPresetChip`, `TarfEmptyState`, `TarfTimeText`, `TarfSliderTile`, `TarfSectionHeader`) + `TarfWheelPicker` for create/edit. l10n via ARB → `flutter gen-l10n` (plain `{n}` = Western digits; never hand-roll). Numerals always through `Numerals.*` / `TarfTimeText`.

**Tech Stack:** Flutter 3.44 / Dart 3.12 · Riverpod 3 (hand-written) · go_router 17 · `shared_preferences` JSON · `intl` · `adhan` (`CalculationMethod` / `Madhab`) · Material 3 + `TarfColors` ThemeExtension (`context.tarf`) · Inter + Amiri. **New dependency (Feature 1 only):** `geolocator` (device GPS, behind an injectable `GeoLocator` abstraction so the picker ships and tests fully without it). Flutter SDK at `C:\dev\flutter\bin` (prepend to PATH).

> **Run/PATH note (PowerShell, Windows):** every test/gen command in this plan is the literal command an agent runs from `C:\Users\sulta\Claude_Code\EyeCure_20\app`. Prepend the SDK once per shell:
> `$env:Path = "C:\dev\flutter\bin;$env:Path"`
> Then e.g. `flutter test test/features/timer/saved_timers_controller_test.dart`.
> `flutter gen-l10n` regenerates `lib/l10n/app_localizations*.dart` from the ARB files; run it whenever ARB keys change and commit the regenerated files.

---

## File Structure

```
app/lib/features/
  eyecare/
    domain/
      eyecare_config.dart                    # MODIFY: add prayerCityLabel (label only; lat/lng/method/madhab already exist)
      tasbih_state.dart                       # NEW (F4): immutable per-day tasbih model
    application/
      tasbih_controller.dart                  # NEW (F4): persisted Notifier<TasbihState>
    presentation/
      location_picker_screen.dart             # NEW (F1): the calm picker
      break_overlay.dart                      # MODIFY (F4): opt-in tasbih tap target BELOW the sacred block
  prayer/                                      # NEW folder (F1)
    domain/
      prayer_calc_options.dart               # NEW (F1): method/madhab id<->label catalogs (pure)
    application/
      geo_locator.dart                        # NEW (F1): GeoLocator abstraction + Unavailable + Fake
      geolocator_geo_locator.dart             # NEW (F1): real geolocator-backed impl (thin, untested-by-unit)
  timer/
    domain/
      saved_timer.dart                        # NEW (F2): immutable named-timer model + sound id
      timer_sound_catalog.dart                # NEW (F2): shared sound-id catalog (see P1 contention note)
    application/
      saved_timers_controller.dart            # NEW (F2): persisted Notifier<List<SavedTimer>>
      timer_controller.dart                   # MODIFY (F2): carry activeTimerId + label + soundId on CountdownData
    presentation/
      timer_screen.dart                       # MODIFY (F2): saved-timer list + run + "+" to editor
      saved_timer_editor_screen.dart          # NEW (F2): wheel + preset grid + label + sound (create/edit)
  permissions/                                 # NEW folder (F3)
    application/
      notification_status.dart                # NEW (F3): NotificationStatus model + notificationStatusProvider (Phase-2 seam)
    presentation/
      degraded_permission_banner.dart         # NEW (F3): reusable warning-tinted banner
  alarm/presentation/alarm_screen.dart        # MODIFY (F1): pill -> Routes.locationPicker ; (F3) banner in Prayer view
  home/presentation/home_screen.dart          # MODIFY (F3): banner above eye-care card when delivery degraded
core/routing/app_router.dart                  # MODIFY (F1): add Routes.locationPicker + GoRoute
l10n/app_en.arb, l10n/app_ar.arb             # MODIFY (F1-F4): new keys (listed per task)

app/test/features/
  prayer/prayer_calc_options_test.dart        # NEW (F1)
  eyecare/location_picker_test.dart           # NEW (F1) widget
  timer/saved_timer_test.dart                 # NEW (F2) model
  timer/saved_timers_controller_test.dart     # NEW (F2) persistence
  timer/timer_controller_active_test.dart     # NEW (F2) runner carries id/label/sound
  timer/saved_timer_editor_test.dart          # NEW (F2) widget
  permissions/notification_status_test.dart   # NEW (F3) model
  permissions/degraded_permission_banner_test.dart # NEW (F3) widget
  eyecare/tasbih_controller_test.dart         # NEW (F4) persistence + cycle
  eyecare/break_overlay_tasbih_test.dart      # NEW (F4) widget (reverence guard)
```

---

## Cross-phase dependencies & integration points

- **Feature 2 (multi-timer) EDITS `timer/application/timer_controller.dart` + `timer/presentation/timer_screen.dart`.** Phase 1 also edits these two files to play the timer chime at zero. **CONTENTION.** Recommendation: **land Feature 2 AFTER Phase 1's timer-chime work merges.** If P1 has not landed, Feature 2 can still proceed because it only *adds* fields (`activeTimerId`, `label`, `soundId`) to `CountdownData` and a `runSaved()` method — additive, no behavior removed — but the integrator MUST reconcile the chime call site. See Task 2.3's explicit P1 seam note.
- **Per-timer sound depends on Phase 1's sound catalog.** P1 is expected to formalize the sound ids currently inlined in `alarm_editor_screen.dart` (`['default','bell','chime','calm']`, l10n `soundDefault/soundBell/soundChime/soundCalm`). Feature 2 introduces `timer/domain/timer_sound_catalog.dart` reusing those exact ids + existing l10n keys, so it works **with or without** P1. If P1 later publishes a canonical `SoundCatalog`, swap `timerSoundIds` to re-export it (one-line change) — Task 2.1 notes this.
- **Feature 3 (banner) CONSUMES Phase 2's permission state.** The Phase 2 plan file `docs/superpowers/plans/2026-06-01-tarf-phase2-background.md` is **absent** at authoring time. Per instructions, Feature 3 designs against an **assumed** `notificationStatusProvider` exposing `granted | denied | limited` + a per-platform limit message. Task 3.1 ships that provider as a **seam** (`permissions/application/notification_status.dart`) that defaults to `granted` and is trivially overridable. When Phase 2 lands its real provider, the integrator either (a) re-exports P2's provider from this file, or (b) points the banner's `ref.watch` at P2's provider — Task 3.1 documents both. **Banner is worktree-safe; it only reads the seam.**
- **Feature 1 (location picker) + Feature 4 (tasbih) are low-contention.** F1 adds a new folder + one route + one pill rewire + a `prayerCityLabel` field on `EyeCareConfig`. F4 adds new files + appends an opt-in widget *below* the existing `_DhikrView` in `break_overlay.dart` (never inside/over it). Neither touches timer/permission code.
- **`EyeCareConfig` is shared by F1.** F1 adds `prayerCityLabel` (a label string only; the numeric `prayerLatitude/Longitude/prayerMethod/prayerMadhab` already exist and are already consumed by `PrayerService.timesFor` via `prayerAlarmsProvider`). Additive `copyWith`/`toJson`/`fromJson` — backward compatible with persisted v1 JSON.

**Recommended merge order:** Phase 1 → **F1 (location picker)** & **F4 (tasbih)** in parallel (independent) → **F3 (banner)** (after/with Phase 2, but seam lets it land anytime) → **F2 (multi-timer)** last (highest contention; reconcile P1 chime). All four are worktree-safe except F2's shared timer files.

---

## Conventions every task follows (read once)

- **Controller tests** use a bare `ProviderContainer` with `addTearDown(container.dispose)` and override `sharedPreferencesProvider`:
  ```dart
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  ```
- **Widget tests** use this host (matches `new_states_test.dart`):
  ```dart
  Widget _host(Widget child, SharedPreferences prefs,
          {Locale locale = const Locale('en')}) =>
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: locale,
          theme: TarfTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
  ```
- **Persistence keys** are versioned: `tarf.<feature>.v1`.
- **Numerals**: never interpolate raw `int` into clock/label UI — use `Numerals.padded/timer/formatInt` or wrap in `TarfTimeText` (forced-LTR, tabular). ARB plural/number placeholders stay plain `{n}` (gen-l10n emits Western digits).
- **RTL**: directional padding (`EdgeInsetsDirectional`), chevrons flip via `Directionality.of(context)`, clock/numeral blocks never mirror (already handled by `TarfTimeText` + `TarfWheelPicker`'s forced-LTR).
- **Commit** after each green task. Commit messages END with the trailer:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **Branch**: create one feature branch per feature, e.g. `git checkout -b phase3/location-picker` before that feature's first task (the repo is not a git repo at authoring time; if `git init` is needed, the integrator does it once — do NOT commit on a default branch).

---

# FEATURE 1 — Prayer-time Location & Method Picker

**Why:** Today's prayer times default to hardcoded Riyadh / Umm al-Qura. `EyeCareConfig` already holds `prayerLatitude/Longitude/prayerMethod/prayerMadhab`; `PrayerService.timesFor` already uses them; `prayerAlarmsProvider` already recomputes on config change. The only gaps: (a) no UI to set them, (b) the Prayer-mode pill in `alarm_screen.dart` routes to `Routes.eyeCareSettings` instead of a picker, (c) no human-readable city label. This feature adds the calm picker, a `prayerCityLabel`, optional device geolocation behind an honest abstraction, and rewires the pill.

**Design decisions (reverence + honesty + RTL):**
- **Manual-first.** Latitude/longitude/city are always editable. Geolocation is an *optional convenience* behind a `GeoLocator` abstraction whose default impl is `UnavailableGeoLocator` (returns `null`/throws-free). If `geolocator` plugin + permission are present, the real impl fills lat/lng; on denial or unavailability the UI stays on manual with a calm note — never an error wall.
- **Lat/lng are numbers, not clock faces** → rendered via plain `TextField`/`Numerals.formatInt`, forced-LTR for the numeric values (a coordinate is not mirrored under RTL), labels localized + directional.
- **Method/madhab** come from `adhan`'s `CalculationMethod` (a curated, ordered subset matching `PrayerService._params`: ummAlQura, muslimWorldLeague, egyptian, karachi, dubai, qatar, kuwait, northAmerica, turkey) and `Madhab` (shafi/hanafi). Catalog is a pure list of `(id, l10nKey)` so it is unit-testable and the UI just maps id→localized label.
- **Western digits** for coordinates and any numbers.

### Task 1.1 — Prayer calculation-options catalog (pure)

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\prayer\domain\prayer_calc_options.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\prayer\prayer_calc_options_test.dart`

- [ ] Write the failing test:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/features/prayer/domain/prayer_calc_options.dart';

  void main() {
    group('PrayerCalcOptions', () {
      test('method ids exactly match PrayerService-supported ids and are unique', () {
        final ids = kPrayerMethods.map((m) => m.id).toList();
        expect(ids.toSet().length, ids.length); // unique
        expect(ids, containsAll(<String>[
          'ummAlQura', 'muslimWorldLeague', 'egyptian', 'karachi',
          'dubai', 'qatar', 'kuwait', 'northAmerica', 'turkey',
        ]));
        // Umm al-Qura is first (the Tarf/KSA default).
        expect(kPrayerMethods.first.id, 'ummAlQura');
      });

      test('every method/madhab option exposes a non-empty l10n key', () {
        for (final m in kPrayerMethods) {
          expect(m.l10nKey, isNotEmpty);
        }
        for (final m in kMadhabs) {
          expect(m.l10nKey, isNotEmpty);
        }
        expect(kMadhabs.map((m) => m.id).toList(), <String>['shafi', 'hanafi']);
      });
    });
  }
  ```
- [ ] Run (expect FAIL — file/types do not exist):
  `flutter test test/features/prayer/prayer_calc_options_test.dart`
  Expected: compile error / "Target of URI doesn't exist" then red.
- [ ] Minimal impl:
  ```dart
  import 'package:flutter/foundation.dart';

  /// A selectable prayer-time option: a stable [id] persisted in EyeCareConfig
  /// and an [l10nKey] used to look up the localized label in the UI. Pure data —
  /// no Flutter/adhan imports so it stays trivially testable.
  @immutable
  class PrayerOption {
    const PrayerOption(this.id, this.l10nKey);
    final String id;
    final String l10nKey;
  }

  /// Calculation methods Tarf exposes, ordered with the KSA default first. The
  /// [id]s MUST stay in lockstep with PrayerService._params' switch arms.
  const List<PrayerOption> kPrayerMethods = [
    PrayerOption('ummAlQura', 'prayerMethodUmmAlQura'),
    PrayerOption('muslimWorldLeague', 'prayerMethodMwl'),
    PrayerOption('egyptian', 'prayerMethodEgyptian'),
    PrayerOption('karachi', 'prayerMethodKarachi'),
    PrayerOption('dubai', 'prayerMethodDubai'),
    PrayerOption('qatar', 'prayerMethodQatar'),
    PrayerOption('kuwait', 'prayerMethodKuwait'),
    PrayerOption('northAmerica', 'prayerMethodNorthAmerica'),
    PrayerOption('turkey', 'prayerMethodTurkey'),
  ];

  /// The two madhabs adhan supports for Asr calculation.
  const List<PrayerOption> kMadhabs = [
    PrayerOption('shafi', 'madhabShafi'),
    PrayerOption('hanafi', 'madhabHanafi'),
  ];
  ```
- [ ] Run (expect PASS): `flutter test test/features/prayer/prayer_calc_options_test.dart`
- [ ] Commit:
  `git add app/lib/features/prayer/domain/prayer_calc_options.dart app/test/features/prayer/prayer_calc_options_test.dart`
  ```
  git commit -m "feat(prayer): add pure calc-method/madhab option catalog

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 1.2 — `prayerCityLabel` on EyeCareConfig (additive, persisted)

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\domain\eyecare_config.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\eyecare\eyecare_config_city_test.dart` (NEW)

- [ ] Write the failing test:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/features/eyecare/domain/eyecare_config.dart';

  void main() {
    test('prayerCityLabel defaults empty and round-trips through json', () {
      const cfg = EyeCareConfig();
      expect(cfg.prayerCityLabel, '');
      final next = cfg.copyWith(
        prayerCityLabel: 'Makkah',
        prayerLatitude: 21.4225,
        prayerLongitude: 39.8262,
        prayerMethod: 'muslimWorldLeague',
        prayerMadhab: 'hanafi',
      );
      final round = EyeCareConfig.fromJson(next.toJson());
      expect(round.prayerCityLabel, 'Makkah');
      expect(round.prayerLatitude, 21.4225);
      expect(round.prayerMethod, 'muslimWorldLeague');
      expect(round.prayerMadhab, 'hanafi');
    });

    test('legacy json without prayerCity decodes to empty label', () {
      final legacy = const EyeCareConfig().toJson()..remove('prayerCity');
      expect(EyeCareConfig.fromJson(legacy).prayerCityLabel, '');
    });
  }
  ```
- [ ] Run (expect FAIL — `prayerCityLabel` undefined):
  `flutter test test/features/eyecare/eyecare_config_city_test.dart`
- [ ] Minimal impl — three edits in `eyecare_config.dart`:
  - Constructor param (place after `this.prayerMadhab = 'shafi',`):
    ```dart
    this.prayerCityLabel = '',
    ```
  - Field (after the `prayerMadhab` field):
    ```dart
    /// Human-readable city/place shown on the Prayer screen (e.g. "Riyadh").
    /// Display-only; prayer times are computed from lat/lng/method/madhab.
    final String prayerCityLabel;
    ```
  - In `copyWith`: add `String? prayerCityLabel,` to the signature and
    `prayerCityLabel: prayerCityLabel ?? this.prayerCityLabel,` to the returned ctor.
  - In `toJson`: add `'prayerCity': prayerCityLabel,`.
  - In `fromJson`: add `prayerCityLabel: (j['prayerCity'] as String?) ?? '',`.
- [ ] Run (expect PASS): `flutter test test/features/eyecare/eyecare_config_city_test.dart`
- [ ] Sanity: existing config tests still green: `flutter test test/features/eyecare/`
- [ ] Commit:
  `git add app/lib/features/eyecare/domain/eyecare_config.dart app/test/features/eyecare/eyecare_config_city_test.dart`
  ```
  git commit -m "feat(eyecare): add persisted prayerCityLabel to EyeCareConfig

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 1.3 — GeoLocator abstraction (honest, testable; real impl thin)

**Files:**
- Impl (interface + fakes): `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\prayer\application\geo_locator.dart`
- Impl (real, not unit-tested): `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\prayer\application\geolocator_geo_locator.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\prayer\geo_locator_test.dart`

- [ ] Add the dependency (Feature 1's only new dep). Edit `app/pubspec.yaml` under `dependencies:` after `adhan: ^2.0.0+1`:
  ```yaml
  geolocator: ^13.0.2
  ```
  Run: `flutter pub get` (expect success). NOTE: platform permission entries (Android `ACCESS_FINE_LOCATION`, iOS `NSLocationWhenInUseUsageDescription`) are **Phase-4 platform wiring** — out of scope here; the default `UnavailableGeoLocator` keeps the app shipping without them.
- [ ] Write the failing test:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:tarf/features/prayer/application/geo_locator.dart';

  void main() {
    test('UnavailableGeoLocator reports unsupported and returns null', () async {
      const g = UnavailableGeoLocator();
      expect(g.isSupported, isFalse);
      expect(await g.currentLatLng(), isNull);
    });

    test('FakeGeoLocator yields the seeded fix', () async {
      final g = FakeGeoLocator(const GeoFix(21.4225, 39.8262));
      expect(g.isSupported, isTrue);
      expect((await g.currentLatLng())!.latitude, 21.4225);
    });

    test('default provider is the Unavailable locator (manual-first)', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(geoLocatorProvider), isA<UnavailableGeoLocator>());
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/features/prayer/geo_locator_test.dart`
- [ ] Minimal impl (`geo_locator.dart`):
  ```dart
  import 'package:flutter/foundation.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  /// A latitude/longitude pair.
  @immutable
  class GeoFix {
    const GeoFix(this.latitude, this.longitude);
    final double latitude;
    final double longitude;
  }

  /// Optional device geolocation behind a seam so the picker is manual-first and
  /// fully testable. Implementations MUST be honest: if unsupported or permission
  /// is denied, return null (never throw) so the UI falls back to manual entry.
  abstract interface class GeoLocator {
    bool get isSupported;

    /// The current device location, or null if unavailable/denied. Never throws.
    Future<GeoFix?> currentLatLng();
  }

  /// Default: geolocation not wired (no plugin/permission). Keeps Tarf shipping
  /// and offline-first; the picker stays on manual entry.
  class UnavailableGeoLocator implements GeoLocator {
    const UnavailableGeoLocator();
    @override
    bool get isSupported => false;
    @override
    Future<GeoFix?> currentLatLng() async => null;
  }

  /// Records calls / yields a seeded fix for tests.
  class FakeGeoLocator implements GeoLocator {
    FakeGeoLocator(this._fix, {this.supported = true});
    final GeoFix? _fix;
    final bool supported;
    int calls = 0;
    @override
    bool get isSupported => supported;
    @override
    Future<GeoFix?> currentLatLng() async {
      calls++;
      return _fix;
    }
  }

  /// Override in main() (or a platform bootstrap) with the geolocator-backed impl
  /// once Phase-4 platform permissions are wired. Defaults to manual-first.
  final geoLocatorProvider =
      Provider<GeoLocator>((ref) => const UnavailableGeoLocator());
  ```
- [ ] Run (expect PASS): `flutter test test/features/prayer/geo_locator_test.dart`
- [ ] Write the **real** impl (no unit test — it talks to the plugin; verified on-device in Phase 4). `geolocator_geo_locator.dart`:
  ```dart
  import 'package:geolocator/geolocator.dart';

  import 'geo_locator.dart';

  /// Real device geolocation. Requests permission, honors denial silently, and
  /// returns null on any failure so the picker never shows an error wall.
  class GeolocatorGeoLocator implements GeoLocator {
    const GeolocatorGeoLocator();

    @override
    bool get isSupported => true;

    @override
    Future<GeoFix?> currentLatLng() async {
      try {
        if (!await Geolocator.isLocationServiceEnabled()) return null;
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          return null;
        }
        final pos = await Geolocator.getCurrentPosition();
        return GeoFix(pos.latitude, pos.longitude);
      } catch (_) {
        return null;
      }
    }
  }
  ```
  > Integrator note: to actually enable GPS, override `geoLocatorProvider` with `const GelocatorGeoLocator()` in `main()` AND add platform permission strings (Phase 4). Until then the default Unavailable impl is correct and honest.
- [ ] Run analyzer (the real impl must compile after `pub get`): `flutter analyze lib/features/prayer`
- [ ] Commit:
  `git add app/pubspec.yaml app/pubspec.lock app/lib/features/prayer/application/geo_locator.dart app/lib/features/prayer/application/geolocator_geo_locator.dart app/test/features/prayer/geo_locator_test.dart`
  ```
  git commit -m "feat(prayer): add GeoLocator seam + geolocator-backed impl (manual-first)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 1.4 — l10n keys for the picker

**Files:** `app/lib/l10n/app_en.arb`, `app/lib/l10n/app_ar.arb`

- [ ] Add to `app_en.arb` (before the closing `}`; keep `locationAndMethod` which already exists and is reused as the screen title):
  ```json
  "locationPickerTitle": "Location & method",
  "prayerLocationGroup": "Location",
  "prayerCityLabelField": "City or place",
  "prayerCityHint": "e.g. Riyadh",
  "prayerLatitude": "Latitude",
  "prayerLongitude": "Longitude",
  "useMyLocation": "Use my location",
  "locationUnavailable": "Device location isn't available — enter it manually below.",
  "locationDenied": "Location permission was declined — you can enter it manually.",
  "prayerMethodGroup": "Calculation method",
  "prayerMadhabGroup": "Asr method (madhab)",
  "prayerMethodUmmAlQura": "Umm al-Qura (Makkah)",
  "prayerMethodMwl": "Muslim World League",
  "prayerMethodEgyptian": "Egyptian General Authority",
  "prayerMethodKarachi": "University of Karachi",
  "prayerMethodDubai": "Dubai",
  "prayerMethodQatar": "Qatar",
  "prayerMethodKuwait": "Kuwait",
  "prayerMethodNorthAmerica": "North America (ISNA)",
  "prayerMethodTurkey": "Türkiye (Diyanet)",
  "madhabShafi": "Shafi, Maliki, Hanbali",
  "madhabHanafi": "Hanafi",
  "locationSaved": "Location updated"
  ```
- [ ] Add the SAME keys to `app_ar.arb` with Arabic values:
  ```json
  "locationPickerTitle": "الموقع والطريقة",
  "prayerLocationGroup": "الموقع",
  "prayerCityLabelField": "المدينة أو المكان",
  "prayerCityHint": "مثال: الرياض",
  "prayerLatitude": "خط العرض",
  "prayerLongitude": "خط الطول",
  "useMyLocation": "استخدم موقعي",
  "locationUnavailable": "موقع الجهاز غير متاح — أدخله يدويًا أدناه.",
  "locationDenied": "تم رفض إذن الموقع — يمكنك إدخاله يدويًا.",
  "prayerMethodGroup": "طريقة الحساب",
  "prayerMadhabGroup": "طريقة العصر (المذهب)",
  "prayerMethodUmmAlQura": "أم القرى (مكة)",
  "prayerMethodMwl": "رابطة العالم الإسلامي",
  "prayerMethodEgyptian": "الهيئة المصرية العامة",
  "prayerMethodKarachi": "جامعة كراتشي",
  "prayerMethodDubai": "دبي",
  "prayerMethodQatar": "قطر",
  "prayerMethodKuwait": "الكويت",
  "prayerMethodNorthAmerica": "أمريكا الشمالية (ISNA)",
  "prayerMethodTurkey": "تركيا (ديانت)",
  "madhabShafi": "شافعي ومالكي وحنبلي",
  "madhabHanafi": "حنفي",
  "locationSaved": "تم تحديث الموقع"
  ```
- [ ] Regenerate + sanity-compile:
  `flutter gen-l10n` then `flutter analyze lib/l10n`
  Expected: PASS, `lib/l10n/app_localizations*.dart` regenerated with the new getters.
- [ ] Commit:
  `git add app/lib/l10n/app_en.arb app/lib/l10n/app_ar.arb app/lib/l10n/app_localizations.dart app/lib/l10n/app_localizations_en.dart app/lib/l10n/app_localizations_ar.dart`
  ```
  git commit -m "i18n(prayer): add location-picker strings (en+ar)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 1.5 — Location picker screen + route + pill rewire

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\presentation\location_picker_screen.dart`
- Route: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\routing\app_router.dart`
- Pill: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\alarm\presentation\alarm_screen.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\eyecare\location_picker_test.dart`

- [ ] Write the failing widget test (drives method change → persisted config, and the geolocation fallback path):
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/settings/settings_controller.dart';
  import 'package:tarf/features/eyecare/application/eyecare_config_controller.dart';
  import 'package:tarf/features/eyecare/presentation/location_picker_screen.dart';
  import 'package:tarf/features/prayer/application/geo_locator.dart';
  import 'package:tarf/l10n/app_localizations.dart';
  import 'package:tarf/theme/app_theme.dart';

  Widget _host(SharedPreferences prefs, GeoLocator geo) => ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          geoLocatorProvider.overrideWithValue(geo),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LocationPickerScreen(),
        ),
      );

  void main() {
    testWidgets('choosing a method persists it to EyeCareConfig',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(
        theme: TarfTheme.dark(),
        home: _host(prefs, const UnavailableGeoLocator()),
      ));
      await tester.pumpAndSettle();

      // Open the method group and pick MWL.
      await tester.tap(find.text('Calculation method'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Muslim World League'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LocationPickerScreen)),
      );
      expect(container.read(eyeCareConfigProvider).prayerMethod,
          'muslimWorldLeague');
    });

    testWidgets('Use my location with no GPS keeps manual entry (no error wall)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(
        theme: TarfTheme.dark(),
        home: _host(prefs, const UnavailableGeoLocator()),
      ));
      await tester.pumpAndSettle();

      // The convenience button is hidden when geolocation is unsupported.
      expect(find.text('Use my location'), findsNothing);
      // Manual coordinate fields are present.
      expect(find.text('Latitude'), findsOneWidget);
      expect(find.text('Longitude'), findsOneWidget);
    });
  }
  ```
  > NOTE on the host: the test wraps `_host` in an outer `MaterialApp` only to satisfy `TarfTheme`; if `localizationsDelegates` collide, simplify to a single `MaterialApp` inside `_host` with `theme: TarfTheme.dark()` and drop the outer wrapper. Keep whichever the analyzer/test accepts — the assertion semantics are what matter.
- [ ] Run (expect FAIL — `LocationPickerScreen` does not exist):
  `flutter test test/features/eyecare/location_picker_test.dart`
- [ ] Minimal impl (`location_picker_screen.dart`) — compose `TarfGroup`/`TarfListRow`, a bottom-sheet selector reusing the alarm-editor pattern, and forced-LTR coordinate fields. Persist on every change:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../core/widgets/tarf_widgets.dart';
  import '../../../l10n/app_localizations.dart';
  import '../../../theme/tokens.dart';
  import '../../prayer/application/geo_locator.dart';
  import '../../prayer/domain/prayer_calc_options.dart';
  import '../application/eyecare_config_controller.dart';
  import '../domain/eyecare_config.dart';

  /// Calm prayer-time location/method picker. Manual-first: lat/lng/city are
  /// always editable; device geolocation is an optional convenience that falls
  /// back honestly to manual entry. Persists into EyeCareConfig, so the Prayer
  /// screen's computed times update immediately (prayerAlarmsProvider watches it).
  class LocationPickerScreen extends ConsumerStatefulWidget {
    const LocationPickerScreen({super.key});
    @override
    ConsumerState<LocationPickerScreen> createState() =>
        _LocationPickerScreenState();
  }

  class _LocationPickerScreenState
      extends ConsumerState<LocationPickerScreen> {
    late TextEditingController _city;
    late TextEditingController _lat;
    late TextEditingController _lng;
    String? _geoNote; // localized fallback note, or null

    @override
    void initState() {
      super.initState();
      final cfg = ref.read(eyeCareConfigProvider);
      _city = TextEditingController(text: cfg.prayerCityLabel);
      _lat = TextEditingController(text: cfg.prayerLatitude.toString());
      _lng = TextEditingController(text: cfg.prayerLongitude.toString());
    }

    @override
    void dispose() {
      _city.dispose();
      _lat.dispose();
      _lng.dispose();
      super.dispose();
    }

    EyeCareConfig get _cfg => ref.read(eyeCareConfigProvider);
    void _update(EyeCareConfig next) =>
        ref.read(eyeCareConfigProvider.notifier).update(next);

    void _commitText() {
      final lat = double.tryParse(_lat.text) ?? _cfg.prayerLatitude;
      final lng = double.tryParse(_lng.text) ?? _cfg.prayerLongitude;
      _update(_cfg.copyWith(
        prayerCityLabel: _city.text.trim(),
        prayerLatitude: lat,
        prayerLongitude: lng,
      ));
    }

    Future<void> _useMyLocation() async {
      final l10n = AppLocalizations.of(context);
      final geo = ref.read(geoLocatorProvider);
      final fix = await geo.currentLatLng();
      if (!mounted) return;
      if (fix == null) {
        setState(() => _geoNote = l10n.locationDenied);
        return;
      }
      setState(() {
        _lat.text = fix.latitude.toString();
        _lng.text = fix.longitude.toString();
        _geoNote = null;
      });
      _commitText();
    }

    Future<void> _pickOption({
      required String title,
      required List<PrayerOption> options,
      required String current,
      required ValueChanged<String> onPick,
    }) async {
      final l10n = AppLocalizations.of(context);
      await showModalBottomSheet<void>(
        context: context,
        builder: (sheetCtx) {
          final scheme = Theme.of(sheetCtx).colorScheme;
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(TarfTokens.space4),
                  child: Text(title,
                      style: Theme.of(sheetCtx).textTheme.titleLarge),
                ),
                for (final o in options)
                  ListTile(
                    title: Text(_label(l10n, o.l10nKey)),
                    trailing: o.id == current
                        ? Icon(Icons.check, color: scheme.primary)
                        : null,
                    onTap: () {
                      onPick(o.id);
                      Navigator.of(sheetCtx).pop();
                    },
                  ),
              ],
            ),
          );
        },
      );
    }

    // Maps an l10n key string to its localized value. Centralized so the option
    // catalogs stay pure (no Flutter import).
    String _label(AppLocalizations l, String key) => switch (key) {
          'prayerMethodUmmAlQura' => l.prayerMethodUmmAlQura,
          'prayerMethodMwl' => l.prayerMethodMwl,
          'prayerMethodEgyptian' => l.prayerMethodEgyptian,
          'prayerMethodKarachi' => l.prayerMethodKarachi,
          'prayerMethodDubai' => l.prayerMethodDubai,
          'prayerMethodQatar' => l.prayerMethodQatar,
          'prayerMethodKuwait' => l.prayerMethodKuwait,
          'prayerMethodNorthAmerica' => l.prayerMethodNorthAmerica,
          'prayerMethodTurkey' => l.prayerMethodTurkey,
          'madhabShafi' => l.madhabShafi,
          _ => l.madhabHanafi,
        };

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context);
      final cfg = ref.watch(eyeCareConfigProvider);
      final geo = ref.watch(geoLocatorProvider);
      final methodKey =
          kPrayerMethods.firstWhere((m) => m.id == cfg.prayerMethod,
              orElse: () => kPrayerMethods.first).l10nKey;
      final madhabKey =
          kMadhabs.firstWhere((m) => m.id == cfg.prayerMadhab,
              orElse: () => kMadhabs.first).l10nKey;

      return Scaffold(
        appBar: AppBar(title: Text(l10n.locationPickerTitle)),
        body: ListView(
          padding: const EdgeInsets.all(TarfTokens.space3),
          children: [
            TarfSectionHeader(l10n.prayerLocationGroup),
            TarfGroup(children: [
              _fieldRow(l10n.prayerCityLabelField, _city,
                  hint: l10n.prayerCityHint),
              _fieldRow(l10n.prayerLatitude, _lat, numeric: true),
              _fieldRow(l10n.prayerLongitude, _lng, numeric: true),
            ]),
            if (geo.isSupported) ...[
              const SizedBox(height: TarfTokens.space3),
              OutlinedButton.icon(
                icon: const Icon(Icons.my_location),
                label: Text(l10n.useMyLocation),
                onPressed: _useMyLocation,
              ),
            ],
            if (_geoNote != null)
              Padding(
                padding: const EdgeInsets.only(top: TarfTokens.space2),
                child: Text(_geoNote!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.tarf.warningText)),
              ),
            TarfSectionHeader(l10n.prayerMethodGroup),
            TarfGroup(children: [
              TarfListRow(
                icon: Icons.public,
                title: l10n.prayerMethodGroup,
                subtitle: _label(l10n, methodKey),
                onTap: () => _pickOption(
                  title: l10n.prayerMethodGroup,
                  options: kPrayerMethods,
                  current: cfg.prayerMethod,
                  onPick: (id) => _update(cfg.copyWith(prayerMethod: id)),
                ),
              ),
            ]),
            TarfSectionHeader(l10n.prayerMadhabGroup),
            TarfGroup(children: [
              TarfListRow(
                icon: Icons.schedule,
                title: l10n.prayerMadhabGroup,
                subtitle: _label(l10n, madhabKey),
                onTap: () => _pickOption(
                  title: l10n.prayerMadhabGroup,
                  options: kMadhabs,
                  current: cfg.prayerMadhab,
                  onPick: (id) => _update(cfg.copyWith(prayerMadhab: id)),
                ),
              ),
            ]),
          ],
        ),
      );
    }

    Widget _fieldRow(String label, TextEditingController c,
        {bool numeric = false, String? hint}) {
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: TarfTokens.space3,
          vertical: TarfTokens.space2,
        ),
        child: TextField(
          controller: c,
          // A coordinate is a number, not a clock face: keep it LTR even in RTL.
          textDirection: numeric ? TextDirection.ltr : null,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(
                  signed: true, decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(labelText: label, hintText: hint),
          onChanged: (_) => _commitText(),
        ),
      );
    }
  }
  ```
  > Reverence/RTL: coordinates forced LTR; method/madhab labels localized + directional via `TarfListRow`'s built-in `EdgeInsetsDirectional`. No prayer *names* are altered. Persisting on change means `prayerAlarmsProvider` (which `ref.watch(eyeCareConfigProvider)`) recomputes times live.
- [ ] Add the route. In `app_router.dart`:
  - In `abstract final class Routes` add: `static const locationPicker = '/settings/prayer-location';`
  - Add the import near the other eyecare imports: `import '../../features/eyecare/presentation/location_picker_screen.dart';`
  - Add a top-level pushed `GoRoute` (alongside `eyeCareSettings`):
    ```dart
    GoRoute(
      path: Routes.locationPicker,
      builder: (context, state) => const LocationPickerScreen(),
    ),
    ```
- [ ] Rewire the Prayer-mode pill. In `alarm_screen.dart` `_prayerView`, change the pill's `onTap` from `() => context.push(Routes.eyeCareSettings)` to `() => context.push(Routes.locationPicker)`.
- [ ] Run (expect PASS): `flutter test test/features/eyecare/location_picker_test.dart`
- [ ] Run the broader suites that touch routing/alarm to catch regressions:
  `flutter test test/features/app_navigation_test.dart test/features/new_states_test.dart`
- [ ] Commit:
  `git add app/lib/features/eyecare/presentation/location_picker_screen.dart app/lib/core/routing/app_router.dart app/lib/features/alarm/presentation/alarm_screen.dart app/test/features/eyecare/location_picker_test.dart`
  ```
  git commit -m "feat(prayer): calm location/method/madhab picker + wire Prayer pill

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

# FEATURE 2 — Multi-Timer / Saved Timers

**Why:** `TimerController` is a single countdown. The phase asks for a LIST of named saved timers (add/edit/delete/run), each with label + duration + sound id, reusing the wheel picker + preset grid for create/edit, persisted.

**Model choice (JUSTIFIED): a saved-timer list + ONE active runner.**
- The existing engine (`TimerController` / `CountdownData` / one `Timer.periodic`) and the whole UI (`_IdleView`/`_ActiveView`, `ProgressRing`, accessory shelf) are built around a **single** running countdown. The Calm Sanctuary design shows **one hero per screen**; concurrent rings would clutter and fight the "one hero" rule and the glass accessory shelf (which surfaces one active session).
- Concurrent runners would multiply timers, audio sessions (Phase-1 chime would need per-timer routing), and notification scheduling — large surface, more contention with P1, and a UX that contradicts the design language.
- **Simplest correct model:** persist a `List<SavedTimer>` (label + duration + soundId). "Run" loads the chosen saved timer into the existing single `TimerController` via a new `runSaved(SavedTimer)` that sets duration AND records `activeTimerId/label/soundId` on `CountdownData`. Starting another saved timer simply replaces the active one (calm, predictable, matches a phone's stock timer's "presets that load into the runner"). This is additive to the engine, minimizes P1 contention, and keeps one hero ring. If true concurrency is ever needed, the saved list is already the right substrate to grow into per-id runners.

### Task 2.1 — `SavedTimer` model + sound catalog

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\timer\domain\saved_timer.dart`
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\timer\domain\timer_sound_catalog.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\timer\saved_timer_test.dart`

- [ ] Write the failing test:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/features/timer/domain/saved_timer.dart';
  import 'package:tarf/features/timer/domain/timer_sound_catalog.dart';

  void main() {
    group('SavedTimer', () {
      test('round-trips through json with defaults', () {
        const t = SavedTimer(
          id: 't1',
          label: 'Tea',
          duration: Duration(minutes: 3),
          soundId: 'chime',
        );
        final r = SavedTimer.fromJson(t.toJson());
        expect(r.id, 't1');
        expect(r.label, 'Tea');
        expect(r.duration, const Duration(minutes: 3));
        expect(r.soundId, 'chime');
      });

      test('soundId defaults to the catalog default when missing', () {
        final r = SavedTimer.fromJson(const {
          'id': 'x', 'label': '', 'durS': 60,
        });
        expect(r.soundId, kDefaultTimerSoundId);
      });

      test('catalog ids are unique and include the default', () {
        expect(timerSoundIds.toSet().length, timerSoundIds.length);
        expect(timerSoundIds, contains(kDefaultTimerSoundId));
      });
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/features/timer/saved_timer_test.dart`
- [ ] Minimal impl (`timer_sound_catalog.dart`) — **reuse Phase-1's existing ids + l10n keys** (`soundDefault/soundBell/soundChime/soundCalm`) so this works with or without a P1-published catalog:
  ```dart
  /// Sound ids a saved timer can use. Mirrors the ids currently used by the alarm
  /// editor (default/bell/chime/calm) and their existing l10n keys
  /// (soundDefault/soundBell/soundChime/soundCalm). When Phase 1 publishes a
  /// canonical SoundCatalog, replace this list with a re-export — one line.
  const String kDefaultTimerSoundId = 'default';
  const List<String> timerSoundIds = ['default', 'bell', 'chime', 'calm'];

  /// The l10n key for a sound id (label resolved in the widget layer).
  String timerSoundL10nKey(String id) => switch (id) {
        'bell' => 'soundBell',
        'chime' => 'soundChime',
        'calm' => 'soundCalm',
        _ => 'soundDefault',
      };
  ```
- [ ] Minimal impl (`saved_timer.dart`):
  ```dart
  import 'package:flutter/foundation.dart';

  import 'timer_sound_catalog.dart';

  /// A user-saved, named countdown preset. Loaded into the single TimerController
  /// runner via runSaved(). Immutable; persisted as JSON in a list.
  @immutable
  class SavedTimer {
    const SavedTimer({
      required this.id,
      required this.label,
      required this.duration,
      this.soundId = kDefaultTimerSoundId,
    });

    final String id;
    final String label;
    final Duration duration;
    final String soundId;

    SavedTimer copyWith({
      String? label,
      Duration? duration,
      String? soundId,
    }) =>
        SavedTimer(
          id: id,
          label: label ?? this.label,
          duration: duration ?? this.duration,
          soundId: soundId ?? this.soundId,
        );

    Map<String, Object?> toJson() => {
          'id': id,
          'label': label,
          'durS': duration.inSeconds,
          'snd': soundId,
        };

    factory SavedTimer.fromJson(Map<String, Object?> j) => SavedTimer(
          id: j['id']! as String,
          label: (j['label'] as String?) ?? '',
          duration: Duration(seconds: (j['durS'] as int?) ?? 0),
          soundId: (j['snd'] as String?) ?? kDefaultTimerSoundId,
        );
  }
  ```
- [ ] Run (expect PASS): `flutter test test/features/timer/saved_timer_test.dart`
- [ ] Commit:
  `git add app/lib/features/timer/domain/saved_timer.dart app/lib/features/timer/domain/timer_sound_catalog.dart app/test/features/timer/saved_timer_test.dart`
  ```
  git commit -m "feat(timer): add SavedTimer model + shared timer sound catalog

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 2.2 — `SavedTimersController` (persisted list, add/edit/delete)

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\timer\application\saved_timers_controller.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\timer\saved_timers_controller_test.dart`

- [ ] Write the failing test (mirror `AlarmsController` idioms):
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/settings/settings_controller.dart';
  import 'package:tarf/features/timer/application/saved_timers_controller.dart';
  import 'package:tarf/features/timer/domain/saved_timer.dart';

  Future<ProviderContainer> _c() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  void main() {
    group('SavedTimersController', () {
      test('starts empty', () async {
        final c = await _c();
        expect(c.read(savedTimersControllerProvider), isEmpty);
      });

      test('upsert adds then edits the same id; persists across rebuild',
          () async {
        final c = await _c();
        final n = c.read(savedTimersControllerProvider.notifier);
        await n.upsert(const SavedTimer(
            id: 't1', label: 'Tea', duration: Duration(minutes: 3)));
        expect(c.read(savedTimersControllerProvider).length, 1);

        await n.upsert(const SavedTimer(
            id: 't1', label: 'Green tea', duration: Duration(minutes: 4)));
        expect(c.read(savedTimersControllerProvider).single.label, 'Green tea');

        // Re-read from storage with a fresh container -> persisted.
        final prefs = await SharedPreferences.getInstance();
        final c2 = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(c2.dispose);
        expect(c2.read(savedTimersControllerProvider).single.duration,
            const Duration(minutes: 4));
      });

      test('remove deletes by id', () async {
        final c = await _c();
        final n = c.read(savedTimersControllerProvider.notifier);
        await n.upsert(const SavedTimer(
            id: 'a', label: 'A', duration: Duration(minutes: 1)));
        await n.upsert(const SavedTimer(
            id: 'b', label: 'B', duration: Duration(minutes: 2)));
        await n.remove('a');
        expect(c.read(savedTimersControllerProvider).map((t) => t.id),
            ['b']);
      });
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/features/timer/saved_timers_controller_test.dart`
- [ ] Minimal impl (`saved_timers_controller.dart`):
  ```dart
  import 'dart:convert';

  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../core/settings/settings_controller.dart';
  import '../domain/saved_timer.dart';

  const _key = 'tarf.saved_timers.v1';

  /// Persisted list of saved timers (label + duration + soundId). Mirrors the
  /// AlarmsController persistence pattern.
  class SavedTimersController extends Notifier<List<SavedTimer>> {
    @override
    List<SavedTimer> build() {
      final raw = ref.watch(sharedPreferencesProvider).getString(_key);
      if (raw == null) return const [];
      try {
        return (jsonDecode(raw) as List)
            .cast<Map<String, Object?>>()
            .map(SavedTimer.fromJson)
            .toList();
      } catch (_) {
        return const [];
      }
    }

    Future<void> _persist(List<SavedTimer> next) async {
      state = next;
      await ref.read(sharedPreferencesProvider).setString(
            _key,
            jsonEncode(next.map((t) => t.toJson()).toList()),
          );
    }

    /// Adds [item] if its id is new, otherwise replaces the timer with that id.
    Future<void> upsert(SavedTimer item) {
      final exists = state.any((t) => t.id == item.id);
      final next = exists
          ? [for (final t in state) if (t.id == item.id) item else t]
          : [...state, item];
      return _persist(next);
    }

    Future<void> remove(String id) =>
        _persist([for (final t in state) if (t.id != id) t]);
  }

  final savedTimersControllerProvider =
      NotifierProvider<SavedTimersController, List<SavedTimer>>(
    SavedTimersController.new,
  );
  ```
- [ ] Run (expect PASS): `flutter test test/features/timer/saved_timers_controller_test.dart`
- [ ] Commit:
  `git add app/lib/features/timer/application/saved_timers_controller.dart app/test/features/timer/saved_timers_controller_test.dart`
  ```
  git commit -m "feat(timer): persisted SavedTimersController (add/edit/delete)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 2.3 — Extend `TimerController` runner to carry id/label/sound (P1 SEAM)

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\timer\application\timer_controller.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\timer\timer_controller_active_test.dart`

> **PHASE-1 CONTENTION (read before editing):** Phase 1 also edits this file to play the timer chime when the countdown reaches zero (in `_tick()` at the `next <= Duration.zero` branch). This task only **adds** fields and a `runSaved()` method; it does NOT change `_tick`'s finish logic. When integrating with P1: keep P1's chime call in `_tick`, and ensure the chime uses `state.soundId` (now available) if P1 wants per-timer sound. Do the merge in the integration step, not here. Existing `timer_controller_test.dart` must stay green.

- [ ] Write the failing test:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/features/timer/application/timer_controller.dart';
  import 'package:tarf/features/timer/domain/saved_timer.dart';

  void main() {
    group('TimerController.runSaved', () {
      test('loads a saved timer into the runner with its id/label/sound', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        c.read(timerControllerProvider.notifier).runSaved(
              const SavedTimer(
                id: 't9',
                label: 'Steep',
                duration: Duration(minutes: 2),
                soundId: 'calm',
              ),
            );
        final s = c.read(timerControllerProvider);
        expect(s.total, const Duration(minutes: 2));
        expect(s.remaining, const Duration(minutes: 2));
        expect(s.activeTimerId, 't9');
        expect(s.label, 'Steep');
        expect(s.soundId, 'calm');
        expect(s.running, isFalse); // loaded, not auto-started
      });

      test('setDuration clears the saved-timer identity (ad-hoc timer)', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        c.read(timerControllerProvider.notifier)
          ..runSaved(const SavedTimer(
              id: 't1', label: 'X', duration: Duration(minutes: 1)))
          ..setDuration(const Duration(minutes: 5));
        final s = c.read(timerControllerProvider);
        expect(s.activeTimerId, isNull);
        expect(s.label, isEmpty);
      });
    });
  }
  ```
- [ ] Run (expect FAIL — `activeTimerId/label/soundId/runSaved` undefined):
  `flutter test test/features/timer/timer_controller_active_test.dart`
- [ ] Minimal impl — edits to `timer_controller.dart` (additive; do NOT remove anything):
  - Add import: `import '../domain/saved_timer.dart';` and `import '../domain/timer_sound_catalog.dart';`
  - Add three fields to `CountdownData` (with defaults so existing `const CountdownData(...)` call sites compile):
    ```dart
    final String? activeTimerId;   // null = ad-hoc timer
    final String label;            // '' = unnamed
    final String soundId;          // chime sound id for finish
    ```
    Update the constructor to: `this.activeTimerId, this.label = '', this.soundId = kDefaultTimerSoundId,` and `copyWith` to thread them (add a `bool clearIdentity = false` so `setDuration` can null the id):
    ```dart
    CountdownData copyWith({
      Duration? total,
      Duration? remaining,
      bool? running,
      bool? finished,
      String? activeTimerId,
      bool clearIdentity = false,
      String? label,
      String? soundId,
    }) =>
        CountdownData(
          total: total ?? this.total,
          remaining: remaining ?? this.remaining,
          running: running ?? this.running,
          finished: finished ?? this.finished,
          activeTimerId:
              clearIdentity ? null : (activeTimerId ?? this.activeTimerId),
          label: clearIdentity ? '' : (label ?? this.label),
          soundId: soundId ?? this.soundId,
        );
    ```
  - In `setDuration`, set identity to ad-hoc:
    ```dart
    void setDuration(Duration d) {
      _ticker?.cancel();
      _ticker = null;
      state = CountdownData(total: d, remaining: d); // identity cleared (defaults)
    }
    ```
  - Add `runSaved` (loads but does not auto-start, matching `setDuration` semantics):
    ```dart
    /// Loads [t] into the single runner (replacing any active timer). Does not
    /// auto-start; the user taps Start, matching the existing idle→active flow.
    void runSaved(SavedTimer t) {
      _ticker?.cancel();
      _ticker = null;
      state = CountdownData(
        total: t.duration,
        remaining: t.duration,
        activeTimerId: t.id,
        label: t.label,
        soundId: t.soundId,
      );
    }
    ```
- [ ] Run (expect PASS): `flutter test test/features/timer/timer_controller_active_test.dart`
- [ ] Run the EXISTING controller test (must stay green — proves additive change):
  `flutter test test/features/timer/timer_controller_test.dart`
- [ ] Commit:
  `git add app/lib/features/timer/application/timer_controller.dart app/test/features/timer/timer_controller_active_test.dart`
  ```
  git commit -m "feat(timer): runner carries saved-timer id/label/sound (additive)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 2.4 — l10n keys for saved timers

**Files:** `app/lib/l10n/app_en.arb`, `app/lib/l10n/app_ar.arb`

- [ ] Add to `app_en.arb`:
  ```json
  "timerSavedTitle": "Saved timers",
  "timerAddSaved": "New timer",
  "timerEditSaved": "Edit timer",
  "timerNoneSaved": "No saved timers yet",
  "timerLabel": "Label",
  "timerLabelHint": "e.g. Tea, Wudu, Study",
  "timerDeleted": "Timer deleted",
  "timerRun": "Start",
  "timerUnnamed": "Timer"
  ```
- [ ] Add the SAME keys to `app_ar.arb`:
  ```json
  "timerSavedTitle": "المؤقتات المحفوظة",
  "timerAddSaved": "مؤقّت جديد",
  "timerEditSaved": "تعديل المؤقّت",
  "timerNoneSaved": "لا توجد مؤقتات محفوظة بعد",
  "timerLabel": "التسمية",
  "timerLabelHint": "مثال: شاي، وضوء، مذاكرة",
  "timerDeleted": "تم حذف المؤقّت",
  "timerRun": "ابدأ",
  "timerUnnamed": "مؤقّت"
  ```
- [ ] Regenerate + compile: `flutter gen-l10n` then `flutter analyze lib/l10n`
- [ ] Commit:
  `git add app/lib/l10n/app_en.arb app/lib/l10n/app_ar.arb app/lib/l10n/app_localizations.dart app/lib/l10n/app_localizations_en.dart app/lib/l10n/app_localizations_ar.dart`
  ```
  git commit -m "i18n(timer): add saved-timer strings (en+ar)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 2.5 — Saved-timer editor screen (wheel + preset grid + label + sound)

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\timer\presentation\saved_timer_editor_screen.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\timer\saved_timer_editor_test.dart`

- [ ] Write the failing widget test:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/settings/settings_controller.dart';
  import 'package:tarf/core/widgets/tarf_wheel_picker.dart';
  import 'package:tarf/features/timer/application/saved_timers_controller.dart';
  import 'package:tarf/features/timer/presentation/saved_timer_editor_screen.dart';
  import 'package:tarf/l10n/app_localizations.dart';
  import 'package:tarf/theme/app_theme.dart';

  Widget _host(SharedPreferences prefs, Widget child) => ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: TarfTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );

  void main() {
    testWidgets('new-timer editor shows the wheel and saves a SavedTimer',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
          _host(prefs, const SavedTimerEditorScreen()));
      await tester.pumpAndSettle();

      // Reuses the calm wheel picker.
      expect(find.byType(TarfWheelPicker), findsOneWidget);

      // Save (a 5-minute default preset is selected initially).
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      expect(container.read(savedTimersControllerProvider), hasLength(1));
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/features/timer/saved_timer_editor_test.dart`
- [ ] Minimal impl (`saved_timer_editor_screen.dart`) — reuse the `_IdleView` wheel + preset grid pattern from `timer_screen.dart` and the bottom-sheet sound picker from `alarm_editor_screen.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';

  import '../../../core/format/numerals.dart';
  import '../../../core/settings/settings_controller.dart';
  import '../../../core/widgets/tarf_wheel_picker.dart';
  import '../../../core/widgets/tarf_widgets.dart';
  import '../../../l10n/app_localizations.dart';
  import '../../../theme/tokens.dart';
  import '../application/saved_timers_controller.dart';
  import '../domain/saved_timer.dart';
  import '../domain/timer_sound_catalog.dart';

  const _presetMinutes = [1, 5, 10, 20, 30, 40];

  /// Create/edit a saved timer. Reuses the calm wheel picker (HH·MM·SS) + the
  /// preset grid for duration, a labeled row, and a sound bottom-sheet.
  class SavedTimerEditorScreen extends ConsumerStatefulWidget {
    const SavedTimerEditorScreen({super.key, this.existing});
    final SavedTimer? existing;
    @override
    ConsumerState<SavedTimerEditorScreen> createState() =>
        _SavedTimerEditorScreenState();
  }

  class _SavedTimerEditorScreenState
      extends ConsumerState<SavedTimerEditorScreen> {
    late int _h, _m, _s;
    late String _label;
    late String _sound;

    @override
    void initState() {
      super.initState();
      final e = widget.existing;
      final d = e?.duration ?? const Duration(minutes: 5);
      _h = d.inHours.clamp(0, 23);
      _m = d.inMinutes % 60;
      _s = d.inSeconds % 60;
      _label = e?.label ?? '';
      _sound = e?.soundId ?? kDefaultTimerSoundId;
    }

    Duration get _duration =>
        Duration(hours: _h, minutes: _m, seconds: _s);

    void _save() {
      if (_duration <= Duration.zero) return;
      final id =
          widget.existing?.id ?? 't${DateTime.now().millisecondsSinceEpoch}';
      ref.read(savedTimersControllerProvider.notifier).upsert(
            SavedTimer(
              id: id,
              label: _label.trim(),
              duration: _duration,
              soundId: _sound,
            ),
          );
      if (context.canPop()) context.pop();
    }

    String _soundLabel(AppLocalizations l, String id) =>
        switch (timerSoundL10nKey(id)) {
          'soundBell' => l.soundBell,
          'soundChime' => l.soundChime,
          'soundCalm' => l.soundCalm,
          _ => l.soundDefault,
        };

    Future<void> _editLabel() async {
      final l10n = AppLocalizations.of(context);
      final controller = TextEditingController(text: _label);
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.timerLabelHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
            ),
          ],
        ),
      );
      if (result != null) setState(() => _label = result);
    }

    Future<void> _editSound() async {
      final l10n = AppLocalizations.of(context);
      await showModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          final scheme = Theme.of(ctx).colorScheme;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final id in timerSoundIds)
                  ListTile(
                    title: Text(_soundLabel(l10n, id)),
                    trailing: id == _sound
                        ? Icon(Icons.check, color: scheme.primary)
                        : null,
                    onTap: () {
                      setState(() => _sound = id);
                      Navigator.of(ctx).pop();
                    },
                  ),
              ],
            ),
          );
        },
      );
    }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context);
      final scheme = Theme.of(context).colorScheme;
      final n = ref.watch(
        settingsControllerProvider.select((s) => s.effectiveNumerals),
      );
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          title: Text(widget.existing == null
              ? l10n.timerAddSaved
              : l10n.timerEditSaved),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: l10n.actionDone,
              onPressed: _save,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(TarfTokens.space3),
          children: [
            const SizedBox(height: TarfTokens.space2),
            TarfWheelPicker(columns: [
              TarfWheelColumn(
                values: [for (var x = 0; x < 24; x++) Numerals.padded(x, n)],
                selected: _h,
                onSelected: (i) => setState(() => _h = i),
                separator: ':',
              ),
              TarfWheelColumn(
                values: [for (var x = 0; x < 60; x++) Numerals.padded(x, n)],
                selected: _m,
                onSelected: (i) => setState(() => _m = i),
                separator: ':',
              ),
              TarfWheelColumn(
                values: [for (var x = 0; x < 60; x++) Numerals.padded(x, n)],
                selected: _s,
                onSelected: (i) => setState(() => _s = i),
              ),
            ]),
            const SizedBox(height: TarfTokens.space4),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: TarfTokens.space3,
              crossAxisSpacing: TarfTokens.space3,
              children: [
                for (final x in _presetMinutes)
                  TarfPresetChip(
                    label: Numerals.timer(Duration(minutes: x), n),
                    selected: _duration == Duration(minutes: x),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _h = 0;
                        _m = x;
                        _s = 0;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: TarfTokens.space4),
            TarfGroup(children: [
              TarfListRow(
                icon: Icons.label_outline,
                title: l10n.timerLabel,
                trailing: _trailing(_label.isEmpty ? '—' : _label, scheme),
                onTap: _editLabel,
              ),
              TarfListRow(
                icon: Icons.music_note_outlined,
                title: l10n.soundLabel,
                trailing: _trailing(_soundLabel(l10n, _sound), scheme),
                onTap: _editSound,
              ),
            ]),
            if (widget.existing != null) ...[
              const SizedBox(height: TarfTokens.space4),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.errorContainer,
                  foregroundColor: scheme.onErrorContainer,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () {
                  ref
                      .read(savedTimersControllerProvider.notifier)
                      .remove(widget.existing!.id);
                  if (context.canPop()) context.pop();
                },
                child: Text(l10n.actionDelete),
              ),
            ],
          ],
        ),
      );
    }

    Widget _trailing(String s, ColorScheme scheme) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: Text(s,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ),
        const SizedBox(width: 4),
        Icon(rtl ? Icons.chevron_left : Icons.chevron_right,
            size: 20, color: scheme.onSurfaceVariant),
      ]);
    }
  }
  ```
- [ ] Run (expect PASS): `flutter test test/features/timer/saved_timer_editor_test.dart`
- [ ] Commit:
  `git add app/lib/features/timer/presentation/saved_timer_editor_screen.dart app/test/features/timer/saved_timer_editor_test.dart`
  ```
  git commit -m "feat(timer): saved-timer editor (wheel + presets + label + sound)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 2.6 — Wire saved-timer list into `TimerScreen` (run / "+") (P1 SEAM)

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\timer\presentation\timer_screen.dart`
- Route: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\routing\app_router.dart`
- Test: extend `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\timer\saved_timer_editor_test.dart` OR new `timer_screen_saved_test.dart`

> **PHASE-1 CONTENTION:** P1 edits `timer_screen.dart` for the chime UX. This task adds a saved-timer list section to the **idle** view and an AppBar "+". Keep changes localized to the idle view's `Column` and the AppBar `actions`. During integration, reconcile with P1's edits (they likely touch `_ActiveView`/the finish state, not the idle list — low overlap, but verify).

- [ ] Write the failing widget test (new file `timer_screen_saved_test.dart`):
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/settings/settings_controller.dart';
  import 'package:tarf/features/timer/application/saved_timers_controller.dart';
  import 'package:tarf/features/timer/application/timer_controller.dart';
  import 'package:tarf/features/timer/domain/saved_timer.dart';
  import 'package:tarf/features/timer/presentation/timer_screen.dart';
  import 'package:tarf/l10n/app_localizations.dart';
  import 'package:tarf/theme/app_theme.dart';

  void main() {
    testWidgets('tapping a saved timer loads it into the runner',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      await container
          .read(savedTimersControllerProvider.notifier)
          .upsert(const SavedTimer(
              id: 't1', label: 'Tea', duration: Duration(minutes: 3)));

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TimerScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tea'), findsOneWidget);
      await tester.tap(find.text('Tea'));
      await tester.pumpAndSettle();

      expect(container.read(timerControllerProvider).activeTimerId, 't1');
      expect(container.read(timerControllerProvider).total,
          const Duration(minutes: 3));
    });
  }
  ```
  > NOTE: wrap with `theme: TarfTheme.dark()` if a token lookup throws; add it to the `MaterialApp`.
- [ ] Run (expect FAIL — no saved list / `Tea` not found): `flutter test test/features/timer/timer_screen_saved_test.dart`
- [ ] Minimal impl — edits to `timer_screen.dart` (idle view only):
  - Add imports: `import 'package:go_router/go_router.dart';`, `import '../../../core/routing/app_router.dart';`, `import '../application/saved_timers_controller.dart';`, `import '../domain/saved_timer.dart';`.
  - Add an AppBar action on `TimerScreen` to open the editor:
    ```dart
    appBar: AppBar(
      title: Text(l10n.tabTimer),
      actions: [
        if (isIdle)
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.timerAddSaved,
            onPressed: () => context.push(Routes.savedTimerEditor),
          ),
      ],
    ),
    ```
    (Compute `isIdle` in `build` as it already does; pass `isIdle` into the AppBar by reading it before returning the `Scaffold`.)
  - Inside `_IdleView`'s `Column`, BELOW the Start button, add a saved-timer section:
    ```dart
    Consumer(builder: (context, ref, _) {
      final saved = ref.watch(savedTimersControllerProvider);
      if (saved.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: TarfTokens.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TarfSectionHeader(l10n.timerSavedTitle),
            TarfGroup(children: [
              for (final t in saved)
                _SavedTimerRow(timer: t, n: n),
            ]),
          ],
        ),
      );
    }),
    ```
  - Add the row widget (run on tap → `runSaved` then `start`; edit affordance via long-press → editor; delete via the editor):
    ```dart
    class _SavedTimerRow extends ConsumerWidget {
      const _SavedTimerRow({required this.timer, required this.n});
      final SavedTimer timer;
      final NumeralSystem n;
      @override
      Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context);
        final label = timer.label.isEmpty ? l10n.timerUnnamed : timer.label;
        return TarfListRow(
          icon: Icons.timer_outlined,
          title: label,
          subtitle: Numerals.timer(timer.duration, n),
          trailing: const Icon(Icons.play_arrow),
          onTap: () {
            ref.read(timerControllerProvider.notifier).runSaved(timer);
            ref.read(timerControllerProvider.notifier).start();
          },
        );
      }
    }
    ```
    > For the test (which asserts only that tapping loads the runner), `onTap` calling `runSaved` is sufficient; `start()` then flips to `_ActiveView`. If the test asserts `activeTimerId` after `pumpAndSettle`, the running ticker is fine (no real time advances in the test). To edit a saved timer, the design adds a long-press → `context.push(Routes.savedTimerEditor, extra: timer)` (optional; include if straightforward).
- [ ] Add the editor route. In `app_router.dart`:
  - `Routes`: `static const savedTimerEditor = '/timer/saved-edit';`
  - import: `import '../../features/timer/presentation/saved_timer_editor_screen.dart';` and `import '../../features/timer/domain/saved_timer.dart';`
  - top-level `GoRoute`:
    ```dart
    GoRoute(
      path: Routes.savedTimerEditor,
      builder: (context, state) =>
          SavedTimerEditorScreen(existing: state.extra as SavedTimer?),
    ),
    ```
- [ ] Run (expect PASS): `flutter test test/features/timer/timer_screen_saved_test.dart`
- [ ] Run the full timer suite + navigation smoke:
  `flutter test test/features/timer/ test/features/app_navigation_test.dart`
- [ ] Commit:
  `git add app/lib/features/timer/presentation/timer_screen.dart app/lib/core/routing/app_router.dart app/test/features/timer/timer_screen_saved_test.dart`
  ```
  git commit -m "feat(timer): saved-timer list on Timer screen (run + add/edit route)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

# FEATURE 3 — Degraded-Permission Banner

**Why:** When background delivery / notifications are degraded (e.g. notifications denied, exact alarms unavailable on Android, or web/desktop limits), Tarf must say so **honestly and calmly** (`tarf.warning`, never alarmist), with an equal non-color cue (icon + text), where it is relevant (Prayer/Alarm + Home eye-care).

**Design:** Reusable widget `DegradedPermissionBanner` that reads a `notificationStatusProvider` seam (Phase-2 contract) and renders nothing when delivery is fine, or a warning-tinted `TarfGroup`-styled card with an icon + the localized per-platform message + an optional "Open settings" affordance otherwise.

### Task 3.1 — `NotificationStatus` model + `notificationStatusProvider` seam (Phase-2 contract)

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\permissions\application\notification_status.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\permissions\notification_status_test.dart`

> **PHASE-2 CONTENTION:** The Phase-2 background plan is absent at authoring time. This seam matches the assumed contract: `granted | denied | limited` + a `limitMessageKey` (l10n key) for the per-platform note. When Phase 2 lands its real provider: either (a) make `notificationStatusProvider` here a thin `ref.watch(p2Provider)` adapter, or (b) delete this provider and re-point the banner's watch at P2's provider. Keep the `NotificationStatus` shape identical so the banner needs no change. Default value is `granted` so the banner is invisible until P2 reports otherwise.

- [ ] Write the failing test:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/features/permissions/application/notification_status.dart';

  void main() {
    group('NotificationStatus', () {
      test('granted is not degraded; denied and limited are', () {
        expect(const NotificationStatus(NotificationDelivery.granted).isDegraded,
            isFalse);
        expect(const NotificationStatus(NotificationDelivery.denied).isDegraded,
            isTrue);
        expect(const NotificationStatus(NotificationDelivery.limited).isDegraded,
            isTrue);
      });

      test('default provider reports granted (banner hidden until P2 reports)',
          () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        expect(c.read(notificationStatusProvider).delivery,
            NotificationDelivery.granted);
      });
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/features/permissions/notification_status_test.dart`
- [ ] Minimal impl:
  ```dart
  import 'package:flutter/foundation.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  /// How reliably the platform can deliver background reminders/alarms.
  /// Mirrors the Phase-2 background-delivery contract.
  enum NotificationDelivery { granted, denied, limited }

  /// Permission/limit snapshot the UI consumes to show an honest banner.
  @immutable
  class NotificationStatus {
    const NotificationStatus(this.delivery, {this.limitMessageKey});

    final NotificationDelivery delivery;

    /// Optional l10n key for a per-platform limit explanation (resolved in the
    /// widget layer). Null = use the generic message for [delivery].
    final String? limitMessageKey;

    bool get isDegraded => delivery != NotificationDelivery.granted;
  }

  /// Phase-2 seam. Defaults to granted so the banner is invisible until Phase 2's
  /// background work reports a real status. Phase 2 overrides this (or the banner
  /// is re-pointed at Phase 2's provider — see plan's cross-phase notes).
  final notificationStatusProvider = Provider<NotificationStatus>(
    (ref) => const NotificationStatus(NotificationDelivery.granted),
  );
  ```
- [ ] Run (expect PASS): `flutter test test/features/permissions/notification_status_test.dart`
- [ ] Commit:
  `git add app/lib/features/permissions/application/notification_status.dart app/test/features/permissions/notification_status_test.dart`
  ```
  git commit -m "feat(permissions): notification-status seam (Phase-2 contract)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 3.2 — l10n keys for the banner

**Files:** `app/lib/l10n/app_en.arb`, `app/lib/l10n/app_ar.arb`

- [ ] Add to `app_en.arb` (calm, never alarmist; honest about the limitation):
  ```json
  "permBannerDeniedTitle": "Reminders may not reach you",
  "permBannerDeniedBody": "Notifications are turned off, so Tarf can't alert you in the background. The break still works while the app is open.",
  "permBannerLimitedTitle": "Background reminders are limited",
  "permBannerLimitedBody": "This device may delay or skip background reminders. Keeping Tarf open ensures your breaks on time.",
  "permBannerAction": "Open settings"
  ```
- [ ] Add the SAME keys to `app_ar.arb`:
  ```json
  "permBannerDeniedTitle": "قد لا تصلك التذكيرات",
  "permBannerDeniedBody": "الإشعارات مُعطّلة، لذا لا يستطيع طَرْف تنبيهك في الخلفية. تعمل الاستراحة ما دام التطبيق مفتوحًا.",
  "permBannerLimitedTitle": "تذكيرات الخلفية محدودة",
  "permBannerLimitedBody": "قد يؤخّر هذا الجهاز تذكيرات الخلفية أو يتخطّاها. إبقاء طَرْف مفتوحًا يضمن وصول استراحاتك في وقتها.",
  "permBannerAction": "فتح الإعدادات"
  ```
- [ ] Regenerate + compile: `flutter gen-l10n` then `flutter analyze lib/l10n`
- [ ] Commit:
  `git add app/lib/l10n/app_en.arb app/lib/l10n/app_ar.arb app/lib/l10n/app_localizations.dart app/lib/l10n/app_localizations_en.dart app/lib/l10n/app_localizations_ar.dart`
  ```
  git commit -m "i18n(permissions): add degraded-permission banner strings (en+ar)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 3.3 — `DegradedPermissionBanner` widget

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\permissions\presentation\degraded_permission_banner.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\permissions\degraded_permission_banner_test.dart`

- [ ] Write the failing widget test (hidden when granted; shown + warning-tinted + icon when degraded; never color-alone):
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/features/permissions/application/notification_status.dart';
  import 'package:tarf/features/permissions/presentation/degraded_permission_banner.dart';
  import 'package:tarf/l10n/app_localizations.dart';
  import 'package:tarf/theme/app_theme.dart';

  Widget _host(NotificationStatus status) => ProviderScope(
        overrides: [
          notificationStatusProvider.overrideWithValue(status),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: DegradedPermissionBanner()),
        ),
      );

  void main() {
    testWidgets('hidden when delivery is granted', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: TarfTheme.dark(),
        home: _host(const NotificationStatus(NotificationDelivery.granted)),
      ));
      await tester.pump();
      expect(find.byType(SizedBox), findsWidgets); // collapses to shrink
      expect(find.textContaining('Reminders'), findsNothing);
    });

    testWidgets('shows an honest title + icon when denied', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: TarfTheme.dark(),
        home: _host(const NotificationStatus(NotificationDelivery.denied)),
      ));
      await tester.pump();
      expect(find.text('Reminders may not reach you'), findsOneWidget);
      // Equal non-color cue: a warning icon accompanies the color.
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/features/permissions/degraded_permission_banner_test.dart`
- [ ] Minimal impl:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../l10n/app_localizations.dart';
  import '../../../theme/tokens.dart';
  import '../application/notification_status.dart';

  /// A calm, honest banner that appears only when background delivery is degraded
  /// (notifications denied or limited). Uses [TarfColors.warning] (never error
  /// red, never alarmist) and always pairs color with an icon + text (never
  /// color-alone). Renders nothing when delivery is granted.
  class DegradedPermissionBanner extends ConsumerWidget {
    const DegradedPermissionBanner({super.key, this.onOpenSettings});

    /// Optional affordance (e.g. open OS settings). Hidden when null.
    final VoidCallback? onOpenSettings;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final status = ref.watch(notificationStatusProvider);
      if (!status.isDegraded) return const SizedBox.shrink();

      final l10n = AppLocalizations.of(context);
      final t = context.tarf;
      final limited = status.delivery == NotificationDelivery.limited;
      final title =
          limited ? l10n.permBannerLimitedTitle : l10n.permBannerDeniedTitle;
      final body =
          limited ? l10n.permBannerLimitedBody : l10n.permBannerDeniedBody;

      return Container(
        margin: const EdgeInsets.only(bottom: TarfTokens.space3),
        padding: const EdgeInsets.all(TarfTokens.space3),
        decoration: BoxDecoration(
          color: t.warning.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(TarfTokens.radiusM),
          border: Border.all(color: t.warning.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equal non-color cue.
            Icon(Icons.warning_amber_rounded, color: t.warning, size: 24),
            const SizedBox(width: TarfTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: t.warningText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: t.warningText,
                        ),
                  ),
                  if (onOpenSettings != null) ...[
                    const SizedBox(height: TarfTokens.space2),
                    TextButton(
                      onPressed: onOpenSettings,
                      child: Text(l10n.permBannerAction),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
  ```
- [ ] Run (expect PASS): `flutter test test/features/permissions/degraded_permission_banner_test.dart`
- [ ] Commit:
  `git add app/lib/features/permissions/presentation/degraded_permission_banner.dart app/test/features/permissions/degraded_permission_banner_test.dart`
  ```
  git commit -m "feat(permissions): reusable honest degraded-permission banner

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 3.4 — Mount the banner where relevant (Prayer view + Home eye-care)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\alarm\presentation\alarm_screen.dart`
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\home\presentation\home_screen.dart` (READ first to find the eye-care card insertion point)
- Test: extend `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\permissions\degraded_permission_banner_test.dart` with a placement smoke (optional) OR rely on `app_navigation_test.dart` staying green.

- [ ] READ `home_screen.dart` to locate the top of its main `ListView`/`Column` (the eye-care "next break" card). The banner mounts as the FIRST child so a degraded status is visible before the eye-care card.
- [ ] Edit `alarm_screen.dart`: in `build`'s `ListView` children, add the banner at the very top (above the `_PrayerBanner`/segmented control) so it shows in both Standard and Prayer modes:
  ```dart
  children: [
    const DegradedPermissionBanner(),
    if (_mode == AlarmMode.prayer) ...[
      const _PrayerBanner(),
      ...
  ```
  Add import: `import '../../permissions/presentation/degraded_permission_banner.dart';`
  (When granted, the banner is a zero-size `SizedBox.shrink()`, so no layout shift.)
- [ ] Edit `home_screen.dart`: add the same `const DegradedPermissionBanner()` as the first child of the main scroll body, with the import. (Exact insertion line determined by the READ; keep it above the eye-care card.)
- [ ] Run navigation smoke (must stay green; banner is invisible by default so no assertion changes):
  `flutter test test/features/app_navigation_test.dart`
- [ ] Commit:
  `git add app/lib/features/alarm/presentation/alarm_screen.dart app/lib/features/home/presentation/home_screen.dart`
  ```
  git commit -m "feat(permissions): surface degraded banner on Alarm + Home

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

# FEATURE 4 — Tasbih Counter on the Break Screen

**Why:** An opt-in, reverent dhikr tally on the break screen: a large tap target (≥44px, gentle haptic) that increments a count, cycles at 33/99 with a calm completion cue, persists per day/session, and **NEVER overlaps or decorates the sacred Amiri line**.

**Reverence rules (non-negotiable):**
- The tasbih lives **below** the existing `_DhikrView` block (the sacred Arabic line stays the sole hero, undecorated, auto-fit). The counter is visually quiet and separate.
- **Opt-in**: a small toggle reveals the counter; default off so the break stays minimal for users who only recite.
- No commercial framing, no streak gamification, no badges. Just a count, a target (33/99), and a calm "completed" cue (a gentle bloom + optional `tarf.success` tick + the existing haptic) — and the completion cue must have an equal non-audio visual (we are not adding sound; a gentle scale/opacity bloom suffices, honoring reduce-motion).
- Persist per day so reopening the break the same day resumes the tally; a new day resets to 0.

### Task 4.1 — `TasbihState` model (per-day, cycle math)

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\domain\tasbih_state.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\eyecare\tasbih_state_test.dart` (NEW)

- [ ] Write the failing test:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/features/eyecare/domain/tasbih_state.dart';

  void main() {
    group('TasbihState', () {
      test('increments and reports cycle position for target 33', () {
        var s = const TasbihState(dayKey: '2026-06-01', count: 0);
        for (var i = 0; i < 33; i++) {
          s = s.increment(target: 33);
        }
        expect(s.count, 33);
        expect(s.justCompletedCycle, isTrue); // landed exactly on a multiple
        expect(s.inCycle, 0); // 33 % 33
      });

      test('inCycle wraps after the target', () {
        const s = TasbihState(dayKey: 'd', count: 34);
        expect(s.cyclePositionFor(33), 1); // 34 % 33
      });

      test('reset zeroes the count', () {
        const s = TasbihState(dayKey: 'd', count: 50);
        expect(s.reset().count, 0);
      });

      test('round-trips through json', () {
        const s = TasbihState(dayKey: '2026-06-01', count: 7);
        final r = TasbihState.fromJson(s.toJson());
        expect(r.dayKey, '2026-06-01');
        expect(r.count, 7);
      });
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/features/eyecare/tasbih_state_test.dart`
- [ ] Minimal impl:
  ```dart
  import 'package:flutter/foundation.dart';

  /// Per-day tasbih tally. [dayKey] is a local 'YYYY-MM-DD' so a new day resets.
  /// Pure value type; the cycle target (33/99) is passed in, not stored, so the
  /// model stays agnostic and testable.
  @immutable
  class TasbihState {
    const TasbihState({required this.dayKey, this.count = 0});

    final String dayKey;
    final int count;

    /// Count within the current cycle for [target] (0 when exactly on a multiple).
    int cyclePositionFor(int target) => target <= 0 ? count : count % target;

    /// Convenience for the default 33 cycle.
    int get inCycle => cyclePositionFor(33);

    /// True when [count] just landed on a non-zero multiple of the last target
    /// used in [increment]. Recomputed there; defaults false on plain construct.
    bool get justCompletedCycle => _justCompleted;
    final bool _justCompleted = false;

    TasbihState increment({required int target}) {
      final next = count + 1;
      final completed = target > 0 && next % target == 0;
      return TasbihState._(dayKey: dayKey, count: next, justCompleted: completed);
    }

    TasbihState reset() => TasbihState(dayKey: dayKey);

    const TasbihState._(
        {required this.dayKey, required this.count, required bool justCompleted})
        : _justCompleted = justCompleted;

    Map<String, Object?> toJson() => {'day': dayKey, 'count': count};

    factory TasbihState.fromJson(Map<String, Object?> j) => TasbihState(
          dayKey: (j['day'] as String?) ?? '',
          count: (j['count'] as int?) ?? 0,
        );
  }
  ```
  > NOTE: `justCompletedCycle` is a transient UI flag (drives the completion bloom); it is intentionally NOT persisted (`toJson` omits it). The public unnamed constructor yields `_justCompleted=false`; only `increment` can set it true.
- [ ] Run (expect PASS): `flutter test test/features/eyecare/tasbih_state_test.dart`
- [ ] Commit:
  `git add app/lib/features/eyecare/domain/tasbih_state.dart app/test/features/eyecare/tasbih_state_test.dart`
  ```
  git commit -m "feat(eyecare): pure per-day TasbihState with 33/99 cycle math

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 4.2 — `TasbihController` (persisted, day-aware, target toggle)

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\application\tasbih_controller.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\eyecare\tasbih_controller_test.dart`

- [ ] Write the failing test:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/settings/settings_controller.dart';
  import 'package:tarf/features/eyecare/application/tasbih_controller.dart';

  Future<ProviderContainer> _c({Map<String, Object> seed = const {}}) async {
    SharedPreferences.setMockInitialValues(seed);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  void main() {
    group('TasbihController', () {
      test('starts at zero for today and increments + persists', () async {
        final c = await _c();
        expect(c.read(tasbihControllerProvider).count, 0);
        await c.read(tasbihControllerProvider.notifier).increment();
        await c.read(tasbihControllerProvider.notifier).increment();
        expect(c.read(tasbihControllerProvider).count, 2);

        final prefs = await SharedPreferences.getInstance();
        final c2 = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(c2.dispose);
        expect(c2.read(tasbihControllerProvider).count, 2); // same day persists
      });

      test('reset zeroes the count', () async {
        final c = await _c();
        final n = c.read(tasbihControllerProvider.notifier);
        await n.increment();
        await n.reset();
        expect(c.read(tasbihControllerProvider).count, 0);
      });

      test('target toggles between 33 and 99 and persists', () async {
        final c = await _c();
        expect(c.read(tasbihTargetProvider), 33);
        await c.read(tasbihTargetProvider.notifier).toggle();
        expect(c.read(tasbihTargetProvider), 99);
      });
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/features/eyecare/tasbih_controller_test.dart`
- [ ] Minimal impl (`tasbih_controller.dart`) — two small notifiers; the count is day-aware (resets when the stored dayKey differs from today):
  ```dart
  import 'dart:convert';

  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../core/settings/settings_controller.dart';
  import '../domain/tasbih_state.dart';

  const _key = 'tarf.tasbih.v1';
  const _targetKey = 'tarf.tasbih_target.v1';

  String _todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  /// Persisted, day-aware tasbih tally. A new day starts fresh.
  class TasbihController extends Notifier<TasbihState> {
    @override
    TasbihState build() {
      final raw = ref.watch(sharedPreferencesProvider).getString(_key);
      final today = _todayKey();
      if (raw == null) return TasbihState(dayKey: today);
      try {
        final stored =
            TasbihState.fromJson(jsonDecode(raw) as Map<String, Object?>);
        return stored.dayKey == today ? stored : TasbihState(dayKey: today);
      } catch (_) {
        return TasbihState(dayKey: today);
      }
    }

    Future<void> _persist(TasbihState next) async {
      state = next;
      await ref
          .read(sharedPreferencesProvider)
          .setString(_key, jsonEncode(next.toJson()));
    }

    Future<void> increment() {
      final target = ref.read(tasbihTargetProvider);
      return _persist(state.increment(target: target));
    }

    Future<void> reset() => _persist(state.reset());
  }

  final tasbihControllerProvider =
      NotifierProvider<TasbihController, TasbihState>(TasbihController.new);

  /// Persisted cycle target: 33 (default) or 99.
  class TasbihTarget extends Notifier<int> {
    @override
    int build() {
      final v = ref.watch(sharedPreferencesProvider).getInt(_targetKey);
      return v == 99 ? 99 : 33;
    }

    Future<void> toggle() async {
      final next = state == 33 ? 99 : 33;
      state = next;
      await ref.read(sharedPreferencesProvider).setInt(_targetKey, next);
    }
  }

  final tasbihTargetProvider =
      NotifierProvider<TasbihTarget, int>(TasbihTarget.new);
  ```
- [ ] Run (expect PASS): `flutter test test/features/eyecare/tasbih_controller_test.dart`
- [ ] Commit:
  `git add app/lib/features/eyecare/application/tasbih_controller.dart app/test/features/eyecare/tasbih_controller_test.dart`
  ```
  git commit -m "feat(eyecare): persisted day-aware TasbihController + 33/99 target

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 4.3 — l10n keys for the tasbih

**Files:** `app/lib/l10n/app_en.arb`, `app/lib/l10n/app_ar.arb`

- [ ] Add to `app_en.arb`:
  ```json
  "tasbihShow": "Count dhikr",
  "tasbihHide": "Hide counter",
  "tasbihTapHint": "Tap to count",
  "tasbihReset": "Reset count",
  "tasbihCompleted": "Completed {n}",
  "@tasbihCompleted": { "placeholders": { "n": { "type": "int" } } },
  "tasbihProgress": "{count} / {target}",
  "@tasbihProgress": { "placeholders": { "count": { "type": "int" }, "target": { "type": "int" } } }
  ```
- [ ] Add the SAME keys to `app_ar.arb`:
  ```json
  "tasbihShow": "عدّ الذكر",
  "tasbihHide": "إخفاء العدّاد",
  "tasbihTapHint": "انقر للعدّ",
  "tasbihReset": "تصفير العدّ",
  "tasbihCompleted": "أتممت {n}",
  "@tasbihCompleted": { "placeholders": { "n": { "type": "int" } } },
  "tasbihProgress": "{count} / {target}",
  "@tasbihProgress": { "placeholders": { "count": { "type": "int" }, "target": { "type": "int" } } }
  ```
  > These number placeholders are plain `{n}`/`{count}`/`{target}` → gen-l10n emits Western digits, satisfying the Western-digits default. The break overlay itself uses `Numerals.formatInt` for the big tally so it honors the user's numeral setting.
- [ ] Regenerate + compile: `flutter gen-l10n` then `flutter analyze lib/l10n`
- [ ] Commit:
  `git add app/lib/l10n/app_en.arb app/lib/l10n/app_ar.arb app/lib/l10n/app_localizations.dart app/lib/l10n/app_localizations_en.dart app/lib/l10n/app_localizations_ar.dart`
  ```
  git commit -m "i18n(eyecare): add reverent tasbih strings (en+ar)

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

### Task 4.4 — Opt-in tasbih widget in `BreakOverlay` (below the sacred line)

**Files:**
- Impl: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\presentation\break_overlay.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\eyecare\break_overlay_tasbih_test.dart`

> **Reverence guard (test-enforced):** the sacred Arabic still renders exactly once and is never wrapped by the tasbih. The tasbih is opt-in (hidden until toggled) and sits in its own section below `_DhikrView`.

- [ ] Write the failing widget test:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/format/numerals.dart';
  import 'package:tarf/core/settings/settings_controller.dart';
  import 'package:tarf/features/eyecare/audio/break_audio.dart';
  import 'package:tarf/features/eyecare/domain/dhikr.dart';
  import 'package:tarf/features/eyecare/presentation/break_overlay.dart';
  import 'package:tarf/l10n/app_localizations.dart';
  import 'package:tarf/theme/app_theme.dart';

  const _dhikr = Dhikr(
    id: 'subhanallah',
    arabic: 'سُبْحَانَ اللّٰهِ',
    transliteration: 'Subhan-Allah',
    english: 'Glory be to Allah.',
    reference: 'Sahih al-Bukhari 6406',
  );

  Widget _host(SharedPreferences prefs, Widget child) => ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: TarfTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );

  void main() {
    testWidgets('tasbih is opt-in and never wraps the sacred line',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(_host(
        prefs,
        BreakOverlay(
          dhikr: _dhikr,
          duration: const Duration(seconds: 20),
          audio: FakeBreakAudio(),
          numerals: NumeralSystem.western,
          showTasbih: true, // opt-in flag exposed for tests/integration
          onFinished: () {},
        ),
      ));
      await tester.pump();

      // Sacred line still present exactly once.
      expect(find.text('سُبْحَانَ اللّٰهِ'), findsOneWidget);

      // The tap target exists and increments the visible count.
      expect(find.text(Numerals.formatInt(0, NumeralSystem.western)),
          findsWidgets);
      await tester.tap(find.byKey(const ValueKey('tasbihTapTarget')));
      await tester.pump();
      expect(find.text('1'), findsOneWidget); // count incremented

      // The tap target is at least 44px (a11y).
      final size = tester.getSize(find.byKey(const ValueKey('tasbihTapTarget')));
      expect(size.width >= 44 && size.height >= 44, isTrue);
    });

    testWidgets('tasbih hidden by default (showTasbih false)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(_host(
        prefs,
        BreakOverlay(
          dhikr: _dhikr,
          duration: const Duration(seconds: 20),
          audio: FakeBreakAudio(),
          numerals: NumeralSystem.western,
          onFinished: () {},
        ),
      ));
      await tester.pump();
      expect(find.byKey(const ValueKey('tasbihTapTarget')), findsNothing);
    });
  }
  ```
- [ ] Run (expect FAIL — `showTasbih` param + tap target absent):
  `flutter test test/features/eyecare/break_overlay_tasbih_test.dart`
- [ ] Minimal impl — edits to `break_overlay.dart`:
  - Convert the file to read Riverpod (it is currently a plain `StatefulWidget`). Simplest non-invasive approach: keep `BreakOverlay` as-is but add an **opt-in** `showTasbih` flag and render a `Consumer`-based `_TasbihPanel` (a `ConsumerWidget`) below `_DhikrView`. This avoids converting the whole widget to `ConsumerStatefulWidget`.
  - Add to the constructor + fields:
    ```dart
    this.showTasbih = false,
    ...
    final bool showTasbih;
    ```
  - In `build`, AFTER the `_DhikrView(...)` widget and its following `Spacer`, insert (guarded by the flag), keeping the sacred line untouched above:
    ```dart
    if (widget.showTasbih) ...[
      _TasbihPanel(
        numerals: widget.numerals,
        hapticEnabled: !widget.reduceMotion, // gentle; gated like other motion
        reduceMotion: widget.reduceMotion,
      ),
      const Spacer(),
    ],
    ```
    > Place it so the `_Controls` row remains last; adjust `Spacer` flexes so the layout stays calm (the sacred block keeps its prominent position; the tasbih is quiet below it).
  - Add the `_TasbihPanel` (new `ConsumerWidget` in the same file). It reads `tasbihControllerProvider`/`tasbihTargetProvider`, shows the big tally via `Numerals.formatInt`, a ≥44px circular tap target with `HapticFeedback.selectionClick()`, a small `count / target` line, a quiet reset, and a gentle completion bloom (scale/opacity) that honors reduce-motion:
    ```dart
    class _TasbihPanel extends ConsumerStatefulWidget {
      const _TasbihPanel({
        required this.numerals,
        required this.hapticEnabled,
        required this.reduceMotion,
      });
      final NumeralSystem numerals;
      final bool hapticEnabled;
      final bool reduceMotion;
      @override
      ConsumerState<_TasbihPanel> createState() => _TasbihPanelState();
    }

    class _TasbihPanelState extends ConsumerState<_TasbihPanel>
        with SingleTickerProviderStateMixin {
      late final AnimationController _bloom = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );

      @override
      void dispose() {
        _bloom.dispose();
        super.dispose();
      }

      Future<void> _tap() async {
        if (widget.hapticEnabled) HapticFeedback.selectionClick();
        await ref.read(tasbihControllerProvider.notifier).increment();
        if (ref.read(tasbihControllerProvider).justCompletedCycle &&
            !widget.reduceMotion) {
          _bloom.forward(from: 0);
        }
      }

      @override
      Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context);
        final t = context.tarf;
        final scheme = Theme.of(context).colorScheme;
        final state = ref.watch(tasbihControllerProvider);
        final target = ref.watch(tasbihTargetProvider);
        final inCycle = state.cyclePositionFor(target);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large, quiet tap target (>=44px) — never over the sacred line.
            Semantics(
              button: true,
              label: l10n.tasbihTapHint,
              child: GestureDetector(
                key: const ValueKey('tasbihTapTarget'),
                onTap: _tap,
                child: AnimatedBuilder(
                  animation: _bloom,
                  builder: (context, _) {
                    final glow = widget.reduceMotion ? 0.0 : _bloom.value;
                    return Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        border: Border.all(
                          color: Color.lerp(
                              t.ringTrack, t.success, glow)!,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: TarfTimeText(
                        Numerals.formatInt(state.count, widget.numerals),
                        style: Theme.of(context).textTheme.headlineMedium,
                        color: scheme.onSurface,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: TarfTokens.space2),
            Text(
              l10n.tasbihProgress(inCycle, target),
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(tasbihControllerProvider.notifier).reset(),
              child: Text(l10n.tasbihReset),
            ),
          ],
        );
      }
    }
    ```
  - Add imports to `break_overlay.dart`: `import 'package:flutter/services.dart';`, `import 'package:flutter_riverpod/flutter_riverpod.dart';`, `import '../application/tasbih_controller.dart';`, and `import '../../../core/widgets/tarf_widgets.dart';` (for `TarfTimeText`).
- [ ] Wire the opt-in toggle through the routed break (`break_screen.dart`) and the engine push (`show_break.dart`). MINIMAL: add a persisted boolean is out of scope for the overlay test; expose `showTasbih` and a small in-overlay toggle button (icon) that flips local state, OR pass `showTasbih: true` from a settings flag. For this task, the overlay's `showTasbih` param + the opt-in toggle button in `_Controls`/header satisfy "opt-in"; the simplest is a header `IconButton` (e.g. `Icons.touch_app`) that toggles a local `_showTasbih` bool initialized from `widget.showTasbih`. Add that toggle so the user opts in within the break without cluttering the sacred line. (Persisting the preference can ride on `EyeCareConfig` in a follow-up; not required for green tests.)
- [ ] Run (expect PASS): `flutter test test/features/eyecare/break_overlay_tasbih_test.dart`
- [ ] Run the EXISTING break overlay test (must stay green — reverence intact):
  `flutter test test/features/eyecare/break_overlay_test.dart`
- [ ] Commit:
  `git add app/lib/features/eyecare/presentation/break_overlay.dart app/test/features/eyecare/break_overlay_tasbih_test.dart`
  ```
  git commit -m "feat(eyecare): opt-in reverent tasbih below the sacred line

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

## Verification

Run from `C:\Users\sulta\Claude_Code\EyeCure_20\app` with `$env:Path = "C:\dev\flutter\bin;$env:Path"` set once.

- [ ] **All new feature tests pass:**
  `flutter test test/features/prayer/ test/features/timer/ test/features/permissions/ test/features/eyecare/`
- [ ] **Full suite green (the original 58 + the new tests):**
  `flutter test`
  Expected: 0 failures. (Count rises from 58 by the number of new tests added across F1–F4.)
- [ ] **Analyzer clean:**
  `flutter analyze`
  Expected: "No issues found!"
- [ ] **l10n regenerated and committed:** confirm `app/lib/l10n/app_localizations*.dart` reflect every new key (`flutter gen-l10n` produces no diff if already current).
- [ ] **Web build still compiles (smoke):**
  `flutter build web --no-web-resources-cdn`
  Expected: build succeeds (geolocator's web support is a no-op behind the Unavailable default, so no platform breakage).
- [ ] **Manual reverence check (F4):** open the break (e.g. `--dart-define` preview), confirm the Amiri line is unchanged, the tasbih is hidden until opted in, the tap target is large, haptic fires, and 33/99 produces a calm bloom (and NO bloom under reduce-motion).
- [ ] **Manual RTL check:** switch locale to `ar`; confirm the location picker labels, the saved-timer rows, and the banner read correctly RTL, while coordinates / clock numerals / `count / target` stay LTR and unmirrored.
- [ ] **Manual honesty check (F1/F3):** with the default `UnavailableGeoLocator`, "Use my location" is hidden and manual entry works; with `notificationStatusProvider` overridden to `denied`/`limited`, the banner appears calm and warning-tinted (not red) with its icon.

## Self-review

- **Reverence (F4):** the tasbih is opt-in, sits BELOW `_DhikrView`, never wraps/decorates the Arabic line; no streaks/badges/commerce; completion is a gentle bloom honoring reduce-motion; tap target ≥44px with gentle haptic; tally uses `Numerals` (user numeral setting), progress line forced-LTR. The existing `break_overlay_test.dart` (sacred line renders once) stays green as a guard. ✓
- **Simplest-correct multi-timer (F2):** justified saved-list + single runner (matches one-hero design, minimizes audio/notification surface, additive to the engine, low P1 contention). `runSaved` loads-without-auto-start to match existing idle→active flow; `setDuration` clears identity for ad-hoc timers. Existing `timer_controller_test.dart` stays green proving the change is additive. ✓
- **P1 contention (F2):** explicitly flagged in cross-phase notes + Tasks 2.3/2.6 with concrete reconciliation guidance (keep P1's chime in `_tick`; per-timer sound available via `state.soundId`). Recommended to land F2 last/after P1. ✓
- **P2 consumption (F3):** banner reads a `notificationStatusProvider` seam matching the assumed `granted/denied/limited` + per-platform message contract; defaults to granted (invisible) so it ships now and integrates by re-pointing/adapting when P2 lands. `tarf.warning` (never error red), icon+text (never color-alone). ✓
- **RTL:** directional padding everywhere; chevrons flip; coordinates, clock faces, numeral blocks forced LTR via `TarfTimeText`/`textDirection: ltr` and the existing forced-LTR `TarfWheelPicker`. ✓
- **Western digits:** ARB placeholders plain `{n}`; UI numbers via `Numerals.*`/`TarfTimeText`; gen-l10n step included after every ARB change. ✓
- **Reuse, no reskin:** composes `TarfGroup`/`TarfListRow`/`TarfPresetChip`/`TarfSectionHeader`/`TarfTimeText`/`TarfWheelPicker` + `TarfTokens`/`context.tarf`; persistence mirrors `AlarmsController`; controllers are hand-written `Notifier`s (no codegen). ✓
- **New dependency:** only `geolocator` (F1), and the picker ships/test-passes without it via `UnavailableGeoLocator` + the `geoLocatorProvider` default; platform permission strings deferred to Phase 4 (noted). ✓
- **Worktree safety / merge order:** F1 + F4 independent and parallel-safe; F3 safe via the seam; F2 touches shared timer files → land last after P1. Documented in cross-phase section. ✓
- **TDD:** every task is red → run-and-see-fail → minimal impl → run-and-see-pass → commit, with full Dart for both test and impl and exact commands. ✓
- **Backward-compatible persistence:** `EyeCareConfig.prayerCityLabel`, `SavedTimer`, `TasbihState` all default missing JSON keys; legacy v1 JSON decodes cleanly (explicit tests). ✓

# Tarf (طَرْف) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build Tarf — an Arabic-first, offline-first, Apple-minimal cross-platform (Android/iOS/Windows/
macOS/Web/Chrome-extension) wellness app whose core is the activity-aware 20-20-20 eye break fused with a
dhikr "repeat-after-me" screen, surrounded by Focus/Timer/Alarm/Stopwatch/Insights/To-dos — plus a download
website with Mada/Visa/Mastercard donations, CI, store guides, and a reusable Project_Sprint skill.

**Architecture:** Single Flutter 3.44 codebase. Riverpod 3 state. Drift (SQLite) local-first store +
Firestore cloud sync. A shared `ReminderScheduler` interface abstracts per-platform scheduling/notifications/
audio. The Chrome extension is a thin native-JS service worker (owns scheduling) with Flutter-web rendering
only the popup/side-panel. Feature-first folder structure under `app/lib/features/*`.

**Tech Stack:** Flutter 3.44 / Dart 3.12 · Riverpod 3 · go_router · Drift · Cloud Firestore + firebase_auth
+ App Check + Remote Config · flutter_local_notifications · just_audio · flutter_tts · window_manager /
tray_manager / launch_at_startup / local_notifier · flutter_localizations + intl · Material 3 · adhan · hijri
· connectivity_plus. Website: static site + serverless donation function (Moyasar/Tap/Stripe).

---

## Decomposition & dependency graph

```
P0 Foundation  ──►  P1 Core (eyecare engine + dhikr break)  ──►  P4 Platform integration ─┐
      │                                                                                     │
      ├──►  P2 Productivity (focus/timer/alarm/stopwatch/todos/insights)  ──────────────────┤
      │                                                                                     ├─► P7 Integration + build/test
      ├──►  P3 Data/Auth/Sync  ────────────────────────────────────────────────────────────┤
      │                                                                                     │
      └──►  P5 Website + donations (independent) ──────────────────────────────────────────┘
                                                                                            
P6 Compliance/CI/store-guides (parallel, docs-mostly)        P8 Project_Sprint skill (last)
```

- **P0 is sequential and blocking** — everything imports its tokens/types/routing/data interfaces.
- **P1, P2, P3, P5 parallelize** after P0 (different folders, minimal overlap). Dispatch as parallel subagents.
- **P4** integrates per-platform plumbing once P1/P2/P3 land.
- **P7** wires everything + verifies real builds (Web, Windows, Android, extension).
- **P6** (compliance/CI/docs) and **P8** (skill) run near the end.

Each phase below is its own mini-plan with file structure, interfaces (real code), tasks, and acceptance.
TDD: write the test, see it fail, implement, see it pass, commit. Commit after every task.

---

## P0 — Foundation (sequential, blocking)

**Files (create):**
- `app/` via `flutter create --org app.tarf --platforms=android,ios,windows,macos,web tarf` (then rename dir)
- `app/pubspec.yaml` — dependencies pinned
- `app/lib/main.dart`, `app/lib/main_dev.dart` — entrypoints + ProviderScope
- `app/lib/app.dart` — MaterialApp.router, theme, localizations, RTL
- `app/lib/theme/tokens.dart` — color/space/radius/typography tokens (teal-green seed)
- `app/lib/theme/app_theme.dart` — light/dark ThemeData from tokens (Material 3, Inter + Amiri)
- `app/lib/theme/motion.dart` — durations/curves + reduceMotion gate
- `app/lib/l10n/app_en.arb`, `app/lib/l10n/app_ar.arb` — seed strings; `l10n.yaml`
- `app/lib/core/routing/app_router.dart` — go_router with shell (tabs/rail) + modal routes
- `app/lib/core/widgets/` — AppScaffold (responsive tabbar/rail), AccessoryShelf, HeroRing, BigNumerals
- `app/lib/core/format/numerals.dart` — Western/Arabic-Indic digit formatting + tabular
- `app/lib/core/time/clock.dart` — Clock abstraction (testable; serverTimestamp-aware)
- `app/lib/data/local/` — Drift database + DAOs (settings, dailyProgress, sessions, todos)
- `app/lib/data/models/` — domain models (freezed/json or plain) shared by local+cloud
- `app/lib/data/repositories/` — repository interfaces (impl in P3)
- `app/analysis_options.yaml` — strict lints (`flutter_lints` + `very_good_analysis`)
- `app/test/` — test harness + first golden test config

**Key interface — design tokens (real code):**
```dart
// app/lib/theme/tokens.dart
import 'package:flutter/material.dart';
class TarfTokens {
  static const seed = Color(0xFF0E7C66);          // calm teal-green accent
  static const radiusS = 8.0, radiusM = 16.0, radiusL = 28.0;
  static const space1 = 4.0, space2 = 8.0, space3 = 16.0, space4 = 24.0, space5 = 40.0;
  static const ringStroke = 10.0;
  static const breakBgLight = Color(0xFFF7F5F0);   // warm paper
  static const breakBgDark  = Color(0xFF0B0F0E);
}
```

**Key interface — responsive scaffold contract:**
```dart
// app/lib/core/widgets/app_scaffold.dart
/// Renders bottom tab bar < 600px, NavigationRail >= 600px. Same destinations everywhere.
/// `accessory` is the persistent active-session shelf/mini-window slot.
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.destinations, required this.body,
      required this.selectedIndex, required this.onSelect, this.accessory});
  // ...
}
```

**Tasks:**
- [ ] T0.1 Run `flutter create` (org `app.tarf`) into `app/`; commit the clean scaffold.
- [ ] T0.2 Add pinned deps to `pubspec.yaml` (`flutter pub get` succeeds). Commit.
- [ ] T0.3 Write `numerals_test.dart` (٠١٢٣ for ar, 0123 for en, tabular width). Run → fail.
- [ ] T0.4 Implement `numerals.dart` (intl NumberFormat per locale + override). Run → pass. Commit.
- [ ] T0.5 Write `clock_test.dart` (fake clock advances; now() injectable). Implement `clock.dart`. Commit.
- [ ] T0.6 Implement `tokens.dart` + `app_theme.dart` (light/dark). Golden test: a button + numerals in
      both themes + RTL. Commit.
- [ ] T0.7 Set up l10n (`l10n.yaml`, ARB en+ar with ~15 seed keys, `flutter gen-l10n`). Widget test asserts
      Arabic locale → TextDirection.rtl. Commit.
- [ ] T0.8 Implement `app_router.dart` shell + `AppScaffold`; widget test: <600px shows bottom bar, ≥600px
      shows rail; destinations identical. Commit.
- [ ] T0.9 Define Drift DB schema (settings, dailyProgress, focusSessions, todos) + DAOs; generate;
      DAO unit test (insert/read settings round-trips). Commit.
- [ ] T0.10 Define repository interfaces + domain models; commit.
- [ ] T0.11 `flutter analyze` clean; `flutter test` green; `flutter build web` succeeds. Commit.

**Acceptance:** App boots to an empty shell with working tab/rail nav, AR/EN + light/dark toggles, Drift DB
opens, all tests green, `flutter build web` produces output.

---

## P1 — Core: eye-care engine + dhikr break (depends on P0)

**Files (create):** `app/lib/features/eyecare/`
- `domain/eyecare_config.dart` — intervals, two-tier, strict/gentle, snooze cap, sound/haptic, working hours
- `domain/break_event.dart`, `domain/scheduler_state.dart`
- `core/reminder_scheduler.dart` — the shared interface (below)
- `core/precedence.dart` — reminder-precedence state machine (pure, fully tested)
- `core/active_time_tracker.dart` — accumulates active time; idle/screen signals (platform-injected)
- `application/eyecare_controller.dart` — Riverpod controller binding tracker→precedence→scheduler→overlay
- `presentation/break_overlay.dart` — full-screen overlay: depleting 20s ring + dhikr + audio + skip/snooze
- `presentation/status_chip.dart` — running-status chip for the shell
- `data/dhikr_repository.dart` + `assets/dhikr.json` — bundled immutable adhkar set
- `audio/break_audio.dart` — just_audio player abstraction (clip + chimes + TTS fallback)

**Key interface (real code):**
```dart
// app/lib/features/eyecare/core/reminder_scheduler.dart
abstract interface class ReminderScheduler {
  Future<void> init();
  Future<void> scheduleNextEyeBreak(Duration fromNow);
  Future<void> cancelAll();
  Future<void> showBreakNotification(BreakEvent e);   // VISUAL cue only
  Stream<BreakEvent> get onBreakDue;                  // fired by platform timer/alarm
}

// app/lib/features/eyecare/core/precedence.dart
enum BreakDecision { fire, suppressIdle, suppressPomodoro, suppressPaused,
                     suppressWorkingHours, suppressPrayer, snoozed }
/// Pure function — the single source of truth for "should a break fire now?".
BreakDecision decideBreak(SchedulerState s);
```

**Representative test (real code):**
```dart
// app/test/features/eyecare/precedence_test.dart
test('idle suppresses the eye break', () {
  final s = SchedulerState.base().copyWith(isIdle: true);
  expect(decideBreak(s), BreakDecision.suppressIdle);
});
test('strict mode during global pause still suppresses (pause wins)', () {
  final s = SchedulerState.base().copyWith(strict: true, globalPauseUntil: future);
  expect(decideBreak(s), BreakDecision.suppressPaused);
});
test('prayer-time window defers the break when enabled', () {
  final s = SchedulerState.base().copyWith(prayerPause: true, inPrayerWindow: true);
  expect(decideBreak(s), BreakDecision.suppressPrayer);
});
```

**Tasks:** (TDD each)
- [ ] T1.1 `EyeCareConfig` model + defaults (20min/20s, two-tier 5min/50min, gentle, snooze cap 3). Test. Commit.
- [ ] T1.2 Precedence state machine — write the full truth-table test first (≥12 cases incl. priorities),
      then implement `decideBreak`. Commit.
- [ ] T1.3 `ActiveTimeTracker` — test accumulation + idle reset with injected signal stream; implement. Commit.
- [ ] T1.4 `ReminderScheduler` interface + an in-memory `FakeScheduler` for tests. Commit.
- [ ] T1.5 `EyeCareController` (Riverpod) wiring tracker→precedence→scheduler; test with FakeScheduler +
      fake clock (advance 20 min active → break fires; idle → suppressed). Commit.
- [ ] T1.6 `dhikr.json` (8 verified entries: Arabic+translit+English+source) + `DhikrRepository` rotate-not-
      random; test rotation determinism. Commit.
- [ ] T1.7 `BreakAudio` abstraction (start chime → 20s clip/loop-stop → end chime; TTS fallback gated). Test
      with a fake audio backend (asserts 20s schedule + end callback). Commit.
- [ ] T1.8 `BreakOverlay` widget — golden tests in AR+EN, light+dark, with auto-fit Arabic (no truncation),
      depleting ring, Skip/Snooze (hidden in strict). Commit.
- [ ] T1.9 `StatusChip` for shell; widget test. Commit.
- [ ] T1.10 Eye-care Settings UI (intervals, strict/gentle, sounds, working hours, prayer pause). Persist to
      Drift; round-trip test. Commit.

**Acceptance:** With a fake clock + fake scheduler, 20 min of active time triggers the break overlay showing
a rotating dhikr with a 20s audio sequence ending on the end-chime; idle/pause/prayer/pomodoro suppress per
the precedence tests; all golden tests pass in AR+EN/light+dark.

---

## P2 — Productivity (depends on P0; parallel with P1/P3)

**Files:** `app/lib/features/{focus,timer,alarm,stopwatch,todos,insights}/`
- focus: Pomodoro controller (work/break/long-break, auto-chain, merge-with-eyebreak), hero ring UI, reflection
- timer: multiple named timers + recents; alarm: list + ringing screen + snooze; stopwatch: laps
- todos: list, estimated vs actual sessions, bind-to-focus
- insights: daily progress aggregation + weekly charts + CSV export

**Key interface (real code):**
```dart
// app/lib/features/focus/application/focus_controller.dart
class FocusState { final FocusPhase phase; final Duration remaining; final int completedCycles;
  final String? taskId; /* ... */ }
enum FocusPhase { idle, work, shortBreak, longBreak }
/// Eye-break overlays NEVER pause/reset this controller (coexistence invariant).
```

**Tasks:** (TDD each — abbreviated; each is test→fail→impl→pass→commit)
- [ ] T2.1 Focus Pomodoro controller + cycle chaining test (25/5, long break after 4). Commit.
- [ ] T2.2 Coexistence test: firing an eye break does NOT change FocusState.remaining. Commit.
- [ ] T2.3 Focus hero UI (ring + numerals + start/pause + goal streak). Golden AR/EN. Commit.
- [ ] T2.4 Timer controller (multiple concurrent) + recents persistence. Test. Commit.
- [ ] T2.5 Timer UI + accessory integration. Golden. Commit.
- [ ] T2.6 Alarm model + scheduling via ReminderScheduler; ringing screen; snooze. Test. Commit.
- [ ] T2.7 Stopwatch controller (laps, tabular digits) + UI. Test. Commit.
- [ ] T2.8 Todos CRUD (Drift) + estimated/actual; bind-to-focus starts a session. Test. Commit.
- [ ] T2.9 Insights aggregation (daily/weekly) + chart widget + CSV export. Test the aggregation math +
      CSV format. Commit.

**Acceptance:** Each tool works against the local store with passing controller tests; the eye-break
coexistence invariant holds; insights math + CSV verified; golden tests pass.

---

## P3 — Data / Auth / Sync (depends on P0; parallel with P1/P2)

**Files:** `app/lib/data/cloud/`, `app/lib/features/{account,onboarding}/`, `app/firebase/`
- `cloud/firestore_refs.dart` — typed collection refs + converters
- `cloud/sync_service.dart` — Drift↔Firestore mirror; increment counters; serverTimestamp; conflict policy
- `auth/auth_service.dart` — Google/Apple/Email; guest gate; account-exists-with-different-credential handling
- `account/account_screen.dart` — sign-in, sync status, **delete account + export data**
- `onboarding/` — sign-in rationale, permission priming (AR-first), language/theme, eye-care quick setup
- `firebase/firestore.rules` — per-uid lockdown; `firebase/firestore.indexes.json`

**Key interface (real code):**
```dart
// app/lib/data/cloud/sync_service.dart
abstract interface class SyncService {
  Future<void> migrateGuestDataToCloud(String uid);   // one-time on sign-in
  Future<void> pushPending();                          // on reconnect
  Stream<SyncStatus> get status;                       // fromCache / pendingWrites / synced
}
```

**Tasks:** (TDD with Firebase emulator or fakes)
- [ ] T3.1 Firestore data model + converters + security rules; rules unit test (uid isolation). Commit.
- [ ] T3.2 AuthService with a fake backend: guest→sign-in→link flow; error cases. Test. Commit.
- [ ] T3.3 SyncService: guest→cloud migration merges without clobber (increment counters). Test against
      emulator/fake. Commit.
- [ ] T3.4 Reconnect replays queued writes; SyncStatus stream reflects fromCache/pending/synced. Test. Commit.
- [ ] T3.5 Account screen: delete-account wipes Firestore subtree + local Drift; export produces JSON. Test. Commit.
- [ ] T3.6 Onboarding flow + permission-priming screens (AR/EN), with denied-path handling. Widget tests. Commit.
- [ ] T3.7 Generate `firebase_options.dart` via FlutterFire (config placeholders documented). Commit (gitignored secrets).

**Acceptance:** Guest data migrates on sign-in without loss; rules enforce per-uid; delete/export work;
onboarding handles granted+denied permission paths.

---

## P4 — Platform integration (depends on P1/P2/P3)

**Files:** `app/lib/features/eyecare/core/{mobile,desktop,extension}_scheduler.dart`, platform dirs.
- Mobile: flutter_local_notifications + android_alarm_manager_plus + workmanager; Android FGS + manifest
  perms (POST_NOTIFICATIONS, USE_EXACT_ALARM, USE_FULL_SCREEN_INTENT, FOREGROUND_SERVICE*); iOS modes/Info.plist
- Desktop: window_manager (hide-to-tray), tray_manager (countdown menu), launch_at_startup, local_notifier
- Audio: just_audio playback verified backgrounded on desktop + Android FGS
- Prayer times: adhan integration + location permission + manual fallback

**Tasks:**
- [ ] T4.1 `MobileScheduler` impl + Android manifest perms + FGS; integration test on the running Android build. Commit.
- [ ] T4.2 `DesktopScheduler` impl + tray + launch-at-startup (Windows verified). Commit.
- [ ] T4.3 Wire BreakAudio to real just_audio on Windows + Android; verify 20s clip plays to end. Commit.
- [ ] T4.4 Prayer-time provider (adhan) + location priming + manual fallback; precedence `inPrayerWindow`. Test. Commit.
- [ ] T4.5 Loud-through-silence (Android high-importance channel + audio session). Commit.

**Acceptance:** On the real Windows build and Android APK, an eye break fires, shows the overlay/notification,
and plays the 20s audio to completion; tray controls work on Windows.

---

## P4b — Chrome extension (depends on P1 UI; highest risk — spike first)

**Files:** `extension/{manifest.json, background.js, offscreen.html, offscreen.js, popup.html, sidepanel.html}`,
build pipeline copying `flutter build web` output into `extension/ui/`.
- `background.js` (MV3 service worker): `chrome.alarms` (20-min schedule, survives SW restart) →
  `chrome.notifications` (visual cue) + `chrome.offscreen` AUDIO_PLAYBACK (20s clip). `chrome.idle` gating.
- Flutter web (CanvasKit, `--no-web-resources-cdn`, local canvaskit) renders popup/side-panel; talks to SW via
  `chrome.runtime` messaging. **Plain-HTML fallback popup** kept.
- CSP `script-src 'self' 'wasm-unsafe-eval'`.

**Tasks:**
- [ ] T4b.1 Spike: minimal MV3 + `flutter build web` in popup renders (white-screen check). Commit or pivot to fallback.
- [ ] T4b.2 background.js scheduling engine + a JS unit test mirroring the Dart precedence cases. Commit.
- [ ] T4b.3 offscreen audio plays 20s clip on alarm; notification shows. Manual verify in Chrome. Commit.
- [ ] T4b.4 Popup/side-panel UI ↔ SW messaging (start/stop/snooze/streak). Commit.
- [ ] T4b.5 Build script (`extension/build.ps1`) producing a loadable unpacked + zipped extension. Commit.

**Acceptance:** Load-unpacked in Chrome: a break fires on schedule (even with popup closed), shows a
notification, and plays 20s audio; popup controls work.

---

## P5 — Website + donations (independent; parallel)

**Files:** `website/` — static marketing/download site (Next.js or Astro static export) + `website/api/donate`
serverless function (gateway abstraction).
- Pages: home (hero, 20-20-20 + dhikr story), download (APK/Play/App Store/MS Store/web/extension links),
  Support/Donate (Mada/Visa/Mastercard via gateway), privacy, terms, licenses.
- `lib/payments/gateway.ts` — interface; `moyasar.ts` impl (primary, Mada-capable); test/sandbox mode.
- Arabic-first + English, RTL, light/dark mirroring the app's design tokens.

**Tasks:**
- [ ] T5.1 Scaffold site + design tokens parity; AR/EN + RTL; deploy-ready static export. Commit.
- [ ] T5.2 Home + download pages (placeholder store links, real APK/extension links once built). Commit.
- [ ] T5.3 PaymentGateway interface + Moyasar impl + `/api/donate` serverless (sandbox keys via env). Unit test the
      amount/currency/validation; sandbox e2e documented. Commit.
- [ ] T5.4 Privacy/terms/licenses pages (render from provenance ledger + compliance drafts). Commit.

**Acceptance:** Site builds and serves AR/EN/RTL; donate page creates a sandbox payment via the gateway
abstraction; legal pages present.

---

## P6 — Compliance / CI / store guides (parallel; docs-heavy)

**Files:** `docs/store/*`, `.github/workflows/*.yml`, `app/ios/Runner/PrivacyInfo.xcprivacy`, ledger.
- CI: `build-android.yml`, `build-windows.yml`, `build-web.yml`, `build-extension.yml` (this repo) +
  `build-apple.yml` (macOS runner: iOS+macOS, signing via secrets).
- Store guides: App Store, Play Console, Microsoft Store, Chrome Web Store — step-by-step.
- Compliance: privacy policy + terms drafts, permissions UX matrix, data-safety/nutrition-label answers,
  account-deletion confirmation, PrivacyInfo.xcprivacy, export-compliance.

**Tasks:**
- [ ] T6.1 GitHub Actions matrix (Android/Windows/Web/extension build+test on push). Commit.
- [ ] T6.2 Apple CI workflow (build, signing placeholders, notarize step) + signing docs. Commit.
- [ ] T6.3 Store-submission guides (5 platforms). Commit.
- [ ] T6.4 Compliance pack (privacy/terms/permissions matrix/PrivacyInfo.xcprivacy/data-safety). Commit.
- [ ] T6.5 `assets_ledger/ledger.json` populated for every bundled asset + Licenses screen renders it. Commit.

**Acceptance:** CI builds the here-buildable targets green; Apple workflow is complete pending owner secrets;
compliance docs + ledger complete.

---

## P7 — Integration + real build/test verification

**Tasks:**
- [ ] T7.1 Wire all features into the shell + accessory + settings; smoke widget test of full nav. Commit.
- [ ] T7.2 `flutter analyze` clean; full `flutter test` (unit+widget+golden) green. Commit.
- [ ] T7.3 `flutter build web` + load as PWA; manual core-loop check. Commit.
- [ ] T7.4 `flutter build windows`; run the .exe; verify break overlay + 20s audio + tray. Commit.
- [ ] T7.5 `flutter build apk --debug`; verify on emulator/device if available, else document. Commit.
- [ ] T7.6 Build the Chrome extension; load-unpacked; verify scheduled break + audio. Commit.
- [ ] T7.7 Tag `v0.1.0`; write CHANGELOG + README with build/run instructions for every target. Commit.

**Acceptance:** Web, Windows, Android (build), and the extension are produced and the core loop verified on
at least Web + Windows; all automated tests green; README documents every target.

---

## P8 — Project_Sprint skill (last)

**Files:** `~/.claude/skills/Project_Sprint/SKILL.md` (+ references/templates).
- Capture this end-to-end process: research workflow → clarifying-questions template → design spec template →
  decomposition/dependency-graph → parallel-subagent execution → build/verify → compliance → website → ship.

**Tasks:**
- [ ] T8.1 Author SKILL.md (frontmatter trigger "Project_Sprint") with the full reusable playbook + templates. 
- [ ] T8.2 Include the research-workflow script template + the spec/plan templates + the per-platform checklists.
- [ ] T8.3 Validate skill loads; commit.

**Acceptance:** Typing/invoking Project_Sprint reproduces this sprint methodology for any new project.

---

## Self-review notes
- Spec coverage: every spec section maps to a phase (core→P1, productivity→P2, data/auth/sync→P3,
  notifications/audio/tray/prayer→P4, extension→P4b, donations/website→P5, compliance/CI/stores→P6,
  build/test→P7, skill→P8). ✓
- Coexistence invariant (eye break never pauses focus) is an explicit test (T2.2). ✓
- Offline-first guest + zero-network core lives in P0/P1 (Drift) before any auth (P3). ✓
- 20s-sound contract realized in P1 (logic) + P4/P4b (real playback) with honest per-platform tiers. ✓
- Account deletion/export (store gate) is T3.5. PrivacyInfo.xcprivacy is T6.4. ✓

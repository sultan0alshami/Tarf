# Phase 2 — Background Delivery: Implementation Plan

> For agentic workers: implement task-by-task; steps use `- [ ]`.
> REQUIRED SUB-SKILL: use `superpowers:subagent-driven-development` (or `superpowers:executing-plans`)
> and `superpowers:test-driven-development`. Write the failing test FIRST, watch it fail, write the
> minimal implementation, watch it pass, then commit. One task = one commit.
> Flutter SDK: prepend `C:\dev\flutter\bin` to PATH. Run all `flutter`/`dart` commands from
> `C:\Users\sulta\Claude_Code\EyeCure_20\app`. Run `git` commands from the repo root
> `C:\Users\sulta\Claude_Code\EyeCure_20` so `git add app/...` paths resolve. Keep the suite green
> (58 existing tests + new ones) and `flutter analyze` clean after every task.

**Goal:** Give Tarf real OS-level scheduling so standard alarms, prayer alarms, and (optionally)
eye-break reminders fire **even when the app/tab is closed** — without ever promising delivery the
platform cannot honor. Add `flutter_local_notifications` (all platforms) + `android_alarm_manager_plus`
(Android exact alarms), a pure-Dart `NotificationService` that schedules/reschedules/cancels using the
Phase-1 sound catalog, a calm permission flow with a persisted granted/denied/limited state machine,
reboot rescheduling, and a foreground-vs-background double-fire guard. Surface a per-platform honest
**degraded state** that Phase 3's banner consumes.

**Architecture:** A thin, testable seam. All scheduling decisions live in **pure Dart** (no platform
calls): a `NextFire` calculator (next occurrence for standard + prayer alarms), a `ScheduledItem`
value type keyed deterministically, a `PermissionState` machine, and a `DoubleFireGuard` keyed by
`itemId + scheduled-minute`. A `NotificationGateway` interface wraps the only impure surface
(`flutter_local_notifications` + `android_alarm_manager_plus` + permission plugins); the real
implementation is `FlutterNotificationGateway`, the test double is `FakeNotificationGateway`. The
`NotificationService` (a Riverpod `Notifier`) orchestrates: it watches `alarmsControllerProvider`,
`prayerAlarmsProvider`, and `eyeCareConfigProvider`, diffs the desired schedule against what is
currently scheduled, and calls the gateway. The existing `AlarmHost`/`EyeCareHost` keep handling
the **foreground** ring/overlay; the `DoubleFireGuard` (shared via SharedPreferences) ensures the OS
notification path and the foreground path never both fire for the same alarm-minute. A
`backgroundDeliveryStatusProvider` exposes the honest per-platform capability + permission result for
Phase 3. Native config is added per platform (Android manifest + boot receiver + channels; iOS
Info.plist + AppDelegate registration + honest background modes; macOS entitlement; Windows
best-effort). On iOS/macOS/web/Windows there is **no** exact-alarm engine — those platforms use
local-notification scheduling only, and the degraded state says so plainly.

**Tech Stack:** Flutter 3.44 / Dart 3.12 · Riverpod 3 hand-written `Notifier`/`NotifierProvider`
(NO codegen) · `flutter_local_notifications` ^19.0.0 · `android_alarm_manager_plus` ^4.0.0 ·
`timezone` ^0.10.0 (required by zoned scheduling) · `flutter_timezone` ^4.0.0 (device tz on device)
· `shared_preferences` JSON (local-first) · `adhan` via existing `PrayerService` · `intl`. ARB →
`flutter gen-l10n` (Western digits, plain `{n}`). Material 3 + `TarfColors` ThemeExtension for the
priming sheet UI. Sound IDs from Phase 1 (`'default'`/`'bell'`/`'chime'`/`'calm'`) mapped to
notification channels/sounds.

---

## File Structure

```
app/
  pubspec.yaml                                          (MODIFY — deps)
  lib/
    core/
      notifications/                                    (NEW dir)
        scheduled_item.dart            (NEW — ScheduledItem value type + ScheduledKind enum + keying)
        next_fire.dart                 (NEW — pure next-occurrence calc for standard + prayer)
        notification_sound.dart        (NEW — maps Phase-1 sound IDs → channel id / sound resource)
        permission_state.dart          (NEW — PermissionStatus enum + PermissionState + machine)
        double_fire_guard.dart         (NEW — claim/seen logic keyed by itemId+minute, prefs-backed)
        background_capability.dart     (NEW — per-platform honest capability descriptor)
        notification_gateway.dart      (NEW — abstract gateway + FakeNotificationGateway)
        flutter_notification_gateway.dart (NEW — real flutter_local_notifications/aam impl)
        notification_service.dart      (NEW — Notifier orchestrator: schedule/reschedule/cancel)
        background_delivery_status.dart (NEW — provider exposing capability+permission for P3)
        notification_bootstrap.dart    (NEW — top-level @pragma vm:entry-point bg callbacks)
      settings/
        settings_controller.dart                        (no change; sharedPreferencesProvider reused)
    features/
      alarm/
        presentation/alarm_host.dart                    (MODIFY — consult DoubleFireGuard before ring)
        application/alarm_derived.dart                  (MODIFY — expose public nextOccurrence via NextFire)
      eyecare/
        application/eyecare_engine.dart                 (MODIFY — claim guard before showing break)
      permissions/                                      (NEW dir)
        presentation/notification_priming_sheet.dart    (NEW — calm rationale sheet, AR+EN)
    main.dart                                           (MODIFY — init tz + gateway, override providers)
    app.dart                                            (no change required; hosts unchanged wiring)
    l10n/
      app_en.arb                                        (MODIFY — perm/degraded copy)
      app_ar.arb                                        (MODIFY — perm/degraded copy)
  test/
    core/notifications/
      next_fire_test.dart                               (NEW)
      scheduled_item_test.dart                          (NEW)
      notification_sound_test.dart                      (NEW)
      permission_state_test.dart                        (NEW)
      double_fire_guard_test.dart                       (NEW)
      notification_service_test.dart                    (NEW)
      background_delivery_status_test.dart              (NEW)
    features/alarm/alarm_host_guard_test.dart           (NEW)

  android/app/src/main/AndroidManifest.xml              (MODIFY — perms + receivers + FGS)
  android/app/src/main/res/raw/                         (NEW — bell.wav, chime.wav, calm.wav)
  android/app/src/main/res/values/strings.xml           (NEW/MODIFY — channel names if needed)
  ios/Runner/Info.plist                                 (MODIFY — background modes, honest)
  ios/Runner/AppDelegate.swift                          (MODIFY — UNUserNotificationCenter delegate)
  macos/Runner/Release.entitlements                     (MODIFY — none needed; documented)
  macos/Runner/DebugProfile.entitlements                (no change)
  windows/runner/*                                      (no native change — plugin handles toasts)
```

---

## Cross-phase dependencies & integration points

- **DEPENDS ON Phase 1** (`docs/superpowers/plans/2026-06-01-tarf-phase1-audio.md`) for the **sound
  catalog**. That plan was not present at authoring time, so this plan designs against the **already-shipped**
  interface used by the app today: `AlarmItem.sound` is a `String` id with the catalog
  `['default','bell','chime','calm']` (see `app/lib/features/alarm/presentation/alarm_editor_screen.dart`
  line 36). `notification_sound.dart` is the **single adapter point**: if Phase 1 lands a richer
  `TarfAudioService` exposing the same ids, only `notification_sound.dart` changes — everything downstream
  keys off the string id. **Merge after P1** so the catalog ids are final.
- **PROVIDES to Phase 3**: `backgroundDeliveryStatusProvider` (a `Provider<BackgroundDeliveryStatus>`)
  exposing `{capability: BackgroundCapability, permission: PermissionStatus, degradedReason: String?}`.
  Phase 3's banner renders this. The l10n keys `status.bgRemindersOff` etc. are added here (the
  permissions matrix already specifies the copy — `docs/compliance/permissions-matrix.md` §A/§D).
- **SHARED files with P1**: `alarm_host.dart`, `eyecare_engine.dart` (the foreground hosts). P1 may
  add audio playback there; P2 adds a single `DoubleFireGuard.claim(...)` call. Keep edits surgical and
  in different regions of the method to minimize merge conflict; if both phases touch the same method,
  P2 rebases onto P1.
- **SHARED files with P3**: the new l10n keys and `background_delivery_status.dart` (P3 reads, P2 writes).
- **Worktree-safe**: yes. All new code lives in **new** files under `core/notifications/`,
  `features/permissions/`, and new test files. The only pre-existing app files modified are
  `pubspec.yaml`, `main.dart`, `alarm_host.dart`, `alarm_derived.dart`, `eyecare_engine.dart`, the two
  ARB files, and native config. Recommended **merge order: P1 → P2 → P3** in the core track.

### The double-fire contract (read before Task 7/8)

Two independent firing paths exist after this phase:
1. **Foreground path** — `AlarmHost` (10 s poll) rings the modal; `EyeCareHost` shows the overlay.
2. **Background path** — the OS delivers the scheduled local notification (Android also via exact alarm).

They must never both fire for the same logical event. The guard key is deterministic:
`"<kind>:<id>:<yyyy-MM-dd-HH-mm>"` (the **scheduled wall-clock minute**, not "now"). Both paths call
`DoubleFireGuard.claim(key)` which is **atomic** against a SharedPreferences-backed set: the first caller
to claim a key wins and proceeds; any later caller for the same key is a no-op. The notification's
payload carries the key; when the OS notification is tapped (or its action handled) while the app is alive,
the handler claims the key too. Stale keys older than 24 h are pruned on each claim so the set never grows
unbounded. Because foreground polls every 10 s and the OS may deliver within the same minute, claiming on
the **minute** (not the second) collapses both into one logical fire.

---

### Task 1 — Pure value type: `ScheduledItem` + `ScheduledKind` + deterministic key

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\scheduled_item.dart` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\notifications\scheduled_item_test.dart` (NEW)

- [ ] Write the failing test `scheduled_item_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/core/notifications/scheduled_item.dart';

  void main() {
    group('ScheduledItem', () {
      final fireAt = DateTime(2026, 6, 1, 6, 30);

      test('guardKey is kind:id:minute and stable', () {
        const item = ScheduledItem(
          kind: ScheduledKind.standardAlarm,
          id: 'a1',
          title: 'Wake',
          body: '',
          soundId: 'bell',
        );
        final key = item.guardKeyFor(fireAt);
        expect(key, 'standardAlarm:a1:2026-06-01-06-30');
        expect(item.guardKeyFor(fireAt), key); // deterministic
      });

      test('notificationId is a stable non-negative 31-bit hash of kind+id', () {
        const a = ScheduledItem(
          kind: ScheduledKind.prayerAlarm, id: 'fajr', title: 'Fajr', body: '',
          soundId: 'default');
        const b = ScheduledItem(
          kind: ScheduledKind.prayerAlarm, id: 'fajr', title: 'Fajr2', body: 'x',
          soundId: 'calm');
        expect(a.notificationId, b.notificationId); // id+kind only
        expect(a.notificationId, greaterThanOrEqualTo(0));
        expect(a.notificationId, lessThan(1 << 31));
        const c = ScheduledItem(
          kind: ScheduledKind.standardAlarm, id: 'fajr', title: 'x', body: '',
          soundId: 'default');
        expect(a.notificationId == c.notificationId, isFalse); // kind matters
      });

      test('payload round-trips through encode/decode', () {
        const item = ScheduledItem(
          kind: ScheduledKind.eyeBreak, id: 'eye', title: 'Rest', body: 'Look away',
          soundId: 'chime');
        final decoded = ScheduledItem.decodePayload(item.encodePayload(fireAt));
        expect(decoded.kind, ScheduledKind.eyeBreak);
        expect(decoded.id, 'eye');
        expect(decoded.guardKey, 'eyeBreak:eye:2026-06-01-06-30');
      });
    });
  }
  ```
- [ ] Run (expect FAIL — file/type does not exist):
  `flutter test test/core/notifications/scheduled_item_test.dart`
  Expected: compile error / "Target of URI doesn't exist: scheduled_item.dart".
- [ ] Minimal implementation `scheduled_item.dart`:
  ```dart
  /// What kind of thing is being scheduled. The kind is part of every key so a
  /// standard alarm and a prayer alarm with the same id never collide.
  enum ScheduledKind { standardAlarm, prayerAlarm, eyeBreak }

  /// One desired OS-level delivery. Pure data — no platform types. The
  /// [NotificationService] turns a set of these into gateway calls.
  class ScheduledItem {
    const ScheduledItem({
      required this.kind,
      required this.id,
      required this.title,
      required this.body,
      required this.soundId,
    });

    final ScheduledKind kind;
    final String id;
    final String title;
    final String body;

    /// Phase-1 sound catalog id: 'default' | 'bell' | 'chime' | 'calm'.
    final String soundId;

    /// Stable 31-bit non-negative id for the OS notification slot. Derived from
    /// kind+id only so rescheduling the same logical alarm overwrites its slot.
    int get notificationId {
      final s = '${kind.name}:$id';
      var h = 0;
      for (final c in s.codeUnits) {
        h = 0x1fffffff & (h * 31 + c);
      }
      return h;
    }

    /// Deterministic guard key for the wall-clock [fireAt] minute.
    String guardKeyFor(DateTime fireAt) {
      String two(int v) => v.toString().padLeft(2, '0');
      final d = '${fireAt.year}-${two(fireAt.month)}-${two(fireAt.day)}'
          '-${two(fireAt.hour)}-${two(fireAt.minute)}';
      return '${kind.name}:$id:$d';
    }

    /// Compact payload the OS hands back on tap. Carries the guard key so the
    /// tap handler can claim it (see DoubleFireGuard).
    String encodePayload(DateTime fireAt) =>
        '${kind.name}|$id|$soundId|${guardKeyFor(fireAt)}';

    static DecodedPayload decodePayload(String raw) {
      final p = raw.split('|');
      return DecodedPayload(
        kind: ScheduledKind.values.byName(p[0]),
        id: p[1],
        soundId: p[2],
        guardKey: p[3],
      );
    }
  }

  /// The parsed result of a tapped notification's payload.
  class DecodedPayload {
    const DecodedPayload({
      required this.kind,
      required this.id,
      required this.soundId,
      required this.guardKey,
    });
    final ScheduledKind kind;
    final String id;
    final String soundId;
    final String guardKey;
  }
  ```
- [ ] Run (expect PASS): `flutter test test/core/notifications/scheduled_item_test.dart` → all 3 pass.
- [ ] Run `flutter analyze` (expect: no new issues).
- [ ] Commit:
  ```
  git add app/lib/core/notifications/scheduled_item.dart app/test/core/notifications/scheduled_item_test.dart
  git commit -m "Add ScheduledItem value type with deterministic keying

  Pure-Dart desired-delivery type with stable notificationId, minute-based
  guardKey, and round-trippable payload. Foundation for Phase 2 scheduling.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 2 — Pure next-fire calculator (standard + prayer)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\next_fire.dart` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\notifications\next_fire_test.dart` (NEW)

- [ ] Write the failing test `next_fire_test.dart` (covers one-shot, repeat, today-already-passed,
  day-of-week wrap, and prayer "next future time today/tomorrow"):
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/core/notifications/next_fire.dart';
  import 'package:tarf/features/alarm/domain/alarm_item.dart';

  void main() {
    group('NextFire.standard', () {
      // Mon 2026-06-01 08:00 local.
      final now = DateTime(2026, 6, 1, 8, 0);

      test('one-shot later today', () {
        const a = AlarmItem(id: 'a', hour: 9, minute: 30); // days empty
        expect(NextFire.standard(a, now), DateTime(2026, 6, 1, 9, 30));
      });

      test('one-shot earlier today rolls to tomorrow', () {
        const a = AlarmItem(id: 'a', hour: 7, minute: 0);
        expect(NextFire.standard(a, now), DateTime(2026, 6, 2, 7, 0));
      });

      test('repeat weekdays from Friday picks Monday', () {
        final fri = DateTime(2026, 6, 5, 22, 0); // Fri
        const a = AlarmItem(id: 'a', hour: 6, minute: 0, days: {1, 2, 3, 4, 5});
        expect(NextFire.standard(a, fri), DateTime(2026, 6, 8, 6, 0)); // Mon
      });

      test('repeat today but time already passed picks same weekday next week',
          () {
        // now Mon 08:00; alarm Mondays only at 06:00 -> next Monday.
        const a = AlarmItem(id: 'a', hour: 6, minute: 0, days: {1});
        expect(NextFire.standard(a, now), DateTime(2026, 6, 8, 6, 0));
      });

      test('exactly now does NOT count as next (strictly after)', () {
        const a = AlarmItem(id: 'a', hour: 8, minute: 0, days: {1});
        expect(NextFire.standard(a, now), DateTime(2026, 6, 8, 8, 0));
      });
    });

    group('NextFire.prayer', () {
      final now = DateTime(2026, 6, 1, 8, 0);
      test('returns the earliest prayer time strictly after now', () {
        final times = [
          DateTime(2026, 6, 1, 4, 10), // passed
          DateTime(2026, 6, 1, 11, 50), // next
          DateTime(2026, 6, 1, 15, 20),
        ];
        expect(NextFire.prayer(times, now), DateTime(2026, 6, 1, 11, 50));
      });

      test('all passed today returns null (caller recomputes for tomorrow)', () {
        final times = [DateTime(2026, 6, 1, 4, 10), DateTime(2026, 6, 1, 7, 0)];
        expect(NextFire.prayer(times, now), isNull);
      });
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/core/notifications/next_fire_test.dart` → URI/type missing.
- [ ] Minimal implementation `next_fire.dart` (extract the proven logic from
  `alarm_derived.dart::_nextOccurrence`, make it public + testable; do NOT touch `alarm_derived.dart`
  yet — that is Task 3):
  ```dart
  import '../../features/alarm/domain/alarm_item.dart';

  /// Pure next-occurrence math for OS scheduling. No platform calls; no DateTime.now.
  abstract final class NextFire {
    NextFire._();

    /// The next time [a] fires strictly after [now], honoring repeat [days]
    /// (empty = one-shot → next future occurrence of the clock time).
    static DateTime standard(AlarmItem a, DateTime now) {
      for (var add = 0; add <= 7; add++) {
        final d = DateTime(now.year, now.month, now.day, a.hour, a.minute)
            .add(Duration(days: add));
        if (!d.isAfter(now)) continue;
        if (a.days.isEmpty || a.days.contains(d.weekday)) return d;
      }
      // Unreachable for valid input; safe fallback = same time tomorrow.
      return DateTime(now.year, now.month, now.day, a.hour, a.minute)
          .add(const Duration(days: 1));
    }

    /// The earliest of today's [prayerTimes] strictly after [now], or null if
    /// they have all passed (the service then recomputes for the next day).
    static DateTime? prayer(List<DateTime> prayerTimes, DateTime now) {
      DateTime? soonest;
      for (final t in prayerTimes) {
        if (t.isAfter(now) && (soonest == null || t.isBefore(soonest))) {
          soonest = t;
        }
      }
      return soonest;
    }
  }
  ```
- [ ] Run (expect PASS): `flutter test test/core/notifications/next_fire_test.dart` → 7 pass.
- [ ] Run `flutter analyze` (expect clean).
- [ ] Commit:
  ```
  git add app/lib/core/notifications/next_fire.dart app/test/core/notifications/next_fire_test.dart
  git commit -m "Add pure NextFire calculator for standard + prayer alarms

  Public, DateTime.now-free next-occurrence math (one-shot, repeat, weekday
  wrap, strictly-after) extracted for OS scheduling and full unit coverage.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 3 — Reuse `NextFire` from `alarm_derived.dart` (no behavior change)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\alarm\application\alarm_derived.dart` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\notifications\next_fire_test.dart` (already covers it)

- [ ] Add a regression test to `next_fire_test.dart` proving `nextAlarmProvider` still computes the same
  soonest duration after the refactor (guards against drift):
  ```dart
  // append inside main()
  group('nextAlarmProvider parity', () {
    test('uses NextFire.standard for enabled alarms', () {
      // Build a container with a single enabled one-shot far in the future and
      // assert nextAlarmProvider is positive and <= 24h (sanity; full wiring is
      // exercised by existing app tests).
      // (Kept light: the math itself is covered above; this asserts the import
      //  swap compiles and is consumed.)
      expect(NextFire.standard(
        const AlarmItem(id: 'x', hour: 23, minute: 59),
        DateTime(2026, 6, 1, 0, 0),
      ), DateTime(2026, 6, 1, 23, 59));
    });
  });
  ```
- [ ] Run (expect PASS already for the new assert; the point is the next edit must keep it passing):
  `flutter test test/core/notifications/next_fire_test.dart`
- [ ] Minimal edit to `alarm_derived.dart`: replace the private `_nextOccurrence` with a call to
  `NextFire.standard`, delete the private function. Add the import. The provider body becomes:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../core/notifications/next_fire.dart';
  import '../../eyecare/application/eyecare_config_controller.dart';
  import '../../eyecare/core/prayer_service.dart';
  import '../domain/alarm_item.dart';
  import 'alarms_controller.dart';
  // ... PrayerAlarm class and prayerAlarmsProvider unchanged ...

  final nextAlarmProvider = Provider<Duration?>((ref) {
    final now = DateTime.now();
    final alarms = ref.watch(alarmsControllerProvider);
    final prayers = ref.watch(prayerAlarmsProvider);

    DateTime? soonest;
    void consider(DateTime t) {
      if (t.isAfter(now) && (soonest == null || t.isBefore(soonest!))) {
        soonest = t;
      }
    }

    for (final a in alarms) {
      if (a.enabled) consider(NextFire.standard(a, now));
    }
    for (final p in prayers) {
      if (p.enabled && p.time.isAfter(now)) consider(p.time);
    }
    return soonest?.difference(now);
  });
  ```
  (Delete the old `DateTime _nextOccurrence(...)` block at the bottom of the file.)
- [ ] Run the FULL suite (expect PASS — proves the existing alarm screen "Ring in…" readout is unchanged):
  `flutter test`
  Expected: all prior tests + new notifications tests green.
- [ ] Run `flutter analyze` (expect clean; the unused-import/dead-code lints must be gone).
- [ ] Commit:
  ```
  git add app/lib/features/alarm/application/alarm_derived.dart app/test/core/notifications/next_fire_test.dart
  git commit -m "Reuse NextFire in nextAlarmProvider (single source of truth)

  Replace the private _nextOccurrence with the shared, tested NextFire.standard.
  No behavior change; the Ring-in readout math is now covered by unit tests.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 4 — Sound mapping: Phase-1 catalog id → channel + sound resource

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\notification_sound.dart` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\notifications\notification_sound_test.dart` (NEW)

- [ ] Write the failing test `notification_sound_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/core/notifications/notification_sound.dart';

  void main() {
    group('NotificationSound', () {
      test('every Phase-1 catalog id maps to a distinct Android channel', () {
        const ids = ['default', 'bell', 'chime', 'calm'];
        final channels = ids.map(NotificationSound.androidChannelId).toSet();
        expect(channels.length, ids.length); // distinct
        for (final c in channels) {
          expect(c.startsWith('tarf_alarm_'), isTrue);
        }
      });

      test('unknown id falls back to default channel (never throws)', () {
        expect(NotificationSound.androidChannelId('does-not-exist'),
            NotificationSound.androidChannelId('default'));
      });

      test('default uses the system sound (null raw resource)', () {
        expect(NotificationSound.androidRawResource('default'), isNull);
      });

      test('custom ids map to a raw resource name without extension', () {
        expect(NotificationSound.androidRawResource('bell'), 'bell');
        expect(NotificationSound.androidRawResource('chime'), 'chime');
        expect(NotificationSound.androidRawResource('calm'), 'calm');
      });

      test('iOS sound file name carries the .caf/.aiff extension or null', () {
        expect(NotificationSound.appleSoundFile('default'), isNull); // default
        expect(NotificationSound.appleSoundFile('bell'), 'bell.caf');
      });

      test('channelName is human-readable per id', () {
        expect(NotificationSound.channelName('calm'), 'Tarf — Calm');
      });
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/core/notifications/notification_sound_test.dart`.
- [ ] Minimal implementation `notification_sound.dart` (the **single adapter** to Phase 1; if Phase 1
  ships a `TarfAudioService`, swap the constant list for `TarfAudioService.soundIds` here only):
  ```dart
  /// Adapter from Phase-1's sound catalog ids to platform notification sound
  /// wiring. Android needs ONE channel per sound (a channel's sound is fixed at
  /// creation), so each id gets its own high-importance channel. iOS/macOS pass a
  /// per-notification sound file. 'default' means "the OS default alarm sound".
  ///
  /// SINGLE SOURCE OF TRUTH for the Phase-1 → notification mapping. If Phase 1
  /// exposes a TarfAudioService, replace [catalogIds] with its ids here only.
  abstract final class NotificationSound {
    NotificationSound._();

    /// Phase-1 catalog (mirrors AlarmEditorScreen._soundIds).
    static const catalogIds = ['default', 'bell', 'chime', 'calm'];

    static bool _known(String id) => catalogIds.contains(id);

    /// One Android channel per sound. Channels are created up-front by the
    /// gateway. Unknown ids fall back to the default channel.
    static String androidChannelId(String soundId) =>
        'tarf_alarm_${_known(soundId) ? soundId : 'default'}';

    static String channelName(String soundId) {
      final id = _known(soundId) ? soundId : 'default';
      return switch (id) {
        'bell' => 'Tarf — Bell',
        'chime' => 'Tarf — Chime',
        'calm' => 'Tarf — Calm',
        _ => 'Tarf — Default',
      };
    }

    /// Android raw resource name (res/raw/<name>.wav) without extension, or null
    /// for the system default sound.
    static String? androidRawResource(String soundId) {
      if (!_known(soundId) || soundId == 'default') return null;
      return soundId; // bell|chime|calm -> res/raw/{bell,chime,calm}.wav
    }

    /// iOS/macOS bundled sound file (with extension), or null for default.
    static String? appleSoundFile(String soundId) {
      if (!_known(soundId) || soundId == 'default') return null;
      return '$soundId.caf';
    }
  }
  ```
- [ ] Run (expect PASS): `flutter test test/core/notifications/notification_sound_test.dart` → 6 pass.
- [ ] Run `flutter analyze` (expect clean).
- [ ] Commit:
  ```
  git add app/lib/core/notifications/notification_sound.dart app/test/core/notifications/notification_sound_test.dart
  git commit -m "Map Phase-1 sound ids to per-platform notification channels

  One Android channel per catalog sound (channel sound is immutable), iOS/macOS
  per-notification sound file, safe default fallback. Single Phase-1 adapter.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 5 — Permission state machine

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\permission_state.dart` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\notifications\permission_state_test.dart` (NEW)

- [ ] Write the failing test `permission_state_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/core/notifications/permission_state.dart';

  void main() {
    group('PermissionState', () {
      test('initial state is notDetermined, not asked', () {
        const s = PermissionState.initial;
        expect(s.notifications, PermissionStatus.notDetermined);
        expect(s.exactAlarm, PermissionStatus.notDetermined);
        expect(s.askedOnce, isFalse);
        expect(s.canRequestNotifications, isTrue);
      });

      test('granting notifications sets granted + askedOnce', () {
        final s = PermissionState.initial
            .afterNotificationResult(PermissionStatus.granted);
        expect(s.notifications, PermissionStatus.granted);
        expect(s.askedOnce, isTrue);
        expect(s.canRequestNotifications, isFalse); // already granted
      });

      test('denied once still allows a single re-ask; twice is permanent', () {
        final once = PermissionState.initial
            .afterNotificationResult(PermissionStatus.denied);
        expect(once.notifications, PermissionStatus.denied);
        expect(once.canRequestNotifications, isTrue); // one gentle re-ask
        final twice = once.afterNotificationResult(PermissionStatus.denied);
        expect(twice.notifications, PermissionStatus.permanentlyDenied);
        expect(twice.canRequestNotifications, isFalse); // -> deep-link only
      });

      test('limited (iOS provisional) is a usable grant for scheduling', () {
        final s = PermissionState.initial
            .afterNotificationResult(PermissionStatus.limited);
        expect(s.notifications, PermissionStatus.limited);
        expect(s.canSchedule, isTrue); // provisional delivers quietly
      });

      test('exact-alarm denial does not block notification scheduling', () {
        final s = PermissionState.initial
            .afterNotificationResult(PermissionStatus.granted)
            .afterExactAlarmResult(PermissionStatus.denied);
        expect(s.exactAlarm, PermissionStatus.denied);
        expect(s.canSchedule, isTrue);
      });

      test('json round-trips', () {
        final s = PermissionState.initial
            .afterNotificationResult(PermissionStatus.granted)
            .afterExactAlarmResult(PermissionStatus.granted);
        final back = PermissionState.fromJson(s.toJson());
        expect(back.notifications, PermissionStatus.granted);
        expect(back.exactAlarm, PermissionStatus.granted);
        expect(back.askedOnce, isTrue);
      });
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/core/notifications/permission_state_test.dart`.
- [ ] Minimal implementation `permission_state.dart`:
  ```dart
  /// Coarse cross-platform permission status. 'limited' models iOS provisional
  /// (quiet delivery) which is still schedulable.
  enum PermissionStatus { notDetermined, granted, limited, denied, permanentlyDenied }

  /// Immutable snapshot of the two permissions Phase 2 cares about, plus a
  /// re-ask budget. Persisted as JSON so the priming flow does not nag.
  class PermissionState {
    const PermissionState({
      required this.notifications,
      required this.exactAlarm,
      required this.deniedCount,
    });

    final PermissionStatus notifications;
    final PermissionStatus exactAlarm;

    /// How many times the notification prompt was denied (drives the one re-ask).
    final int deniedCount;

    static const initial = PermissionState(
      notifications: PermissionStatus.notDetermined,
      exactAlarm: PermissionStatus.notDetermined,
      deniedCount: 0,
    );

    bool get askedOnce => notifications != PermissionStatus.notDetermined;

    /// Provisional/limited and full grant both allow scheduling.
    bool get canSchedule =>
        notifications == PermissionStatus.granted ||
        notifications == PermissionStatus.limited;

    /// We may still call the OS prompt: never asked, or denied exactly once.
    bool get canRequestNotifications =>
        notifications == PermissionStatus.notDetermined ||
        (notifications == PermissionStatus.denied && deniedCount < 2);

    PermissionState afterNotificationResult(PermissionStatus result) {
      // Two denials => treat as permanently denied (OS stops prompting anyway).
      final nextDenied =
          result == PermissionStatus.denied ? deniedCount + 1 : deniedCount;
      final status = (result == PermissionStatus.denied && nextDenied >= 2)
          ? PermissionStatus.permanentlyDenied
          : result;
      return PermissionState(
        notifications: status,
        exactAlarm: exactAlarm,
        deniedCount: nextDenied,
      );
    }

    PermissionState afterExactAlarmResult(PermissionStatus result) =>
        PermissionState(
          notifications: notifications,
          exactAlarm: result,
          deniedCount: deniedCount,
        );

    Map<String, Object?> toJson() => {
          'notif': notifications.name,
          'exact': exactAlarm.name,
          'deniedCount': deniedCount,
        };

    factory PermissionState.fromJson(Map<String, Object?> j) => PermissionState(
          notifications: PermissionStatus.values
              .byName((j['notif'] as String?) ?? 'notDetermined'),
          exactAlarm: PermissionStatus.values
              .byName((j['exact'] as String?) ?? 'notDetermined'),
          deniedCount: (j['deniedCount'] as int?) ?? 0,
        );
  }
  ```
- [ ] Run (expect PASS): `flutter test test/core/notifications/permission_state_test.dart` → 6 pass.
- [ ] Run `flutter analyze` (expect clean).
- [ ] Commit:
  ```
  git add app/lib/core/notifications/permission_state.dart app/test/core/notifications/permission_state_test.dart
  git commit -m "Add notification + exact-alarm permission state machine

  Models notDetermined/granted/limited/denied/permanentlyDenied with a one
  gentle re-ask budget; limited (iOS provisional) is schedulable; JSON-persisted.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 6 — Double-fire guard (prefs-backed, atomic claim)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\double_fire_guard.dart` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\notifications\double_fire_guard_test.dart` (NEW)

- [ ] Write the failing test `double_fire_guard_test.dart` (uses the project's `SharedPreferences` mock
  pattern from `new_states_test.dart`):
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/notifications/double_fire_guard.dart';

  void main() {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('first claim wins, second for same key is a no-op', () async {
      final prefs = await SharedPreferences.getInstance();
      final guard = DoubleFireGuard(prefs);
      final now = DateTime(2026, 6, 1, 6, 30);
      expect(guard.claim('standardAlarm:a1:2026-06-01-06-30', now), isTrue);
      expect(guard.claim('standardAlarm:a1:2026-06-01-06-30', now), isFalse);
    });

    test('different minutes are independent claims', () async {
      final prefs = await SharedPreferences.getInstance();
      final guard = DoubleFireGuard(prefs);
      final now = DateTime(2026, 6, 1, 6, 30);
      expect(guard.claim('standardAlarm:a1:2026-06-01-06-30', now), isTrue);
      expect(guard.claim('standardAlarm:a1:2026-06-01-06-31', now), isTrue);
    });

    test('claims persist across guard instances (same prefs)', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime(2026, 6, 1, 6, 30);
      expect(DoubleFireGuard(prefs).claim('k', now), isTrue);
      expect(DoubleFireGuard(prefs).claim('k', now), isFalse); // remembered
    });

    test('claims older than 24h are pruned on the next claim', () async {
      final prefs = await SharedPreferences.getInstance();
      final guard = DoubleFireGuard(prefs);
      final old = DateTime(2026, 6, 1, 6, 30);
      guard.claim('old-key', old);
      // 25h later, a new claim prunes the stale entry; re-claiming old-key works.
      final later = old.add(const Duration(hours: 25));
      guard.claim('fresh', later);
      expect(guard.claim('old-key', later), isTrue); // pruned -> claimable again
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/core/notifications/double_fire_guard_test.dart`.
- [ ] Minimal implementation `double_fire_guard.dart`:
  ```dart
  import 'dart:convert';

  import 'package:shared_preferences/shared_preferences.dart';

  /// Collapses the foreground (AlarmHost/EyeCareHost) and background (OS
  /// notification) firing paths into a single logical fire per alarm-minute.
  ///
  /// Stored as a JSON map { guardKey -> claimedAtMillis } so claims survive a
  /// process restart (the OS may deliver a notification while the app is dead,
  /// then the user opens the app within the same minute). Entries older than 24h
  /// are pruned on every claim.
  class DoubleFireGuard {
    DoubleFireGuard(this._prefs);

    final SharedPreferences _prefs;
    static const _key = 'tarf.fire_guard.v1';
    static const _ttl = Duration(hours: 24);

    Map<String, int> _read() {
      final raw = _prefs.getString(_key);
      if (raw == null) return {};
      try {
        return (jsonDecode(raw) as Map<String, Object?>)
            .map((k, v) => MapEntry(k, v as int));
      } catch (_) {
        return {};
      }
    }

    /// Atomically claims [guardKey] as of [now]. Returns true if THIS caller is
    /// the first to claim it (and should proceed to ring/show); false if it was
    /// already claimed (caller must do nothing).
    bool claim(String guardKey, DateTime now) {
      final map = _read();
      final cutoff = now.subtract(_ttl).millisecondsSinceEpoch;
      map.removeWhere((_, ms) => ms < cutoff); // prune stale
      final already = map.containsKey(guardKey);
      if (!already) map[guardKey] = now.millisecondsSinceEpoch;
      // Persist (prune + possible insert). Fire-and-forget; read path is sync.
      _prefs.setString(_key, jsonEncode(map));
      return !already;
    }
  }
  ```
- [ ] Run (expect PASS): `flutter test test/core/notifications/double_fire_guard_test.dart` → 4 pass.
- [ ] Run `flutter analyze` (expect clean).
- [ ] Commit:
  ```
  git add app/lib/core/notifications/double_fire_guard.dart app/test/core/notifications/double_fire_guard_test.dart
  git commit -m "Add prefs-backed DoubleFireGuard with atomic minute claims

  First caller to claim a kind:id:minute key wins; later callers no-op. Persists
  across restarts, prunes >24h entries. Collapses foreground + OS paths.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 7 — Wire the guard into the foreground hosts (no double fire)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\double_fire_guard.dart` (MODIFY — add provider)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\alarm\presentation\alarm_host.dart` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\application\eyecare_engine.dart` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\alarm\alarm_host_guard_test.dart` (NEW)

- [ ] Add a provider for the guard at the bottom of `double_fire_guard.dart`:
  ```dart
  // append to double_fire_guard.dart
  // (import at top:)
  // import 'package:flutter_riverpod/flutter_riverpod.dart';
  // import '../settings/settings_controller.dart';

  final doubleFireGuardProvider = Provider<DoubleFireGuard>(
    (ref) => DoubleFireGuard(ref.watch(sharedPreferencesProvider)),
  );
  ```
- [ ] Write the failing test `alarm_host_guard_test.dart` — assert that when the guard has ALREADY
  claimed an alarm's current-minute key, `AlarmHost` does NOT present the ringing modal:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/notifications/double_fire_guard.dart';
  import 'package:tarf/core/settings/settings_controller.dart';
  import 'package:tarf/features/alarm/application/alarms_controller.dart';
  import 'package:tarf/features/alarm/domain/alarm_item.dart';
  import 'package:tarf/features/alarm/presentation/alarm_host.dart';
  import 'package:tarf/features/alarm/presentation/alarm_ringing_screen.dart';
  import 'package:tarf/l10n/app_localizations.dart';
  import 'package:tarf/theme/app_theme.dart';

  Widget _app(SharedPreferences prefs) => ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: TarfTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AlarmHost(child: Scaffold(body: SizedBox.expand())),
        ),
      );

  void main() {
    testWidgets('AlarmHost does not ring when the minute is already claimed',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await tester.pumpWidget(_app(prefs));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AlarmHost)),
      );

      // An enabled alarm scheduled for THIS minute.
      await container.read(alarmsControllerProvider.notifier).upsert(
            AlarmItem(id: 'a1', hour: now.hour, minute: now.minute),
          );
      // The background path already claimed this minute.
      final item = const AlarmItem(id: 'a1', hour: 0, minute: 0);
      final key = 'standardAlarm:a1:'
          '${now.year}-${now.month.toString().padLeft(2, '0')}'
          '-${now.day.toString().padLeft(2, '0')}'
          '-${now.hour.toString().padLeft(2, '0')}'
          '-${now.minute.toString().padLeft(2, '0')}';
      container.read(doubleFireGuardProvider).claim(key, now);

      // Drive the host's 10s poll a few times.
      await tester.pump(const Duration(seconds: 11));
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
      await tester.pump();

      // The ringing modal must NOT have been pushed.
      expect(find.byType(AlarmRingingScreen), findsNothing);
      // (Use `item` to avoid unused: assert the key matches its own helper.)
      expect(item.id, 'a1');
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/features/alarm/alarm_host_guard_test.dart` → the modal
  appears because the host does not yet consult the guard.
- [ ] Minimal edit to `alarm_host.dart`: import the guard + `ScheduledItem`, and in `_ring(...)`
  (the single choke point all three firing branches funnel through) claim the key BEFORE pushing.
  Edit the top of `_ring`:
  ```dart
  // add imports at top of alarm_host.dart:
  // import '../../../core/notifications/double_fire_guard.dart';
  // import '../../../core/notifications/scheduled_item.dart';

  Future<void> _ring(AlarmItem item, DateTime now) async {
    if (_ringing || !mounted) return;

    // Double-fire guard: if the OS notification path already claimed this
    // alarm-minute (app was woken/opened around delivery), do not also ring.
    final kind = item.id.startsWith('prayer_')
        ? ScheduledKind.prayerAlarm
        : ScheduledKind.standardAlarm;
    final guardId = item.id.startsWith('prayer_')
        ? item.id.substring('prayer_'.length)
        : item.id;
    final key = ScheduledItem(
      kind: kind, id: guardId, title: item.label, body: '', soundId: item.sound,
    ).guardKeyFor(DateTime(now.year, now.month, now.day, now.hour, now.minute));
    if (!ref.read(doubleFireGuardProvider).claim(key, now)) {
      return; // already fired via the OS path this minute
    }

    _ringing = true;
    final navigator = Navigator.of(context, rootNavigator: true);
    // ... rest unchanged ...
  ```
- [ ] Minimal edit to `eyecare_engine.dart`: before `_breakShowing = true; await showEyeBreak(...)`,
  claim the eye-break minute. Insert just before `_breakShowing = true;`:
  ```dart
  // add imports:
  // import '../../../core/notifications/double_fire_guard.dart';
  // import '../../../core/notifications/scheduled_item.dart';

  // inside _onTick(), right after `if (decideBreak(state) != BreakDecision.fire) return;`
  final guardKey = const ScheduledItem(
    kind: ScheduledKind.eyeBreak, id: 'eye', title: '', body: '',
    soundId: 'default',
  ).guardKeyFor(DateTime(now.year, now.month, now.day, now.hour, now.minute));
  if (!ref.read(doubleFireGuardProvider).claim(guardKey, now)) return;

  _breakShowing = true;
  ```
- [ ] Run (expect PASS): `flutter test test/features/alarm/alarm_host_guard_test.dart`.
- [ ] Run the FULL suite (expect PASS — existing `new_states_test.dart` alarm-modal test still passes
  because in that test no key is pre-claimed): `flutter test`.
- [ ] Run `flutter analyze` (expect clean).
- [ ] Commit:
  ```
  git add app/lib/core/notifications/double_fire_guard.dart app/lib/features/alarm/presentation/alarm_host.dart app/lib/features/eyecare/application/eyecare_engine.dart app/test/features/alarm/alarm_host_guard_test.dart
  git commit -m "Guard foreground ring/overlay against OS double-fire

  AlarmHost._ring and EyeCareHost._onTick now claim the minute key before
  presenting; if the OS path already claimed it, the foreground path no-ops.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 8 — `NotificationGateway` interface + `FakeNotificationGateway`

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\notification_gateway.dart` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\notifications\notification_service_test.dart`
  (NEW — starts here; exercised against the fake)

- [ ] Write a first failing test in `notification_service_test.dart` that pins the gateway contract
  (the service itself comes in Task 9; here we assert the fake records correctly):
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:tarf/core/notifications/notification_gateway.dart';
  import 'package:tarf/core/notifications/permission_state.dart';
  import 'package:tarf/core/notifications/scheduled_item.dart';

  void main() {
    group('FakeNotificationGateway', () {
      test('records scheduled items and can cancel by notificationId', () async {
        final g = FakeNotificationGateway();
        const item = ScheduledItem(
          kind: ScheduledKind.standardAlarm, id: 'a1', title: 'Wake', body: '',
          soundId: 'bell');
        final at = DateTime(2026, 6, 1, 6, 30);
        await g.schedule(item, at);
        expect(g.scheduled.single.$1.id, 'a1');
        expect(g.scheduled.single.$2, at);

        await g.cancel(item.notificationId);
        expect(g.scheduled, isEmpty);
      });

      test('cancelAll clears everything', () async {
        final g = FakeNotificationGateway();
        await g.schedule(const ScheduledItem(
          kind: ScheduledKind.prayerAlarm, id: 'fajr', title: 'F', body: '',
          soundId: 'default'), DateTime(2026, 6, 1, 4, 10));
        await g.cancelAll();
        expect(g.scheduled, isEmpty);
      });

      test('permission requests return the programmed result', () async {
        final g = FakeNotificationGateway(
          notificationResult: PermissionStatus.granted,
          exactAlarmResult: PermissionStatus.denied,
        );
        expect(await g.requestNotificationPermission(), PermissionStatus.granted);
        expect(await g.requestExactAlarmPermission(), PermissionStatus.denied);
        expect(g.notificationRequests, 1);
      });
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/core/notifications/notification_service_test.dart`.
- [ ] Minimal implementation `notification_gateway.dart`:
  ```dart
  import 'permission_state.dart';
  import 'scheduled_item.dart';

  /// The ONLY impure surface in Phase 2. Wraps flutter_local_notifications +
  /// android_alarm_manager_plus + permission plugins so all scheduling logic is
  /// unit-testable against [FakeNotificationGateway].
  abstract interface class NotificationGateway {
    /// Create channels (Android), set up tz, register tap handlers. Idempotent.
    Future<void> init();

    /// Schedule [item] to fire at [fireAt] (local wall-clock). Overwrites any
    /// prior schedule with the same notificationId.
    Future<void> schedule(ScheduledItem item, DateTime fireAt);

    /// Cancel a single scheduled notification by its [notificationId].
    Future<void> cancel(int notificationId);

    /// Cancel everything Tarf scheduled.
    Future<void> cancelAll();

    /// Current OS notification authorization (queried, not requested).
    Future<PermissionStatus> queryNotificationPermission();

    /// Show the OS notification permission prompt; returns the result.
    Future<PermissionStatus> requestNotificationPermission();

    /// Android 12+ exact-alarm consent. Non-Android returns granted (n/a).
    Future<PermissionStatus> requestExactAlarmPermission();

    /// Android 12+ exact-alarm capability check (canScheduleExactAlarms).
    Future<PermissionStatus> queryExactAlarmPermission();
  }

  /// In-memory test double. Records calls; programmable permission results.
  class FakeNotificationGateway implements NotificationGateway {
    FakeNotificationGateway({
      this.notificationResult = PermissionStatus.granted,
      this.exactAlarmResult = PermissionStatus.granted,
    });

    PermissionStatus notificationResult;
    PermissionStatus exactAlarmResult;

    final List<(ScheduledItem, DateTime)> scheduled = [];
    int initCount = 0;
    int notificationRequests = 0;
    int exactAlarmRequests = 0;
    int cancelAllCount = 0;

    @override
    Future<void> init() async => initCount++;

    @override
    Future<void> schedule(ScheduledItem item, DateTime fireAt) async {
      scheduled
        ..removeWhere((e) => e.$1.notificationId == item.notificationId)
        ..add((item, fireAt));
    }

    @override
    Future<void> cancel(int notificationId) async =>
        scheduled.removeWhere((e) => e.$1.notificationId == notificationId);

    @override
    Future<void> cancelAll() async {
      cancelAllCount++;
      scheduled.clear();
    }

    @override
    Future<PermissionStatus> queryNotificationPermission() async =>
        notificationResult;

    @override
    Future<PermissionStatus> requestNotificationPermission() async {
      notificationRequests++;
      return notificationResult;
    }

    @override
    Future<PermissionStatus> requestExactAlarmPermission() async {
      exactAlarmRequests++;
      return exactAlarmResult;
    }

    @override
    Future<PermissionStatus> queryExactAlarmPermission() async =>
        exactAlarmResult;
  }
  ```
- [ ] Run (expect PASS): `flutter test test/core/notifications/notification_service_test.dart` → 3 pass.
- [ ] Run `flutter analyze` (expect clean).
- [ ] Commit:
  ```
  git add app/lib/core/notifications/notification_gateway.dart app/test/core/notifications/notification_service_test.dart
  git commit -m "Add NotificationGateway interface + in-memory fake

  Single impure seam over flutter_local_notifications/aam/permissions; records
  schedules and cancels and returns programmable permission results for tests.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 9 — `NotificationService` orchestrator (schedule / reschedule / cancel)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\notification_service.dart` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\notifications\notification_service_test.dart` (MODIFY — add orchestration tests)

This is the heart of the phase. The service builds the **desired set** of `ScheduledItem`s from the
three sources, computes each one's next fire, and reconciles with the gateway. It exposes a Riverpod
`Notifier<bool>` (value = "background scheduling active"). Permission is injected via a
`PermissionState` read from a `permissionStateProvider` (added in this task too).

- [ ] Add orchestration tests to `notification_service_test.dart`:
  ```dart
  // add imports:
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/notifications/notification_service.dart';
  import 'package:tarf/core/settings/settings_controller.dart';
  import 'package:tarf/features/alarm/application/alarms_controller.dart';
  import 'package:tarf/features/eyecare/application/eyecare_config_controller.dart';
  import 'package:tarf/features/eyecare/domain/eyecare_config.dart';

  ProviderContainer _container(
    SharedPreferences prefs,
    FakeNotificationGateway gateway,
  ) =>
      ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationGatewayProvider.overrideWithValue(gateway),
      ]);

  // ... inside main(), new group:
  group('NotificationService.reconcile', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('no scheduling when notifications not granted', () async {
      final g = FakeNotificationGateway(
          notificationResult: PermissionStatus.denied);
      final c = _container(prefs, g);
      addTearDown(c.dispose);
      await c.read(alarmsControllerProvider.notifier)
          .upsert(const AlarmItem(id: 'a1', hour: 9, minute: 0));
      // Permission state denied.
      await c.read(notificationServiceProvider.notifier).reconcile();
      expect(g.scheduled, isEmpty);
    });

    test('schedules one enabled standard alarm at its next fire', () async {
      final g = FakeNotificationGateway();
      final c = _container(prefs, g);
      addTearDown(c.dispose);
      c.read(permissionStateProvider.notifier)
          .setForTest(PermissionState.initial
              .afterNotificationResult(PermissionStatus.granted));
      await c.read(alarmsControllerProvider.notifier)
          .upsert(const AlarmItem(id: 'a1', hour: 9, minute: 0, days: {1,2,3,4,5}));
      await c.read(notificationServiceProvider.notifier).reconcile();
      expect(g.scheduled.length, 1);
      expect(g.scheduled.single.$1.id, 'a1');
      expect(g.scheduled.single.$1.kind, ScheduledKind.standardAlarm);
    });

    test('disabled alarms are not scheduled; toggling reschedules', () async {
      final g = FakeNotificationGateway();
      final c = _container(prefs, g);
      addTearDown(c.dispose);
      c.read(permissionStateProvider.notifier)
          .setForTest(PermissionState.initial
              .afterNotificationResult(PermissionStatus.granted));
      await c.read(alarmsControllerProvider.notifier).upsert(
          const AlarmItem(id: 'a1', hour: 9, minute: 0, enabled: false));
      await c.read(notificationServiceProvider.notifier).reconcile();
      expect(g.scheduled, isEmpty);

      await c.read(alarmsControllerProvider.notifier).toggle('a1');
      await c.read(notificationServiceProvider.notifier).reconcile();
      expect(g.scheduled.length, 1);
    });

    test('reconcile is idempotent (cancelAll then reschedule)', () async {
      final g = FakeNotificationGateway();
      final c = _container(prefs, g);
      addTearDown(c.dispose);
      c.read(permissionStateProvider.notifier)
          .setForTest(PermissionState.initial
              .afterNotificationResult(PermissionStatus.granted));
      await c.read(alarmsControllerProvider.notifier)
          .upsert(const AlarmItem(id: 'a1', hour: 9, minute: 0));
      await c.read(notificationServiceProvider.notifier).reconcile();
      await c.read(notificationServiceProvider.notifier).reconcile();
      expect(g.scheduled.length, 1); // not doubled
      expect(g.cancelAllCount, 2); // each reconcile clears then rebuilds
    });

    test('enabled prayer alarms are scheduled by kind prayerAlarm', () async {
      final g = FakeNotificationGateway();
      final c = _container(prefs, g);
      addTearDown(c.dispose);
      c.read(permissionStateProvider.notifier)
          .setForTest(PermissionState.initial
              .afterNotificationResult(PermissionStatus.granted));
      // Default config enables all five prayers.
      await c.read(eyeCareConfigProvider.notifier)
          .update(const EyeCareConfig());
      await c.read(notificationServiceProvider.notifier).reconcile();
      final prayerCount = g.scheduled
          .where((e) => e.$1.kind == ScheduledKind.prayerAlarm)
          .length;
      expect(prayerCount, greaterThanOrEqualTo(1)); // at least the next one today
    });
  });
  ```
- [ ] Run (expect FAIL): `flutter test test/core/notifications/notification_service_test.dart`.
- [ ] Minimal implementation `notification_service.dart`:
  ```dart
  import 'dart:convert';

  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../features/alarm/application/alarms_controller.dart';
  import '../../features/alarm/domain/alarm_item.dart';
  import '../../features/eyecare/application/alarm_derived_imports.dart'
      if (dart.library.io) '../../features/eyecare/application/alarm_derived_imports.dart';
  import '../../features/eyecare/application/eyecare_config_controller.dart';
  import '../../features/eyecare/core/prayer_service.dart';
  import '../settings/settings_controller.dart';
  import 'next_fire.dart';
  import 'notification_gateway.dart';
  import 'permission_state.dart';
  import 'scheduled_item.dart';

  /// Injected gateway. main() overrides with FlutterNotificationGateway; tests
  /// override with FakeNotificationGateway.
  final notificationGatewayProvider = Provider<NotificationGateway>(
    (ref) => throw UnimplementedError('notificationGatewayProvider must be overridden'),
  );

  /// Persisted permission snapshot. Updated by the priming flow (Task 11).
  class PermissionStateController extends Notifier<PermissionState> {
    static const _key = 'tarf.permissions.v1';

    @override
    PermissionState build() {
      final raw = ref.watch(sharedPreferencesProvider).getString(_key);
      if (raw == null) return PermissionState.initial;
      try {
        return PermissionState.fromJson(jsonDecode(raw) as Map<String, Object?>);
      } catch (_) {
        return PermissionState.initial;
      }
    }

    Future<void> _persist(PermissionState next) async {
      state = next;
      await ref.read(sharedPreferencesProvider)
          .setString(_key, jsonEncode(next.toJson()));
    }

    Future<void> recordNotificationResult(PermissionStatus r) =>
        _persist(state.afterNotificationResult(r));

    Future<void> recordExactAlarmResult(PermissionStatus r) =>
        _persist(state.afterExactAlarmResult(r));

    /// Test seam (synchronous, no I/O wait needed in unit tests).
    void setForTest(PermissionState s) => state = s;
  }

  final permissionStateProvider =
      NotifierProvider<PermissionStateController, PermissionState>(
          PermissionStateController.new);

  /// Orchestrates OS scheduling. Value = whether background scheduling is active
  /// (permission granted/limited). Call [reconcile] after any alarm/config change.
  class NotificationService extends Notifier<bool> {
    @override
    bool build() => false;

    NotificationGateway get _gateway => ref.read(notificationGatewayProvider);

    /// Build the desired set of items from the three sources.
    List<(ScheduledItem, DateTime)> _desired(DateTime now) {
      final out = <(ScheduledItem, DateTime)>[];
      final alarms = ref.read(alarmsControllerProvider);
      for (final a in alarms) {
        if (!a.enabled) continue;
        final at = NextFire.standard(a, now);
        out.add((
          ScheduledItem(
            kind: ScheduledKind.standardAlarm,
            id: a.id,
            title: a.label.isEmpty ? 'Alarm' : a.label,
            body: '',
            soundId: a.sound,
          ),
          at,
        ));
      }
      final cfg = ref.read(eyeCareConfigProvider);
      if (cfg.prayerAlarmsEnabled.isNotEmpty) {
        final times = PrayerService.timesFor(
          latitude: cfg.prayerLatitude,
          longitude: cfg.prayerLongitude,
          day: now,
          method: cfg.prayerMethod,
          madhab: cfg.prayerMadhab,
        );
        const ids = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
        for (var i = 0; i < ids.length && i < times.length; i++) {
          if (!cfg.prayerAlarmsEnabled.contains(ids[i])) continue;
          var at = times[i];
          if (!at.isAfter(now)) {
            // Today's passed; schedule tomorrow's computed time.
            final tomorrow = now.add(const Duration(days: 1));
            final t2 = PrayerService.timesFor(
              latitude: cfg.prayerLatitude,
              longitude: cfg.prayerLongitude,
              day: tomorrow,
              method: cfg.prayerMethod,
              madhab: cfg.prayerMadhab,
            );
            at = t2[i];
          }
          out.add((
            ScheduledItem(
              kind: ScheduledKind.prayerAlarm,
              id: ids[i],
              title: ids[i],
              body: '',
              soundId: 'default',
            ),
            at,
          ));
        }
      }
      return out;
    }

    /// Cancel everything and reschedule the desired set. Honest: only schedules
    /// if the user has granted/limited notification permission.
    Future<void> reconcile() async {
      final perm = ref.read(permissionStateProvider);
      await _gateway.cancelAll();
      if (!perm.canSchedule) {
        state = false;
        return;
      }
      final now = DateTime.now();
      for (final (item, at) in _desired(now)) {
        await _gateway.schedule(item, at);
      }
      state = true;
    }
  }

  final notificationServiceProvider =
      NotifierProvider<NotificationService, bool>(NotificationService.new);
  ```
  NOTE for the worker: drop the bogus conditional-import line — it is illustrative only. The real
  imports needed are exactly: `alarms_controller.dart`, `alarm_item.dart`,
  `eyecare_config_controller.dart`, `prayer_service.dart`, `settings_controller.dart`, plus the four
  `core/notifications/*` files. Use the prayer-id list inline as shown (do not import
  `alarm_derived.dart` to avoid a provider cycle).
- [ ] Run (expect PASS): `flutter test test/core/notifications/notification_service_test.dart` → all pass.
- [ ] Run the FULL suite (expect PASS): `flutter test`.
- [ ] Run `flutter analyze` (expect clean).
- [ ] Commit:
  ```
  git add app/lib/core/notifications/notification_service.dart app/test/core/notifications/notification_service_test.dart
  git commit -m "Add NotificationService: build + reconcile desired schedule

  Builds ScheduledItems from standard alarms, enabled prayers (today/tomorrow),
  computes next fire, cancels-all then reschedules. Honest: only when permitted.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 10 — Auto-reschedule on any alarm/config change + cancel on disable/delete

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\notification_service.dart` (MODIFY — add `listenForChanges`)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\notifications\notification_service_test.dart` (MODIFY)

- [ ] Add tests proving that wiring `listenForChanges` triggers `reconcile` automatically when alarms or
  config change:
  ```dart
  // add to the reconcile group:
  test('listenForChanges reschedules when an alarm is added', () async {
    final g = FakeNotificationGateway();
    final c = _container(prefs, g);
    addTearDown(c.dispose);
    c.read(permissionStateProvider.notifier).setForTest(PermissionState.initial
        .afterNotificationResult(PermissionStatus.granted));
    c.read(notificationServiceProvider.notifier).listenForChanges();
    await c.read(alarmsControllerProvider.notifier)
        .upsert(const AlarmItem(id: 'a1', hour: 9, minute: 0));
    await Future<void>.delayed(Duration.zero); // let listeners flush
    expect(g.scheduled.length, 1);
  });

  test('removing an alarm cancels its schedule on next reconcile', () async {
    final g = FakeNotificationGateway();
    final c = _container(prefs, g);
    addTearDown(c.dispose);
    c.read(permissionStateProvider.notifier).setForTest(PermissionState.initial
        .afterNotificationResult(PermissionStatus.granted));
    c.read(notificationServiceProvider.notifier).listenForChanges();
    await c.read(alarmsControllerProvider.notifier)
        .upsert(const AlarmItem(id: 'a1', hour: 9, minute: 0));
    await Future<void>.delayed(Duration.zero);
    expect(g.scheduled.length, 1);
    await c.read(alarmsControllerProvider.notifier).remove('a1');
    await Future<void>.delayed(Duration.zero);
    expect(g.scheduled, isEmpty);
  });
  ```
- [ ] Run (expect FAIL): `flutter test test/core/notifications/notification_service_test.dart` →
  `listenForChanges` missing.
- [ ] Minimal edit to `notification_service.dart` — add inside `NotificationService`:
  ```dart
  bool _listening = false;

  /// Subscribe to the three scheduling inputs; reconcile on any change. Also
  /// reconciles when permission becomes granted. Call once from main() after init.
  void listenForChanges() {
    if (_listening) return;
    _listening = true;
    ref.listen(alarmsControllerProvider, (_, __) => reconcile());
    ref.listen(eyeCareConfigProvider, (_, __) => reconcile());
    ref.listen(permissionStateProvider, (_, __) => reconcile());
  }
  ```
- [ ] Run (expect PASS): `flutter test test/core/notifications/notification_service_test.dart`.
- [ ] Run the FULL suite (expect PASS): `flutter test`.
- [ ] Run `flutter analyze` (expect clean).
- [ ] Commit:
  ```
  git add app/lib/core/notifications/notification_service.dart app/test/core/notifications/notification_service_test.dart
  git commit -m "Auto-reschedule on alarm/config/permission changes

  listenForChanges() wires ref.listen on the three scheduling inputs so add/
  edit/toggle/delete and permission grants reconcile the OS schedule.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 11 — Background capability descriptor + honest degraded status provider (for Phase 3)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\background_capability.dart` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\background_delivery_status.dart` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\notifications\background_delivery_status_test.dart` (NEW)

- [ ] Write the failing test `background_delivery_status_test.dart`:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/notifications/background_capability.dart';
  import 'package:tarf/core/notifications/background_delivery_status.dart';
  import 'package:tarf/core/notifications/notification_service.dart';
  import 'package:tarf/core/notifications/permission_state.dart';
  import 'package:tarf/core/settings/settings_controller.dart';

  void main() {
    group('BackgroundCapability', () {
      test('android claims exact-capable background delivery', () {
        const cap = BackgroundCapability.android;
        expect(cap.deliversWhenClosed, isTrue);
        expect(cap.supportsExactAlarms, isTrue);
      });
      test('web only delivers while the tab is open', () {
        const cap = BackgroundCapability.web;
        expect(cap.deliversWhenClosed, isFalse);
        expect(cap.supportsExactAlarms, isFalse);
      });
      test('ios delivers when closed but without exact alarms', () {
        const cap = BackgroundCapability.ios;
        expect(cap.deliversWhenClosed, isTrue);
        expect(cap.supportsExactAlarms, isFalse);
      });
    });

    group('backgroundDeliveryStatusProvider', () {
      late SharedPreferences prefs;
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      });

      ProviderContainer build(BackgroundCapability cap) => ProviderContainer(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              platformCapabilityProvider.overrideWithValue(cap),
            ],
          );

      test('degraded when notifications denied even on capable platform', () {
        final c = build(BackgroundCapability.android);
        addTearDown(c.dispose);
        c.read(permissionStateProvider.notifier).setForTest(
            PermissionState.initial
                .afterNotificationResult(PermissionStatus.denied));
        final status = c.read(backgroundDeliveryStatusProvider);
        expect(status.isDegraded, isTrue);
        expect(status.reason, DegradedReason.notificationsDenied);
      });

      test('degraded (foreground-only) on web regardless of permission', () {
        final c = build(BackgroundCapability.web);
        addTearDown(c.dispose);
        c.read(permissionStateProvider.notifier).setForTest(
            PermissionState.initial
                .afterNotificationResult(PermissionStatus.granted));
        final status = c.read(backgroundDeliveryStatusProvider);
        expect(status.isDegraded, isTrue);
        expect(status.reason, DegradedReason.platformForegroundOnly);
      });

      test('not degraded on android with granted notifications + exact alarm',
          () {
        final c = build(BackgroundCapability.android);
        addTearDown(c.dispose);
        c.read(permissionStateProvider.notifier).setForTest(
            PermissionState.initial
                .afterNotificationResult(PermissionStatus.granted)
                .afterExactAlarmResult(PermissionStatus.granted));
        final status = c.read(backgroundDeliveryStatusProvider);
        expect(status.isDegraded, isFalse);
        expect(status.reason, isNull);
      });

      test('inexact on android when exact-alarm denied is a soft degrade', () {
        final c = build(BackgroundCapability.android);
        addTearDown(c.dispose);
        c.read(permissionStateProvider.notifier).setForTest(
            PermissionState.initial
                .afterNotificationResult(PermissionStatus.granted)
                .afterExactAlarmResult(PermissionStatus.denied));
        final status = c.read(backgroundDeliveryStatusProvider);
        expect(status.isDegraded, isTrue);
        expect(status.reason, DegradedReason.exactAlarmDenied);
      });
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/core/notifications/background_delivery_status_test.dart`.
- [ ] Minimal implementation `background_capability.dart`:
  ```dart
  import 'package:flutter/foundation.dart';

  /// What a platform can honestly do for background delivery. Drives the degraded
  /// banner (Phase 3) — we never claim more than the OS provides.
  class BackgroundCapability {
    const BackgroundCapability({
      required this.deliversWhenClosed,
      required this.supportsExactAlarms,
    });

    /// Can a scheduled reminder fire when the app/tab is fully closed?
    final bool deliversWhenClosed;

    /// Exact (Doze-piercing) alarms available? Android only.
    final bool supportsExactAlarms;

    static const android =
        BackgroundCapability(deliversWhenClosed: true, supportsExactAlarms: true);
    static const ios =
        BackgroundCapability(deliversWhenClosed: true, supportsExactAlarms: false);
    static const macos =
        BackgroundCapability(deliversWhenClosed: true, supportsExactAlarms: false);
    static const windows =
        BackgroundCapability(deliversWhenClosed: true, supportsExactAlarms: false);

    /// Web/extension: only while the tab/worker is alive. We do NOT pretend.
    static const web =
        BackgroundCapability(deliversWhenClosed: false, supportsExactAlarms: false);

    /// The capability for the platform this build runs on.
    static BackgroundCapability detect() {
      if (kIsWeb) return web;
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return android;
        case TargetPlatform.iOS:
          return ios;
        case TargetPlatform.macOS:
          return macos;
        case TargetPlatform.windows:
          return windows;
        default:
          return web; // conservative: assume foreground-only
      }
    }
  }
  ```
- [ ] Minimal implementation `background_delivery_status.dart`:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import 'background_capability.dart';
  import 'notification_service.dart';
  import 'permission_state.dart';

  /// Why background delivery is degraded (null = not degraded).
  enum DegradedReason {
    /// Platform cannot deliver when closed (web/extension) — foreground only.
    platformForegroundOnly,

    /// User denied/never granted notifications.
    notificationsDenied,

    /// Notifications granted but exact-alarm consent denied (timing may drift).
    exactAlarmDenied,
  }

  /// The honest background-delivery status Phase 3's banner renders.
  class BackgroundDeliveryStatus {
    const BackgroundDeliveryStatus({required this.reason});

    /// null when delivery is fully reliable on this platform.
    final DegradedReason? reason;

    bool get isDegraded => reason != null;
  }

  /// Overridable so tests pin a platform; defaults to runtime detection.
  final platformCapabilityProvider = Provider<BackgroundCapability>(
    (ref) => BackgroundCapability.detect(),
  );

  /// Combines platform capability + permission state into a single honest status.
  final backgroundDeliveryStatusProvider =
      Provider<BackgroundDeliveryStatus>((ref) {
    final cap = ref.watch(platformCapabilityProvider);
    final perm = ref.watch(permissionStateProvider);

    // 1) Platform can't deliver when closed -> foreground-only, always degraded.
    if (!cap.deliversWhenClosed) {
      return const BackgroundDeliveryStatus(
          reason: DegradedReason.platformForegroundOnly);
    }
    // 2) Notifications not usable -> degraded.
    if (!perm.canSchedule) {
      return const BackgroundDeliveryStatus(
          reason: DegradedReason.notificationsDenied);
    }
    // 3) Exact alarms supported but consent denied -> soft (timing) degrade.
    if (cap.supportsExactAlarms &&
        (perm.exactAlarm == PermissionStatus.denied ||
            perm.exactAlarm == PermissionStatus.permanentlyDenied)) {
      return const BackgroundDeliveryStatus(
          reason: DegradedReason.exactAlarmDenied);
    }
    return const BackgroundDeliveryStatus(reason: null);
  });
  ```
- [ ] Run (expect PASS): `flutter test test/core/notifications/background_delivery_status_test.dart` → all pass.
- [ ] Run `flutter analyze` (expect clean).
- [ ] Commit:
  ```
  git add app/lib/core/notifications/background_capability.dart app/lib/core/notifications/background_delivery_status.dart app/test/core/notifications/background_delivery_status_test.dart
  git commit -m "Expose honest per-platform background-delivery status for Phase 3

  BackgroundCapability per platform + backgroundDeliveryStatusProvider that
  reports platformForegroundOnly / notificationsDenied / exactAlarmDenied.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 12 — l10n copy for priming + degraded states (AR + EN)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\l10n\app_en.arb` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\l10n\app_ar.arb` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\notifications\background_delivery_status_test.dart` (no change)

Copy is taken verbatim from `docs/compliance/permissions-matrix.md` §A/§D so the app and store stay
consistent. Western digits; plain `{}` placeholders not needed here.

- [ ] Add keys to `app_en.arb` (insert after the `"alarmNativeNote"` line):
  ```json
  "notifPrimingTitle": "Break reminders",
  "notifPrimingBody": "To remind you to rest your eyes even when Tarf is closed, we need notification permission. Without it, Tarf reminds you only while open.",
  "exactAlarmPrimingBody": "So your alarm rings at the exact time, Tarf needs the ‘exact alarms’ permission.",
  "permEnable": "Enable",
  "permNotNow": "Not now",
  "permOpenSettings": "Open settings",
  "bgRemindersOff": "Background reminders off — Tarf will only remind you while it's open.",
  "bgForegroundOnlyPlatform": "On this platform, reminders fire only while Tarf is open.",
  "bgExactAlarmOff": "Reminders may arrive a few minutes late — enable exact alarms for precise timing.",
  "bgRemindersOn": "Background reminders on.",
  ```
- [ ] Add the SAME keys to `app_ar.arb` with Arabic values:
  ```json
  "notifPrimingTitle": "تذكيرات الراحة",
  "notifPrimingBody": "حتى يصلك تذكير الراحة وأنت خارج التطبيق، يحتاج طَرْف إذنك بالإشعارات. بدونها سيُذكّرك أثناء فتحه فقط.",
  "exactAlarmPrimingBody": "لكي يرنّ المنبّه في وقته بالضبط، يحتاج طَرْف إذن «التنبيهات الدقيقة».",
  "permEnable": "تفعيل",
  "permNotNow": "لاحقًا",
  "permOpenSettings": "فتح الإعدادات",
  "bgRemindersOff": "التنبيهات في الخلفية متوقّفة — سيُذكّرك طَرْف أثناء فتحه فقط.",
  "bgForegroundOnlyPlatform": "على هذه المنصّة، تظهر التذكيرات أثناء فتح طَرْف فقط.",
  "bgExactAlarmOff": "قد تصل التذكيرات متأخرة بضع دقائق — فعّل التنبيهات الدقيقة لتوقيت أدق.",
  "bgRemindersOn": "التنبيهات في الخلفية مفعّلة.",
  ```
- [ ] Regenerate localizations: `flutter gen-l10n`
  Expected: `app/lib/l10n/app_localizations*.dart` regenerated with the new getters; no errors.
- [ ] Add a tiny test asserting the generated getters exist (append to
  `background_delivery_status_test.dart`):
  ```dart
  // add import: import 'package:tarf/l10n/app_localizations_en.dart';
  test('degraded l10n keys are generated', () {
    final en = AppLocalizationsEn();
    expect(en.bgRemindersOff.isNotEmpty, isTrue);
    expect(en.bgForegroundOnlyPlatform.isNotEmpty, isTrue);
    expect(en.bgExactAlarmOff.isNotEmpty, isTrue);
    expect(en.notifPrimingTitle.isNotEmpty, isTrue);
  });
  ```
- [ ] Run (expect PASS): `flutter test test/core/notifications/background_delivery_status_test.dart`.
- [ ] Run the FULL suite (expect PASS): `flutter test`.
- [ ] Run `flutter analyze` (expect clean).
- [ ] Commit:
  ```
  git add app/lib/l10n/app_en.arb app/lib/l10n/app_ar.arb app/lib/l10n/app_localizations.dart app/lib/l10n/app_localizations_en.dart app/lib/l10n/app_localizations_ar.dart app/test/core/notifications/background_delivery_status_test.dart
  git commit -m "Add AR+EN copy for permission priming and degraded states

  Verbatim from the permissions matrix: priming title/body, exact-alarm body,
  CTAs, and the four background-delivery status strings. Western digits.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 13 — Calm permission priming sheet

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\permissions\presentation\notification_priming_sheet.dart` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\permissions\notification_priming_sheet_test.dart` (NEW)

The sheet NEVER calls the OS API directly; it returns the user's choice. The caller (Settings/onboarding
in a later phase) requests the OS permission only on an affirmative result, then records it via
`permissionStateProvider`. This keeps the matrix's golden rule (never prompt cold).

- [ ] Write the failing widget test `notification_priming_sheet_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:tarf/core/settings/settings_controller.dart';
  import 'package:tarf/features/permissions/presentation/notification_priming_sheet.dart';
  import 'package:tarf/l10n/app_localizations.dart';
  import 'package:tarf/theme/app_theme.dart';

  Widget _host(SharedPreferences prefs, Widget child) => ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: TarfTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      );

  void main() {
    testWidgets('shows honest rationale and returns true on Enable',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      PrimingChoice? result;

      await tester.pumpWidget(_host(
        prefs,
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async =>
                result = await showNotificationPrimingSheet(context),
            child: const Text('open'),
          );
        }),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Honest body present.
      expect(find.textContaining('only while open'), findsOneWidget);
      await tester.tap(find.text('Enable'));
      await tester.pumpAndSettle();
      expect(result, PrimingChoice.enable);
    });

    testWidgets('returns notNow on Not now', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      PrimingChoice? result;
      await tester.pumpWidget(_host(
        prefs,
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async =>
                result = await showNotificationPrimingSheet(context),
            child: const Text('open'),
          );
        }),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(result, PrimingChoice.notNow);
    });
  }
  ```
- [ ] Run (expect FAIL): `flutter test test/features/permissions/notification_priming_sheet_test.dart`.
- [ ] Minimal implementation `notification_priming_sheet.dart` (reuse tokens; honor reduce-motion via
  the default modal; RTL handled by `MaterialApp` locale):
  ```dart
  import 'package:flutter/material.dart';

  import '../../../l10n/app_localizations.dart';
  import '../../../theme/tokens.dart';

  /// The user's decision on the priming sheet. The CALLER (not the sheet) calls
  /// the OS permission API on [enable] — never prompt cold (permissions matrix).
  enum PrimingChoice { enable, notNow }

  /// A calm bottom sheet explaining why Tarf wants notifications and stating the
  /// honest foreground-only fallback. Returns the user's [PrimingChoice].
  Future<PrimingChoice> showNotificationPrimingSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final result = await showModalBottomSheet<PrimingChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(TarfTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notifications_active_outlined,
                size: 40, color: scheme.primary),
            const SizedBox(height: TarfTokens.space3),
            Text(l10n.notifPrimingTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: TarfTokens.space2),
            Text(l10n.notifPrimingBody,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: TarfTokens.space4),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              onPressed: () => Navigator.of(context).pop(PrimingChoice.enable),
              child: Text(l10n.permEnable),
            ),
            const SizedBox(height: TarfTokens.space2),
            TextButton(
              style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.of(context).pop(PrimingChoice.notNow),
              child: Text(l10n.permNotNow),
            ),
          ],
        ),
      ),
    );
    return result ?? PrimingChoice.notNow;
  }
  ```
- [ ] Run (expect PASS): `flutter test test/features/permissions/notification_priming_sheet_test.dart`.
- [ ] Run `flutter analyze` (expect clean).
- [ ] Commit:
  ```
  git add app/lib/features/permissions/presentation/notification_priming_sheet.dart app/test/features/permissions/notification_priming_sheet_test.dart
  git commit -m "Add calm notification priming sheet (returns user choice)

  Honest rationale + foreground-only fallback; never prompts the OS cold. The
  caller requests the OS permission only on Enable.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 14 — Real gateway: `FlutterNotificationGateway` (platform plumbing, manual-verify)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\pubspec.yaml` (MODIFY — add deps)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\flutter_notification_gateway.dart` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\notifications\notification_bootstrap.dart` (NEW)

This task touches the impure plugin surface; it is **not** unit-tested on a device (the task forbids
requiring one). Correctness of the *logic* is already covered by Tasks 1–11 against the fake. Here we
just implement the adapter and confirm it **compiles** and `flutter analyze` stays clean.

- [ ] Edit `pubspec.yaml` dependencies (add under `adhan: ^2.0.0+1`):
  ```yaml
  flutter_local_notifications: ^19.0.0
  android_alarm_manager_plus: ^4.0.0
  timezone: ^0.10.0
  flutter_timezone: ^4.0.0
  ```
- [ ] Run: `flutter pub get`
  Expected: resolves successfully (PASS). If a tighter constraint is needed for Flutter 3.44, pin the
  latest compatible patch printed by pub; do NOT downgrade `flutter_riverpod`.
- [ ] Create `notification_bootstrap.dart` (top-level entry points required by the plugins for
  background isolates; kept tiny and side-effect-light):
  ```dart
  import 'package:flutter_local_notifications/flutter_local_notifications.dart';

  /// Background tap handler (runs in a separate isolate on some platforms). Must
  /// be a top-level or static function annotated for the VM entry point. We keep
  /// it minimal: the actual ring/overlay is handled when the app is foregrounded
  /// and the DoubleFireGuard reconciles. Heavy work here is unsafe.
  @pragma('vm:entry-point')
  void notificationBackgroundTap(NotificationResponse response) {
    // No-op: payload is the guard key; foreground handler claims/acts on resume.
  }
  ```
- [ ] Create `flutter_notification_gateway.dart`:
  ```dart
  import 'dart:io' show Platform;

  import 'package:flutter/foundation.dart';
  import 'package:flutter_local_notifications/flutter_local_notifications.dart';
  import 'package:flutter_timezone/flutter_timezone.dart';
  import 'package:timezone/data/latest_all.dart' as tzdata;
  import 'package:timezone/timezone.dart' as tz;

  import 'notification_bootstrap.dart';
  import 'notification_gateway.dart';
  import 'notification_sound.dart';
  import 'permission_state.dart';
  import 'scheduled_item.dart';

  /// Real gateway over flutter_local_notifications (+ exact alarms on Android).
  /// All scheduling DECISIONS live in NotificationService; this only executes.
  class FlutterNotificationGateway implements NotificationGateway {
    final FlutterLocalNotificationsPlugin _plugin =
        FlutterLocalNotificationsPlugin();
    bool _ready = false;

    bool get _isAndroid => !kIsWeb && Platform.isAndroid;
    bool get _isApple =>
        !kIsWeb && (Platform.isIOS || Platform.isMacOS);

    @override
    Future<void> init() async {
      if (_ready) return;
      tzdata.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false, // we prompt via our priming flow
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linux =
          LinuxInitializationSettings(defaultActionName: 'Open');
      const windows = WindowsInitializationSettings(
        appName: 'Tarf',
        appUserModelId: 'app.tarf.Tarf',
        guid: '4f1d2b6a-9c3e-4a7b-8f21-7e6d5c4b3a21',
      );
      await _plugin.initialize(
        const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
          linux: linux,
          windows: windows,
        ),
        onDidReceiveBackgroundNotificationResponse: notificationBackgroundTap,
      );

      // Create one Android channel per sound (channel sound is immutable).
      if (_isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        for (final id in NotificationSound.catalogIds) {
          final raw = NotificationSound.androidRawResource(id);
          await android?.createNotificationChannel(AndroidNotificationChannel(
            NotificationSound.androidChannelId(id),
            NotificationSound.channelName(id),
            importance: Importance.max,
            playSound: true,
            sound: raw == null
                ? null
                : RawResourceAndroidNotificationSound(raw),
          ));
        }
      }
      _ready = true;
    }

    @override
    Future<void> schedule(ScheduledItem item, DateTime fireAt) async {
      await init();
      final when = tz.TZDateTime.from(fireAt, tz.local);
      final androidRaw = NotificationSound.androidRawResource(item.soundId);
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationSound.androidChannelId(item.soundId),
          NotificationSound.channelName(item.soundId),
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: item.kind != ScheduledKind.eyeBreak,
          sound: androidRaw == null
              ? null
              : RawResourceAndroidNotificationSound(androidRaw),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
        iOS: DarwinNotificationDetails(
          sound: NotificationSound.appleSoundFile(item.soundId),
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
        macOS: DarwinNotificationDetails(
          sound: NotificationSound.appleSoundFile(item.soundId),
        ),
        windows: const WindowsNotificationDetails(),
      );
      await _plugin.zonedSchedule(
        item.notificationId,
        item.title,
        item.body.isEmpty ? null : item.body,
        when,
        details,
        payload: item.encodePayload(fireAt),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    @override
    Future<void> cancel(int notificationId) => _plugin.cancel(notificationId);

    @override
    Future<void> cancelAll() => _plugin.cancelAll();

    @override
    Future<PermissionStatus> queryNotificationPermission() async {
      if (_isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.areNotificationsEnabled() ?? false;
        return granted ? PermissionStatus.granted : PermissionStatus.denied;
      }
      if (_isApple) {
        // flutter_local_notifications does not expose a query on all versions;
        // treat as notDetermined until a request resolves it.
        return PermissionStatus.notDetermined;
      }
      return PermissionStatus.granted; // desktop best-effort
    }

    @override
    Future<PermissionStatus> requestNotificationPermission() async {
      if (_isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final ok = await android?.requestNotificationsPermission() ?? false;
        return ok ? PermissionStatus.granted : PermissionStatus.denied;
      }
      if (!kIsWeb && Platform.isIOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final ok = await ios?.requestPermissions(
                alert: true, badge: true, sound: true) ??
            false;
        return ok ? PermissionStatus.granted : PermissionStatus.denied;
      }
      if (!kIsWeb && Platform.isMacOS) {
        final mac = _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
        final ok = await mac?.requestPermissions(
                alert: true, badge: true, sound: true) ??
            false;
        return ok ? PermissionStatus.granted : PermissionStatus.denied;
      }
      return PermissionStatus.granted; // windows/linux best-effort
    }

    @override
    Future<PermissionStatus> requestExactAlarmPermission() async {
      if (!_isAndroid) return PermissionStatus.granted; // n/a elsewhere
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ok = await android?.requestExactAlarmsPermission() ?? false;
      return ok ? PermissionStatus.granted : PermissionStatus.denied;
    }

    @override
    Future<PermissionStatus> queryExactAlarmPermission() async {
      if (!_isAndroid) return PermissionStatus.granted;
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ok = await android?.canScheduleExactNotifications() ?? false;
      return ok ? PermissionStatus.granted : PermissionStatus.denied;
    }
  }
  ```
  NOTE for the worker: the exact plugin method names (`requestNotificationsPermission`,
  `requestExactAlarmsPermission`, `canScheduleExactNotifications`,
  `RawResourceAndroidNotificationSound`, `WindowsNotificationDetails`) match
  `flutter_local_notifications` ^19. If `flutter pub get` resolves a different major, adjust to that
  version's API (check the package's README) — the **interface** (`NotificationGateway`) does not change,
  so no other file is affected.
- [ ] Run: `flutter analyze`
  Expected: clean (PASS). Resolve any plugin-API name mismatches here only.
- [ ] Run the FULL suite (expect PASS — nothing imports the real gateway yet): `flutter test`.
- [ ] Commit:
  ```
  git add app/pubspec.yaml app/pubspec.lock app/lib/core/notifications/flutter_notification_gateway.dart app/lib/core/notifications/notification_bootstrap.dart
  git commit -m "Add flutter_local_notifications + AAM deps and real gateway

  FlutterNotificationGateway: tz init, one channel per sound, exact zoned
  schedule, full-screen-intent for alarms, per-platform permission requests.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 15 — Wire it up in `main()` (init gateway, override provider, reschedule on launch)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\main.dart` (MODIFY)

- [ ] Edit `main.dart` to init the gateway, override the provider, kick off `listenForChanges`, and
  reconcile on launch (covers reboot on Android too: launch reconcile re-arms everything). Keep the
  existing `sharedPreferencesProvider` override:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  import 'app.dart';
  import 'core/notifications/flutter_notification_gateway.dart';
  import 'core/notifications/notification_gateway.dart';
  import 'core/notifications/notification_service.dart';
  import 'core/settings/settings_controller.dart';

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();

    final gateway = FlutterNotificationGateway();
    await gateway.init();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationGatewayProvider.overrideWithValue(gateway),
      ],
    );
    // Reconcile on every cold start (re-arms after reboot on Android) and keep
    // the schedule in sync with future changes.
    container.read(notificationServiceProvider.notifier)
      ..listenForChanges()
      ..reconcile();

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const TarfApp(),
      ),
    );
  }
  ```
- [ ] Run the FULL suite (expect PASS — tests build their own containers/scopes, so `main()` is not
  exercised; this confirms no import breakage): `flutter test`.
- [ ] Run `flutter analyze` (expect clean).
- [ ] Manual smoke (optional, owner/device): build the web app
  `flutter build web` and an Android debug `flutter build apk --debug` to confirm compilation across
  the new native plugins. (No assertion — compilation success is the gate.)
- [ ] Commit:
  ```
  git add app/lib/main.dart
  git commit -m "Init notification gateway and reconcile schedule on launch

  Wire FlutterNotificationGateway into a single ProviderContainer, override the
  gateway provider, start listenForChanges, and reconcile on cold start.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 16 — Android native config (manifest, boot receiver, exact alarms, FGS, sounds)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\android\app\src\main\AndroidManifest.xml` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\android\app\src\main\res\raw\bell.wav` (NEW placeholder)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\android\app\src\main\res\raw\chime.wav` (NEW placeholder)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\android\app\src\main\res\raw\calm.wav` (NEW placeholder)

There are no Dart tests for native XML; the gate is `flutter analyze` + a debug build compiling. Align
permissions to the permissions matrix §B rows 3–7 and §C.

- [ ] Replace the `<manifest>` body of `AndroidManifest.xml` with the permission-augmented version (add
  the permission lines before `<application>`, and the receivers + FGS service inside `<application>`):
  ```xml
  <manifest xmlns:android="http://schemas.android.com/apk/res/android">

      <!-- Phase 2 background delivery -->
      <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
      <!-- Tarf's core function includes Alarm + Timer, so USE_EXACT_ALARM is
           justified (owner completes Play "exact alarm" declaration); keep
           SCHEDULE_EXACT_ALARM as the user-revocable fallback. -->
      <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
      <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
      <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
      <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
      <uses-permission android:name="android.permission.VIBRATE"/>
      <uses-permission android:name="android.permission.WAKE_LOCK"/>
      <!-- android_alarm_manager_plus foreground execution -->
      <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
      <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>

      <application
          android:label="tarf"
          android:name="${applicationName}"
          android:icon="@mipmap/ic_launcher">
          <activity
              android:name=".MainActivity"
              android:exported="true"
              android:launchMode="singleTop"
              android:taskAffinity=""
              android:theme="@style/LaunchTheme"
              android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
              android:hardwareAccelerated="true"
              android:windowSoftInputMode="adjustResize"
              android:showWhenLocked="true"
              android:turnScreenOn="true">
              <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"
                />
              <intent-filter>
                  <action android:name="android.intent.action.MAIN"/>
                  <category android:name="android.intent.category.LAUNCHER"/>
              </intent-filter>
          </activity>

          <!-- flutter_local_notifications: reschedule after reboot -->
          <receiver
              android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
              android:exported="false">
              <intent-filter>
                  <action android:name="android.intent.action.BOOT_COMPLETED"/>
                  <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                  <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
              </intent-filter>
          </receiver>
          <receiver
              android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
              android:exported="false"/>
          <receiver
              android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver"
              android:exported="false"/>

          <!-- android_alarm_manager_plus -->
          <service
              android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmService"
              android:permission="android.permission.BIND_JOB_SERVICE"
              android:exported="false"
              android:foregroundServiceType="specialUse">
              <property
                  android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                  android:value="Exact alarm and eye-break scheduling for the alarm/timer feature"/>
          </service>
          <receiver
              android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmBroadcastReceiver"
              android:exported="false"/>
          <receiver
              android:name="dev.fluttercommunity.plus.androidalarmmanager.RebootBroadcastReceiver"
              android:exported="false">
              <intent-filter>
                  <action android:name="android.intent.action.BOOT_COMPLETED"/>
              </intent-filter>
          </receiver>

          <meta-data
              android:name="flutterEmbedding"
              android:value="2" />
      </application>

      <queries>
          <intent>
              <action android:name="android.intent.action.PROCESS_TEXT"/>
              <data android:mimeType="text/plain"/>
          </intent>
      </queries>
  </manifest>
  ```
- [ ] Create the three raw sound placeholders so channel creation references resolve. The worker should
  copy the Phase-1 synthesized clips (or a short WAV) into:
  `app/android/app/src/main/res/raw/bell.wav`,
  `app/android/app/src/main/res/raw/chime.wav`,
  `app/android/app/src/main/res/raw/calm.wav`.
  (If Phase-1 audio assets are not yet exported, ship 1-second silent WAVs as placeholders; the visual
  notification still fires and `'default'` uses the system sound — honest fallback.)
- [ ] Run: `flutter analyze` (expect clean — Dart only; XML is not analyzed).
- [ ] Run a debug Android build to validate the manifest merges:
  `flutter build apk --debug`
  Expected: BUILD SUCCESSFUL (PASS). If the manifest merger flags a missing receiver class name,
  reconcile the class path against the resolved plugin version's README.
- [ ] Commit:
  ```
  git add app/android/app/src/main/AndroidManifest.xml app/android/app/src/main/res/raw/bell.wav app/android/app/src/main/res/raw/chime.wav app/android/app/src/main/res/raw/calm.wav
  git commit -m "Android: notification + exact-alarm + boot + FGS manifest config

  POST_NOTIFICATIONS, USE/SCHEDULE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED,
  USE_FULL_SCREEN_INTENT, FGS(specialUse); fln + AAM receivers; raw sounds.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 17 — iOS + macOS + Windows native config (honest)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\ios\Runner\Info.plist` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\ios\Runner\AppDelegate.swift` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\macos\Runner\Release.entitlements` (MODIFY — documented; no add needed)

iOS local notifications need **no** background mode to be *scheduled* (the OS delivers them). We do NOT
add `UIBackgroundModes` we don't use (App Store honesty). The AppDelegate sets the
`UNUserNotificationCenter` delegate so foreground notifications can present (and so the plugin's tap
routing works on iOS 10+). Windows toasts are handled entirely by the plugin's `WindowsInitializationSettings`
(Task 14) — no native edit required.

- [ ] Edit `Info.plist` — add the foreground-presentation hint key (no background-fetch claim). Insert
  before the closing `</dict>`:
  ```xml
  	<!-- Tarf schedules LOCAL notifications only; no remote push, no background
  	     fetch. We claim no UIBackgroundModes we do not use (honesty). -->
  	<key>UNUserNotificationCenterDelegateForegroundPresentation</key>
  	<true/>
  ```
  (This custom key is documentation-only; the real foreground presentation is set in AppDelegate below.
  If lint complains about an unknown key, omit it — it is purely a marker comment-equivalent.)
- [ ] Edit `AppDelegate.swift` to register the notification-center delegate so iOS routes
  taps/foreground presentation to the plugin:
  ```swift
  import Flutter
  import UIKit
  import UserNotifications

  @main
  @objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
      // Route notification callbacks to flutter_local_notifications.
      if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self
      }
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
      GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
  }
  ```
- [ ] macOS: the existing `Release.entitlements` already has `com.apple.security.app-sandbox`. Local
  notifications require **no extra entitlement** on macOS for `UNUserNotificationCenter` (authorization
  is requested at runtime via the priming flow). Add a clarifying comment-free no-op: confirm the file
  is unchanged and document in the commit body that no entitlement edit is needed. (If a future signed
  build needs the notification entitlement, it is added then — not now.)
- [ ] Run `flutter analyze` (expect clean — Dart only).
- [ ] Validate iOS compiles (owner/macOS host only; otherwise skip and rely on CI):
  `flutter build ios --no-codesign` → expected BUILD SUCCEEDED. On non-mac dev hosts, skip and note it.
- [ ] Commit:
  ```
  git add app/ios/Runner/Info.plist app/ios/Runner/AppDelegate.swift
  git commit -m "iOS/macOS: register notification delegate; no false background modes

  AppDelegate sets UNUserNotificationCenter delegate for tap/foreground routing.
  We deliberately add NO unused UIBackgroundModes (App Store honesty). macOS needs
  no extra entitlement for local notifications.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 18 — Update the honest in-app note (Alarms screen) + final full verification

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\l10n\app_en.arb` (MODIFY — refine `alarmNativeNote`)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\l10n\app_ar.arb` (MODIFY)

The Alarms screen currently shows `alarmNativeNote` = "Alarms will ring once native scheduling is
enabled on this device." After this phase, native scheduling IS enabled — the note must now reflect the
honest *current* state (background on when permitted; foreground-only otherwise). This is a copy-only
change; the dynamic banner itself is Phase 3.

- [ ] Edit `app_en.arb` value:
  ```json
  "alarmNativeNote": "Alarms ring in the background when notifications are allowed. Otherwise, Tarf rings only while open.",
  ```
- [ ] Edit `app_ar.arb` value:
  ```json
  "alarmNativeNote": "ترنّ المنبّهات في الخلفية عند السماح بالإشعارات. وإلا، يرنّ طَرْف أثناء فتحه فقط.",
  ```
- [ ] Regenerate: `flutter gen-l10n` (expect: regenerated, no errors).
- [ ] Run the FULL suite (expect PASS): `flutter test`
  Expected: all 58 prior tests + the new Phase-2 tests pass. Total target ≈ 58 + ~30 new = ~88 green.
- [ ] Run `flutter analyze` (expect: "No issues found!").
- [ ] Commit:
  ```
  git add app/lib/l10n/app_en.arb app/lib/l10n/app_ar.arb app/lib/l10n/app_localizations.dart app/lib/l10n/app_localizations_en.dart app/lib/l10n/app_localizations_ar.dart
  git commit -m "Make the Alarms note honest about background delivery

  Native scheduling now exists; the note states background rings when allowed,
  foreground-only otherwise. Dynamic banner lands in Phase 3.

  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

## Verification

Run from `C:\Users\sulta\Claude_Code\EyeCure_20\app` (Flutter SDK on PATH):

- [ ] `flutter pub get` — resolves with the four new deps, no constraint conflicts.
- [ ] `flutter gen-l10n` — regenerates `app_localizations*.dart` with the new getters, no errors.
- [ ] `flutter analyze` — prints "No issues found!" (zero new issues).
- [ ] `flutter test` — the full suite is green (58 existing + ~30 new ≈ 88 tests).
- [ ] `flutter test test/core/notifications/` — all notification-unit suites pass without a device
  (everything runs against `FakeNotificationGateway` and `SharedPreferences` mocks).
- [ ] `flutter build apk --debug` — manifest merges; fln + AAM receivers/services resolve.
- [ ] `flutter build web` — compiles (web is foreground-only; no exact alarms; the status provider
  reports `platformForegroundOnly`).
- [ ] (mac host) `flutter build ios --no-codesign` — AppDelegate compiles with the UN delegate.
- [ ] Manual on Android device (owner): create a one-shot alarm 2 min out, background the app, confirm
  the OS notification fires with the chosen sound; reopen within the same minute and confirm the
  foreground modal does **not** also ring (double-fire guard). Toggle the alarm off → confirm the
  scheduled notification is cancelled (`adb shell dumpsys alarm | findstr tarf` shows none).
- [ ] Manual reboot test (owner, Android): schedule an alarm, reboot the device, confirm the alarm still
  fires (BOOT_COMPLETED reschedule + cold-start `reconcile`).
- [ ] Deny notifications (Android 13+ / iOS): confirm `backgroundDeliveryStatusProvider.isDegraded` is
  true with `notificationsDenied`, the app stays fully usable in the foreground, and no schedule is set.

## Self-review

- [ ] **Honesty principle upheld.** No `UIBackgroundModes` we don't use; web/macos/windows/ios all
  report their true capability via `BackgroundCapability`; the degraded provider distinguishes
  `platformForegroundOnly` vs `notificationsDenied` vs `exactAlarmDenied`; the Alarms note and store copy
  match `docs/compliance/permissions-matrix.md`.
- [ ] **No cold prompts.** The priming sheet returns a choice; only the caller calls the OS API on
  `enable`. Permission results flow through `permissionStateProvider` (persisted, with a one-re-ask budget).
- [ ] **Double-fire is provably prevented.** Both foreground hosts and the OS-tap handler claim the same
  deterministic `kind:id:minute` key via the prefs-backed `DoubleFireGuard`; tests cover first-wins,
  per-minute independence, cross-instance persistence, and 24h pruning; an `AlarmHost` widget test proves
  a pre-claimed minute suppresses the modal.
- [ ] **Reschedule/cancel/reboot covered.** `listenForChanges` reconciles on alarm/config/permission
  change (tested); `reconcile` cancels-all then rebuilds (idempotent, tested); cold-start `reconcile`
  plus Android BOOT_COMPLETED receivers re-arm after reboot (manual-verified).
- [ ] **Per-platform background limits respected.** Android = exact alarms + FGS(specialUse) + boot
  receiver; iOS/macOS/windows = local-notification scheduling only (no exact engine), capability says so;
  web = foreground-only, capability says so.
- [ ] **Phase-1 coupling is a single adapter.** All sound wiring funnels through `notification_sound.dart`
  keyed on the catalog string ids the app already uses (`default/bell/chime/calm`); a richer
  `TarfAudioService` would change only that file.
- [ ] **Phase-3 contract delivered.** `backgroundDeliveryStatusProvider` +
  `platformCapabilityProvider` + the four `bg*` l10n keys are ready for the banner to consume.
- [ ] **Conventions honored.** Hand-written Riverpod `Notifier`/`NotifierProvider` (no codegen);
  `sharedPreferencesProvider` reused; JSON persistence pattern matches existing controllers; tests use
  `ProviderContainer`+`addTearDown` and `SharedPreferences.setMockInitialValues`; Western digits; RTL via
  `MaterialApp` locale; reduce-motion via default modal transitions; no `_nextOccurrence` duplication
  (single `NextFire`).
- [ ] **Worktree-safe + merge order.** New files isolated under `core/notifications/` and
  `features/permissions/`; surgical edits to `pubspec.yaml`, `main.dart`, `alarm_host.dart`,
  `alarm_derived.dart`, `eyecare_engine.dart`, two ARBs, native config. Land **after P1**, **before P3**.

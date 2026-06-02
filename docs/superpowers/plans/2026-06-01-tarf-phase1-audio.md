# Phase 1 — Real Sound System: Implementation Plan
> For agentic workers: implement task-by-task; steps use `- [ ]` checkboxes.

**Goal:** Give Tarf one shared, testable audio engine that plays audibly-distinct, stable-ID sounds for the dhikr break, alarms, the timer, and focus phase-transitions — with equal visual+haptic cues, silent-mode honoring, and a web-autoplay prime — while keeping the existing 58 tests green.

**Architecture:** A new pure-Dart `core/audio/` layer owns (a) a `SoundCatalog` of named `SoundSpec`s (synth parameters today, optional bundled assets later) keyed by stable IDs, (b) a `synthesizeTone()` WAV synthesizer generalized from the current break synth, and (c) a `TarfAudioService` interface with one real `JustAudioService` (single shared engine + `audio_session` configuration) plus `FakeAudioService`/`SilentAudioService` doubles. Feature controllers/hosts (eyecare break, alarm host, timer controller, focus controller) depend only on the interface via Riverpod providers. The existing `BreakAudioPlayer` becomes a thin adapter over `TarfAudioService` so the reverent "sound ends == break ends" contract and the `FakeBreakAudio` test pattern are preserved untouched.

**Tech Stack:** Flutter 3.44 / Dart 3.12 · Riverpod 3 hand-written `Notifier`/`Provider` · `just_audio ^0.10.5` + `audio_session ^0.2.3` (already in pubspec, already native-registered) · `flutter/services.dart` `HapticFeedback` · ARB + `flutter gen-l10n` (Western digits, plain `{n}` placeholders) · bundled `assets/audio/` (catalog tones optional; `assets/audio/recitation/` path reserved for owner-supplied clips). Flutter SDK at `C:\dev\flutter\bin` (PowerShell: `$env:Path = "C:\dev\flutter\bin;$env:Path"`).

---

## File Structure

### Create
- `app/lib/core/audio/sound_spec.dart` — `SoundSpec` (immutable synth/asset description) + `SoundLayer` + `SoundRole` enum. Single responsibility: declarative description of one playable sound.
- `app/lib/core/audio/sound_catalog.dart` — `SoundCatalog`: maps the stable IDs (`'default'`,`'bell'`,`'chime'`,`'calm'`) and role-defaults (alarm/timer/focus/breakStart/breakEnd) to `SoundSpec`s. The public catalog API Phase 2 consumes.
- `app/lib/core/audio/tone_synth.dart` — `synthesizeTone(SoundSpec, {Duration? duration})` → in-memory 16-bit PCM mono WAV. Generalizes the break synth (pad + chimes + per-layer envelopes). Single responsibility: turn a `SoundSpec` into bytes.
- `app/lib/core/audio/tarf_audio_service.dart` — `TarfAudioService` interface + `SilentAudioService` + `FakeAudioService` (records calls for unit tests). Single responsibility: the playback contract everyone shares.
- `app/lib/core/audio/just_audio_service.dart` — `JustAudioService implements TarfAudioService`: one shared `AudioPlayer` per concurrent channel, `audio_session` config, looping, web data-URI vs native byte source, autoplay-block detection. Single responsibility: real cross-platform playback.
- `app/lib/core/audio/audio_providers.dart` — `tarfAudioServiceProvider` (+ `audioPrimeProvider` for web). Single responsibility: DI wiring for the engine.
- `app/lib/core/audio/audio_haptics.dart` — `AudioHaptics` thin wrapper over `HapticFeedback` with an injectable test seam (`HapticSink`). Single responsibility: the equal-haptic cue, independent of reduce-motion.
- `app/lib/core/audio/web_audio_prime.dart` — `WebAudioPrime` notifier (`primed`/`needsPrime`) + the calm one-time "tap to enable sound" prompt widget `TapToEnableSoundBanner`. Single responsibility: surface + resolve a blocked web autoplay via a user gesture.
- `app/test/core/audio/tone_synth_test.dart` — synth WAV correctness + distinctness.
- `app/test/core/audio/sound_catalog_test.dart` — stable IDs, distinctness, role-defaults.
- `app/test/core/audio/tarf_audio_service_test.dart` — `FakeAudioService` records role/id/loop/duration.
- `app/test/core/audio/audio_haptics_test.dart` — haptics fire/skip per flag, independent of reduce-motion.
- `app/test/core/audio/web_audio_prime_test.dart` — prime state machine + banner gesture.
- `app/test/features/alarm/alarm_sound_test.dart` — alarm host triggers looped alarm sound + haptic + stop/snooze stops it.
- `app/test/features/timer/timer_sound_test.dart` — timer completion plays looped sound + haptic; dismiss stops.
- `app/test/features/focus/focus_sound_test.dart` — `justCompletedPhase` drives a one-shot transition chime + haptic at each boundary.
- `app/test/features/eyecare/break_soundtrack_test.dart` — soundtrack setting selects the right `SoundSpec`; bundled-asset code path is taken when a recitation asset is configured.

### Modify
- `app/lib/features/eyecare/audio/break_audio.dart` — keep `BreakAudioPlayer`/`SilentBreakAudio`/`FakeBreakAudio` exactly; no behavioral change (interface preserved for the existing test).
- `app/lib/features/eyecare/audio/just_audio_break_player.dart` — re-implement `JustAudioBreakPlayer` as an adapter delegating to `TarfAudioService` + `SoundCatalog`; supports the soundtrack + bundled-asset path. (`break_audio_synth.dart` stays as-is; `tone_synth.dart` supersedes it for new code but we do NOT delete it to avoid churn.)
- `app/lib/features/eyecare/application/eyecare_providers.dart` — `breakAudioProvider` now builds `JustAudioBreakPlayer` from `ref.watch(tarfAudioServiceProvider)` + the configured soundtrack.
- `app/lib/features/eyecare/domain/eyecare_config.dart` — add `breakSoundtrack` (stable id, default `'calm'`) with copyWith/toJson/fromJson.
- `app/lib/features/eyecare/presentation/break_overlay.dart` — add an equal haptic at the end cue (gated by a new `hapticEnabled` field, independent of reduce-motion); no other change.
- `app/lib/features/eyecare/presentation/show_break.dart` — pass `hapticEnabled: config.hapticEnabled` to `BreakOverlay`.
- `app/lib/features/eyecare/presentation/break_screen.dart` — pass `hapticEnabled: config.hapticEnabled` to `BreakOverlay`.
- `app/lib/features/alarm/presentation/alarm_host.dart` — on ring, start the alarm's catalog sound looped for `ringDurationSeconds` (capped) + repeating haptic; stop on Stop/Snooze/auto-timeout.
- `app/lib/features/timer/application/timer_controller.dart` — expose a way for the screen to react to the zero-crossing; no audio in the controller (pure), but add a `justFinished` one-shot flag mirroring focus, consumed by the screen.
- `app/lib/features/timer/presentation/timer_screen.dart` — when `justFinished` fires, start the timer-completion sound looped + haptic; Reset/Pause stops it.
- `app/lib/features/focus/application/focus_controller.dart` — on `justCompletedPhase` (any), fire the transition sound + haptic via the service (kept out of the pure `advanceFocus`; done in `_tick`).
- `app/lib/features/eyecare/presentation/eyecare_settings_screen.dart` — add a "Break sound" picker row (soundtrack chooser) under the Dhikr/sound group.
- `app/lib/features/settings/presentation/settings_screen.dart` — the "Dhikr & audio" group's sound surface gains the soundtrack chooser entry (chevron → eye-care settings row, or inline picker).
- `app/lib/features/alarm/presentation/alarm_editor_screen.dart` — add a "Preview" affordance to the existing Sound picker that plays the chosen catalog sound once (proves the picker drives playback); the stored id already flows to the host.
- `app/lib/app.dart` — mount `TapToEnableSoundBanner` (web-only visual) above the routed child so a blocked autoplay can be primed by a gesture.
- `app/lib/l10n/app_en.arb` + `app/lib/l10n/app_ar.arb` — new strings (break-sound label, soundtrack names, tap-to-enable, timer-done, preview). Then `flutter gen-l10n` regenerates `app_localizations*.dart`.
- `app/pubspec.yaml` — register `assets/audio/` (and the reserved `assets/audio/recitation/`) under `flutter: assets:`.

---

## Cross-phase dependencies & integration points

**This phase PROVIDES (consumed downstream):**
- `core/audio/sound_catalog.dart` — `SoundCatalog` + the four stable IDs (`'default'`,`'bell'`,`'chime'`,`'calm'`) and role-default lookup. **Phase 2 (notifications)** maps these same IDs to native notification-channel sounds; **Phase 3 (per-timer sound)** lets each timer pick a catalog ID.
- `core/audio/tarf_audio_service.dart` — the single playback interface. P2/P3 depend only on this, never on `just_audio` directly.
- `core/audio/audio_providers.dart` — `tarfAudioServiceProvider` is the one DI seam P2/P3 override in tests.

**This phase NEEDS:** nothing new beyond what is already in `pubspec.yaml` (`just_audio`, `audio_session`, both already native-registered on macOS per `GeneratedPluginRegistrant.swift`). No new pub package, no new native plugin.

**SHARED FILES other phases also edit (contention — coordinate merge order):**
- `app/lib/features/alarm/presentation/alarm_host.dart` — **P2** also edits this to add native/background scheduling. P1 must land first; P2 rebases onto P1's foreground-audio version.
- `app/lib/features/eyecare/application/eyecare_engine.dart` / `app.dart` host wiring — **P2** edits hosts for notifications. P1 only touches `app.dart` to mount the web prime banner (additive, low-conflict).
- `app/lib/features/timer/application/timer_controller.dart` + `timer/presentation/timer_screen.dart` — **P3** (per-timer sound) builds directly on P1's `justFinished` + completion-sound wiring. P1 must land first.
- `app/lib/features/eyecare/domain/eyecare_config.dart` — P1 adds `breakSoundtrack`; any other phase touching this config must rebase (additive field, JSON-back-compat via `fromJson` default).
- `app/lib/l10n/*.arb` — every phase adds keys here; keep additions append-only and run `flutter gen-l10n` after merge.

**Merge-order constraint:** P1 lands FIRST in the core track, before P2 and P3.

---

## Conventions for every task
- Prepend Flutter to PATH once per shell: PowerShell `$env:Path = "C:\dev\flutter\bin;$env:Path"`. All commands below assume cwd `C:\Users\sulta\Claude_Code\EyeCure_20\app`.
- TDD loop: write the failing test → run it (see the expected failure) → minimal implementation → run (see PASS) → `flutter analyze` clean → commit.
- Commit messages end with the Co-Authored-By trailer shown in each task.
- Never break `test/features/eyecare/break_overlay_test.dart` (the `FakeBreakAudio` contract) or any of the 58 baseline tests.

---

### Task 1: `SoundSpec` + `SoundRole` value types

**Files:**
- Create: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\audio\sound_spec.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\audio\tone_synth_test.dart` (shared with Task 2; create here, extend in Task 2)

- [ ] Write the failing test `test/core/audio/tone_synth_test.dart` (Task-1 portion — value types only):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/sound_spec.dart';

void main() {
  group('SoundSpec', () {
    test('a tone layer carries frequency, peak, decay and waveform', () {
      const layer = SoundLayer(frequencyHz: 880, peak: 0.2, decay: 5, attack: 0.01);
      expect(layer.frequencyHz, 880);
      expect(layer.peak, 0.2);
      expect(layer.decay, 5);
      expect(layer.attack, 0.01);
      expect(layer.waveform, Waveform.sine); // default
    });

    test('an asset-backed spec exposes its asset path and is not synth', () {
      const spec = SoundSpec.asset('default-bell', 'assets/audio/recitation/x.mp3');
      expect(spec.id, 'default-bell');
      expect(spec.assetPath, 'assets/audio/recitation/x.mp3');
      expect(spec.isAsset, isTrue);
      expect(spec.layers, isEmpty);
    });

    test('a synth spec is identified by id and is not asset', () {
      const spec = SoundSpec.synth(
        'bell',
        role: SoundRole.alarm,
        layers: [SoundLayer(frequencyHz: 660, peak: 0.3, decay: 3)],
      );
      expect(spec.id, 'bell');
      expect(spec.role, SoundRole.alarm);
      expect(spec.isAsset, isFalse);
      expect(spec.layers, hasLength(1));
    });
  });
}
```
- [ ] Run it (expect compile FAIL): `flutter test test/core/audio/tone_synth_test.dart`
  Expected failure: `Error: Couldn't resolve the package 'tarf' ... 'core/audio/sound_spec.dart'` / `Target of URI doesn't exist`.
- [ ] Minimal implementation `lib/core/audio/sound_spec.dart`:
```dart
import 'package:flutter/foundation.dart';

/// Which functional slot a sound fills. Lets the catalog supply sensible
/// role-defaults and lets Phase 2/3 ask for "the alarm sound" abstractly.
enum SoundRole { alarm, timerDone, focusTransition, breakStart, breakEnd, breakBed }

/// Oscillator shape for a synthesized layer.
enum Waveform { sine, triangle }

/// One additive synthesized component of a [SoundSpec].
@immutable
class SoundLayer {
  const SoundLayer({
    required this.frequencyHz,
    required this.peak,
    this.decay = 4,
    this.attack = 0.005,
    this.waveform = Waveform.sine,
    this.startSec = 0.0,
    this.sustain = false,
  });

  /// Tone frequency in Hz.
  final double frequencyHz;

  /// Peak linear amplitude (0..1) before mixing/limiting.
  final double peak;

  /// Exponential decay rate (higher = shorter). Ignored when [sustain].
  final double decay;

  /// Linear attack time in seconds (click-free onset).
  final double attack;

  final Waveform waveform;

  /// Seconds from the sound's start at which this layer begins.
  final double startSec;

  /// When true the layer holds (a gentle pad) instead of decaying; it fades
  /// with the overall duration envelope.
  final bool sustain;
}

/// Declarative description of one playable sound — either synthesized from
/// [layers] or backed by a bundled [assetPath]. Immutable and const-friendly so
/// the [SoundCatalog] can be a compile-time table.
@immutable
class SoundSpec {
  const SoundSpec.synth(
    this.id, {
    required this.role,
    required this.layers,
    this.defaultDuration = const Duration(milliseconds: 1400),
    this.gain = 1.0,
  }) : assetPath = null;

  const SoundSpec.asset(
    this.id,
    this.assetPath, {
    this.role = SoundRole.breakBed,
    this.defaultDuration = const Duration(seconds: 20),
    this.gain = 1.0,
  }) : layers = const [];

  final String id;
  final SoundRole role;

  /// Additive synth layers (empty for asset-backed specs).
  final List<SoundLayer> layers;

  /// Bundled asset path, or null for synthesized sounds.
  final String? assetPath;

  /// Natural length when the caller does not override it.
  final Duration defaultDuration;

  /// Overall linear gain multiplier applied after mixing.
  final double gain;

  bool get isAsset => assetPath != null;
}
```
- [ ] Run it (expect PASS): `flutter test test/core/audio/tone_synth_test.dart` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/core/audio/sound_spec.dart` → `No issues found!`
- [ ] Commit:
```
git add app/lib/core/audio/sound_spec.dart app/test/core/audio/tone_synth_test.dart
git commit -m "$(cat <<'EOF'
feat(audio): add SoundSpec/SoundLayer/SoundRole value types

Declarative, const-friendly description of synth and asset-backed sounds —
the foundation for the shared catalog and synthesizer.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: `synthesizeTone()` WAV synthesizer

**Files:**
- Create: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\audio\tone_synth.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\audio\tone_synth_test.dart` (extend)

- [ ] Extend `test/core/audio/tone_synth_test.dart` — add a `synthesizeTone` group below the existing `SoundSpec` group:
```dart
// add imports at top of the file:
//   import 'dart:typed_data';
//   import 'package:tarf/core/audio/tone_synth.dart';

  group('synthesizeTone', () {
    const bell = SoundSpec.synth('bell', role: SoundRole.alarm, layers: [
      SoundLayer(frequencyHz: 660, peak: 0.3, decay: 3),
      SoundLayer(frequencyHz: 990, peak: 0.15, decay: 4),
    ]);
    const chime = SoundSpec.synth('chime', role: SoundRole.timerDone, layers: [
      SoundLayer(frequencyHz: 1320, peak: 0.25, decay: 5),
    ]);

    test('produces a valid little-endian 16-bit PCM mono WAV header', () {
      final wav = synthesizeTone(bell, duration: const Duration(seconds: 1));
      final ascii = String.fromCharCodes(wav.sublist(0, 4));
      expect(ascii, 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      final bd = ByteData.sublistView(wav);
      expect(bd.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(bd.getUint16(34, Endian.little), 16, reason: '16-bit');
      expect(bd.getUint32(24, Endian.little), 44100, reason: 'sample rate');
    });

    test('length tracks the requested duration', () {
      final oneSec = synthesizeTone(bell, duration: const Duration(seconds: 1));
      final twoSec = synthesizeTone(bell, duration: const Duration(seconds: 2));
      // ~ +44100 samples * 2 bytes between 1s and 2s.
      expect(twoSec.length - oneSec.length, closeTo(44100 * 2, 8));
    });

    test('falls back to the spec defaultDuration when none is given', () {
      final wav = synthesizeTone(chime);
      final dataBytes = wav.length - 44;
      final expected = (chime.defaultDuration.inMilliseconds / 1000 * 44100).round() * 2;
      expect(dataBytes, closeTo(expected, 8));
    });

    test('two different specs render audibly different bytes', () {
      final a = synthesizeTone(bell, duration: const Duration(seconds: 1));
      final b = synthesizeTone(chime, duration: const Duration(seconds: 1));
      expect(a.length, b.length); // same duration → same length
      var differing = 0;
      for (var i = 44; i < a.length; i++) {
        if (a[i] != b[i]) differing++;
      }
      // Distinct timbre → the vast majority of PCM samples differ.
      expect(differing, greaterThan((a.length - 44) ~/ 2));
    });

    test('never clips: all samples stay within int16 range', () {
      final loud = SoundSpec.synth('loud', role: SoundRole.alarm, gain: 4.0, layers: const [
        SoundLayer(frequencyHz: 440, peak: 0.9, decay: 0.1, sustain: true),
        SoundLayer(frequencyHz: 441, peak: 0.9, decay: 0.1, sustain: true),
      ]);
      final wav = synthesizeTone(loud, duration: const Duration(milliseconds: 500));
      final bd = ByteData.sublistView(wav);
      for (var i = 44; i + 1 < wav.length; i += 2) {
        final s = bd.getInt16(i, Endian.little);
        expect(s, inInclusiveRange(-32768, 32767));
      }
    });
  });
```
- [ ] Run it (expect FAIL): `flutter test test/core/audio/tone_synth_test.dart`
  Expected failure: `Target of URI doesn't exist: 'package:tarf/core/audio/tone_synth.dart'`.
- [ ] Minimal implementation `lib/core/audio/tone_synth.dart`:
```dart
import 'dart:math' as math;
import 'dart:typed_data';

import 'sound_spec.dart';

/// Renders [spec] to an in-memory 16-bit PCM mono WAV. Additive layers, each
/// with attack + (decay | sustained) envelope; a soft overall fade prevents
/// clicks at the boundaries; a final hard limit guarantees no int16 clipping.
/// The byte length is a deterministic function of the duration, so tests can
/// assert "sound ends == duration".
Uint8List synthesizeTone(SoundSpec spec, {Duration? duration, int sampleRate = 44100}) {
  final dur = duration ?? spec.defaultDuration;
  final seconds = dur.inMilliseconds / 1000.0;
  final n = (seconds * sampleRate).round().clamp(1, 1 << 30);
  final buf = Float64List(n);

  final overallFade = math.min(0.08, seconds / 4); // gentle in/out
  for (final layer in spec.layers) {
    final startIdx = (layer.startSec * sampleRate).round();
    final w = 2 * math.pi * layer.frequencyHz;
    for (var i = math.max(0, startIdx); i < n; i++) {
      final tLayer = (i - startIdx) / sampleRate;
      double env;
      if (layer.sustain) {
        env = 1.0;
      } else {
        env = math.exp(-tLayer * layer.decay);
      }
      if (tLayer < layer.attack && layer.attack > 0) {
        env *= tLayer / layer.attack;
      }
      final phase = w * tLayer;
      final sample = switch (layer.waveform) {
        Waveform.sine => math.sin(phase),
        Waveform.triangle =>
          2 / math.pi * math.asin(math.sin(phase)),
      };
      buf[i] += layer.peak * env * sample;
    }
  }

  // Overall fade in/out across the whole sound.
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    double f = 1.0;
    if (t < overallFade) {
      f = t / overallFade;
    } else if (t > seconds - overallFade) {
      f = math.max(0.0, (seconds - t) / overallFade);
    }
    buf[i] *= f * spec.gain;
  }

  return _toWav(buf, sampleRate);
}

Uint8List _toWav(Float64List samples, int sampleRate) {
  final n = samples.length;
  const bytesPerSample = 2;
  final dataSize = n * bytesPerSample;
  final bytes = BytesBuilder();
  void writeStr(String s) => bytes.add(s.codeUnits);
  void writeU32(int v) =>
      bytes.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
  void writeU16(int v) => bytes.add([v & 0xff, (v >> 8) & 0xff]);

  writeStr('RIFF');
  writeU32(36 + dataSize);
  writeStr('WAVE');
  writeStr('fmt ');
  writeU32(16);
  writeU16(1); // PCM
  writeU16(1); // mono
  writeU32(sampleRate);
  writeU32(sampleRate * bytesPerSample);
  writeU16(bytesPerSample);
  writeU16(16);
  writeStr('data');
  writeU32(dataSize);

  final pcm = Uint8List(dataSize);
  final view = ByteData.view(pcm.buffer);
  for (var i = 0; i < n; i++) {
    final s = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    view.setInt16(i * 2, s, Endian.little);
  }
  bytes.add(pcm);
  return bytes.toBytes();
}
```
- [ ] Run it (expect PASS): `flutter test test/core/audio/tone_synth_test.dart` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/core/audio/tone_synth.dart` → `No issues found!`
- [ ] Commit:
```
git add app/lib/core/audio/tone_synth.dart app/test/core/audio/tone_synth_test.dart
git commit -m "$(cat <<'EOF'
feat(audio): synthesizeTone WAV synthesizer for SoundSpec

Additive layered synth with attack/decay/sustain envelopes, click-free
fades, and hard int16 limiting; byte length is a deterministic function of
duration so "sound ends == duration" stays testable.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: `SoundCatalog` with stable IDs + role defaults

**Files:**
- Create: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\audio\sound_catalog.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\audio\sound_catalog_test.dart`

- [ ] Write the failing test `test/core/audio/sound_catalog_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/sound_catalog.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tone_synth.dart';

void main() {
  group('SoundCatalog', () {
    test('exposes the four stable alarm IDs in a deterministic order', () {
      expect(SoundCatalog.alarmIds, ['default', 'bell', 'chime', 'calm']);
    });

    test('byId returns a spec for every alarm id; unknown falls back to default', () {
      for (final id in SoundCatalog.alarmIds) {
        expect(SoundCatalog.byId(id).id, id);
      }
      expect(SoundCatalog.byId('nonexistent').id, 'default');
    });

    test('role defaults resolve to specs with the matching role', () {
      expect(SoundCatalog.forRole(SoundRole.timerDone).role, SoundRole.timerDone);
      expect(SoundCatalog.forRole(SoundRole.focusTransition).role,
          SoundRole.focusTransition);
      expect(SoundCatalog.forRole(SoundRole.breakEnd).role, SoundRole.breakEnd);
    });

    test('the four alarm sounds are audibly distinct from one another', () {
      final rendered = {
        for (final id in SoundCatalog.alarmIds)
          id: synthesizeTone(SoundCatalog.byId(id),
              duration: const Duration(seconds: 1)),
      };
      final ids = SoundCatalog.alarmIds;
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final a = rendered[ids[i]]!;
          final b = rendered[ids[j]]!;
          var diff = 0;
          final len = a.length < b.length ? a.length : b.length;
          for (var k = 44; k < len; k++) {
            if (a[k] != b[k]) diff++;
          }
          expect(diff, greaterThan(len ~/ 4),
              reason: '${ids[i]} vs ${ids[j]} must differ audibly');
        }
      }
    });

    test('breakSoundtrackIds is a stable subset reused by the break screen', () {
      expect(SoundCatalog.breakSoundtrackIds, contains('calm'));
      expect(SoundCatalog.breakSoundtrackIds, contains('chime'));
    });
  });
}
```
- [ ] Run it (expect FAIL): `flutter test test/core/audio/sound_catalog_test.dart`
  Expected failure: `Target of URI doesn't exist: 'package:tarf/core/audio/sound_catalog.dart'`.
- [ ] Minimal implementation `lib/core/audio/sound_catalog.dart`:
```dart
import 'sound_spec.dart';

/// The single registry of named, stable-ID sounds shared by alarms, the timer,
/// focus, and the dhikr break — and consumed by Phase 2 (notifications) and
/// Phase 3 (per-timer sound). IDs are STABLE: never rename without a migration.
abstract final class SoundCatalog {
  SoundCatalog._();

  /// The four user-pickable alarm sounds, in display order.
  /// IDs match `alarm_editor_screen.dart` `_soundIds` and `AlarmItem.sound`.
  static const List<String> alarmIds = ['default', 'bell', 'chime', 'calm'];

  /// Soundtrack choices offered for the dhikr break (a curated subset; the
  /// bundled-recitation option is added at runtime when an asset is present).
  static const List<String> breakSoundtrackIds = ['calm', 'chime'];

  static const Map<String, SoundSpec> _byId = {
    // A bright two-tone wake tone.
    'default': SoundSpec.synth('default', role: SoundRole.alarm, layers: [
      SoundLayer(frequencyHz: 880, peak: 0.32, decay: 2.2, attack: 0.004),
      SoundLayer(frequencyHz: 1174.7, peak: 0.18, decay: 2.6, startSec: 0.18),
    ], defaultDuration: Duration(milliseconds: 1500)),
    // A lower, rounder bell with a long tail.
    'bell': SoundSpec.synth('bell', role: SoundRole.alarm, layers: [
      SoundLayer(frequencyHz: 587.33, peak: 0.34, decay: 1.4),
      SoundLayer(frequencyHz: 1760.0, peak: 0.10, decay: 3.5),
    ], defaultDuration: Duration(milliseconds: 1800)),
    // A clear high single chime.
    'chime': SoundSpec.synth('chime', role: SoundRole.alarm, layers: [
      SoundLayer(frequencyHz: 1318.5, peak: 0.26, decay: 4.0, attack: 0.003),
    ], defaultDuration: Duration(milliseconds: 1300)),
    // A soft mellow pair (triangle) — the calmest.
    'calm': SoundSpec.synth('calm', role: SoundRole.breakBed, layers: [
      SoundLayer(frequencyHz: 392.0, peak: 0.16, sustain: true,
          waveform: Waveform.triangle),
      SoundLayer(frequencyHz: 523.25, peak: 0.12, sustain: true,
          waveform: Waveform.triangle),
    ], defaultDuration: Duration(milliseconds: 2000)),
  };

  static const Map<SoundRole, String> _roleDefault = {
    SoundRole.alarm: 'default',
    SoundRole.timerDone: 'chime',
    SoundRole.focusTransition: 'calm',
    SoundRole.breakStart: 'chime',
    SoundRole.breakEnd: 'chime',
    SoundRole.breakBed: 'calm',
  };

  /// The spec for [id]; unknown ids fall back to 'default' (never throws).
  static SoundSpec byId(String id) => _byId[id] ?? _byId['default']!;

  /// The role's default spec, with its [SoundSpec.role] overridden to [role] so
  /// callers can match on role. Used by timer/focus/break which think in roles.
  static SoundSpec forRole(SoundRole role) {
    final base = _byId[_roleDefault[role] ?? 'default']!;
    return SoundSpec.synth(base.id, role: role, layers: base.layers,
        defaultDuration: base.defaultDuration, gain: base.gain);
  }
}
```
- [ ] Run it (expect PASS): `flutter test test/core/audio/sound_catalog_test.dart` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/core/audio/sound_catalog.dart` → `No issues found!`
- [ ] Commit:
```
git add app/lib/core/audio/sound_catalog.dart app/test/core/audio/sound_catalog_test.dart
git commit -m "$(cat <<'EOF'
feat(audio): SoundCatalog with stable IDs and role defaults

Single registry mapping default/bell/chime/calm + role-defaults to audibly
distinct SoundSpecs; the API Phase 2 (notifications) and Phase 3 (per-timer
sound) will consume.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: `TarfAudioService` interface + Fake/Silent doubles

**Files:**
- Create: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\audio\tarf_audio_service.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\audio\tarf_audio_service_test.dart`

- [ ] Write the failing test `test/core/audio/tarf_audio_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/sound_catalog.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';

void main() {
  group('FakeAudioService', () {
    test('records play calls with spec, channel, loop and duration', () async {
      final fake = FakeAudioService();
      await fake.play(
        SoundCatalog.byId('bell'),
        channel: AudioChannel.alarm,
        loop: true,
        duration: const Duration(seconds: 60),
        playThroughSilent: true,
      );
      expect(fake.plays, hasLength(1));
      final p = fake.plays.single;
      expect(p.spec.id, 'bell');
      expect(p.channel, AudioChannel.alarm);
      expect(p.loop, isTrue);
      expect(p.duration, const Duration(seconds: 60));
      expect(p.playThroughSilent, isTrue);
    });

    test('stop targets a channel and is recorded', () async {
      final fake = FakeAudioService();
      await fake.play(SoundCatalog.forRole(SoundRole.timerDone),
          channel: AudioChannel.timer, loop: true);
      await fake.stop(AudioChannel.timer);
      expect(fake.stops, [AudioChannel.timer]);
      expect(fake.isPlaying(AudioChannel.timer), isFalse);
    });

    test('isPlaying reflects the latest play/stop per channel', () async {
      final fake = FakeAudioService();
      expect(fake.isPlaying(AudioChannel.focus), isFalse);
      await fake.play(SoundCatalog.forRole(SoundRole.focusTransition),
          channel: AudioChannel.focus);
      expect(fake.isPlaying(AudioChannel.focus), isTrue);
    });
  });

  group('SilentAudioService', () {
    test('never throws and never reports playing', () async {
      const svc = SilentAudioService();
      await svc.play(SoundCatalog.byId('default'), channel: AudioChannel.alarm);
      await svc.stop(AudioChannel.alarm);
      await svc.stopAll();
      await svc.dispose();
      expect(svc.isPlaying(AudioChannel.alarm), isFalse);
    });
  });
}
```
- [ ] Run it (expect FAIL): `flutter test test/core/audio/tarf_audio_service_test.dart`
  Expected failure: `Target of URI doesn't exist: 'package:tarf/core/audio/tarf_audio_service.dart'`.
- [ ] Minimal implementation `lib/core/audio/tarf_audio_service.dart`:
```dart
import 'package:flutter/foundation.dart';

import 'sound_spec.dart';

/// Independent playback lanes so e.g. a focus chime and a break bed don't fight.
/// Each channel owns at most one active sound at a time.
enum AudioChannel { alarm, timer, focus, breakBed, breakCue, preview }

/// The single audio contract every feature depends on. Implemented by
/// [SilentAudioService] (default/disabled), [FakeAudioService] (tests), and the
/// real `JustAudioService`. Phase 2/3 depend ONLY on this interface.
abstract interface class TarfAudioService {
  /// Plays [spec] on [channel]. When [loop] is true the sound repeats until
  /// [stop]/[stopAll] (or, if [duration] is given, auto-stops after it).
  /// [playThroughSilent] requests the OS "play even in silent mode" category.
  /// Returns false if playback was blocked (e.g. web autoplay) so callers can
  /// fall back to the visual cue.
  Future<bool> play(
    SoundSpec spec, {
    required AudioChannel channel,
    bool loop = false,
    Duration? duration,
    bool playThroughSilent = false,
  });

  /// Stops the sound on [channel] (no-op if idle).
  Future<void> stop(AudioChannel channel);

  /// Stops every channel.
  Future<void> stopAll();

  /// Whether [channel] currently has an active sound.
  bool isPlaying(AudioChannel channel);

  /// Releases underlying resources.
  Future<void> dispose();
}

/// No-op implementation: safe default and the value when sound is disabled.
class SilentAudioService implements TarfAudioService {
  const SilentAudioService();
  @override
  Future<bool> play(SoundSpec spec,
          {required AudioChannel channel,
          bool loop = false,
          Duration? duration,
          bool playThroughSilent = false}) async =>
      false;
  @override
  Future<void> stop(AudioChannel channel) async {}
  @override
  Future<void> stopAll() async {}
  @override
  bool isPlaying(AudioChannel channel) => false;
  @override
  Future<void> dispose() async {}
}

/// One recorded [TarfAudioService.play] call.
@immutable
class PlayCall {
  const PlayCall({
    required this.spec,
    required this.channel,
    required this.loop,
    required this.duration,
    required this.playThroughSilent,
  });
  final SoundSpec spec;
  final AudioChannel channel;
  final bool loop;
  final Duration? duration;
  final bool playThroughSilent;
}

/// Records calls for unit/widget tests. `blockPlayback=true` simulates a web
/// autoplay block (play() returns false).
class FakeAudioService implements TarfAudioService {
  FakeAudioService({this.blockPlayback = false});

  bool blockPlayback;
  final List<PlayCall> plays = [];
  final List<AudioChannel> stops = [];
  int stopAllCount = 0;
  final Set<AudioChannel> _active = {};

  @override
  Future<bool> play(SoundSpec spec,
      {required AudioChannel channel,
      bool loop = false,
      Duration? duration,
      bool playThroughSilent = false}) async {
    plays.add(PlayCall(
      spec: spec,
      channel: channel,
      loop: loop,
      duration: duration,
      playThroughSilent: playThroughSilent,
    ));
    if (blockPlayback) return false;
    _active.add(channel);
    return true;
  }

  @override
  Future<void> stop(AudioChannel channel) async {
    stops.add(channel);
    _active.remove(channel);
  }

  @override
  Future<void> stopAll() async {
    stopAllCount++;
    _active.clear();
  }

  @override
  bool isPlaying(AudioChannel channel) => _active.contains(channel);

  @override
  Future<void> dispose() async {}
}
```
- [ ] Run it (expect PASS): `flutter test test/core/audio/tarf_audio_service_test.dart` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/core/audio/tarf_audio_service.dart` → `No issues found!`
- [ ] Commit:
```
git add app/lib/core/audio/tarf_audio_service.dart app/test/core/audio/tarf_audio_service_test.dart
git commit -m "$(cat <<'EOF'
feat(audio): TarfAudioService interface + Silent/Fake doubles

One playback contract (channels, loop, duration, play-through-silent,
blocked->false) that alarm/timer/focus/break share; Phase 2/3 depend only
on this seam.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: `JustAudioService` real engine (+ providers)

**Files:**
- Create: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\audio\just_audio_service.dart`
- Create: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\audio\audio_providers.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\audio\just_audio_service_test.dart` (light — the real engine is exercised via the feature tests; here we only assert construction + the provider seam without touching real platform audio)

> Rationale: `just_audio` has no headless backend in `flutter test`, so we do NOT call `play()` on the real engine in unit tests (that needs a device/web — covered by the Verification web build). We test (a) the engine constructs and disposes cleanly, (b) `tarfAudioServiceProvider` is overridable and is `SilentAudioService` by default in a pure `ProviderContainer` (so existing/other tests never hit real audio).

- [ ] Write the failing test `test/core/audio/just_audio_service_test.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/audio_providers.dart';
import 'package:tarf/core/audio/just_audio_service.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';

void main() {
  test('JustAudioService constructs and disposes without throwing', () async {
    final svc = JustAudioService();
    expect(svc.isPlaying(AudioChannel.alarm), isFalse);
    await svc.dispose();
  });

  test('tarfAudioServiceProvider is overridable with a Fake', () {
    final fake = FakeAudioService();
    final container = ProviderContainer(
      overrides: [tarfAudioServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    expect(container.read(tarfAudioServiceProvider), same(fake));
  });
}
```
- [ ] Run it (expect FAIL): `flutter test test/core/audio/just_audio_service_test.dart`
  Expected failure: `Target of URI doesn't exist: 'package:tarf/core/audio/just_audio_service.dart'`.
- [ ] Minimal implementation `lib/core/audio/just_audio_service.dart`:
```dart
// just_audio marks StreamAudioResponse experimental, but it is the documented,
// widely-used way to serve in-memory audio; safe to use here.
// ignore_for_file: experimental_member_use
import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'sound_spec.dart';
import 'tarf_audio_service.dart';
import 'tone_synth.dart';

/// Real cross-platform engine: one [AudioPlayer] per [AudioChannel] so lanes are
/// independent. Synth specs are rendered to an in-memory WAV (data-URI on web,
/// byte source on native); asset specs are loaded from the bundle. Looping uses
/// just_audio's [LoopMode]; an optional [Duration] auto-stops a looped sound.
class JustAudioService implements TarfAudioService {
  final Map<AudioChannel, AudioPlayer> _players = {};
  final Map<AudioChannel, Timer> _autoStop = {};
  AudioSession? _session;
  bool _sessionConfigured = false;

  AudioPlayer _playerFor(AudioChannel channel) =>
      _players.putIfAbsent(channel, AudioPlayer.new);

  Future<void> _configureSession({required bool playThroughSilent}) async {
    if (kIsWeb) return; // no audio_session on web
    _session ??= await AudioSession.instance;
    // Reconfigure if the silent-mode requirement changed.
    await _session!.configure(AudioSessionConfiguration(
      avAudioSessionCategory: playThroughSilent
          ? AVAudioSessionCategory.playback
          : AVAudioSessionCategory.ambient,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.duckOthers,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        usage: playThroughSilent
            ? AndroidAudioUsage.alarm
            : AndroidAudioUsage.assistanceSonification,
      ),
      androidWillPauseWhenDucked: false,
    ));
    _sessionConfigured = true;
    await _session!.setActive(true);
  }

  @override
  Future<bool> play(SoundSpec spec,
      {required AudioChannel channel,
      bool loop = false,
      Duration? duration,
      bool playThroughSilent = false}) async {
    final player = _playerFor(channel);
    _autoStop.remove(channel)?.cancel();
    try {
      await _configureSession(playThroughSilent: playThroughSilent);
      if (spec.isAsset) {
        await player.setAsset(spec.assetPath!);
      } else {
        final wav = synthesizeTone(spec, duration: loop ? null : duration);
        if (kIsWeb) {
          await player.setAudioSource(
            AudioSource.uri(Uri.dataFromBytes(wav, mimeType: 'audio/wav')),
          );
        } else {
          await player.setAudioSource(_BytesSource(wav));
        }
      }
      await player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await player.seek(Duration.zero);
      await player.play();
      if (loop && duration != null) {
        _autoStop[channel] = Timer(duration, () => stop(channel));
      }
      return true;
    } catch (_) {
      // Blocked/failed playback (e.g. web autoplay without a gesture) must never
      // break the experience; the caller falls back to the visual cue.
      return false;
    }
  }

  @override
  Future<void> stop(AudioChannel channel) async {
    _autoStop.remove(channel)?.cancel();
    try {
      await _players[channel]?.stop();
    } catch (_) {}
  }

  @override
  Future<void> stopAll() async {
    for (final c in _players.keys.toList()) {
      await stop(c);
    }
  }

  @override
  bool isPlaying(AudioChannel channel) =>
      _players[channel]?.playing ?? false;

  @override
  Future<void> dispose() async {
    for (final t in _autoStop.values) {
      t.cancel();
    }
    _autoStop.clear();
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
    if (!kIsWeb && _sessionConfigured) {
      try {
        await _session?.setActive(false);
      } catch (_) {}
    }
  }
}

/// Serves synthesized WAV bytes to just_audio on native platforms.
class _BytesSource extends StreamAudioSource {
  _BytesSource(this._bytes);
  final Uint8List _bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final s = start ?? 0;
    final e = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: e - s,
      offset: s,
      stream: Stream.value(_bytes.sublist(s, e)),
      contentType: 'audio/wav',
    );
  }
}
```
- [ ] Minimal implementation `lib/core/audio/audio_providers.dart`:
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'just_audio_service.dart';
import 'tarf_audio_service.dart';

/// The shared audio engine. Defaults to silence in pure tests (no real audio in
/// `flutter test`); overridden in `main()` with the real [JustAudioService] and
/// in tests with a [FakeAudioService]. Phase 2/3 read this same provider.
final tarfAudioServiceProvider = Provider<TarfAudioService>((ref) {
  // In the widget tree (real app) this is overridden in main(); the bare default
  // is Silent so any test that forgets to override never touches platform audio.
  return const SilentAudioService();
});

/// Builds the real engine. Call once from `main()` to override the provider:
///   tarfAudioServiceProvider.overrideWith((ref) {
///     final svc = buildRealAudioService();
///     ref.onDispose(svc.dispose);
///     return svc;
///   })
TarfAudioService buildRealAudioService() => JustAudioService();

/// Whether we are on web (autoplay needs a user gesture). Exposed for tests.
final isWebProvider = Provider<bool>((ref) => kIsWeb);
```
- [ ] Run it (expect PASS): `flutter test test/core/audio/just_audio_service_test.dart` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/core/audio/just_audio_service.dart lib/core/audio/audio_providers.dart` → `No issues found!`
- [ ] Wire the real engine in `main()`. Read `app/lib/main.dart` first, then add to its `ProviderScope(overrides: [...])` (alongside the existing `sharedPreferencesProvider` override):
```dart
// import 'core/audio/audio_providers.dart';
        tarfAudioServiceProvider.overrideWith((ref) {
          final svc = buildRealAudioService();
          ref.onDispose(svc.dispose);
          return svc;
        }),
```
- [ ] Run full suite to confirm nothing regressed: `flutter test` → `+58: All tests passed!` (plus the new audio tests).
- [ ] Commit:
```
git add app/lib/core/audio/just_audio_service.dart app/lib/core/audio/audio_providers.dart app/lib/main.dart app/test/core/audio/just_audio_service_test.dart
git commit -m "$(cat <<'EOF'
feat(audio): JustAudioService engine + DI providers

One AudioPlayer per channel, audio_session category config (ambient vs
playback for play-through-silent), looping with optional auto-stop, web
data-URI vs native byte source, blocked-playback returns false. Default
provider is Silent in tests; real engine wired in main().

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: `AudioHaptics` — the equal haptic cue

**Files:**
- Create: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\audio\audio_haptics.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\audio\audio_haptics_test.dart`

- [ ] Write the failing test `test/core/audio/audio_haptics_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/audio_haptics.dart';

void main() {
  group('AudioHaptics', () {
    test('fires when enabled, regardless of reduce-motion', () {
      final sink = RecordingHapticSink();
      final h = AudioHaptics(sink);
      h.cue(HapticKind.transition, enabled: true);
      expect(sink.events, [HapticKind.transition]);
    });

    test('does nothing when disabled', () {
      final sink = RecordingHapticSink();
      AudioHaptics(sink).cue(HapticKind.alarm, enabled: false);
      expect(sink.events, isEmpty);
    });

    test('alarm/timer use a heavier impact than a transition', () {
      final sink = RecordingHapticSink();
      final h = AudioHaptics(sink)
        ..cue(HapticKind.transition, enabled: true)
        ..cue(HapticKind.alarm, enabled: true)
        ..cue(HapticKind.timerDone, enabled: true);
      expect(sink.events,
          [HapticKind.transition, HapticKind.alarm, HapticKind.timerDone]);
    });
  });
}
```
- [ ] Run it (expect FAIL): `flutter test test/core/audio/audio_haptics_test.dart`
  Expected failure: `Target of URI doesn't exist: 'package:tarf/core/audio/audio_haptics.dart'`.
- [ ] Minimal implementation `lib/core/audio/audio_haptics.dart`:
```dart
import 'package:flutter/services.dart';

/// Why a haptic is firing — selects an intensity and lets tests assert intent.
enum HapticKind { transition, alarm, timerDone, breakEnd }

/// Indirection over [HapticFeedback] so haptics are unit-testable.
abstract interface class HapticSink {
  void impact(HapticKind kind);
}

/// Production sink: maps each kind to a Flutter haptic primitive.
class PlatformHapticSink implements HapticSink {
  const PlatformHapticSink();
  @override
  void impact(HapticKind kind) {
    switch (kind) {
      case HapticKind.alarm:
      case HapticKind.timerDone:
        HapticFeedback.heavyImpact();
      case HapticKind.breakEnd:
        HapticFeedback.mediumImpact();
      case HapticKind.transition:
        HapticFeedback.selectionClick();
    }
  }
}

/// Records events for tests.
class RecordingHapticSink implements HapticSink {
  final List<HapticKind> events = [];
  @override
  void impact(HapticKind kind) => events.add(kind);
}

/// The equal-to-audio haptic cue. Honors only the user's haptics flag — it is
/// INDEPENDENT of reduce-motion (per Tarf accessibility rules).
class AudioHaptics {
  const AudioHaptics([this._sink = const PlatformHapticSink()]);
  final HapticSink _sink;

  void cue(HapticKind kind, {required bool enabled}) {
    if (!enabled) return;
    _sink.impact(kind);
  }
}
```
- [ ] Run it (expect PASS): `flutter test test/core/audio/audio_haptics_test.dart` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/core/audio/audio_haptics.dart` → `No issues found!`
- [ ] Commit:
```
git add app/lib/core/audio/audio_haptics.dart app/test/core/audio/audio_haptics_test.dart
git commit -m "$(cat <<'EOF'
feat(audio): AudioHaptics equal-cue wrapper (reduce-motion independent)

HapticSink seam + kind->intensity mapping; honors the haptics flag only,
never reduce-motion, per accessibility rules.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Add `breakSoundtrack` to `EyeCareConfig`

**Files:**
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\domain\eyecare_config.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\eyecare\eyecare_config_soundtrack_test.dart` (Create)

- [ ] Write the failing test `test/features/eyecare/eyecare_config_soundtrack_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/eyecare/domain/eyecare_config.dart';

void main() {
  group('EyeCareConfig.breakSoundtrack', () {
    test('defaults to calm', () {
      expect(const EyeCareConfig().breakSoundtrack, 'calm');
    });

    test('round-trips through JSON', () {
      const cfg = EyeCareConfig(breakSoundtrack: 'chime');
      final restored = EyeCareConfig.fromJson(cfg.toJson());
      expect(restored.breakSoundtrack, 'chime');
    });

    test('fromJson without the key falls back to calm (back-compat)', () {
      final restored = EyeCareConfig.fromJson(const {'enabled': true});
      expect(restored.breakSoundtrack, 'calm');
    });

    test('copyWith updates only the soundtrack', () {
      const cfg = EyeCareConfig();
      final next = cfg.copyWith(breakSoundtrack: 'chime');
      expect(next.breakSoundtrack, 'chime');
      expect(next.soundEnabled, cfg.soundEnabled);
    });
  });
}
```
- [ ] Run it (expect FAIL): `flutter test test/features/eyecare/eyecare_config_soundtrack_test.dart`
  Expected failure: `The named parameter 'breakSoundtrack' isn't defined` / `The getter 'breakSoundtrack' isn't defined`.
- [ ] Implement: in `lib/features/eyecare/domain/eyecare_config.dart`:
  - Add constructor param after `loudThroughSilence`: `this.breakSoundtrack = 'calm',`
  - Add field: `/// Stable SoundCatalog id chosen for the dhikr break bed.\n  final String breakSoundtrack;`
  - Add to `copyWith` params: `String? breakSoundtrack,` and to the returned `EyeCareConfig(... breakSoundtrack: breakSoundtrack ?? this.breakSoundtrack, ...)`.
  - Add to `toJson`: `'breakSoundtrack': breakSoundtrack,`
  - Add to `fromJson`: `breakSoundtrack: (j['breakSoundtrack'] as String?) ?? 'calm',`
- [ ] Run it (expect PASS): `flutter test test/features/eyecare/eyecare_config_soundtrack_test.dart` → `All tests passed!`
- [ ] Run full suite (config is widely read): `flutter test` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/features/eyecare/domain/eyecare_config.dart` → `No issues found!`
- [ ] Commit:
```
git add app/lib/features/eyecare/domain/eyecare_config.dart app/test/features/eyecare/eyecare_config_soundtrack_test.dart
git commit -m "$(cat <<'EOF'
feat(eyecare): add breakSoundtrack to EyeCareConfig

Stable SoundCatalog id (default 'calm') with copyWith/JSON + back-compat
default so older saved configs still load.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Re-implement `JustAudioBreakPlayer` over `TarfAudioService` (+ rewire provider) — keep `FakeBreakAudio` contract

**Files:**
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\audio\just_audio_break_player.dart`
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\application\eyecare_providers.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\eyecare\break_soundtrack_test.dart` (Create)

> The `BreakAudioPlayer` interface and `FakeBreakAudio` in `break_audio.dart` are LEFT UNCHANGED; the existing `break_overlay_test.dart` keeps passing. We only swap the *real* implementation's internals to delegate to `TarfAudioService` + the configured soundtrack, and add the bundled-asset code path.

- [ ] Write the failing test `test/features/eyecare/break_soundtrack_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/features/eyecare/audio/just_audio_break_player.dart';

void main() {
  group('JustAudioBreakPlayer (over TarfAudioService)', () {
    test('plays the configured soundtrack on the breakBed channel for the duration', () async {
      final fake = FakeAudioService();
      final player = JustAudioBreakPlayer(audio: fake, soundtrackId: 'chime');
      await player.start(
        duration: const Duration(seconds: 20),
        soundEnabled: true,
      );
      expect(fake.plays, hasLength(1));
      final p = fake.plays.single;
      expect(p.channel, AudioChannel.breakBed);
      expect(p.spec.id, 'chime');
      expect(p.duration, const Duration(seconds: 20));
    });

    test('does nothing when sound is disabled', () async {
      final fake = FakeAudioService();
      final player = JustAudioBreakPlayer(audio: fake, soundtrackId: 'calm');
      await player.start(
        duration: const Duration(seconds: 20),
        soundEnabled: false,
      );
      expect(fake.plays, isEmpty);
    });

    test('stop() stops the breakBed channel', () async {
      final fake = FakeAudioService();
      final player = JustAudioBreakPlayer(audio: fake, soundtrackId: 'calm');
      await player.start(duration: const Duration(seconds: 5), soundEnabled: true);
      await player.stop();
      expect(fake.stops, contains(AudioChannel.breakBed));
    });

    test('a recitation asset id takes the bundled-asset code path (isAsset)', () async {
      final fake = FakeAudioService();
      final player = JustAudioBreakPlayer(
        audio: fake,
        soundtrackId: 'recitation',
        recitationAssetPath: 'assets/audio/recitation/001.mp3',
      );
      await player.start(duration: const Duration(seconds: 20), soundEnabled: true);
      final p = fake.plays.single;
      expect(p.spec.isAsset, isTrue);
      expect(p.spec.assetPath, 'assets/audio/recitation/001.mp3');
      expect(p.spec.role, SoundRole.breakBed);
    });
  });
}
```
- [ ] Run it (expect FAIL): `flutter test test/features/eyecare/break_soundtrack_test.dart`
  Expected failure: `No named parameter with the name 'audio'` (current `JustAudioBreakPlayer` has no constructor args).
- [ ] Re-implement `lib/features/eyecare/audio/just_audio_break_player.dart`:
```dart
import '../../../core/audio/sound_catalog.dart';
import '../../../core/audio/sound_spec.dart';
import '../../../core/audio/tarf_audio_service.dart';
import '../domain/dhikr.dart';
import 'break_audio.dart';

/// Real cross-platform break audio, now a thin adapter over the shared
/// [TarfAudioService]. Plays the configured soundtrack (a calm catalog bed, or a
/// bundled recitation clip when [recitationAssetPath] is set) for the full break
/// duration so the SOUND ending is the cue that the break is over. Honors the
/// silent setting and degrades gracefully (visual ring still drives the break)
/// if playback is blocked (e.g. web autoplay without a user gesture).
class JustAudioBreakPlayer implements BreakAudioPlayer {
  JustAudioBreakPlayer({
    required TarfAudioService audio,
    required String soundtrackId,
    String? recitationAssetPath,
    bool ownsService = false,
  })  : _audio = audio,
        _soundtrackId = soundtrackId,
        _recitationAssetPath = recitationAssetPath,
        _ownsService = ownsService;

  final TarfAudioService _audio;
  final String _soundtrackId;
  final String? _recitationAssetPath;
  final bool _ownsService;

  SoundSpec _spec() {
    // Bundled recitation clip wins when configured AND present (owner-supplied).
    if (_recitationAssetPath != null) {
      return SoundSpec.asset(_soundtrackId, _recitationAssetPath!,
          role: SoundRole.breakBed);
    }
    final base = SoundCatalog.byId(_soundtrackId);
    // Force the breakBed role so it sits on the breakBed channel semantics.
    return SoundSpec.synth(base.id,
        role: SoundRole.breakBed,
        layers: base.layers,
        defaultDuration: base.defaultDuration,
        gain: base.gain);
  }

  @override
  Future<void> start({
    required Duration duration,
    required bool soundEnabled,
    Dhikr? dhikr,
  }) async {
    if (!soundEnabled) return;
    // A dhikr that bundles its own recitation overrides the soundtrack bed.
    final assetFromDhikr = dhikr?.audio;
    final spec = assetFromDhikr != null
        ? SoundSpec.asset(dhikr!.id, assetFromDhikr, role: SoundRole.breakBed)
        : _spec();
    await _audio.play(
      spec,
      channel: AudioChannel.breakBed,
      duration: duration, // sound ends == break ends
    );
  }

  @override
  Future<void> stop() async => _audio.stop(AudioChannel.breakBed);

  @override
  Future<void> dispose() async {
    if (_ownsService) await _audio.dispose();
  }
}
```
- [ ] Run it (expect PASS): `flutter test test/features/eyecare/break_soundtrack_test.dart` → `All tests passed!`
- [ ] Rewire `lib/features/eyecare/application/eyecare_providers.dart` `breakAudioProvider`:
```dart
import '../../../core/audio/audio_providers.dart';
// ...
/// The break audio player — a thin adapter over the shared audio engine that
/// plays the user's chosen break soundtrack for the full duration.
final breakAudioProvider = Provider<BreakAudioPlayer>((ref) {
  final audio = ref.watch(tarfAudioServiceProvider);
  final soundtrack = ref.watch(
    eyeCareConfigProvider.select((c) => c.breakSoundtrack),
  );
  return JustAudioBreakPlayer(audio: audio, soundtrackId: soundtrack);
});
```
  (Add the import `import '../application/eyecare_config_controller.dart';` if not already present — it is in the same folder, so the path is `'eyecare_config_controller.dart'`.) Remove the now-unused `ref.onDispose(player.dispose)` (the service, not the adapter, owns disposal).
- [ ] Run the break overlay regression test (the `FakeBreakAudio` contract): `flutter test test/features/eyecare/break_overlay_test.dart` → `All tests passed!`
- [ ] Run full suite: `flutter test` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/features/eyecare/audio/just_audio_break_player.dart lib/features/eyecare/application/eyecare_providers.dart` → `No issues found!`
- [ ] Commit:
```
git add app/lib/features/eyecare/audio/just_audio_break_player.dart app/lib/features/eyecare/application/eyecare_providers.dart app/test/features/eyecare/break_soundtrack_test.dart
git commit -m "$(cat <<'EOF'
refactor(eyecare): break player delegates to shared TarfAudioService

JustAudioBreakPlayer becomes a thin adapter: plays the configured soundtrack
(calm catalog bed or bundled recitation asset, dhikr.audio overrides) on the
breakBed channel for the full duration. BreakAudioPlayer interface and
FakeBreakAudio are untouched; the 58 tests stay green.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 9: Equal haptic at the break end cue

**Files:**
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\presentation\break_overlay.dart`
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\presentation\show_break.dart`
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\presentation\break_screen.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\eyecare\break_overlay_test.dart` (extend — keep the two existing tests intact)

- [ ] Extend `test/features/eyecare/break_overlay_test.dart` — add a haptics seam test after the existing tests (and import `audio_haptics`):
```dart
// add import:
//   import 'package:tarf/core/audio/audio_haptics.dart';

  testWidgets('fires an equal breakEnd haptic when the countdown completes',
      (tester) async {
    final audio = FakeBreakAudio();
    final sink = RecordingHapticSink();

    await tester.pumpWidget(
      _host(
        BreakOverlay(
          dhikr: _dhikr,
          duration: const Duration(seconds: 1),
          audio: audio,
          numerals: NumeralSystem.western,
          hapticEnabled: true,
          haptics: AudioHaptics(sink),
          onFinished: () {},
        ),
      ),
    );
    await tester.pump();
    expect(sink.events, isEmpty); // not yet
    await tester.pump(const Duration(milliseconds: 1100));
    expect(sink.events, contains(HapticKind.breakEnd));
  });

  testWidgets('no haptic at completion when hapticEnabled is false',
      (tester) async {
    final sink = RecordingHapticSink();
    await tester.pumpWidget(
      _host(
        BreakOverlay(
          dhikr: _dhikr,
          duration: const Duration(seconds: 1),
          audio: FakeBreakAudio(),
          numerals: NumeralSystem.western,
          hapticEnabled: false,
          haptics: AudioHaptics(sink),
          onFinished: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(sink.events, isEmpty);
  });
```
- [ ] Run it (expect FAIL): `flutter test test/features/eyecare/break_overlay_test.dart`
  Expected failure: `No named parameter with the name 'hapticEnabled'` / `'haptics'`.
- [ ] Implement in `lib/features/eyecare/presentation/break_overlay.dart`:
  - Add import: `import '../../../core/audio/audio_haptics.dart';`
  - Add constructor params (with defaults so all existing call sites compile): `this.hapticEnabled = true,` and `this.haptics = const AudioHaptics(),`
  - Add fields: `final bool hapticEnabled;` and `final AudioHaptics haptics;`
  - In the `_controller` status listener, when transitioning to completed, after `setState(() => _finished = true);` add: `widget.haptics.cue(HapticKind.breakEnd, enabled: widget.hapticEnabled);`
- [ ] Pass the flag through both presenters:
  - `show_break.dart`: in the `BreakOverlay(...)` constructor add `hapticEnabled: config.hapticEnabled,`
  - `break_screen.dart`: in the `BreakOverlay(...)` constructor add `hapticEnabled: config.hapticEnabled,`
- [ ] Run it (expect PASS): `flutter test test/features/eyecare/break_overlay_test.dart` → `All tests passed!`
- [ ] Run full suite: `flutter test` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/features/eyecare/presentation/break_overlay.dart lib/features/eyecare/presentation/show_break.dart lib/features/eyecare/presentation/break_screen.dart` → `No issues found!`
- [ ] Commit:
```
git add app/lib/features/eyecare/presentation/break_overlay.dart app/lib/features/eyecare/presentation/show_break.dart app/lib/features/eyecare/presentation/break_screen.dart app/test/features/eyecare/break_overlay_test.dart
git commit -m "$(cat <<'EOF'
feat(eyecare): equal breakEnd haptic at the countdown completion

Injectable AudioHaptics seam; honors hapticEnabled, independent of
reduce-motion. The visual bloom + audio end-chime already covered the cue;
this adds the matching haptic. Existing FakeBreakAudio tests unchanged.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 10: ALARM — looped sound + repeating haptic for `ringDurationSeconds`

**Files:**
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\alarm\presentation\alarm_host.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\alarm\alarm_sound_test.dart` (Create)

> `alarm_host.dart` is a stateful host driven by a 10s `Timer.periodic`; hard to time-travel in a widget test. To keep the audio decision testable WITHOUT rewriting the host's scheduling, extract a tiny pure helper + drive playback in `_ring` via the provider. The widget test pumps an `AlarmRingingScreen` wrapped by a minimal harness that invokes the same `startAlarmSound`/`stopAlarmSound` helper through a `FakeAudioService` override, and asserts Stop/Snooze stop it. The host change is verified by `flutter analyze` + the full suite (no behavioral regression) since its timer can't be advanced deterministically here.

- [ ] Write the failing test `test/features/alarm/alarm_sound_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/audio_haptics.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/features/alarm/domain/alarm_item.dart';
import 'package:tarf/features/alarm/presentation/alarm_sound.dart';

void main() {
  group('alarm sound controller', () {
    test('startAlarmSound loops the chosen catalog sound for ringDurationSeconds', () async {
      final fake = FakeAudioService();
      final sink = RecordingHapticSink();
      final ctl = AlarmSoundController(audio: fake, haptics: AudioHaptics(sink));
      await ctl.start(
        const AlarmItem(id: 'a', hour: 6, minute: 30, sound: 'bell', ringDurationSeconds: 45),
        hapticEnabled: true,
        playThroughSilent: true,
      );
      final p = fake.plays.single;
      expect(p.channel, AudioChannel.alarm);
      expect(p.spec.id, 'bell');
      expect(p.loop, isTrue);
      expect(p.duration, const Duration(seconds: 45));
      expect(p.playThroughSilent, isTrue);
      expect(sink.events, contains(HapticKind.alarm));
      ctl.dispose();
    });

    test('an unknown sound id falls back to the default spec', () async {
      final fake = FakeAudioService();
      final ctl = AlarmSoundController(audio: fake, haptics: const AudioHaptics());
      await ctl.start(
        const AlarmItem(id: 'a', hour: 1, minute: 1, sound: 'does-not-exist'),
        hapticEnabled: false,
      );
      expect(fake.plays.single.spec.id, 'default');
      expect(fake.plays.single.spec.role, SoundRole.alarm);
      ctl.dispose();
    });

    test('stop() stops the alarm channel and the repeating haptic', () async {
      final fake = FakeAudioService();
      final sink = RecordingHapticSink();
      final ctl = AlarmSoundController(audio: fake, haptics: AudioHaptics(sink));
      await ctl.start(
        const AlarmItem(id: 'a', hour: 1, minute: 1, sound: 'calm'),
        hapticEnabled: true,
      );
      await ctl.stop();
      expect(fake.stops, contains(AudioChannel.alarm));
      expect(ctl.isRinging, isFalse);
    });

    test('a repeating haptic fires more than once over time', () {
      fakeAsync((async) {
        final fake = FakeAudioService();
        final sink = RecordingHapticSink();
        final ctl = AlarmSoundController(audio: fake, haptics: AudioHaptics(sink));
        ctl.start(
          const AlarmItem(id: 'a', hour: 1, minute: 1, sound: 'bell'),
          hapticEnabled: true,
        );
        async.elapse(const Duration(seconds: 5));
        expect(sink.events.where((e) => e == HapticKind.alarm).length,
            greaterThan(1));
        ctl.stop();
      });
    });
  });
}
```
  (Add `import 'package:fake_async/fake_async.dart';` — `fake_async` ships transitively with `flutter_test`.)
- [ ] Run it (expect FAIL): `flutter test test/features/alarm/alarm_sound_test.dart`
  Expected failure: `Target of URI doesn't exist: 'package:tarf/features/alarm/presentation/alarm_sound.dart'`.
- [ ] Create `lib/features/alarm/presentation/alarm_sound.dart` (the testable controller the host will use):
```dart
import 'dart:async';

import '../../../core/audio/audio_haptics.dart';
import '../../../core/audio/sound_catalog.dart';
import '../../../core/audio/sound_spec.dart';
import '../../../core/audio/tarf_audio_service.dart';
import '../domain/alarm_item.dart';

/// Owns the *sound + haptic* side of a ringing alarm, separate from the modal's
/// visuals. The alarm bell loops for [AlarmItem.ringDurationSeconds] (capped) or
/// until [stop]; a gentle haptic repeats on a fixed cadence in parallel.
class AlarmSoundController {
  AlarmSoundController({
    required TarfAudioService audio,
    AudioHaptics haptics = const AudioHaptics(),
  })  : _audio = audio,
        _haptics = haptics;

  final TarfAudioService _audio;
  final AudioHaptics _haptics;
  Timer? _hapticTimer;
  bool _ringing = false;

  bool get isRinging => _ringing;

  /// Max ring we will hold sound for, so a misconfigured value can't loop forever.
  static const _maxRing = Duration(minutes: 5);
  static const _hapticEvery = Duration(seconds: 2);

  Future<void> start(
    AlarmItem item, {
    required bool hapticEnabled,
    bool playThroughSilent = false,
  }) async {
    if (_ringing) return;
    _ringing = true;
    final base = SoundCatalog.byId(item.sound);
    final spec = SoundSpec.synth(base.id,
        role: SoundRole.alarm,
        layers: base.layers,
        defaultDuration: base.defaultDuration,
        gain: base.gain);
    final ring = Duration(seconds: item.ringDurationSeconds);
    final capped = ring > _maxRing ? _maxRing : ring;
    await _audio.play(spec,
        channel: AudioChannel.alarm,
        loop: true,
        duration: capped,
        playThroughSilent: playThroughSilent);
    if (hapticEnabled) {
      _haptics.cue(HapticKind.alarm, enabled: true);
      _hapticTimer = Timer.periodic(
        _hapticEvery,
        (_) => _haptics.cue(HapticKind.alarm, enabled: true),
      );
    }
  }

  Future<void> stop() async {
    _ringing = false;
    _hapticTimer?.cancel();
    _hapticTimer = null;
    await _audio.stop(AudioChannel.alarm);
  }

  void dispose() {
    _hapticTimer?.cancel();
    _hapticTimer = null;
  }
}
```
- [ ] Run it (expect PASS): `flutter test test/features/alarm/alarm_sound_test.dart` → `All tests passed!`
- [ ] Wire into `lib/features/alarm/presentation/alarm_host.dart`:
  - Add imports: `import '../../../core/audio/audio_providers.dart';`, `import '../../eyecare/application/eyecare_config_controller.dart';` (already imported), and `import 'alarm_sound.dart';`.
  - Add a field: `AlarmSoundController? _sound;`
  - In `_ring(...)`, right after `_ringing = true;`, before pushing the route:
```dart
    final cfg = ref.read(eyeCareConfigProvider);
    _sound = AlarmSoundController(audio: ref.read(tarfAudioServiceProvider))
      ..start(
        item,
        hapticEnabled: cfg.hapticEnabled,
        playThroughSilent: cfg.loudThroughSilence,
      );
```
  - Make `stop()` and `snooze()` stop the sound first: add `_sound?.stop();` as the first line of each closure.
  - In the `finally` block (after the push resolves), add `_sound?.stop(); _sound?.dispose(); _sound = null;` so an auto-timeout (route popped by the OS/back) also silences it.
  - In `dispose()` add `_sound?.dispose();`.

  Note on prayer alarms: the synthesized prayer `AlarmItem` in `_check()` uses the default `sound: 'default'` and `ringDurationSeconds: 60`; that flows through unchanged, so prayer alarms now ring with the default tone — acceptable and consistent. (Per-prayer adhan is an OWNER/Phase-2 task; state honestly, no code here.)
- [ ] Run full suite: `flutter test` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/features/alarm/presentation/alarm_host.dart lib/features/alarm/presentation/alarm_sound.dart` → `No issues found!`
- [ ] Commit:
```
git add app/lib/features/alarm/presentation/alarm_sound.dart app/lib/features/alarm/presentation/alarm_host.dart app/test/features/alarm/alarm_sound_test.dart
git commit -m "$(cat <<'EOF'
feat(alarm): ring the chosen sound looped + repeating haptic

AlarmSoundController loops AlarmItem.sound for ringDurationSeconds (capped),
honors play-through-silent via audio_session, and pulses a gentle haptic;
Stop/Snooze/auto-timeout all silence it. Wired into AlarmHost._ring.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 11: TIMER — `justFinished` flag in the controller

**Files:**
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\timer\application\timer_controller.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\timer\timer_controller_test.dart` (extend — keep existing 4 tests)

> The controller stays pure (no audio); it exposes a one-shot `justFinished` that the screen consumes, mirroring focus's `justCompletedPhase`. `justFinished` is true only on the tick that crosses zero, then cleared.

- [ ] Extend `test/features/timer/timer_controller_test.dart` with a `justFinished` group (uses `fake_async` to advance the 1s ticker):
```dart
// add imports:
//   import 'package:fake_async/fake_async.dart';

  group('justFinished one-shot', () {
    test('is false before the timer reaches zero', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(timerControllerProvider.notifier).setDuration(const Duration(seconds: 2));
      expect(container.read(timerControllerProvider).justFinished, isFalse);
    });

    test('fires exactly on the zero-crossing tick, then clears next tick', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final c = container.read(timerControllerProvider.notifier)
          ..setDuration(const Duration(seconds: 1))
          ..start();
        async.elapse(const Duration(seconds: 1));
        final atZero = container.read(timerControllerProvider);
        expect(atZero.remaining, Duration.zero);
        expect(atZero.finished, isTrue);
        expect(atZero.justFinished, isTrue);
        // The screen will have consumed it; a controller acknowledge clears it.
        c.acknowledgeFinished();
        expect(container.read(timerControllerProvider).justFinished, isFalse);
        expect(container.read(timerControllerProvider).finished, isTrue);
      });
    });

    test('reset clears finished and justFinished', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final c = container.read(timerControllerProvider.notifier)
        ..setDuration(const Duration(seconds: 1));
      c.reset();
      final s = container.read(timerControllerProvider);
      expect(s.finished, isFalse);
      expect(s.justFinished, isFalse);
    });
  });
```
- [ ] Run it (expect FAIL): `flutter test test/features/timer/timer_controller_test.dart`
  Expected failure: `The getter 'justFinished' isn't defined for the class 'CountdownData'`.
- [ ] Implement in `lib/features/timer/application/timer_controller.dart`:
  - Add `this.justFinished = false,` to the `CountdownData` constructor; add field `final bool justFinished;`; add `bool? justFinished,` to `copyWith` and `justFinished: justFinished ?? this.justFinished,` in its body.
  - In `_tick()`, the zero-crossing branch becomes:
```dart
    if (next <= Duration.zero) {
      state = state.copyWith(
        remaining: Duration.zero,
        running: false,
        finished: true,
        justFinished: true,
      );
    } else {
      state = state.copyWith(remaining: next, justFinished: false);
    }
```
  - Add a method `void acknowledgeFinished() { if (state.justFinished) state = state.copyWith(justFinished: false); }`
  - In `setDuration`, `start`, and `reset`, ensure `justFinished: false` is set (they already build fresh `CountdownData`/copyWith; for `start` add `justFinished: false`, for `setDuration`/`reset` the new `CountdownData(...)` defaults it to false — explicit is fine).
- [ ] Run it (expect PASS): `flutter test test/features/timer/timer_controller_test.dart` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/features/timer/application/timer_controller.dart` → `No issues found!`
- [ ] Commit:
```
git add app/lib/features/timer/application/timer_controller.dart app/test/features/timer/timer_controller_test.dart
git commit -m "$(cat <<'EOF'
feat(timer): one-shot justFinished flag on the zero-crossing

Pure controller exposes justFinished (set on the tick that hits zero,
cleared by acknowledgeFinished()/next tick/reset), mirroring focus's
justCompletedPhase so the screen can fire a completion sound + haptic.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 12: TIMER — completion sound looped + haptic + calm "time's up" state

**Files:**
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\timer\presentation\timer_screen.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\timer\timer_sound_test.dart` (Create)

- [ ] Write the failing test `test/features/timer/timer_sound_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/audio/audio_providers.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/timer/application/timer_controller.dart';
import 'package:tarf/features/timer/presentation/timer_screen.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

Widget _host(SharedPreferences prefs, FakeAudioService audio) => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tarfAudioServiceProvider.overrideWithValue(audio),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TimerScreen(),
      ),
    );

void main() {
  testWidgets('plays a looped completion sound on the timer channel at zero',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final audio = FakeAudioService();

    await tester.pumpWidget(_host(prefs, audio));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TimerScreen)),
    );
    final c = container.read(timerControllerProvider.notifier)
      ..setDuration(const Duration(seconds: 1))
      ..start();
    await tester.pump(const Duration(seconds: 1)); // ticker -> zero
    await tester.pump(); // listener runs

    expect(audio.plays, hasLength(1));
    expect(audio.plays.single.channel, AudioChannel.timer);
    expect(audio.plays.single.loop, isTrue);
    expect(audio.plays.single.spec.role, SoundRole.timerDone);
    expect(find.text("Time's up"), findsOneWidget); // calm time's-up state
    // The flag was acknowledged so a rebuild does not double-trigger.
    expect(container.read(timerControllerProvider).justFinished, isFalse);

    // Reset stops the completion sound.
    c.reset();
    await tester.pump();
    expect(audio.stops, contains(AudioChannel.timer));
  });
}
```
- [ ] Run it (expect FAIL): `flutter test test/features/timer/timer_sound_test.dart`
  Expected failure: an `expect(audio.plays, hasLength(1))` mismatch (`Actual: []`) because the screen does not yet react — or a compile error on a missing symbol if any. (Before implementing, the screen plays nothing.)
- [ ] Implement in `lib/features/timer/presentation/timer_screen.dart`:
  - Convert `TimerScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` (so it can `ref.listen` + own a `HapticFeedback` cue). Keep the existing `_IdleView`/`_ActiveView`/`_PresetCircle` unchanged.
  - Add imports: `import '../../../core/audio/audio_providers.dart';`, `import '../../../core/audio/audio_haptics.dart';`, `import '../../../core/audio/sound_catalog.dart';`, `import '../../../core/audio/sound_spec.dart';`, `import '../../../core/audio/tarf_audio_service.dart';`, `import '../../eyecare/application/eyecare_config_controller.dart';`.
  - In `build`, add a `ref.listen(timerControllerProvider, ...)` that, when `next.justFinished && prev?.justFinished != true`, calls a `_onFinished()` method and then `ref.read(timerControllerProvider.notifier).acknowledgeFinished();`.
  - `_onFinished()`:
```dart
  Future<void> _onFinished() async {
    final cfg = ref.read(eyeCareConfigProvider); // reuse global sound/haptic flags
    final audio = ref.read(tarfAudioServiceProvider);
    final base = SoundCatalog.forRole(SoundRole.timerDone);
    if (cfg.soundEnabled) {
      await audio.play(base,
          channel: AudioChannel.timer,
          loop: true,
          playThroughSilent: cfg.loudThroughSilence);
    }
    const AudioHaptics().cue(HapticKind.timerDone, enabled: cfg.hapticEnabled);
  }
```
  - Stop the completion sound when leaving the finished state: in the same `ref.listen`, if `prev?.finished == true && next.finished == false` (Reset/new duration) call `ref.read(tarfAudioServiceProvider).stop(AudioChannel.timer);`. Also call it from a `dispose()` override (`ref.read(...).stop(AudioChannel.timer)` is unsafe in dispose; instead store the service reference in `initState` via `ref.read` is also unavailable — so use `WidgetsBinding.instance.addPostFrameCallback` is overkill). Simplest: stop on Reset via the listener (covered) and rely on `stopAll` at app dispose. The test covers the Reset path.
  - The "calm time's-up state" already exists in `_ActiveView` (`l10n.timeUp` + zero), so no new visual is required; confirm it shows (the test asserts `find.text("Time's up")`). Optionally add a subtle "tap to dismiss" by making Reset also the dismiss — already present.
- [ ] Run it (expect PASS): `flutter test test/features/timer/timer_sound_test.dart` → `All tests passed!`
- [ ] Run full suite (TimerScreen is in navigation/widget tests): `flutter test` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/features/timer/presentation/timer_screen.dart` → `No issues found!`
- [ ] Commit:
```
git add app/lib/features/timer/presentation/timer_screen.dart app/test/features/timer/timer_sound_test.dart
git commit -m "$(cat <<'EOF'
feat(timer): completion sound (looped) + haptic at zero

TimerScreen listens for justFinished, plays the timerDone catalog sound on
the timer channel (looped until dismissed), pulses a haptic, and reuses the
existing calm "Time's up" state; Reset stops the sound. Honors global
sound/haptic/play-through-silent flags.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 13: FOCUS — soft phase-transition chime + haptic on every boundary

**Files:**
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\focus\application\focus_controller.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\focus\focus_sound_test.dart` (Create)

> The pure `advanceFocus` already sets `justCompletedPhase` on BOTH work→break and break→work boundaries. We consume it in `FocusController._tick` (not in `advanceFocus`, which stays pure), so a chime + haptic fire once per transition. Sound/haptic flags reuse `EyeCareConfig` (the app's single sound/haptics toggles).

- [ ] Write the failing test `test/features/focus/focus_sound_test.dart`:
```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/audio/audio_providers.dart';
import 'package:tarf/core/audio/sound_spec.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/eyecare/application/eyecare_config_controller.dart';
import 'package:tarf/features/eyecare/domain/eyecare_config.dart';
import 'package:tarf/features/focus/application/focus_controller.dart';
import 'package:tarf/features/focus/domain/focus_models.dart';

void main() {
  testWidgets('plays a focusTransition chime when work completes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final audio = FakeAudioService();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tarfAudioServiceProvider.overrideWithValue(audio),
    ]);
    addTearDown(container.dispose);

    // Tiny work duration so one tick completes it.
    container.read(focusConfigProvider.notifier).update(
          const FocusConfig(work: Duration(seconds: 1)),
        );
    container.read(focusControllerProvider.notifier).startWork();

    // Pump the real 1s ticker.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(audio.plays.where((p) => p.channel == AudioChannel.focus), hasLength(1));
    expect(audio.plays.single.spec.role, SoundRole.focusTransition);
  });

  test('no chime when sound is disabled', () {
    fakeAsync((async) {
      SharedPreferences.setMockInitialValues({});
      late SharedPreferences prefs;
      // getInstance is async; resolve synchronously within fakeAsync.
      SharedPreferences.getInstance().then((p) => prefs = p);
      async.flushMicrotasks();
      final audio = FakeAudioService();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tarfAudioServiceProvider.overrideWithValue(audio),
      ]);
      container.read(eyeCareConfigProvider.notifier)
          .update(const EyeCareConfig(soundEnabled: false));
      async.flushMicrotasks();
      container.read(focusConfigProvider.notifier)
          .update(const FocusConfig(work: Duration(seconds: 1)));
      container.read(focusControllerProvider.notifier).startWork();
      async.elapse(const Duration(seconds: 1));
      expect(audio.plays.where((p) => p.channel == AudioChannel.focus), isEmpty);
      container.dispose();
    });
  });
}
```
- [ ] Run it (expect FAIL): `flutter test test/features/focus/focus_sound_test.dart`
  Expected failure: `expect(... hasLength(1))` fails with `Actual: <empty>` (controller plays nothing yet).
- [ ] Implement in `lib/features/focus/application/focus_controller.dart`:
  - Add imports: `import '../../../core/audio/audio_haptics.dart';`, `import '../../../core/audio/audio_providers.dart';`, `import '../../../core/audio/sound_catalog.dart';`, `import '../../../core/audio/sound_spec.dart';`, `import '../../../core/audio/tarf_audio_service.dart';`, `import '../../eyecare/application/eyecare_config_controller.dart';`.
  - In `_tick()`, after the existing `if (state.justCompletedPhase == FocusPhase.work) _recordCompletedWork();`, add a call `_onPhaseTransition();` (fires for any non-null `justCompletedPhase`):
```dart
  void _onPhaseTransition() {
    if (state.justCompletedPhase == null) return;
    final cfg = ref.read(eyeCareConfigProvider);
    if (cfg.soundEnabled) {
      final spec = SoundCatalog.forRole(SoundRole.focusTransition);
      ref.read(tarfAudioServiceProvider).play(
            spec,
            channel: AudioChannel.focus,
            playThroughSilent: cfg.loudThroughSilence,
          );
    }
    const AudioHaptics().cue(HapticKind.transition, enabled: cfg.hapticEnabled);
  }
```
  - Call `_onPhaseTransition()` in `_tick()` right after the work-record line (so it runs on both work→break and break→work). Also call it at the end of `skip()` (skip transitions immediately and should cue too): after the `advanceFocus(...)` assignment in `skip()`, add `_onPhaseTransition();`.
- [ ] Run it (expect PASS): `flutter test test/features/focus/focus_sound_test.dart` → `All tests passed!`
- [ ] Run focus reducer + screen tests (ensure no regression): `flutter test test/features/focus/` → `All tests passed!`
- [ ] Run full suite: `flutter test` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/features/focus/application/focus_controller.dart` → `No issues found!`
- [ ] Commit:
```
git add app/lib/features/focus/application/focus_controller.dart app/test/features/focus/focus_sound_test.dart
git commit -m "$(cat <<'EOF'
feat(focus): soft transition chime + haptic on phase boundaries

FocusController consumes justCompletedPhase (work<->break and skip) to play
the focusTransition catalog sound + a selection haptic; advanceFocus stays
pure. Honors global sound/haptic/play-through-silent flags.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 14: WEB autoplay prime — state machine + calm one-time banner

**Files:**
- Create: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\core\audio\web_audio_prime.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\core\audio\web_audio_prime_test.dart` (Create)

> When a break auto-fires on web with no prior gesture, `play()` returns false (blocked). We surface a one-time calm banner; tapping it plays a near-silent priming tone tied to the gesture, which unlocks audio for the session. Native always reports primed (no banner).

- [ ] Write the failing test `test/core/audio/web_audio_prime_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/audio/audio_providers.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/core/audio/web_audio_prime.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

void main() {
  group('WebAudioPrime', () {
    test('on native it reports primed immediately (no banner needed)', () {
      final container = ProviderContainer(overrides: [
        isWebProvider.overrideWithValue(false),
      ]);
      addTearDown(container.dispose);
      expect(container.read(webAudioPrimeProvider).needsPrime, isFalse);
    });

    test('on web it starts not-yet-primed and can be marked blocked', () {
      final container = ProviderContainer(overrides: [
        isWebProvider.overrideWithValue(true),
      ]);
      addTearDown(container.dispose);
      expect(container.read(webAudioPrimeProvider).primed, isFalse);
      container.read(webAudioPrimeProvider.notifier).reportBlocked();
      expect(container.read(webAudioPrimeProvider).needsPrime, isTrue);
    });

    test('priming plays a prime tone and clears needsPrime', () async {
      final audio = FakeAudioService();
      final container = ProviderContainer(overrides: [
        isWebProvider.overrideWithValue(true),
        tarfAudioServiceProvider.overrideWithValue(audio),
      ]);
      addTearDown(container.dispose);
      container.read(webAudioPrimeProvider.notifier).reportBlocked();
      await container.read(webAudioPrimeProvider.notifier).prime();
      expect(audio.plays.single.channel, AudioChannel.preview);
      expect(container.read(webAudioPrimeProvider).primed, isTrue);
      expect(container.read(webAudioPrimeProvider).needsPrime, isFalse);
    });
  });

  testWidgets('TapToEnableSoundBanner shows only when needsPrime and primes on tap',
      (tester) async {
    final audio = FakeAudioService();
    final container = ProviderContainer(overrides: [
      isWebProvider.overrideWithValue(true),
      tarfAudioServiceProvider.overrideWithValue(audio),
    ]);
    addTearDown(container.dispose);
    container.read(webAudioPrimeProvider.notifier).reportBlocked();

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TapToEnableSoundBanner()),
      ),
    ));
    await tester.pump();

    expect(find.text('Tap to enable sound'), findsOneWidget);
    await tester.tap(find.text('Tap to enable sound'));
    await tester.pump();
    expect(audio.plays, isNotEmpty);
    await tester.pump();
    expect(find.text('Tap to enable sound'), findsNothing); // hides once primed
  });
}
```
- [ ] Run it (expect FAIL): `flutter test test/core/audio/web_audio_prime_test.dart`
  Expected failure: `Target of URI doesn't exist: 'package:tarf/core/audio/web_audio_prime.dart'`.
- [ ] Minimal implementation `lib/core/audio/web_audio_prime.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import 'audio_providers.dart';
import 'sound_spec.dart';
import 'tarf_audio_service.dart';

/// Web-autoplay prime state. On native, [primed] is always true and [needsPrime]
/// is always false. On web, audio may be blocked until a user gesture: when a
/// play() is blocked we [reportBlocked]; the calm banner then offers [prime].
@immutable
class WebAudioPrimeState {
  const WebAudioPrimeState({required this.isWeb, this.primed = false, this.blocked = false});
  final bool isWeb;
  final bool primed;
  final bool blocked;

  /// Show the prime affordance only on web, only after a real block, only once.
  bool get needsPrime => isWeb && blocked && !primed;

  WebAudioPrimeState copyWith({bool? primed, bool? blocked}) => WebAudioPrimeState(
        isWeb: isWeb,
        primed: primed ?? this.primed,
        blocked: blocked ?? this.blocked,
      );
}

class WebAudioPrime extends Notifier<WebAudioPrimeState> {
  @override
  WebAudioPrimeState build() {
    final isWeb = ref.watch(isWebProvider);
    // Native needs no prime.
    return WebAudioPrimeState(isWeb: isWeb, primed: !isWeb);
  }

  /// Called when a play() returned false (autoplay blocked) without a gesture.
  void reportBlocked() {
    if (!state.isWeb || state.primed) return;
    if (!state.blocked) state = state.copyWith(blocked: true);
  }

  /// Tied to a user gesture: play a near-silent prime tone to unlock the audio
  /// context, then mark primed for the session.
  Future<void> prime() async {
    final audio = ref.read(tarfAudioServiceProvider);
    const primeTone = SoundSpec.synth('prime', role: SoundRole.breakCue, layers: [
      SoundLayer(frequencyHz: 440, peak: 0.0008, decay: 20),
    ], defaultDuration: Duration(milliseconds: 120));
    await audio.play(primeTone, channel: AudioChannel.preview);
    state = state.copyWith(primed: true, blocked: false);
  }
}

final webAudioPrimeProvider =
    NotifierProvider<WebAudioPrime, WebAudioPrimeState>(WebAudioPrime.new);

/// A calm, one-time "tap to enable sound" strip. Renders nothing unless
/// [WebAudioPrimeState.needsPrime]. The tap is the gesture that unlocks web audio.
class TapToEnableSoundBanner extends ConsumerWidget {
  const TapToEnableSoundBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(webAudioPrimeProvider);
    if (!state.needsPrime) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TarfTokens.space3),
        child: Material(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(TarfTokens.radiusM),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => ref.read(webAudioPrimeProvider.notifier).prime(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TarfTokens.space3,
                vertical: TarfTokens.space2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up_outlined,
                      color: scheme.onSecondaryContainer),
                  const SizedBox(width: TarfTokens.space2),
                  Flexible(
                    child: Text(
                      l10n.tapToEnableSound,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```
  (`l10n.tapToEnableSound` is added in Task 16; this task's widget test will compile only after Task 16's `gen-l10n`. **Order note:** run Task 16 BEFORE the widget portion of this test passes. The non-widget unit tests in this file pass independently. To keep TDD honest, implement Task 16's ARB+gen-l10n first OR temporarily assert against a literal then swap — the plan sequences Task 16 last for strings; therefore: do the three pure-Dart tests here now (they pass), and add the `testWidgets` case after Task 16. Mark the widget test with `, skip: true` until Task 16, then un-skip.)
- [ ] Run the pure tests (expect PASS): `flutter test test/core/audio/web_audio_prime_test.dart --plain-name "WebAudioPrime"` → `All tests passed!`
- [ ] Wire blocked-detection into the break path. In `lib/features/eyecare/audio/just_audio_break_player.dart` `start()`, capture the result and (only relevant on web) let callers know. Simplest non-invasive hook: change `_audio.play(...)` to `final ok = await _audio.play(...);` and return early is unchanged; to report blocks, the *provider* wraps it. Instead, add the report at the break presenter: in `show_break.dart` after building the overlay is too late. Cleanest: have `JustAudioBreakPlayer.start` accept an optional `void Function()? onBlocked` and call it when `ok == false`. Add `onBlocked` param (default null) and `if (!ok) onBlocked?.call();`. Then in `eyecare_providers.dart` `breakAudioProvider`, pass `onBlocked: () => ref.read(webAudioPrimeProvider.notifier).reportBlocked()` (import `web_audio_prime.dart`). Update the Task-8 test only if it asserted the signature — it does not (it uses named `audio`/`soundtrackId`), so it stays green.
- [ ] Run full suite: `flutter test` → `All tests passed!`
- [ ] Analyze: `flutter analyze lib/core/audio/web_audio_prime.dart` → expect `No issues found!` AFTER Task 16 adds the string; if running before Task 16, expect one `The getter 'tapToEnableSound' isn't defined` error — acceptable transient; resolved in Task 16.
- [ ] Commit (after Task 16 makes analyze fully clean, OR commit now with the widget test skipped and re-commit the un-skip in Task 16):
```
git add app/lib/core/audio/web_audio_prime.dart app/lib/features/eyecare/audio/just_audio_break_player.dart app/lib/features/eyecare/application/eyecare_providers.dart app/test/core/audio/web_audio_prime_test.dart
git commit -m "$(cat <<'EOF'
feat(audio): web autoplay prime state + tap-to-enable banner

Detects a blocked web play() (play() -> false) on an ungestured break,
surfaces a one-time calm "tap to enable sound" strip; the tap plays a
near-silent prime tone that unlocks audio for the session. Native reports
primed and shows nothing.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 15: Mount the prime banner + register `assets/audio/`; SETTINGS soundtrack picker & alarm preview

**Files:**
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\app.dart`
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\pubspec.yaml`
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\eyecare\presentation\eyecare_settings_screen.dart`
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\features\alarm\presentation\alarm_editor_screen.dart`
- Test: `C:\Users\sulta\Claude_Code\EyeCure_20\app\test\features\eyecare\break_sound_settings_test.dart` (Create)

- [ ] Write the failing test `test/features/eyecare/break_sound_settings_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/audio/audio_providers.dart';
import 'package:tarf/core/audio/tarf_audio_service.dart';
import 'package:tarf/features/eyecare/application/eyecare_config_controller.dart';
import 'package:tarf/features/eyecare/presentation/eyecare_settings_screen.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

Widget _host(SharedPreferences prefs, FakeAudioService audio) => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tarfAudioServiceProvider.overrideWithValue(audio),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EyeCareSettingsScreen(),
      ),
    );

void main() {
  testWidgets('break-sound picker changes the soundtrack and previews it',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final audio = FakeAudioService();

    await tester.pumpWidget(_host(prefs, audio));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EyeCareSettingsScreen)),
    );
    expect(container.read(eyeCareConfigProvider).breakSoundtrack, 'calm');

    // Open the break-sound row and choose "Chime".
    await tester.tap(find.text('Break sound'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chime').last);
    await tester.pumpAndSettle();

    expect(container.read(eyeCareConfigProvider).breakSoundtrack, 'chime');
    // Choosing previews the sound on the preview channel.
    expect(audio.plays.any((p) => p.channel == AudioChannel.preview), isTrue);
  });
}
```
- [ ] Run it (expect FAIL): `flutter test test/features/eyecare/break_sound_settings_test.dart`
  Expected failure: `find.text('Break sound')` finds nothing (`Actual: <zero widgets>`).
- [ ] Implement the picker in `lib/features/eyecare/presentation/eyecare_settings_screen.dart` — add to the "Behavior & alerts" `TarfGroup` (or a new "Dhikr & audio" group) a `TarfListRow` that opens a bottom-sheet listing `SoundCatalog.breakSoundtrackIds`, sets `breakSoundtrack`, and previews:
  - Add imports: `import '../../../core/audio/audio_providers.dart';`, `import '../../../core/audio/sound_catalog.dart';`, `import '../../../core/audio/sound_spec.dart';`, `import '../../../core/audio/tarf_audio_service.dart';`.
  - Convert the row's `onTap` to a method (since this is a `ConsumerWidget`, do the work inline with `ref`):
```dart
              TarfListRow(
                icon: Icons.library_music_outlined,
                title: l10n.breakSoundLabel,
                trailing: Text(
                  _soundtrackLabel(l10n, cfg.breakSoundtrack),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () => _pickBreakSound(context, ref, cfg.breakSoundtrack),
              ),
```
  - Add top-level helpers in the file:
```dart
String _soundtrackLabel(AppLocalizations l10n, String id) => switch (id) {
      'chime' => l10n.soundChime,
      _ => l10n.soundCalm,
    };

Future<void> _pickBreakSound(
    BuildContext context, WidgetRef ref, String current) async {
  final l10n = AppLocalizations.of(context);
  final audio = ref.read(tarfAudioServiceProvider);
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetCtx) {
      final scheme = Theme.of(sheetCtx).colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final id in SoundCatalog.breakSoundtrackIds)
              ListTile(
                title: Text(_soundtrackLabel(l10n, id)),
                trailing: id == current
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () {
                  final cfg = ref.read(eyeCareConfigProvider);
                  ref.read(eyeCareConfigProvider.notifier)
                      .update(cfg.copyWith(breakSoundtrack: id));
                  final base = SoundCatalog.byId(id);
                  audio.play(
                    SoundSpec.synth(base.id,
                        role: SoundRole.breakBed,
                        layers: base.layers,
                        defaultDuration: base.defaultDuration,
                        gain: base.gain),
                    channel: AudioChannel.preview,
                  );
                  Navigator.of(sheetCtx).pop();
                },
              ),
          ],
        ),
      );
    },
  );
}
```
- [ ] Run it (expect PASS): `flutter test test/features/eyecare/break_sound_settings_test.dart` → `All tests passed!` (after Task 16 adds `breakSoundLabel`; sequence Task 16 first for the new string, then run).
- [ ] Add a "Preview" affordance to the alarm editor's Sound row in `lib/features/alarm/presentation/alarm_editor_screen.dart`: in `_editSound()`'s `ListTile`, add a `trailing` play `IconButton` (alongside the check) that previews the catalog sound for that id on `AudioChannel.preview` without closing the sheet:
  - Add imports: `import '../../../core/audio/audio_providers.dart';`, `import '../../../core/audio/sound_catalog.dart';`, `import '../../../core/audio/sound_spec.dart';`, `import '../../../core/audio/tarf_audio_service.dart';`.
  - Replace the `trailing:` of the sound `ListTile` with a `Row(mainAxisSize: MainAxisSize.min, ...)` containing the existing check icon (when selected) and an `IconButton(icon: const Icon(Icons.play_arrow), onPressed: () { final base = SoundCatalog.byId(id); ref.read(tarfAudioServiceProvider).play(SoundSpec.synth(base.id, role: SoundRole.alarm, layers: base.layers, defaultDuration: base.defaultDuration, gain: base.gain), channel: AudioChannel.preview); })`.
  (No new test for the alarm preview UI beyond `flutter analyze` + the existing alarm tests; the playback wiring is already proven by Task 10.)
- [ ] Register assets in `pubspec.yaml` under `flutter: assets:` (append to the existing list):
```yaml
  assets:
    - assets/dhikr/
    - assets/audio/
    - assets/audio/recitation/
```
  Create the directories so the build doesn't fail on a missing asset folder: add a `.gitkeep` in each (`assets/audio/.gitkeep`, `assets/audio/recitation/.gitkeep`). (No tone assets ship today — the catalog is synth-only; the folders are the reserved drop-in path for owner-supplied recitation. State honestly: recitation clips + scholarly sign-off are OWNER tasks.)
- [ ] Mount the banner in `lib/app.dart` — wrap the routed child so it overlays at the top without disturbing layout. Replace the `builder:` body:
```dart
// import 'core/audio/web_audio_prime.dart';
      builder: (context, child) => AlarmHost(
        child: EyeCareHost(
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const Align(
                alignment: Alignment.topCenter,
                child: TapToEnableSoundBanner(),
              ),
            ],
          ),
        ),
      ),
```
- [ ] Run `pub get` (assets changed): `flutter pub get`
- [ ] Run full suite: `flutter test` → `All tests passed!`
- [ ] Analyze: `flutter analyze` → `No issues found!`
- [ ] Commit:
```
git add app/lib/app.dart app/pubspec.yaml app/lib/features/eyecare/presentation/eyecare_settings_screen.dart app/lib/features/alarm/presentation/alarm_editor_screen.dart app/assets/audio/.gitkeep app/assets/audio/recitation/.gitkeep app/test/features/eyecare/break_sound_settings_test.dart
git commit -m "$(cat <<'EOF'
feat(settings): break-sound picker, alarm sound preview, web prime banner

Eye-care settings gains a Break-sound chooser (sets breakSoundtrack +
previews); alarm editor's Sound rows gain a play-preview button proving the
picker drives playback; app mounts the one-time web tap-to-enable banner;
assets/audio/ (+ recitation/) registered as the reserved drop-in path.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 16: l10n strings (both ARB) + `flutter gen-l10n`

**Files:**
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\l10n\app_en.arb`
- Modify: `C:\Users\sulta\Claude_Code\EyeCure_20\app\lib\l10n\app_ar.arb`
- (Generated, do not hand-edit) `app/lib/l10n/app_localizations*.dart`
- Test: reuse the suite (the new keys are asserted by Task 12/14/15 tests).

> Sequencing: although listed as Task 16 to keep all strings in one place, the keys `tapToEnableSound`, `breakSoundLabel`, and `timerDoneTapToDismiss` are referenced by earlier tasks' code/tests. In practice, ADD these ARB keys and run `gen-l10n` at the FIRST task that needs them (Task 12 → `timerDoneTapToDismiss` optional; Task 14 → `tapToEnableSound`; Task 15 → `breakSoundLabel`), then this task is the consolidation/Arabic-parity pass. Do not leave any task with an undefined getter at its own commit.

- [ ] Add to `app_en.arb` (append before the final `}`; remember the trailing comma on the preceding key):
```json
  "breakSoundLabel": "Break sound",
  "tapToEnableSound": "Tap to enable sound",
  "soundPreview": "Preview",
  "timerDoneTapToDismiss": "Tap reset to dismiss"
```
- [ ] Add the Arabic parity to `app_ar.arb` (same keys; reverent, natural Arabic; Western digits not relevant here as these have no numbers):
```json
  "breakSoundLabel": "صوت الاستراحة",
  "tapToEnableSound": "اضغط لتفعيل الصوت",
  "soundPreview": "استماع",
  "timerDoneTapToDismiss": "اضغط إعادة للإغلاق"
```
  (Confirm `app_ar.arb` already contains the four sound-name keys `soundDefault/soundBell/soundChime/soundCalm`, `soundLabel`, and `timeUp`; the En ARB defines them at lines 196-199/104/24. If any are missing from `app_ar.arb`, add Arabic values: `"soundDefault": "افتراضي"`, `"soundBell": "جرس"`, `"soundChime": "رنين"`, `"soundCalm": "هادئ"`.)
- [ ] Regenerate: `flutter gen-l10n`
  Expected: regenerates `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_ar.dart` with the new getters; no errors.
- [ ] Un-skip the `TapToEnableSoundBanner` widget test from Task 14 (remove `skip: true`).
- [ ] Run full suite: `flutter test` → `All tests passed!`
- [ ] Analyze (now fully clean, including `web_audio_prime.dart` and the settings picker): `flutter analyze` → `No issues found!`
- [ ] Commit:
```
git add app/lib/l10n/app_en.arb app/lib/l10n/app_ar.arb app/lib/l10n/app_localizations.dart app/lib/l10n/app_localizations_en.dart app/lib/l10n/app_localizations_ar.dart app/test/core/audio/web_audio_prime_test.dart
git commit -m "$(cat <<'EOF'
i18n(audio): break-sound, tap-to-enable, preview strings (ar + en)

New ARB keys in both locales + gen-l10n; un-skips the web prime banner
widget test now that the string exists.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Verification

- [ ] **Analyze clean:** `flutter analyze` → `No issues found!` (must stay clean per project rule).
- [ ] **Full test suite green:** `flutter test` → all baseline 58 tests PLUS the new audio tests pass (`+NN: All tests passed!`). Confirm `test/features/eyecare/break_overlay_test.dart` (the `FakeBreakAudio` contract) and `test/features/new_states_test.dart` still pass unchanged.
- [ ] **No real audio in tests:** confirm no test constructs `JustAudioService` and calls `play()` (only the construct/dispose smoke test). All feature tests override `tarfAudioServiceProvider` with `FakeAudioService` (or rely on the Silent default).
- [ ] **Web build compiles:** `flutter build web` → succeeds (validates the data-URI path + `kIsWeb` branches + asset registration).
- [ ] **Web autoplay prime, real browser (headless-Chrome recipe in MEMORY):** serve the web build bound to IPv4 with `--user-data-dir`, navigate, let a break auto-fire WITHOUT clicking first → confirm the calm "Tap to enable sound" strip appears (audio blocked, visual cue still drives the ring). Click it → confirm the strip disappears and a subsequent break plays sound. Capture a screenshot of the primed banner for the PR.
- [ ] **Native sanity (Windows desktop, fastest local target):** `flutter run -d windows` → set a 1-minute alarm, confirm it rings the chosen sound looped with a repeating haptic-less (desktop) but audible cue; Stop silences it. Start a 5s timer → confirm completion sound loops + "Time's up"; Reset silences it. Run a short Focus work phase → confirm a soft chime on the work→break boundary. Take a 20s break → confirm the calm bed plays and ends exactly at zero with the bloom.
- [ ] **RTL/numerals untouched:** the new banner/pickers use directional padding and localized strings; no clock/timer face or numeral was mirrored. Spot-check with `--dart-define=FORCE_THEME=dark` in Arabic.

## Self-review

- [ ] **Spec coverage:**
  - (1) Shared engine extracted to `core/audio/` (`TarfAudioService` + `JustAudioService`); break player refactored to delegate; 58 tests + `FakeBreakAudio` pattern preserved — Tasks 4,5,8.
  - (2) Sound catalog with stable IDs `default/bell/chime/calm`, audibly distinct (distinctness asserted), role-defaults, public API for P2/P3 — Tasks 1,2,3.
  - (3) Alarm rings chosen sound LOOPING for `ringDurationSeconds` (capped) + repeating haptic + play-through-silent via `audio_session` — Task 10.
  - (4) Timer completion sound looped until dismissed + haptic + calm "time's up" — Tasks 11,12.
  - (5) Focus consumes `justCompletedPhase` → transition chime + haptic on work↔break (and skip) — Task 13.
  - (6) Break soundtrack setting + bundled-asset code path (`assets/audio/recitation/…`, `SoundSpec.asset`, `dhikr.audio` override); "sound ends == break ends" kept; clips + sign-off stated as OWNER tasks — Tasks 7,8,15.
  - (7) Web autoplay block detected (`play()` → false → `reportBlocked`) → one-time calm "tap to enable sound" prime tied to a gesture; native unaffected — Task 14.
  - (8) Settings wiring: eye-care Break-sound picker drives `breakSoundtrack`; alarm editor Sound picker now drives playback (preview + stored id flows to host); respects `soundEnabled`/`hapticEnabled`/`loudThroughSilence` — Tasks 10,12,13,15.
  - (9) l10n for new strings (ar + en) + `gen-l10n` — Task 16.
- [ ] **Placeholder scan:** every code step shows ACTUAL Dart; no "TODO/handle edge cases/similar to Task N". Owner-only items (real recitation clips, scholarly sign-off, native background scheduling, per-prayer adhan) are explicitly named, not implemented, not faked.
- [ ] **Type/name consistency:** `SoundSpec`/`SoundLayer`/`SoundRole`/`Waveform` (Task 1) → used identically by `synthesizeTone` (2), `SoundCatalog` (3), services (4,5), break player (8), alarm/timer/focus (10,12,13), prime (14), settings (15). `TarfAudioService`/`AudioChannel`/`PlayCall`/`FakeAudioService`/`SilentAudioService` (Task 4) reused everywhere via `tarfAudioServiceProvider` (5). `AudioHaptics`/`HapticKind`/`HapticSink`/`RecordingHapticSink` (Task 6) reused in 9,10,12,13. `JustAudioBreakPlayer({audio, soundtrackId, recitationAssetPath, onBlocked, ownsService})` defined in Task 8 and used by the provider (8) + prime wiring (14). `CountdownData.justFinished`/`acknowledgeFinished()` (11) consumed by the screen (12). `breakSoundtrack` field (7) read by the provider (8) and settings (15). `webAudioPrimeProvider`/`WebAudioPrimeState.needsPrime`/`reportBlocked`/`prime` (14) used by the banner (14) and `app.dart` (15). `SoundCatalog.alarmIds`/`breakSoundtrackIds`/`byId`/`forRole` (3) used by alarm editor/host, timer, focus, settings. No symbol is used before the task that defines it (l10n getters are the one cross-cutting dependency, handled by adding the ARB key at first use per the Task 16 sequencing note).

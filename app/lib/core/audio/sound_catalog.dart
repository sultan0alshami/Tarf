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
    SoundRole.breakCue: 'chime',
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

  /// The spec for a user-picked [id], retagged to [role] so callers that route
  /// by role (e.g. the timer's completion channel) keep their role semantics
  /// while honoring the chosen sound. Used by per-timer sound: a saved timer
  /// stores an id; at zero we play THAT id at the [SoundRole.timerDone] role.
  /// Asset-backed specs are returned as-is (no layers to retag).
  static SoundSpec forId(String id, {required SoundRole role}) {
    final base = byId(id);
    if (base.isAsset) return base;
    return SoundSpec.synth(base.id, role: role, layers: base.layers,
        defaultDuration: base.defaultDuration, gain: base.gain);
  }
}

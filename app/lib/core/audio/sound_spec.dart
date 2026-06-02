import 'package:flutter/foundation.dart';

/// Which functional slot a sound fills. Lets the catalog supply sensible
/// role-defaults and lets Phase 2/3 ask for "the alarm sound" abstractly.
enum SoundRole { alarm, timerDone, focusTransition, breakStart, breakEnd, breakBed, breakCue }

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

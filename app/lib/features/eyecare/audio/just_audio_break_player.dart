// Private fields are assigned from public named constructor params so callers
// use clean names (audio:/soundtrackId:) rather than underscore-prefixed ones.
// ignore_for_file: prefer_initializing_formals
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
    void Function()? onBlocked,
    bool ownsService = false,
    bool loudThroughSilence = false,
  })  : _audio = audio,
        _soundtrackId = soundtrackId,
        _recitationAssetPath = recitationAssetPath,
        _onBlocked = onBlocked,
        _ownsService = ownsService,
        _loudThroughSilence = loudThroughSilence;

  final TarfAudioService _audio;
  final String _soundtrackId;
  final String? _recitationAssetPath;
  final void Function()? _onBlocked;
  final bool _ownsService;

  /// Mirrors the user's "play even when the phone is on silent" choice; forwarded
  /// to the engine so the dhikr break bed honors it like the alarm/timer/focus do.
  final bool _loudThroughSilence;

  SoundSpec _spec() {
    // Bundled recitation clip wins when configured AND present (owner-supplied).
    final recitation = _recitationAssetPath;
    if (recitation != null) {
      return SoundSpec.asset(_soundtrackId, recitation,
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
    final ok = await _audio.play(
      spec,
      channel: AudioChannel.breakBed,
      duration: duration, // sound ends == break ends
      playThroughSilent: _loudThroughSilence,
    );
    if (!ok) _onBlocked?.call();
  }

  @override
  Future<void> stop() async => _audio.stop(AudioChannel.breakBed);

  @override
  Future<void> dispose() async {
    if (_ownsService) await _audio.dispose();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_providers.dart';
import '../audio/break_audio.dart';
import '../audio/just_audio_break_player.dart';
import '../data/dhikr_repository.dart';
import 'eyecare_config_controller.dart';

/// Loads the bundled adhkar set once.
final dhikrRepositoryProvider = FutureProvider<DhikrRepository>(
  (ref) => DhikrRepository.load(),
);

/// The break audio player — a thin adapter over the shared audio engine that
/// plays the user's chosen break soundtrack for the full duration.
final breakAudioProvider = Provider<BreakAudioPlayer>((ref) {
  final audio = ref.watch(tarfAudioServiceProvider);
  final soundtrack = ref.watch(
    eyeCareConfigProvider.select((c) => c.breakSoundtrack),
  );
  return JustAudioBreakPlayer(audio: audio, soundtrackId: soundtrack);
});

/// Persisted rotation counter so the dhikr varies across breaks and restarts.
class DhikrRotation extends Notifier<int> {
  @override
  int build() => 0;

  void next() => state = state + 1;
}

final dhikrRotationProvider =
    NotifierProvider<DhikrRotation, int>(DhikrRotation.new);

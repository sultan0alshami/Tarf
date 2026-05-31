import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/break_audio.dart';
import '../data/dhikr_repository.dart';

/// Loads the bundled adhkar set once.
final dhikrRepositoryProvider = FutureProvider<DhikrRepository>(
  (ref) => DhikrRepository.load(),
);

/// The break audio player. Defaults to silent; the native backend
/// (just_audio / TTS / offscreen) overrides this per platform in P4.
final breakAudioProvider = Provider<BreakAudioPlayer>(
  (ref) => const SilentBreakAudio(),
);

/// Persisted rotation counter so the dhikr varies across breaks and restarts.
class DhikrRotation extends Notifier<int> {
  @override
  int build() => 0;

  void next() => state = state + 1;
}

final dhikrRotationProvider =
    NotifierProvider<DhikrRotation, int>(DhikrRotation.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/break_audio.dart';
import '../audio/just_audio_break_player.dart';
import '../data/dhikr_repository.dart';

/// Loads the bundled adhkar set once.
final dhikrRepositoryProvider = FutureProvider<DhikrRepository>(
  (ref) => DhikrRepository.load(),
);

/// The break audio player — a real cross-platform synthesized 20s sound.
final breakAudioProvider = Provider<BreakAudioPlayer>((ref) {
  final player = JustAudioBreakPlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// Persisted rotation counter so the dhikr varies across breaks and restarts.
class DhikrRotation extends Notifier<int> {
  @override
  int build() => 0;

  void next() => state = state + 1;
}

final dhikrRotationProvider =
    NotifierProvider<DhikrRotation, int>(DhikrRotation.new);

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

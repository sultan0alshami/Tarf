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
      const ids = SoundCatalog.alarmIds;
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

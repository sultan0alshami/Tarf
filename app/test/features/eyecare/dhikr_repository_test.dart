import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/eyecare/data/dhikr_repository.dart';
import 'package:tarf/features/eyecare/domain/dhikr.dart';

const _sample = '''
{
  "dhikr": [
    {"id":"a","arabic":"أ","transliteration":"a","english":"A","reference":"R1"},
    {"id":"b","arabic":"ب","transliteration":"b","english":"B","reference":"R2"},
    {"id":"c","arabic":"ج","transliteration":"c","english":"C","reference":"R3"}
  ]
}
''';

void main() {
  group('DhikrRepository', () {
    test('parses entries from JSON', () {
      final repo = DhikrRepository.fromJsonString(_sample);
      expect(repo.length, 3);
      expect(repo.all.first.id, 'a');
      expect(repo.all.first.arabic, 'أ');
    });

    test('rotates deterministically and wraps around', () {
      final repo = DhikrRepository.fromJsonString(_sample);
      expect(repo.at(0).id, 'a');
      expect(repo.at(1).id, 'b');
      expect(repo.at(2).id, 'c');
      expect(repo.at(3).id, 'a'); // wraps
      expect(repo.at(4).id, 'b');
    });

    test('handles negative indices safely', () {
      final repo = DhikrRepository.fromJsonString(_sample);
      expect(repo.at(-1).id, 'c');
      expect(repo.at(-3).id, 'a');
    });
  });

  group('DhikrRepository.resolveAudio (recitation drop-in)', () {
    List<Dhikr> dhikr(List<(String, String?)> idsAndAudio) => [
          for (final (id, audio) in idsAndAudio)
            Dhikr(
              id: id,
              arabic: 'x',
              transliteration: 'x',
              english: 'x',
              reference: 'r',
              audio: audio,
            ),
        ];

    test('auto-assigns a recitation clip whose name matches the dhikr id', () {
      final resolved = DhikrRepository.resolveAudio(
        dhikr([('subhanallah', null)]),
        const {'assets/audio/recitation/subhanallah.ogg'},
      );
      expect(resolved.single.audio, 'assets/audio/recitation/subhanallah.ogg');
    });

    test('leaves audio null when no matching clip is present', () {
      final resolved = DhikrRepository.resolveAudio(
        dhikr([('astaghfirullah', null)]),
        const {'assets/audio/recitation/.gitkeep'},
      );
      expect(resolved.single.audio, isNull);
    });

    test('an explicit audio path in the JSON always wins over a dropped clip',
        () {
      final resolved = DhikrRepository.resolveAudio(
        dhikr([('salawat', 'assets/audio/recitation/curated-salawat.m4a')]),
        const {
          'assets/audio/recitation/salawat.ogg',
          'assets/audio/recitation/curated-salawat.m4a',
        },
      );
      expect(resolved.single.audio,
          'assets/audio/recitation/curated-salawat.m4a');
    });

    test('prefers extensions in order: ogg, oga, m4a, aac, mp3, wav', () {
      // All candidates present at once -> ogg wins.
      final all = DhikrRepository.resolveAudio(
        dhikr([('alhamdulillah', null)]),
        const {
          'assets/audio/recitation/alhamdulillah.wav',
          'assets/audio/recitation/alhamdulillah.mp3',
          'assets/audio/recitation/alhamdulillah.aac',
          'assets/audio/recitation/alhamdulillah.m4a',
          'assets/audio/recitation/alhamdulillah.oga',
          'assets/audio/recitation/alhamdulillah.ogg',
        },
      );
      expect(all.single.audio, 'assets/audio/recitation/alhamdulillah.ogg');

      // Only m4a + mp3 present -> m4a wins (earlier in the order).
      final some = DhikrRepository.resolveAudio(
        dhikr([('alhamdulillah', null)]),
        const {
          'assets/audio/recitation/alhamdulillah.mp3',
          'assets/audio/recitation/alhamdulillah.m4a',
        },
      );
      expect(some.single.audio, 'assets/audio/recitation/alhamdulillah.m4a');
    });

    test('ignores clips that do not match any dhikr id', () {
      final resolved = DhikrRepository.resolveAudio(
        dhikr([('subhanallah', null)]),
        const {'assets/audio/recitation/some-other-id.ogg'},
      );
      expect(resolved.single.audio, isNull);
    });

    test('does not match a clip whose name only contains the id as a substring',
        () {
      // "la-hawla" must not be matched by "la-hawla-extra.ogg".
      final resolved = DhikrRepository.resolveAudio(
        dhikr([('la-hawla', null)]),
        const {'assets/audio/recitation/la-hawla-extra.ogg'},
      );
      expect(resolved.single.audio, isNull);
    });

    test('resolves each dhikr independently across the set', () {
      final resolved = DhikrRepository.resolveAudio(
        dhikr([
          ('subhanallah', null),
          ('alhamdulillah', null),
          ('salawat', null),
        ]),
        const {
          'assets/audio/recitation/subhanallah.ogg',
          'assets/audio/recitation/salawat.m4a',
        },
      );
      expect(resolved[0].audio, 'assets/audio/recitation/subhanallah.ogg');
      expect(resolved[1].audio, isNull); // no clip dropped
      expect(resolved[2].audio, 'assets/audio/recitation/salawat.m4a');
    });
  });
}

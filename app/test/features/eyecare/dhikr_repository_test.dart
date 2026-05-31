import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/eyecare/data/dhikr_repository.dart';

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
}

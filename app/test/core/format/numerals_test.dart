import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/format/numerals.dart';

void main() {
  group('Numerals', () {
    test('default numeral system follows locale', () {
      expect(Numerals.defaultForLocale('ar'), NumeralSystem.arabicIndic);
      expect(Numerals.defaultForLocale('ar_SA'), NumeralSystem.arabicIndic);
      expect(Numerals.defaultForLocale('en'), NumeralSystem.western);
    });

    test('formatInt renders western digits', () {
      expect(Numerals.formatInt(2023, NumeralSystem.western), '2,023');
    });

    test('formatInt renders Eastern Arabic-Indic digits', () {
      expect(Numerals.formatInt(123, NumeralSystem.arabicIndic), '١٢٣');
    });

    test('padded clock segment zero-pads to width 2', () {
      expect(Numerals.padded(5, NumeralSystem.western), '05');
      expect(Numerals.padded(5, NumeralSystem.arabicIndic), '٠٥');
    });

    test('timer formats mm:ss in both systems', () {
      expect(
        Numerals.timer(const Duration(minutes: 1, seconds: 5), NumeralSystem.western),
        '01:05',
      );
      expect(
        Numerals.timer(const Duration(seconds: 20), NumeralSystem.arabicIndic),
        '٠٠:٢٠',
      );
    });
  });
}

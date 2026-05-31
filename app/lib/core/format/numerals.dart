import 'package:intl/intl.dart';

/// Which digit glyphs to render.
enum NumeralSystem {
  /// 0123456789 (Western Arabic / Latin).
  western,

  /// ٠١٢٣٤٥٦٧٨٩ (Eastern Arabic-Indic), the default for Arabic locale.
  arabicIndic,
}

/// Formats numbers for display, honoring the user's chosen numeral system.
///
/// Tabular alignment of the rendered text is handled by the UI font's tabular
/// figures (see [TarfTheme]); this class only decides *which glyphs* appear.
abstract final class Numerals {
  Numerals._();

  static const _arabicIndicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  /// The default numeral system. Tarf uses Western digits (1234) everywhere —
  /// including the Arabic locale — because those are the digits used across the
  /// Arab world. (Eastern "Hindi" digits ٠١٢٣ remain available via the enum for
  /// an optional future setting, but are not the default.)
  static NumeralSystem defaultForLocale(String localeCode) =>
      NumeralSystem.western;

  /// Formats an integer in [system].
  static String formatInt(int value, NumeralSystem system) {
    final western = NumberFormat.decimalPattern('en').format(value);
    return system == NumeralSystem.arabicIndic ? _toArabicIndic(western) : western;
  }

  /// Formats a clock segment with zero padding, e.g. 5 -> "05".
  static String padded(int value, NumeralSystem system, {int width = 2}) {
    final western = value.toString().padLeft(width, '0');
    return system == NumeralSystem.arabicIndic ? _toArabicIndic(western) : western;
  }

  /// Formats a mm:ss timer string in the given [system].
  static String timer(Duration d, NumeralSystem system) {
    final totalSeconds = d.inSeconds.abs();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${padded(minutes, system)}:${padded(seconds, system)}';
  }

  /// Formats a stopwatch string mm:ss.cc (centiseconds) in [system].
  static String stopwatch(Duration d, NumeralSystem system) {
    final total = d.inMilliseconds.abs();
    final minutes = total ~/ 60000;
    final seconds = (total ~/ 1000) % 60;
    final centis = (total % 1000) ~/ 10;
    return '${padded(minutes, system)}:${padded(seconds, system)}'
        '.${padded(centis, system)}';
  }

  static String _toArabicIndic(String western) {
    final buffer = StringBuffer();
    for (final ch in western.codeUnits) {
      if (ch >= 0x30 && ch <= 0x39) {
        buffer.write(_arabicIndicDigits[ch - 0x30]);
      } else {
        buffer.writeCharCode(ch);
      }
    }
    return buffer.toString();
  }
}

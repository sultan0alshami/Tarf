import 'package:flutter/foundation.dart';

/// A selectable prayer-time option: a stable [id] persisted in EyeCareConfig
/// and an [l10nKey] used to look up the localized label in the UI. Pure data —
/// no Flutter/adhan imports so it stays trivially testable.
@immutable
class PrayerOption {
  const PrayerOption(this.id, this.l10nKey);
  final String id;
  final String l10nKey;
}

/// Calculation methods Tarf exposes, ordered with the KSA default first. The
/// [id]s MUST stay in lockstep with PrayerService._params' switch arms.
const List<PrayerOption> kPrayerMethods = [
  PrayerOption('ummAlQura', 'prayerMethodUmmAlQura'),
  PrayerOption('muslimWorldLeague', 'prayerMethodMwl'),
  PrayerOption('egyptian', 'prayerMethodEgyptian'),
  PrayerOption('karachi', 'prayerMethodKarachi'),
  PrayerOption('dubai', 'prayerMethodDubai'),
  PrayerOption('qatar', 'prayerMethodQatar'),
  PrayerOption('kuwait', 'prayerMethodKuwait'),
  PrayerOption('northAmerica', 'prayerMethodNorthAmerica'),
  PrayerOption('turkey', 'prayerMethodTurkey'),
];

/// The two madhabs adhan supports for Asr calculation.
const List<PrayerOption> kMadhabs = [
  PrayerOption('shafi', 'madhabShafi'),
  PrayerOption('hanafi', 'madhabHanafi'),
];

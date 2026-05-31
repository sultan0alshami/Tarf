// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Tarf';

  @override
  String get tabFocus => 'Focus';

  @override
  String get tabTimer => 'Timer';

  @override
  String get tabAlarm => 'Alarm';

  @override
  String get tabStopwatch => 'Stopwatch';

  @override
  String get navInsights => 'Insights';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionStart => 'Start';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionSnooze => 'Snooze';

  @override
  String get actionDone => 'Done';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get lap => 'Lap';

  @override
  String get timeUp => 'Time\'s up';

  @override
  String get eyeCareTitle => 'Eye care';

  @override
  String get takeBreakNow => 'Take a break now';

  @override
  String get breakLookAway => 'Look 20 feet away';

  @override
  String get breakInstruction => 'Rest your eyes for 20 seconds';

  @override
  String get breakRepeatAfter => 'Repeat after the recitation';

  @override
  String get breakOver => 'You may look back now';

  @override
  String get transliterationShow => 'Show transliteration';

  @override
  String get transliterationHide => 'Hide transliteration';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get signInTitle => 'Sign in to sync';

  @override
  String get signInRationale =>
      'Sign in once to enable cross-device sync and back up your progress. The eye-care break works without an account.';

  @override
  String get signInGoogle => 'Continue with Google';

  @override
  String get signInApple => 'Continue with Apple';

  @override
  String get signInEmail => 'Continue with email';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get focusDailyGoal => 'Daily goal';

  @override
  String get focusReady => 'Ready to focus';

  @override
  String get phaseWork => 'Focus';

  @override
  String get phaseShortBreak => 'Short break';

  @override
  String get phaseLongBreak => 'Long break';

  @override
  String get restEyes => 'Rest eyes';

  @override
  String focusSessionsProgress(int done, int goal) {
    return '$done / $goal sessions today';
  }

  @override
  String focusSessionsToday(int count) {
    return '$count sessions today';
  }

  @override
  String todayMinutes(int minutes) {
    return '$minutes min focused today';
  }
}

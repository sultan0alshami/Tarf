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

  @override
  String get insightsToday => 'Today';

  @override
  String insightsStreak(int days) {
    return '$days-day streak';
  }

  @override
  String get labelFocusMinutes => 'Focus minutes';

  @override
  String get labelSessions => 'Sessions';

  @override
  String get labelBreaks => 'Breaks taken';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get noDataYet => 'No data yet — start a focus session';

  @override
  String get tasks => 'Tasks';

  @override
  String get addTask => 'Add task';

  @override
  String get taskHint => 'What are you working on?';

  @override
  String get noTasks => 'No tasks yet';

  @override
  String get startFocus => 'Start focus';

  @override
  String get estLabel => 'est.';

  @override
  String get alarms => 'Alarms';

  @override
  String get addAlarm => 'Add alarm';

  @override
  String get noAlarms => 'No alarms yet';

  @override
  String get alarmNativeNote =>
      'Alarms will ring once native scheduling is enabled on this device.';

  @override
  String get eyeCareEnabled => 'Eye-care reminders';

  @override
  String get reminderInterval => 'Reminder interval';

  @override
  String get breakLength => 'Break length';

  @override
  String get twoTierBreaks => 'Add longer stand/stretch breaks';

  @override
  String get longBreakInterval => 'Long break interval';

  @override
  String get longBreakLength => 'Long break length';

  @override
  String get strictMode => 'Strict mode (no skip)';

  @override
  String get soundLabel => 'Sound';

  @override
  String get hapticsLabel => 'Haptics';

  @override
  String get prayerPauseLabel => 'Pause around prayer times';

  @override
  String get loudThroughSilenceLabel => 'Play through silent mode';

  @override
  String minutesShort(int n) {
    return '$n min';
  }

  @override
  String secondsShort(int n) {
    return '$n s';
  }

  @override
  String get onbTitle => 'Rest your eyes, remember Allah';

  @override
  String get onbBody =>
      'Every 20 minutes, Tarf gently invites you to look away for 20 seconds with a calm dhikr — caring for your eyes and your heart.';

  @override
  String get onbChooseLanguage => 'Choose your language';

  @override
  String get onbChooseTheme => 'Choose your theme';

  @override
  String get onbQuickSetup => 'Quick setup';

  @override
  String get onbNext => 'Next';

  @override
  String get onbGetStarted => 'Get started';

  @override
  String get accountTitle => 'Account & Sync';

  @override
  String get accountGuest => 'Guest — your data stays on this device';

  @override
  String get syncSetupNote =>
      'Cloud sync and sign-in require connecting Firebase. See docs/firebase-setup.md.';

  @override
  String get exportData => 'Export my data';

  @override
  String get deleteAllData => 'Delete all my data';

  @override
  String get deleteAllConfirm =>
      'This permanently deletes all your Tarf data on this device and cannot be undone.';

  @override
  String get dataExported => 'Your data was copied to the clipboard';

  @override
  String get dataDeleted => 'All data deleted';

  @override
  String get tabHome => 'Home';

  @override
  String get nextEyeBreak => 'Next eye break';

  @override
  String eyeRestsToday(int count) {
    return '$count eye rests today';
  }

  @override
  String get startFocusSession => 'Start focus session';

  @override
  String get pausedLabel => 'Paused';

  @override
  String get focusTodayLabel => 'Focus today';

  @override
  String get todosLabel => 'To-dos';

  @override
  String get editDurations => 'Edit durations';
}

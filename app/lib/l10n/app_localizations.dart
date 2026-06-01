import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The app name (brand).
  ///
  /// In en, this message translates to:
  /// **'Tarf'**
  String get appName;

  /// No description provided for @tabFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get tabFocus;

  /// No description provided for @tabTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get tabTimer;

  /// No description provided for @tabAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get tabAlarm;

  /// No description provided for @tabStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Stopwatch'**
  String get tabStopwatch;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// No description provided for @actionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// No description provided for @actionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get actionSnooze;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @lap.
  ///
  /// In en, this message translates to:
  /// **'Lap'**
  String get lap;

  /// No description provided for @timeUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up'**
  String get timeUp;

  /// No description provided for @eyeCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Eye care'**
  String get eyeCareTitle;

  /// No description provided for @takeBreakNow.
  ///
  /// In en, this message translates to:
  /// **'Take a break now'**
  String get takeBreakNow;

  /// No description provided for @breakLookAway.
  ///
  /// In en, this message translates to:
  /// **'Look 20 feet away'**
  String get breakLookAway;

  /// No description provided for @breakInstruction.
  ///
  /// In en, this message translates to:
  /// **'Rest your eyes for 20 seconds'**
  String get breakInstruction;

  /// No description provided for @breakRepeatAfter.
  ///
  /// In en, this message translates to:
  /// **'Repeat after the recitation'**
  String get breakRepeatAfter;

  /// No description provided for @breakOver.
  ///
  /// In en, this message translates to:
  /// **'You may look back now'**
  String get breakOver;

  /// No description provided for @transliterationShow.
  ///
  /// In en, this message translates to:
  /// **'Show transliteration'**
  String get transliterationShow;

  /// No description provided for @transliterationHide.
  ///
  /// In en, this message translates to:
  /// **'Hide transliteration'**
  String get transliterationHide;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync'**
  String get signInTitle;

  /// No description provided for @signInRationale.
  ///
  /// In en, this message translates to:
  /// **'Sign in once to enable cross-device sync and back up your progress. The eye-care break works without an account.'**
  String get signInRationale;

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInGoogle;

  /// No description provided for @signInApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get signInApple;

  /// No description provided for @signInEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get signInEmail;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @focusDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get focusDailyGoal;

  /// No description provided for @focusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to focus'**
  String get focusReady;

  /// No description provided for @focusSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session complete'**
  String get focusSessionComplete;

  /// No description provided for @phaseWork.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get phaseWork;

  /// No description provided for @phaseShortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short break'**
  String get phaseShortBreak;

  /// No description provided for @phaseLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Long break'**
  String get phaseLongBreak;

  /// No description provided for @restEyes.
  ///
  /// In en, this message translates to:
  /// **'Rest eyes'**
  String get restEyes;

  /// No description provided for @focusSessionsProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {goal} sessions today'**
  String focusSessionsProgress(int done, int goal);

  /// No description provided for @focusSessionsToday.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions today'**
  String focusSessionsToday(int count);

  /// No description provided for @todayMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min focused today'**
  String todayMinutes(int minutes);

  /// No description provided for @insightsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get insightsToday;

  /// No description provided for @insightsStreak.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String insightsStreak(int days);

  /// No description provided for @labelFocusMinutes.
  ///
  /// In en, this message translates to:
  /// **'Focus minutes'**
  String get labelFocusMinutes;

  /// No description provided for @labelSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get labelSessions;

  /// No description provided for @labelBreaks.
  ///
  /// In en, this message translates to:
  /// **'Breaks taken'**
  String get labelBreaks;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet — start a focus session'**
  String get noDataYet;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// No description provided for @taskHint.
  ///
  /// In en, this message translates to:
  /// **'What are you working on?'**
  String get taskHint;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasks;

  /// No description provided for @startFocus.
  ///
  /// In en, this message translates to:
  /// **'Start focus'**
  String get startFocus;

  /// No description provided for @estLabel.
  ///
  /// In en, this message translates to:
  /// **'est.'**
  String get estLabel;

  /// No description provided for @alarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarms;

  /// No description provided for @addAlarm.
  ///
  /// In en, this message translates to:
  /// **'Add alarm'**
  String get addAlarm;

  /// No description provided for @noAlarms.
  ///
  /// In en, this message translates to:
  /// **'No alarms yet'**
  String get noAlarms;

  /// No description provided for @alarmNativeNote.
  ///
  /// In en, this message translates to:
  /// **'Alarms will ring once native scheduling is enabled on this device.'**
  String get alarmNativeNote;

  /// No description provided for @eyeCareEnabled.
  ///
  /// In en, this message translates to:
  /// **'Eye-care reminders'**
  String get eyeCareEnabled;

  /// No description provided for @reminderInterval.
  ///
  /// In en, this message translates to:
  /// **'Reminder interval'**
  String get reminderInterval;

  /// No description provided for @breakLength.
  ///
  /// In en, this message translates to:
  /// **'Break length'**
  String get breakLength;

  /// No description provided for @twoTierBreaks.
  ///
  /// In en, this message translates to:
  /// **'Add longer stand/stretch breaks'**
  String get twoTierBreaks;

  /// No description provided for @longBreakInterval.
  ///
  /// In en, this message translates to:
  /// **'Long break interval'**
  String get longBreakInterval;

  /// No description provided for @longBreakLength.
  ///
  /// In en, this message translates to:
  /// **'Long break length'**
  String get longBreakLength;

  /// No description provided for @strictMode.
  ///
  /// In en, this message translates to:
  /// **'Strict mode (no skip)'**
  String get strictMode;

  /// No description provided for @soundLabel.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get soundLabel;

  /// No description provided for @hapticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get hapticsLabel;

  /// No description provided for @prayerPauseLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause around prayer times'**
  String get prayerPauseLabel;

  /// No description provided for @loudThroughSilenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Play through silent mode'**
  String get loudThroughSilenceLabel;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutesShort(int n);

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'{n} s'**
  String secondsShort(int n);

  /// No description provided for @onbTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest your eyes, remember Allah'**
  String get onbTitle;

  /// No description provided for @onbBody.
  ///
  /// In en, this message translates to:
  /// **'Every 20 minutes, Tarf gently invites you to look away for 20 seconds with a calm dhikr — caring for your eyes and your heart.'**
  String get onbBody;

  /// No description provided for @onbChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onbChooseLanguage;

  /// No description provided for @onbChooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose your theme'**
  String get onbChooseTheme;

  /// No description provided for @onbQuickSetup.
  ///
  /// In en, this message translates to:
  /// **'Quick setup'**
  String get onbQuickSetup;

  /// No description provided for @onbNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// No description provided for @onbGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onbGetStarted;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & Sync'**
  String get accountTitle;

  /// No description provided for @accountGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest — your data stays on this device'**
  String get accountGuest;

  /// No description provided for @syncSetupNote.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync and sign-in require connecting Firebase. See docs/firebase-setup.md.'**
  String get syncSetupNote;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportData;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all my data'**
  String get deleteAllData;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes all your Tarf data on this device and cannot be undone.'**
  String get deleteAllConfirm;

  /// No description provided for @dataExported.
  ///
  /// In en, this message translates to:
  /// **'Your data was copied to the clipboard'**
  String get dataExported;

  /// No description provided for @dataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get dataDeleted;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @nextEyeBreak.
  ///
  /// In en, this message translates to:
  /// **'Next eye break'**
  String get nextEyeBreak;

  /// No description provided for @eyeRestsToday.
  ///
  /// In en, this message translates to:
  /// **'{count} eye rests today'**
  String eyeRestsToday(int count);

  /// No description provided for @startFocusSession.
  ///
  /// In en, this message translates to:
  /// **'Start focus session'**
  String get startFocusSession;

  /// No description provided for @pausedLabel.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pausedLabel;

  /// No description provided for @focusTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus today'**
  String get focusTodayLabel;

  /// No description provided for @todosLabel.
  ///
  /// In en, this message translates to:
  /// **'To-dos'**
  String get todosLabel;

  /// No description provided for @editDurations.
  ///
  /// In en, this message translates to:
  /// **'Edit durations'**
  String get editDurations;

  /// No description provided for @unitHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get unitHours;

  /// No description provided for @unitMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get unitMinutes;

  /// No description provided for @unitSeconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get unitSeconds;

  /// No description provided for @alarmRepeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get alarmRepeatDaily;

  /// No description provided for @alarmRepeatWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get alarmRepeatWeekdays;

  /// No description provided for @alarmRepeatWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get alarmRepeatWeekends;

  /// No description provided for @alarmRepeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get alarmRepeatOnce;

  /// No description provided for @alarmRepeatCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get alarmRepeatCustom;

  /// No description provided for @alarmLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fajr, Wake up'**
  String get alarmLabelHint;

  /// No description provided for @alarmDeleted.
  ///
  /// In en, this message translates to:
  /// **'Alarm deleted'**
  String get alarmDeleted;

  /// No description provided for @alarmToggleSemantic.
  ///
  /// In en, this message translates to:
  /// **'Toggle alarm'**
  String get alarmToggleSemantic;

  /// No description provided for @lapNumber.
  ///
  /// In en, this message translates to:
  /// **'Lap {n}'**
  String lapNumber(int n);

  /// No description provided for @lapTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get lapTotal;

  /// No description provided for @lapFastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get lapFastest;

  /// No description provided for @lapSlowest.
  ///
  /// In en, this message translates to:
  /// **'Slowest'**
  String get lapSlowest;

  /// No description provided for @noLapsYet.
  ///
  /// In en, this message translates to:
  /// **'No laps yet'**
  String get noLapsYet;

  /// No description provided for @insightsEyeRestsCaption.
  ///
  /// In en, this message translates to:
  /// **'Eye rests today'**
  String get insightsEyeRestsCaption;

  /// No description provided for @insightsEyeRestsSubline.
  ///
  /// In en, this message translates to:
  /// **'Nicely done — your eyes thank you.'**
  String get insightsEyeRestsSubline;

  /// No description provided for @insightsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get insightsThisWeek;

  /// No description provided for @todosEmptyLine.
  ///
  /// In en, this message translates to:
  /// **'We\'re here whenever you need a moment'**
  String get todosEmptyLine;

  /// No description provided for @todoSessions.
  ///
  /// In en, this message translates to:
  /// **'{actual} of {estimated} sessions'**
  String todoSessions(int actual, int estimated);

  /// No description provided for @settingsEyeCare.
  ///
  /// In en, this message translates to:
  /// **'Eye-care'**
  String get settingsEyeCare;

  /// No description provided for @settingsBreakInterval.
  ///
  /// In en, this message translates to:
  /// **'Break interval'**
  String get settingsBreakInterval;

  /// No description provided for @settingsBreakDuration.
  ///
  /// In en, this message translates to:
  /// **'Break duration'**
  String get settingsBreakDuration;

  /// No description provided for @settingsDhikrAudio.
  ///
  /// In en, this message translates to:
  /// **'Dhikr & audio'**
  String get settingsDhikrAudio;

  /// No description provided for @settingsMoreEyeCare.
  ///
  /// In en, this message translates to:
  /// **'More eye-care settings'**
  String get settingsMoreEyeCare;

  /// No description provided for @settingsNumerals.
  ///
  /// In en, this message translates to:
  /// **'Numerals'**
  String get settingsNumerals;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @syncStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline · On this device'**
  String get syncStatusOffline;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @eyeCareSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Eye-care settings'**
  String get eyeCareSettingsTitle;

  /// No description provided for @coreBreakGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder & rest'**
  String get coreBreakGroupLabel;

  /// No description provided for @longerBreakGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Longer stand & stretch break'**
  String get longerBreakGroupLabel;

  /// No description provided for @behaviorAlertsGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Behavior & alerts'**
  String get behaviorAlertsGroupLabel;

  /// No description provided for @alarmStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get alarmStandard;

  /// No description provided for @alarmPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get alarmPrayer;

  /// No description provided for @ringInHm.
  ///
  /// In en, this message translates to:
  /// **'Ring in {h}h {m}m'**
  String ringInHm(int h, int m);

  /// No description provided for @editAlarm.
  ///
  /// In en, this message translates to:
  /// **'Edit alarm'**
  String get editAlarm;

  /// No description provided for @newAlarm.
  ///
  /// In en, this message translates to:
  /// **'New alarm'**
  String get newAlarm;

  /// No description provided for @alarmRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get alarmRepeat;

  /// No description provided for @alarmLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get alarmLabel;

  /// No description provided for @alarmRingDuration.
  ///
  /// In en, this message translates to:
  /// **'Ring duration'**
  String get alarmRingDuration;

  /// No description provided for @alarmSnoozeDuration.
  ///
  /// In en, this message translates to:
  /// **'Snooze duration'**
  String get alarmSnoozeDuration;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @soundDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get soundDefault;

  /// No description provided for @soundBell.
  ///
  /// In en, this message translates to:
  /// **'Bell'**
  String get soundBell;

  /// No description provided for @soundChime.
  ///
  /// In en, this message translates to:
  /// **'Chime'**
  String get soundChime;

  /// No description provided for @soundCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get soundCalm;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @prayerTimesForDate.
  ///
  /// In en, this message translates to:
  /// **'Prayer times · {date}'**
  String prayerTimesForDate(String date);

  /// No description provided for @prayerTimeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Prayer time updated: {date}'**
  String prayerTimeUpdated(String date);

  /// No description provided for @locationAndMethod.
  ///
  /// In en, this message translates to:
  /// **'Location & method'**
  String get locationAndMethod;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

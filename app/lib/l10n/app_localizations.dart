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

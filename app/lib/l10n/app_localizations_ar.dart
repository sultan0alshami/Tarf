// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'طَرْف';

  @override
  String get tabFocus => 'التركيز';

  @override
  String get tabTimer => 'المؤقّت';

  @override
  String get tabAlarm => 'المنبّه';

  @override
  String get tabStopwatch => 'ساعة الإيقاف';

  @override
  String get navInsights => 'الإحصاءات';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get actionStart => 'ابدأ';

  @override
  String get actionPause => 'إيقاف مؤقّت';

  @override
  String get actionResume => 'متابعة';

  @override
  String get actionStop => 'إيقاف';

  @override
  String get actionReset => 'إعادة ضبط';

  @override
  String get actionSkip => 'تخطّي';

  @override
  String get actionSnooze => 'تأجيل';

  @override
  String get actionDone => 'تمّ';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get lap => 'لفة';

  @override
  String get timeUp => 'انتهى الوقت';

  @override
  String get eyeCareTitle => 'العناية بالعين';

  @override
  String get takeBreakNow => 'خذ راحة الآن';

  @override
  String get breakLookAway => 'انظر إلى مسافة 6 أمتار';

  @override
  String get breakInstruction => 'أرِح عينيك لمدّة 20 ثانية';

  @override
  String get breakRepeatAfter => 'ردّد خلف التلاوة';

  @override
  String get breakOver => 'يمكنك العودة الآن';

  @override
  String get transliterationShow => 'إظهار النطق اللاتيني';

  @override
  String get transliterationHide => 'إخفاء النطق اللاتيني';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeSystem => 'تلقائي';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get reduceMotion => 'تقليل الحركة';

  @override
  String get signInTitle => 'سجّل الدخول للمزامنة';

  @override
  String get signInRationale =>
      'سجّل الدخول مرّة واحدة لتفعيل المزامنة بين الأجهزة وحفظ تقدّمك. تعمل فترة راحة العين دون حساب.';

  @override
  String get signInGoogle => 'المتابعة عبر Google';

  @override
  String get signInApple => 'المتابعة عبر Apple';

  @override
  String get signInEmail => 'المتابعة بالبريد الإلكتروني';

  @override
  String get continueAsGuest => 'المتابعة كضيف';

  @override
  String get focusDailyGoal => 'الهدف اليومي';

  @override
  String get focusReady => 'جاهز للتركيز';

  @override
  String get focusSessionComplete => 'اكتملت الجلسة';

  @override
  String get phaseWork => 'تركيز';

  @override
  String get phaseShortBreak => 'راحة قصيرة';

  @override
  String get phaseLongBreak => 'راحة طويلة';

  @override
  String get restEyes => 'أرِح عينيك';

  @override
  String focusSessionsProgress(int done, int goal) {
    return '$done / $goal جلسات اليوم';
  }

  @override
  String focusSessionsToday(int count) {
    return '$count جلسات اليوم';
  }

  @override
  String todayMinutes(int minutes) {
    return '$minutes دقيقة تركيز اليوم';
  }

  @override
  String get insightsToday => 'اليوم';

  @override
  String insightsStreak(int days) {
    return 'سلسلة $days يوم';
  }

  @override
  String get labelFocusMinutes => 'دقائق التركيز';

  @override
  String get labelSessions => 'الجلسات';

  @override
  String get labelBreaks => 'فترات الراحة';

  @override
  String get last7Days => 'آخر 7 أيام';

  @override
  String get exportCsv => 'تصدير CSV';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get noDataYet => 'لا توجد بيانات بعد — ابدأ جلسة تركيز';

  @override
  String get tasks => 'المهام';

  @override
  String get addTask => 'إضافة مهمة';

  @override
  String get taskHint => 'بماذا تعمل الآن؟';

  @override
  String get noTasks => 'لا توجد مهام بعد';

  @override
  String get startFocus => 'ابدأ التركيز';

  @override
  String get estLabel => 'متوقع';

  @override
  String get alarms => 'المنبّهات';

  @override
  String get addAlarm => 'إضافة منبّه';

  @override
  String get noAlarms => 'لا توجد منبّهات بعد';

  @override
  String get alarmNativeNote =>
      'ترنّ المنبّهات في الخلفية عند السماح بالإشعارات. وإلا، يرنّ طَرْف أثناء فتحه فقط.';

  @override
  String get notifPrimingTitle => 'تذكيرات الراحة';

  @override
  String get notifPrimingBody =>
      'حتى يصلك تذكير الراحة وأنت خارج التطبيق، يحتاج طَرْف إذنك بالإشعارات. بدونها سيُذكّرك أثناء فتحه فقط.';

  @override
  String get exactAlarmPrimingBody =>
      'لكي يرنّ المنبّه في وقته بالضبط، يحتاج طَرْف إذن «التنبيهات الدقيقة».';

  @override
  String get permEnable => 'تفعيل';

  @override
  String get permNotNow => 'لاحقًا';

  @override
  String get permOpenSettings => 'فتح الإعدادات';

  @override
  String get bgRemindersOff =>
      'التنبيهات في الخلفية متوقّفة — سيُذكّرك طَرْف أثناء فتحه فقط.';

  @override
  String get bgForegroundOnlyPlatform =>
      'على هذه المنصّة، تظهر التذكيرات أثناء فتح طَرْف فقط.';

  @override
  String get bgExactAlarmOff =>
      'قد تصل التذكيرات متأخرة بضع دقائق — فعّل التنبيهات الدقيقة لتوقيت أدق.';

  @override
  String get bgRemindersOn => 'التنبيهات في الخلفية مفعّلة.';

  @override
  String get eyeCareEnabled => 'تذكيرات العناية بالعين';

  @override
  String get reminderInterval => 'مدة التذكير';

  @override
  String get breakLength => 'مدة الراحة';

  @override
  String get twoTierBreaks => 'إضافة فترات راحة أطول للوقوف والتمدّد';

  @override
  String get longBreakInterval => 'مدة الراحة الطويلة';

  @override
  String get longBreakLength => 'طول الراحة الطويلة';

  @override
  String get strictMode => 'الوضع الصارم (بدون تخطّي)';

  @override
  String get soundLabel => 'الصوت';

  @override
  String get hapticsLabel => 'الاهتزاز';

  @override
  String get prayerPauseLabel => 'الإيقاف حول أوقات الصلاة';

  @override
  String get loudThroughSilenceLabel => 'التشغيل رغم الوضع الصامت';

  @override
  String minutesShort(int n) {
    return '$n دقيقة';
  }

  @override
  String secondsShort(int n) {
    return '$n ثانية';
  }

  @override
  String get onbTitle => 'أرِح عينيك واذكر الله';

  @override
  String get onbBody =>
      'كل 20 دقيقة، يدعوك طَرْف بلطف إلى النظر بعيدًا لمدة 20 ثانية مع ذكرٍ هادئ — عنايةً بعينيك وقلبك.';

  @override
  String get onbChooseLanguage => 'اختر لغتك';

  @override
  String get onbChooseTheme => 'اختر المظهر';

  @override
  String get onbQuickSetup => 'إعداد سريع';

  @override
  String get onbNext => 'التالي';

  @override
  String get onbGetStarted => 'ابدأ الآن';

  @override
  String get accountTitle => 'الحساب والمزامنة';

  @override
  String get accountGuest => 'ضيف — تبقى بياناتك على هذا الجهاز';

  @override
  String get syncSetupNote =>
      'تتطلّب المزامنة السحابية وتسجيل الدخول ربط Firebase. راجع docs/firebase-setup.md.';

  @override
  String get exportData => 'تصدير بياناتي';

  @override
  String get deleteAllData => 'حذف جميع بياناتي';

  @override
  String get deleteAllConfirm =>
      'سيؤدي هذا إلى حذف جميع بيانات طَرْف على هذا الجهاز نهائيًا ولا يمكن التراجع عنه.';

  @override
  String get dataExported => 'تم نسخ بياناتك إلى الحافظة';

  @override
  String get dataDeleted => 'تم حذف جميع البيانات';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get nextEyeBreak => 'راحة العين القادمة';

  @override
  String eyeRestsToday(int count) {
    return '$count راحات للعين اليوم';
  }

  @override
  String get startFocusSession => 'ابدأ جلسة تركيز';

  @override
  String get pausedLabel => 'متوقّف مؤقّتًا';

  @override
  String get focusTodayLabel => 'تركيز اليوم';

  @override
  String get todosLabel => 'المهام';

  @override
  String get editDurations => 'تعديل المدد';

  @override
  String get unitHours => 'ساعات';

  @override
  String get unitMinutes => 'دقائق';

  @override
  String get unitSeconds => 'ثوانٍ';

  @override
  String get alarmRepeatDaily => 'يوميًا';

  @override
  String get alarmRepeatWeekdays => 'أيام الأسبوع';

  @override
  String get alarmRepeatWeekends => 'نهاية الأسبوع';

  @override
  String get alarmRepeatOnce => 'مرة واحدة';

  @override
  String get alarmRepeatCustom => 'مخصّص';

  @override
  String get alarmLabelHint => 'مثل: الفجر، الاستيقاظ';

  @override
  String get alarmDeleted => 'تم حذف المنبّه';

  @override
  String get alarmToggleSemantic => 'تبديل المنبّه';

  @override
  String lapNumber(int n) {
    return 'لفة $n';
  }

  @override
  String get lapTotal => 'الإجمالي';

  @override
  String get lapFastest => 'الأسرع';

  @override
  String get lapSlowest => 'الأبطأ';

  @override
  String get noLapsYet => 'لا لفات بعد';

  @override
  String get insightsEyeRestsCaption => 'راحات العين اليوم';

  @override
  String get insightsEyeRestsSubline => 'أحسنت — عيناك تشكرانك.';

  @override
  String get insightsThisWeek => 'هذا الأسبوع';

  @override
  String get todosEmptyLine => 'نحن هنا متى احتجت إلى لحظة';

  @override
  String todoSessions(int actual, int estimated) {
    return '$actual من $estimated جلسات';
  }

  @override
  String get settingsEyeCare => 'العناية بالعين';

  @override
  String get settingsBreakInterval => 'مدة التذكير';

  @override
  String get settingsBreakDuration => 'مدة الراحة';

  @override
  String get settingsDhikrAudio => 'الذِّكر والصوت';

  @override
  String get settingsMoreEyeCare => 'مزيد من إعدادات العناية بالعين';

  @override
  String get settingsNumerals => 'الأرقام';

  @override
  String get settingsAccount => 'الحساب';

  @override
  String get syncStatusOffline => 'غير متصل · على هذا الجهاز';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get eyeCareSettingsTitle => 'إعدادات العناية بالعين';

  @override
  String get coreBreakGroupLabel => 'التذكير والراحة';

  @override
  String get longerBreakGroupLabel => 'استراحة أطول للوقوف والتمدّد';

  @override
  String get behaviorAlertsGroupLabel => 'السلوك والتنبيهات';

  @override
  String get alarmStandard => 'عادي';

  @override
  String get alarmPrayer => 'الصلاة';

  @override
  String ringInHm(int h, int m) {
    return 'يرنّ خلال $hس $mد';
  }

  @override
  String get editAlarm => 'تعديل المنبّه';

  @override
  String get newAlarm => 'منبّه جديد';

  @override
  String get alarmRepeat => 'التكرار';

  @override
  String get alarmLabel => 'التسمية';

  @override
  String get alarmRingDuration => 'مدة الرنين';

  @override
  String get alarmSnoozeDuration => 'مدة التأجيل';

  @override
  String get actionDelete => 'حذف';

  @override
  String get soundDefault => 'افتراضي';

  @override
  String get soundBell => 'جرس';

  @override
  String get soundChime => 'رنين';

  @override
  String get soundCalm => 'هادئ';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String prayerTimesForDate(String date) {
    return 'أوقات الصلاة · $date';
  }

  @override
  String prayerTimeUpdated(String date) {
    return 'تحديث أوقات الصلاة: $date';
  }

  @override
  String get locationAndMethod => 'الموقع والطريقة';

  @override
  String get tapToEnableSound => 'اضغط لتفعيل الصوت';

  @override
  String get breakSoundLabel => 'صوت الاستراحة';

  @override
  String get soundPreview => 'استماع';

  @override
  String get timerDoneTapToDismiss => 'اضغط إعادة للإغلاق';
}

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
  String get breakLookAway => 'انظر إلى مسافة ٦ أمتار';

  @override
  String get breakInstruction => 'أرِح عينيك لمدّة ٢٠ ثانية';

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
  String get last7Days => 'آخر ٧ أيام';

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
      'ستُشغَّل المنبّهات عند تفعيل الجدولة الأصلية على هذا الجهاز.';
}

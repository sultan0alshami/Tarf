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
  String focusSessionsToday(int count) {
    return '$count جلسات اليوم';
  }

  @override
  String todayMinutes(int minutes) {
    return '$minutes دقيقة تركيز اليوم';
  }
}

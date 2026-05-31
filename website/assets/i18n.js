/* =============================================================================
   Tarf — vanilla-JS i18n + language toggle
   - Arabic is the DEFAULT (dir="rtl"). English is the secondary (dir="ltr").
   - Choice persists in localStorage ("tarf-lang").
   - Any element with a [data-i18n="key"] gets its textContent set (no innerHTML,
     so translated copy can never inject markup — XSS-safe by construction).
   - [data-i18n-attr="attr:key,attr2:key2"] sets attributes (e.g. aria-label, placeholder).
   - <html lang> and <html dir> are switched; <title> via data-i18n on <title>.
   No build step, no dependencies.
   ============================================================================= */

(function () {
  "use strict";

  var STORE_KEY = "tarf-lang";
  var DEFAULT_LANG = "ar"; // Arabic-first

  /* --------------------------------------------------------- String tables */
  var STRINGS = {
    ar: {
      /* meta / brand */
      "brand.name": "طَرْف",
      "brand.tagline": "راحةٌ للعين، وذِكرٌ للقلب",
      "lang.toggle": "EN",
      "lang.toggleAria": "التبديل إلى الإنجليزية",
      "nav.menu": "القائمة",

      /* nav */
      "nav.features": "المزايا",
      "nav.howItWorks": "كيف يعمل",
      "nav.download": "التحميل",
      "nav.support": "ادعمنا",

      /* page titles */
      "title.home": "طَرْف — راحةٌ للعين وذِكرٌ للقلب",
      "title.download": "تحميل طَرْف",
      "title.support": "ادعم طَرْف",
      "title.privacy": "سياسة الخصوصية — طَرْف",
      "title.terms": "شروط الاستخدام — طَرْف",
      "title.licenses": "التراخيص والاعتمادات — طَرْف",

      /* hero */
      "hero.h1.app": "طَرْف",
      "hero.tagline": "راحةٌ للعين، وذِكرٌ للقلب.",
      "hero.lede": "تطبيق هادئ يذكّرك أن ترفع بصرك عن الشاشة كل عشرين دقيقة من العمل الفعلي — فيتحوّل الفاصل إلى لحظة ذِكرٍ مع صوتٍ يمتد عشرين ثانية، فنهاية الصوت هي إشارة العودة.",
      "hero.cta.download": "حمّل التطبيق",
      "hero.cta.support": "ادعمنا",
      "hero.note": "مجاني بالكامل، مموّل بالتبرّعات — بلا إعلانات، ولا شيء تجاري قُرب النص المقدّس.",
      "hero.break.label": "حان وقت الراحة",
      "hero.break.dhikr": "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
      "hero.break.translit": "Subḥānallāhi wa bi-ḥamdih",
      "hero.break.en": "Glory and praise be to Allah",
      "hero.break.ringStrong": "٢٠ ثانية",
      "hero.break.ring": "انظر بعيدًا حتى ينتهي الصوت",

      /* 20-20-20 explainer */
      "how.eyebrow": "قاعدة ٢٠-٢٠-٢٠",
      "how.h2": "راحةٌ ذكيّة، تأتي في وقتها فقط",
      "how.lede": "بعكس المنبّهات التي تُزعجك حين لا تكون أمام الشاشة، يحتسب طَرْف وقت العمل الفعلي فحسب — فلا تذكير إلا حين تحتاجه عينك حقًّا.",
      "how.step1.num": "٢٠",
      "how.step1.unit": "دقيقة",
      "how.step1.h3": "كل عشرين دقيقة عمل",
      "how.step1.p": "يحتسب طَرْف وقت نشاطك الفعلي على الشاشة، لا الساعة فحسب، فيتوقّف حين تبتعد ويستأنف حين تعود.",
      "how.step2.num": "٢٠",
      "how.step2.unit": "قدمًا",
      "how.step2.h3": "انظر إلى ستة أمتار",
      "how.step2.p": "انقل بصرك إلى شيء بعيد نحو ستة أمتار؛ فهذا يُرخي عضلات العين ويخفّف إجهاد الشاشة.",
      "how.step3.num": "٢٠",
      "how.step3.unit": "ثانية",
      "how.step3.h3": "مع ذِكرٍ ثابت",
      "how.step3.p": "يظهر ذِكرٌ واحد على شاشة هادئة مع صوتٍ يمتد عشرين ثانية بالتمام، فنهاية الصوت هي إشارة العودة.",

      /* features */
      "feat.eyebrow": "المزايا",
      "feat.h2": "كل ما تحتاجه راحةً وتركيزًا، في هدوءٍ واحد",
      "feat.lede": "أداة متقنة متعدّدة المنصّات، عربيّة أوّلًا، تعمل دون اتصال.",

      "feat.activity.h3": "راحةٌ واعية بالنشاط",
      "feat.activity.p": "لا يُذكّرك إلا حين تكون أمام الشاشة فعلًا — يتوقّف تلقائيًّا حين تبتعد أو تقفل الجهاز، ويستأنف حين تعود.",
      "feat.dhikr.h3": "فاصل الذِّكر",
      "feat.dhikr.p": "أذكار صحيحة متّفق عليها مع التشكيل الكامل والمصدر، تتناوب لا تتكرّر، بصوتٍ هادئ يمتد عشرين ثانية.",
      "feat.tools.h3": "تركيز ومؤقّت ومنبّه وساعة إيقاف",
      "feat.tools.p": "طبقة إنتاجية رشيقة: جلسات تركيز (بومودورو)، ومؤقّتات مسمّاة، ومنبّهات، وساعة إيقاف مع لفّات.",
      "feat.offline.h3": "يعمل دون اتصال، ويُزامن عند الحاجة",
      "feat.offline.p": "النواة تعمل بلا شبكة أبدًا (وضع الضيف). وعند تسجيل الدخول تُزامَن بياناتك بأمان عبر السحابة.",
      "feat.prayer.h3": "إيقاف وقت الصلاة",
      "feat.prayer.p": "حساب أوقات الصلوات الخمس محليًّا، فتتوقّف التذكيرات حول الصلاة تلقائيًّا — اختياري بالكامل.",
      "feat.appearance.h3": "فاتح وداكن، وأرقام عربيّة",
      "feat.appearance.p": "مظهر يتبع نظامك، تاريخ هجري اختياري، وأرقام عربيّة-هنديّة (٠١٢٣) في الواجهة العربيّة.",
      "feat.arabic.h3": "عربيّة أوّلًا، لا مترجمة",
      "feat.arabic.p": "صُمّم من اليمين إلى اليسار منذ اليوم الأول، واختُبر بنصٍّ عربيٍّ حقيقي — مع احترامٍ تامّ للنص المقدّس.",
      "feat.access.h3": "وصولٌ ميسّر",
      "feat.access.p": "يلتزم معايير WCAG 2.1 AA: أهداف لمسٍ كبيرة، خطٌّ ديناميكي، تقليل الحركة والشفافية، وقارئ شاشة.",

      /* download */
      "dl.head.h1": "حمّل طَرْف",
      "dl.head.p": "متوفّر — أو قادم قريبًا — على كل منصّاتك. اختر متجرك وابدأ راحتك الأولى اليوم.",
      "dl.soon": "قريبًا",
      "dl.get": "احصل عليه",
      "dl.getApk": "تنزيل APK",
      "dl.open": "افتح تطبيق الويب",
      "dl.add": "أضِف للمتصفّح",

      "dl.appstore.h3": "App Store",
      "dl.appstore.plat": "iPhone · iPad",
      "dl.appstore.p": "تطبيق طَرْف الأصلي لأجهزة آبل، مع راحة العين وفاصل الذِّكر.",
      "dl.play.h3": "Google Play",
      "dl.play.plat": "أندرويد",
      "dl.play.p": "ثبّته من المتجر لتصلك التحديثات تلقائيًّا على هاتف أندرويد أو لوحه.",
      "dl.apk.h3": "تنزيل مباشر (APK)",
      "dl.apk.plat": "أندرويد · ملف ‎.apk",
      "dl.apk.p": "للتثبيت اليدوي خارج المتجر. فعّل تثبيت المصادر غير المعروفة لجهازك.",
      "dl.msstore.h3": "Microsoft Store",
      "dl.msstore.plat": "ويندوز ١٠ وما بعده",
      "dl.msstore.p": "تطبيق سطح المكتب مع أيقونة المنبّه الحيّة في شريط المهام: إيقاف، تأجيل، تخطٍّ.",
      "dl.pwa.h3": "تطبيق الويب (PWA)",
      "dl.pwa.plat": "كل المتصفّحات",
      "dl.pwa.p": "جرّب طَرْف فورًا في متصفّحك، وثبّته كتطبيق ويب يعمل دون اتصال.",
      "dl.ext.h3": "إضافة Chrome",
      "dl.ext.plat": "Chrome · Edge",
      "dl.ext.p": "تذكيرات راحة العين أثناء التصفّح، مع لوحة جانبيّة للمؤقّت والإنجاز.",
      "dl.note": "الروابط المعلّمة بـ«قريبًا» قيد المراجعة لدى المتاجر. حدّث هذه الروابط في website/download.html عند نشر التطبيق.",
      "dl.macos.h3": "macOS",
      "dl.macos.plat": "macOS 11 وما بعده",
      "dl.macos.p": "تطبيق أصلي لسطح مكتب ماك مع حضورٍ في شريط القوائم وتحديث تلقائي.",

      /* support / donate */
      "sup.head.h1": "ادعم طَرْف",
      "sup.head.p": "طَرْف مجاني للجميع وبلا إعلانات. تبرّعك يبقيه كذلك — ويُموّل أصواتًا أنقى وميزاتٍ أهدأ.",
      "sup.form.title": "تبرّع لمرّة واحدة",
      "sup.form.amount": "اختر مبلغًا",
      "sup.amount.custom": "مبلغ آخر",
      "sup.field.customAmount": "مبلغ مخصّص (ريال سعودي)",
      "sup.field.name": "الاسم (اختياري)",
      "sup.field.namePh": "كيف نشكرك؟",
      "sup.field.email": "البريد الإلكتروني (لإيصال التبرّع)",
      "sup.field.emailPh": "you@example.com",
      "sup.field.message": "رسالة (اختياريّة)",
      "sup.field.messagePh": "كلمة طيّبة تصلنا…",
      "sup.submit": "تابِع إلى الدفع الآمن",
      "sup.secure": "تتم المعالجة عبر بوّابة دفع معتمدة (PCI DSS). لا تُدخَل بيانات بطاقتك في هذه الصفحة إطلاقًا.",
      "sup.cards": "نقبل: مدى · Visa · Mastercard",
      "sup.aside.how.h3": "كيف يعمل الدفع",
      "sup.aside.how.p": "عند الضغط على «تابِع إلى الدفع»، نُنشئ عمليّة دفع آمنة لدى بوّابتنا (Moyasar) ونحوّلك إلى صفحتها المستضافة لإدخال بطاقتك. بيانات البطاقة لا تمرّ عبر خوادمنا أبدًا.",
      "sup.aside.where.h3": "أين يذهب تبرّعك",
      "sup.aside.where.li1": "ترخيص أصوات وتلاوات نقيّة ومُصرّح بها.",
      "sup.aside.where.li2": "استضافة المزامنة السحابيّة وتشغيل الخدمة.",
      "sup.aside.where.li3": "مراجعة شرعيّة وتدقيق لغوي للنصوص المقدّسة.",
      "sup.aside.where.li4": "تطوير مستمرّ عبر كل المنصّات.",
      "sup.aside.ios.h3": "ملاحظة لمستخدمي iOS",
      "sup.aside.ios.p": "وفقًا لسياسات آبل، لا يعرض تطبيق iOS رابط تبرّع؛ يكتفي بشكرٍ ومشاركة. يمكنك التبرّع من هذه الصفحة عبر المتصفّح.",
      "sup.callout": "لا إعلانات، ولا تتبّع، ولا أي محتوى تجاري بجوار الذِّكر — هذا وعدٌ دائم، لا خطّة تسعير.",
      "sup.status.validating": "نتحقّق من المبلغ…",
      "sup.status.redirecting": "نُحوّلك إلى صفحة الدفع الآمنة…",
      "sup.status.testMode": "وضع الاختبار: لم تُضبط مفاتيح البوّابة بعد، لذا لن يُخصم مبلغ فعلي. (هذه استجابة تجريبيّة.)",
      "sup.status.errAmount": "فضلًا أدخل مبلغًا صحيحًا (١ ريال على الأقل).",
      "sup.status.errEmail": "فضلًا أدخل بريدًا إلكترونيًّا صحيحًا.",
      "sup.status.errNetwork": "تعذّر الاتصال بالخادم. حاول مجددًا.",
      "sup.currency": "ريال",

      /* CTA band */
      "cta.h2": "ابدأ راحتك الأولى اليوم",
      "cta.p": "جرّبه ضيفًا دون تسجيل — تعمل نواة راحة العين والذِّكر فورًا، دون اتصال.",
      "cta.download": "حمّل طَرْف",
      "cta.support": "ادعم المشروع",

      /* footer */
      "footer.about": "تطبيق هادئ يجمع راحة العين ٢٠-٢٠-٢٠ مع فاصل ذِكرٍ يطمئن القلب. مجاني، مموّل بالتبرّعات، يعمل دون اتصال.",
      "footer.product": "المنتج",
      "footer.legal": "قانوني",
      "footer.links.features": "المزايا",
      "footer.links.download": "التحميل",
      "footer.links.support": "ادعمنا",
      "footer.links.privacy": "سياسة الخصوصية",
      "footer.links.terms": "شروط الاستخدام",
      "footer.links.licenses": "التراخيص والاعتمادات",
      "footer.copyright": "© ٢٠٢٦ طَرْف. جميع الحقوق محفوظة.",
      "footer.madeWith": "صُنع بعنايةٍ واحترامٍ للنص المقدّس.",

      /* legal: privacy */
      "pp.title": "سياسة الخصوصية",
      "pp.updated": "آخر تحديث: ٣١ مايو ٢٠٢٦",
      "pp.intro": "نحترم خصوصيّتك احترامًا عميقًا. صُمّم طَرْف ليعمل دون اتصال أوّلًا، ولا يجمع إلا أقلّ ما يلزم لتشغيل الخدمة. لا إعلانات، ولا متعقّبات تحليليّة بجوار النص المقدّس.",
      "pp.s1.h": "البيانات التي نخزّنها",
      "pp.s1.p": "في وضع الضيف، تبقى كل بياناتك (إعداداتك وإحصاءاتك) على جهازك فقط ولا تُرسَل إلى أي خادم. عند تسجيل الدخول، نُخزّن لكل مستخدمٍ على حدة: ملفّك التعريفي، إعداداتك، تقدّمك اليومي، جلسات التركيز، ومهامك — مقفلةً بمعرّف حسابك وحده.",
      "pp.s2.h": "الدِّين بوصفه بيانات حسّاسة",
      "pp.s2.p": "محتوى الأذكار ثابتٌ ومُضمَّن في التطبيق، ولا نربطه بهويّتك ولا نستنتج منه انتماءك الديني. لا نُجري معالجةً لفئاتٍ خاصّةٍ من البيانات الشخصيّة، ولا نطلب موافقةً صريحةً لأنّنا لا نجمع بياناتٍ دينيّةً عنك أصلًا.",
      "pp.s3.h": "بلا إعلانات ولا تتبّع",
      "pp.s3.p": "لا نعرض إعلانات، ولا نبيع بياناتك، ولا نضع أي متعقّبٍ تجاريّ. أي قياسٍ تشغيليّ يحترم الخصوصيّة، ولا يُجمع أبدًا داخل شاشة الذِّكر أو بجوار النص المقدّس.",
      "pp.s4.h": "الحذف والتصدير",
      "pp.s4.p": "يمكنك حذف حسابك وكل بياناتك السحابيّة من داخل التطبيق في أي وقت، كما يمكنك تصدير بياناتك. ننفّذ طلب الحذف فورًا على خوادمنا.",
      "pp.s5.h": "التبرّعات",
      "pp.s5.p": "تُعالَج المدفوعات عبر بوّابة دفعٍ معتمدةٍ (PCI DSS)؛ لا تمرّ بيانات بطاقتك عبر خوادمنا. نحتفظ بأقلّ القدر اللازم لإصدار الإيصال والامتثال المحاسبي.",
      "pp.s6.h": "حقوقك (GDPR / CCPA)",
      "pp.s6.p": "لك حقّ الوصول إلى بياناتك وتصحيحها وحذفها وتصديرها، وحقّ الاعتراض على المعالجة. أساسنا القانوني هو تنفيذ الخدمة التي طلبتها وموافقتك. للاستفسار راسلنا على البريد أدناه.",
      "pp.s7.h": "تواصل معنا",
      "pp.s7.p": "لأي سؤالٍ حول الخصوصيّة أو طلبٍ يتعلّق ببياناتك، راسلنا على: privacy@tarf.app",

      /* legal: terms */
      "tt.title": "شروط الاستخدام",
      "tt.updated": "آخر تحديث: ٣١ مايو ٢٠٢٦",
      "tt.intro": "باستخدامك طَرْف فإنّك توافق على هذه الشروط. صيغت بلغةٍ واضحةٍ قدر الإمكان.",
      "tt.s1.h": "الخدمة",
      "tt.s1.p": "طَرْف تطبيق رفاهيّةٍ مجانيّ يقدّم تذكيرات راحة العين، وفاصل ذِكرٍ، وأدوات تركيزٍ وتوقيت. يُقدَّم «كما هو» لأغراض الرفاهيّة العامّة، وليس بديلًا عن استشارةٍ طبيّة.",
      "tt.s2.h": "حسابك",
      "tt.s2.p": "وضع الضيف لا يتطلّب حسابًا. تتطلّب الميزات الإنتاجيّة والمزامنة تسجيل الدخول. أنت مسؤول عن الحفاظ على سرّية بيانات دخولك.",
      "tt.s3.h": "التبرّعات",
      "tt.s3.p": "التبرّعات طوعيّة وغير مستردّة إلا حيث يفرض القانون خلاف ذلك، ولا تمنح أي ميزةٍ مدفوعةٍ داخل التطبيق؛ فجميع الميزات مجانيّة للجميع.",
      "tt.s4.h": "المحتوى المقدّس",
      "tt.s4.p": "نصوص الأذكار مُضمَّنة وثابتة، وقد رُوجعت لغويًّا وشرعيًّا قبل النشر. نلتزم بعدم وضع أي محتوًى تجاريّ أو إعلانيّ بجوارها.",
      "tt.s5.h": "حدود المسؤوليّة",
      "tt.s5.p": "نبذل وسعنا لإطلاق التذكيرات وتشغيل الصوت في وقتها، لكنّ ذلك قد يتأثّر بقيود نظام التشغيل وإعدادات الجهاز. لا نتحمّل مسؤوليّة أي ضررٍ ناشئٍ عن الاعتماد المطلق على التطبيق.",
      "tt.s6.h": "تعديل الشروط",
      "tt.s6.p": "قد نُحدّث هذه الشروط؛ وسننشر أي تغييرٍ جوهريّ على هذه الصفحة مع تحديث التاريخ أعلاه.",
      "tt.s7.h": "تواصل معنا",
      "tt.s7.p": "لأي استفسار حول الشروط راسلنا على: hello@tarf.app",

      /* legal: licenses */
      "lic.title": "التراخيص والاعتمادات",
      "lic.updated": "آخر تحديث: ٣١ مايو ٢٠٢٦",
      "lic.intro": "نؤمن بإسناد كل أصلٍ إلى مصدره. تُدار التراخيص عبر سجلّ مصادر (assets_ledger/ledger.json) الذي يقود أيضًا شاشة «التراخيص» داخل التطبيق.",
      "lic.fonts.h": "الخطوط",
      "lic.fonts.intro": "نستخدم خطوطًا مفتوحة المصدر بترخيص SIL Open Font License.",
      "lic.col.asset": "الأصل",
      "lic.col.type": "النوع",
      "lic.col.source": "المصدر / المؤلّف",
      "lic.col.license": "الترخيص",
      "lic.col.attr": "الإسناد المطلوب",
      "lic.inter.note": "خط الواجهة (لاتيني/أرقام)",
      "lic.amiri.note": "خط النص العربي (نسخ)",
      "lic.audio.h": "الأصوات المُضمَّنة",
      "lic.audio.intro": "كل مقطع صوتيّ مُدرَجٌ في سجلّ المصادر مع رابطه ورخصته ولقطةٍ من نصّ الترخيص وتاريخ التنزيل والإسناد المطلوب. الجدول أدناه نموذجٌ يُملأ من السجلّ.",
      "lic.audio.placeholder": "يُملأ من سجلّ المصادر",
      "lic.audio.r1": "تلاوة ذِكر (مثال)",
      "lic.audio.r1type": "صوت",
      "lic.audio.r2": "نغمة بداية/نهاية",
      "lic.audio.r2type": "صوت",
      "lic.audio.r3": "أجواء هادئة",
      "lic.audio.r3type": "صوت",
      "lic.text.h": "نصوص الأذكار",
      "lic.text.p": "الأذكار من «حصن المسلم» و sunnah.com مع المرجع الدقيق لكلٍّ منها، مُخزَّنةً كـ JSON ثابتٍ مُضمَّن، بعد مراجعةٍ لغويّةٍ وشرعيّة.",

      /* misc */
      "back.home": "العودة إلى الرئيسيّة",
    },

    en: {
      "brand.name": "Tarf",
      "brand.tagline": "Rest for the eyes, remembrance for the heart",
      "lang.toggle": "ع",
      "lang.toggleAria": "Switch to Arabic",
      "nav.menu": "Menu",

      "nav.features": "Features",
      "nav.howItWorks": "How it works",
      "nav.download": "Download",
      "nav.support": "Support",

      "title.home": "Tarf — Rest for the eyes, remembrance for the heart",
      "title.download": "Download Tarf",
      "title.support": "Support Tarf",
      "title.privacy": "Privacy Policy — Tarf",
      "title.terms": "Terms of Use — Tarf",
      "title.licenses": "Licenses & Credits — Tarf",

      "hero.h1.app": "Tarf",
      "hero.tagline": "Rest for the eyes, remembrance for the heart.",
      "hero.lede": "A calm app that nudges you to look away from the screen every 20 minutes of real, active work — turning the break into a moment of dhikr, with audio that runs for a full 20 seconds, so the sound ending is your cue to look back.",
      "hero.cta.download": "Download the app",
      "hero.cta.support": "Support us",
      "hero.note": "Completely free, donation-funded — no ads, and nothing commercial next to sacred text.",
      "hero.break.label": "Time for a break",
      "hero.break.dhikr": "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
      "hero.break.translit": "Subḥānallāhi wa bi-ḥamdih",
      "hero.break.en": "Glory and praise be to Allah",
      "hero.break.ringStrong": "20 seconds",
      "hero.break.ring": "Look away until the sound ends",

      "how.eyebrow": "The 20-20-20 rule",
      "how.h2": "Intelligent rest — only when you need it",
      "how.lede": "Unlike timers that nag when you are not even at your screen, Tarf counts only real active work time, so a break fires exactly when your eyes need one.",
      "how.step1.num": "20",
      "how.step1.unit": "minutes",
      "how.step1.h3": "Every 20 minutes of work",
      "how.step1.p": "Tarf counts your real active screen time, not just the wall clock — it pauses when you step away and resumes when you return.",
      "how.step2.num": "20",
      "how.step2.unit": "feet",
      "how.step2.h3": "Look 6 metres away",
      "how.step2.p": "Shift your gaze to something far, about 6 metres away. It relaxes the eye muscles and eases screen strain.",
      "how.step3.num": "20",
      "how.step3.unit": "seconds",
      "how.step3.h3": "With a steady dhikr",
      "how.step3.p": "A single dhikr appears on a calm screen with audio that runs for a full 20 seconds, so the sound ending is your cue to look back.",

      "feat.eyebrow": "Features",
      "feat.h2": "Everything you need to rest and focus, in one calm place",
      "feat.lede": "A polished, cross-platform, Arabic-first tool that works offline.",

      "feat.activity.h3": "Activity-aware breaks",
      "feat.activity.p": "It only reminds you when you are actually at the screen — pausing automatically when you step away or lock the device, and resuming when you return.",
      "feat.dhikr.h3": "The dhikr break",
      "feat.dhikr.p": "Authentic, universally-agreed adhkār with full diacritics and a source tag — rotating, never repeating — set to a calm 20-second audio.",
      "feat.tools.h3": "Focus, Timer, Alarm, Stopwatch",
      "feat.tools.p": "A restrained productivity layer: Focus (Pomodoro) sessions, named timers, alarms, and a stopwatch with laps.",
      "feat.offline.h3": "Offline-first, syncs when you want",
      "feat.offline.p": "The core works with zero network ever (guest mode). Sign in and your data syncs safely across devices via the cloud.",
      "feat.prayer.h3": "Prayer-time pause",
      "feat.prayer.p": "Computes the five daily prayer times locally, so reminders pause automatically around salah — fully optional.",
      "feat.appearance.h3": "Light & dark, Arabic numerals",
      "feat.appearance.p": "Appearance follows your system, with an optional Hijri date and Eastern Arabic-Indic digits (٠١٢٣) in the Arabic interface.",
      "feat.arabic.h3": "Arabic-first, not translated",
      "feat.arabic.p": "Designed right-to-left from day one and tested with real Arabic text — with full reverence for sacred content.",
      "feat.access.h3": "Accessible by default",
      "feat.access.p": "Meets WCAG 2.1 AA: large tap targets, Dynamic Type, Reduce Motion and Transparency, and screen-reader labels.",

      "dl.head.h1": "Download Tarf",
      "dl.head.p": "Available — or coming soon — on every platform you use. Pick your store and start your first break today.",
      "dl.soon": "Coming soon",
      "dl.get": "Get it",
      "dl.getApk": "Download APK",
      "dl.open": "Open the web app",
      "dl.add": "Add to browser",

      "dl.appstore.h3": "App Store",
      "dl.appstore.plat": "iPhone · iPad",
      "dl.appstore.p": "The native Tarf app for Apple devices, with eye-care and the dhikr break.",
      "dl.play.h3": "Google Play",
      "dl.play.plat": "Android",
      "dl.play.p": "Install from the store to get automatic updates on your Android phone or tablet.",
      "dl.apk.h3": "Direct download (APK)",
      "dl.apk.plat": "Android · .apk file",
      "dl.apk.p": "For manual install outside the store. Enable installing from unknown sources on your device.",
      "dl.msstore.h3": "Microsoft Store",
      "dl.msstore.plat": "Windows 10 and later",
      "dl.msstore.p": "The desktop app with a live tray countdown: pause, snooze, and skip from the system tray.",
      "dl.pwa.h3": "Web App (PWA)",
      "dl.pwa.plat": "Any browser",
      "dl.pwa.p": "Try Tarf instantly in your browser, and install it as a web app that works offline.",
      "dl.ext.h3": "Chrome Extension",
      "dl.ext.plat": "Chrome · Edge",
      "dl.ext.p": "Eye-care break reminders while you browse, plus a side panel for your timer and streak.",
      "dl.note": "Links marked “Coming soon” are under store review. Update these links in website/download.html once the app is published.",
      "dl.macos.h3": "macOS",
      "dl.macos.plat": "macOS 11 and later",
      "dl.macos.p": "A native Mac desktop app with a menu-bar presence and automatic updates.",

      "sup.head.h1": "Support Tarf",
      "sup.head.p": "Tarf is free for everyone and ad-free. Your donation keeps it that way — funding cleaner audio and calmer features.",
      "sup.form.title": "One-time donation",
      "sup.form.amount": "Choose an amount",
      "sup.amount.custom": "Custom",
      "sup.field.customAmount": "Custom amount (SAR)",
      "sup.field.name": "Name (optional)",
      "sup.field.namePh": "How should we thank you?",
      "sup.field.email": "Email (for your receipt)",
      "sup.field.emailPh": "you@example.com",
      "sup.field.message": "Message (optional)",
      "sup.field.messagePh": "A kind word reaches us…",
      "sup.submit": "Continue to secure payment",
      "sup.secure": "Processed by a certified (PCI DSS) payment gateway. Your card details are never entered on this page.",
      "sup.cards": "We accept: Mada · Visa · Mastercard",
      "sup.aside.how.h3": "How payment works",
      "sup.aside.how.p": "When you continue, we create a secure payment with our gateway (Moyasar) and redirect you to its hosted page to enter your card. Card data never touches our servers.",
      "sup.aside.where.h3": "Where your donation goes",
      "sup.aside.where.li1": "Licensing clean, cleared recitation audio.",
      "sup.aside.where.li2": "Cloud-sync hosting and running the service.",
      "sup.aside.where.li3": "Scholarly review and linguistic proofing of sacred text.",
      "sup.aside.where.li4": "Continued development across every platform.",
      "sup.aside.ios.h3": "A note for iOS users",
      "sup.aside.ios.p": "Per Apple’s policies, the iOS app shows no donation link — only a thank-you and share. You can donate here from your browser.",
      "sup.callout": "No ads, no tracking, and nothing commercial beside the dhikr — that is a permanent promise, not a pricing tier.",
      "sup.status.validating": "Validating amount…",
      "sup.status.redirecting": "Redirecting you to the secure payment page…",
      "sup.status.testMode": "Test mode: the gateway keys are not set yet, so no real charge will be made. (This is a sandbox response.)",
      "sup.status.errAmount": "Please enter a valid amount (at least 1 SAR).",
      "sup.status.errEmail": "Please enter a valid email address.",
      "sup.status.errNetwork": "Could not reach the server. Please try again.",
      "sup.currency": "SAR",

      "cta.h2": "Start your first break today",
      "cta.p": "Try it as a guest with no sign-in — the eye-care and dhikr core works instantly, offline.",
      "cta.download": "Download Tarf",
      "cta.support": "Support the project",

      "footer.about": "A calm app pairing the 20-20-20 eye break with a heart-settling dhikr. Free, donation-funded, offline-first.",
      "footer.product": "Product",
      "footer.legal": "Legal",
      "footer.links.features": "Features",
      "footer.links.download": "Download",
      "footer.links.support": "Support",
      "footer.links.privacy": "Privacy Policy",
      "footer.links.terms": "Terms of Use",
      "footer.links.licenses": "Licenses & Credits",
      "footer.copyright": "© 2026 Tarf. All rights reserved.",
      "footer.madeWith": "Made with care and reverence for sacred text.",

      "pp.title": "Privacy Policy",
      "pp.updated": "Last updated: 31 May 2026",
      "pp.intro": "We respect your privacy deeply. Tarf is built offline-first and collects only the minimum needed to run the service. No ads, and no analytics trackers near sacred text.",
      "pp.s1.h": "Data we store",
      "pp.s1.p": "In guest mode, all your data (settings and stats) stays on your device only and is never sent to any server. When you sign in, we store per-user: your profile, settings, daily progress, focus sessions, and to-dos — locked to your account ID alone.",
      "pp.s2.h": "Religion as sensitive data",
      "pp.s2.p": "The dhikr content is fixed and bundled into the app; we do not link it to your identity nor infer your religious affiliation from it. We perform no special-category processing of personal data, and we ask for no explicit consent because we do not collect religious data about you at all.",
      "pp.s3.h": "No ads, no tracking",
      "pp.s3.p": "We show no ads, never sell your data, and place no commercial trackers. Any operational measurement is privacy-respecting and is never collected inside the dhikr screen or near sacred text.",
      "pp.s4.h": "Deletion & export",
      "pp.s4.p": "You can delete your account and all your cloud data from inside the app at any time, and you can export your data. We honor deletion requests promptly on our servers.",
      "pp.s5.h": "Donations",
      "pp.s5.p": "Payments are processed by a certified (PCI DSS) gateway; your card data never passes through our servers. We retain the minimum needed to issue a receipt and meet accounting obligations.",
      "pp.s6.h": "Your rights (GDPR / CCPA)",
      "pp.s6.p": "You have the right to access, correct, delete, and export your data, and to object to processing. Our legal basis is performing the service you requested and your consent. For requests, email us below.",
      "pp.s7.h": "Contact us",
      "pp.s7.p": "For any privacy question or data request, email: privacy@tarf.app",

      "tt.title": "Terms of Use",
      "tt.updated": "Last updated: 31 May 2026",
      "tt.intro": "By using Tarf, you agree to these terms. We have written them as plainly as we can.",
      "tt.s1.h": "The service",
      "tt.s1.p": "Tarf is a free wellness app offering eye-care reminders, a dhikr break, and focus and timing tools. It is provided “as is” for general wellbeing and is not a substitute for medical advice.",
      "tt.s2.h": "Your account",
      "tt.s2.p": "Guest mode requires no account. Productivity features and sync require sign-in. You are responsible for keeping your sign-in credentials confidential.",
      "tt.s3.h": "Donations",
      "tt.s3.p": "Donations are voluntary and non-refundable except where required by law, and grant no paid in-app benefit; every feature is free for everyone.",
      "tt.s4.h": "Sacred content",
      "tt.s4.p": "The dhikr texts are bundled and immutable, and are linguistically and scholarly reviewed before release. We commit to placing no commercial or advertising content beside them.",
      "tt.s5.h": "Limitation of liability",
      "tt.s5.p": "We do our best to fire reminders and play audio on time, but this can be affected by operating-system limits and device settings. We are not liable for any harm arising from absolute reliance on the app.",
      "tt.s6.h": "Changes to these terms",
      "tt.s6.p": "We may update these terms; we will post any material change on this page and update the date above.",
      "tt.s7.h": "Contact us",
      "tt.s7.p": "For any question about these terms, email: hello@tarf.app",

      "lic.title": "Licenses & Credits",
      "lic.updated": "Last updated: 31 May 2026",
      "lic.intro": "We believe in crediting every asset to its source. Licenses are tracked in a provenance ledger (assets_ledger/ledger.json), which also drives the in-app Licenses screen.",
      "lic.fonts.h": "Fonts",
      "lic.fonts.intro": "We use open-source fonts under the SIL Open Font License.",
      "lic.col.asset": "Asset",
      "lic.col.type": "Type",
      "lic.col.source": "Source / Author",
      "lic.col.license": "License",
      "lic.col.attr": "Required attribution",
      "lic.inter.note": "UI typeface (Latin / figures)",
      "lic.amiri.note": "Arabic body typeface (Naskh)",
      "lic.audio.h": "Bundled audio",
      "lic.audio.intro": "Every audio clip is listed in the provenance ledger with its source URL, license, a license-text snapshot, download date, and required attribution. The table below is a template, populated from the ledger.",
      "lic.audio.placeholder": "Populated from the provenance ledger",
      "lic.audio.r1": "Dhikr recitation (example)",
      "lic.audio.r1type": "Audio",
      "lic.audio.r2": "Start / end chime",
      "lic.audio.r2type": "Audio",
      "lic.audio.r3": "Calm ambience",
      "lic.audio.r3type": "Audio",
      "lic.text.h": "Dhikr texts",
      "lic.text.p": "The adhkār are sourced from Hisn al-Muslim and sunnah.com with an exact reference for each, stored as immutable bundled JSON, after linguistic and scholarly review.",

      "back.home": "Back to home",
    },
  };

  /* ------------------------------------------------------------- Engine */

  function getStored() {
    try { return localStorage.getItem(STORE_KEY); } catch (e) { return null; }
  }
  function setStored(lang) {
    try { localStorage.setItem(STORE_KEY, lang); } catch (e) {}
  }

  function t(lang, key) {
    var table = STRINGS[lang] || STRINGS[DEFAULT_LANG];
    if (key in table) return table[key];
    // graceful fallback to default language, then the key itself
    if (STRINGS[DEFAULT_LANG] && key in STRINGS[DEFAULT_LANG]) {
      return STRINGS[DEFAULT_LANG][key];
    }
    return key;
  }

  function applyLang(lang) {
    if (!STRINGS[lang]) lang = DEFAULT_LANG;
    var html = document.documentElement;
    html.setAttribute("lang", lang);
    html.setAttribute("dir", lang === "ar" ? "rtl" : "ltr");

    // textContent only — never innerHTML — so translations cannot inject markup
    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      el.textContent = t(lang, el.getAttribute("data-i18n"));
    });
    // attributes: "aria-label:key, placeholder:key2"
    document.querySelectorAll("[data-i18n-attr]").forEach(function (el) {
      el.getAttribute("data-i18n-attr").split(",").forEach(function (pair) {
        var parts = pair.split(":");
        if (parts.length === 2) {
          el.setAttribute(parts[0].trim(), t(lang, parts[1].trim()));
        }
      });
    });

    // Update the toggle button label + aria
    document.querySelectorAll("[data-lang-toggle]").forEach(function (btn) {
      btn.textContent = t(lang, "lang.toggle");
      btn.setAttribute("aria-label", t(lang, "lang.toggleAria"));
    });

    setStored(lang);

    // Let any page-specific code react
    document.dispatchEvent(new CustomEvent("tarf:langchange", { detail: { lang: lang } }));
  }

  function currentLang() {
    return document.documentElement.getAttribute("lang") || DEFAULT_LANG;
  }

  function toggleLang() {
    applyLang(currentLang() === "ar" ? "en" : "ar");
  }

  // Expose a tiny API for page scripts (e.g. donate.html status messages)
  window.Tarf = window.Tarf || {};
  window.Tarf.i18n = { t: t, apply: applyLang, current: currentLang, toggle: toggleLang };

  /* ---------------------------------------------------------- Bootstrap */
  function boot() {
    var initial = getStored() || DEFAULT_LANG;
    applyLang(initial);

    document.querySelectorAll("[data-lang-toggle]").forEach(function (btn) {
      btn.addEventListener("click", toggleLang);
    });

    // Mobile nav toggle
    var navToggle = document.querySelector("[data-nav-toggle]");
    var navLinks = document.querySelector("[data-nav-links]");
    if (navToggle && navLinks) {
      navToggle.addEventListener("click", function () {
        var open = navLinks.classList.toggle("open");
        navToggle.setAttribute("aria-expanded", open ? "true" : "false");
      });
      navLinks.querySelectorAll("a").forEach(function (a) {
        a.addEventListener("click", function () {
          navLinks.classList.remove("open");
          navToggle.setAttribute("aria-expanded", "false");
        });
      });
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();

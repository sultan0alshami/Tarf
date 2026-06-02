(function () {
  "use strict";
  var STRINGS = {
    ar: {
      off: "التذكيرات متوقّفة",
      due: "حان وقت الراحة",
      scheduling: "نُجدوِل…",
      nextIn: function (p) {
        return "الراحة القادمة بعد " + p.m + "م " + String(p.s).padStart(2, "0") + "ث";
      },
      every: "كل",
      breakNow: "خذ راحة الآن",
      snooze: "تأجيل",
      limit: "يعمل فقط أثناء فتح Chrome — لا يُذكّرك بعد إغلاقه.",
      "link.support": "ادعمنا",
      "link.download": "التطبيق الكامل",
      footer: "٢٠ · ٢٠ · ٢٠ — انظر بعيدًا ٢٠ ثانية كل ٢٠ دقيقة."
    },
    en: {
      off: "Reminders are off",
      due: "Break is due",
      scheduling: "Scheduling…",
      nextIn: function (p) {
        return "Next break in " + p.m + "m " + String(p.s).padStart(2, "0") + "s";
      },
      every: "Every",
      breakNow: "Take a break now",
      snooze: "Snooze",
      limit: "Works only while Chrome is open — it cannot remind you after you quit.",
      "link.support": "Support us",
      "link.download": "Full app",
      footer: "20 · 20 · 20 — look away for 20s every 20 min."
    }
  };
  var lang = "ar";

  function t(key, params) {
    var v = (STRINGS[lang] || STRINGS.ar)[key];
    return typeof v === "function" ? v(params || {}) : (v !== undefined ? v : key);
  }

  function apply(l) {
    lang = STRINGS[l] ? l : "ar";
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      el.textContent = t(el.getAttribute("data-i18n"));
    });
  }

  window.TarfI18n = {
    t: t,
    apply: apply,
    get lang() { return lang; },
    toggle: function () { apply(lang === "ar" ? "en" : "ar"); }
  };

  document.addEventListener("DOMContentLoaded", function () { apply("ar"); });
})();

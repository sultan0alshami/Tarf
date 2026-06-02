// Side panel — persistent timer/streak dashboard.
// Reads background status via messaging; reuses i18n.js for AR/EN strings.
const send = (cmd, extra = {}) => chrome.runtime.sendMessage({ target: "background", cmd, ...extra });
const $ = (id) => document.getElementById(id);

async function refresh() {
  const s = await send("getStatus").catch(() => null);
  if (!s) return;
  const ms = s.enabled && s.nextAt ? s.nextAt - Date.now() : 0;
  $("status").textContent = !s.enabled ? (window.TarfI18n ? window.TarfI18n.t("off") : "الراحة متوقّفة")
    : ms <= 0 ? (window.TarfI18n ? window.TarfI18n.t("due") : "حان وقت الراحة")
    : window.TarfI18n
      ? window.TarfI18n.t("nextIn", { m: Math.floor(ms / 60000), s: Math.floor((ms % 60000) / 1000) })
      : `الراحة بعد ${Math.floor(ms / 60000)} دقيقة`;
}

$("breakNow").addEventListener("click", () => send("breakNow"));

(async () => {
  try {
    const list = (await (await fetch(chrome.runtime.getURL("dhikr.json"))).json()).dhikr;
    $("dhikr").textContent = list[Math.floor(Math.random() * list.length)].arabic;
  } catch (_) {}
})();

refresh();
setInterval(refresh, 1000);

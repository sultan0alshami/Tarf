// Popup control surface. All real work happens in background.js; the popup just
// reads status and sends commands.

var send = function (cmd, extra) {
  return chrome.runtime.sendMessage(Object.assign({ target: "background", cmd: cmd }, extra || {}));
};

var $ = function (id) { return document.getElementById(id); };

function t(key, params) {
  return window.TarfI18n ? window.TarfI18n.t(key, params) : key;
}

function renderStatus(state) {
  var el = $("status");
  if (!state.enabled) {
    el.textContent = t("off");
    return;
  }
  if (!state.nextAt) {
    el.textContent = t("scheduling");
    return;
  }
  var ms = state.nextAt - Date.now();
  if (ms <= 0) {
    el.textContent = t("due");
    return;
  }
  var min = Math.floor(ms / 60000);
  var sec = Math.floor((ms % 60000) / 1000);
  el.textContent = t("nextIn", { m: min, s: sec });
}

function refresh() {
  return send("getStatus").then(function (state) {
    if (!state) return;
    $("enabled").checked = !!state.enabled;
    $("interval").value = String(state.intervalMin);
    renderStatus(state);
  });
}

$("enabled").addEventListener("change", function (e) {
  send("setEnabled", { value: e.target.checked }).then(function () { refresh(); });
});

$("interval").addEventListener("change", function (e) {
  send("setInterval", { value: Number(e.target.value) }).then(function () { refresh(); });
});

$("breakNow").addEventListener("click", function () {
  send("breakNow");
  window.close();
});

document.querySelectorAll(".snooze button").forEach(function (b) {
  b.addEventListener("click", function () {
    send("snooze", { minutes: Number(b.dataset.min) }).then(function () { refresh(); });
  });
});

// Language toggle
var langBtn = $("lang");
if (langBtn) {
  langBtn.addEventListener("click", function () {
    if (window.TarfI18n) {
      window.TarfI18n.toggle();
      langBtn.textContent = window.TarfI18n.lang === "ar" ? "EN" : "عر";
    }
  });
}

// Fetch and display a random dhikr line
(function () {
  try {
    fetch(chrome.runtime.getURL("dhikr.json"))
      .then(function (r) { return r.json(); })
      .then(function (data) {
        var list = data.dhikr;
        if (list && list.length) {
          var el = $("dhikr");
          if (el) el.textContent = list[Math.floor(Math.random() * list.length)].arabic;
        }
      })
      .catch(function () {});
  } catch (_) {}
})();

refresh();
setInterval(refresh, 1000);

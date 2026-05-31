// Tarf Chrome extension — MV3 service worker.
// Owns ALL scheduling, notifications, and audio. The popup is only a control
// surface (it may be closed when a break fires). Audio plays via an offscreen
// document so "sound ends exactly when the 20s break ends" holds.

const DEFAULTS = { enabled: true, intervalMin: 20, breakSec: 20, rotation: 0 };
const EYE_ALARM = 'tarf-eye-break';
const END_ALARM = 'tarf-break-end';
const NOTIF_ID = 'tarf-break';
const IDLE_THRESHOLD_SEC = 60;

let dhikrCache = null;

async function getState() {
  return { ...DEFAULTS, ...(await chrome.storage.local.get(DEFAULTS)) };
}

async function loadDhikr() {
  if (dhikrCache) return dhikrCache;
  const res = await fetch(chrome.runtime.getURL('dhikr.json'));
  const json = await res.json();
  dhikrCache = json.dhikr;
  return dhikrCache;
}

async function nextDhikr() {
  const list = await loadDhikr();
  const { rotation } = await getState();
  const item = list[rotation % list.length];
  await chrome.storage.local.set({ rotation: rotation + 1 });
  return item;
}

async function scheduleNext() {
  const { enabled, intervalMin } = await getState();
  await chrome.alarms.clear(EYE_ALARM);
  if (enabled) {
    chrome.alarms.create(EYE_ALARM, {
      periodInMinutes: intervalMin,
      delayInMinutes: intervalMin,
    });
  }
}

async function ensureOffscreen() {
  const has = await chrome.offscreen.hasDocument();
  if (has) return;
  await chrome.offscreen.createDocument({
    url: 'offscreen.html',
    reasons: ['AUDIO_PLAYBACK'],
    justification: 'Play the 20-second eye-break completion sound.',
  });
}

async function fireBreak({ force = false } = {}) {
  // Activity awareness: don't nag when the user is idle or the screen is locked.
  if (!force) {
    const idle = await chrome.idle.queryState(IDLE_THRESHOLD_SEC);
    if (idle !== 'active') return;
  }

  const dhikr = await nextDhikr();
  const { breakSec } = await getState();

  await chrome.notifications.create(NOTIF_ID, {
    type: 'basic',
    iconUrl: 'icon128.png',
    title: 'Tarf — look ~6 m away',
    message: `${dhikr.arabic}\n${dhikr.transliteration} — ${dhikr.english}`,
    priority: 2,
  });

  try {
    await ensureOffscreen();
    chrome.runtime.sendMessage({
      target: 'offscreen',
      cmd: 'play',
      durationMs: breakSec * 1000,
    });
  } catch (_) {
    // Audio is best-effort; the notification is the guaranteed visual cue.
  }

  chrome.alarms.create(END_ALARM, { delayInMinutes: breakSec / 60 });
}

async function endBreak() {
  await chrome.alarms.clear(END_ALARM);
  try {
    chrome.runtime.sendMessage({ target: 'offscreen', cmd: 'stop' });
  } catch (_) {}
  await chrome.notifications.update(NOTIF_ID, {
    title: 'Tarf — you may look back now',
    message: 'Break complete. Back to it. 🌿',
  });
  setTimeout(() => chrome.notifications.clear(NOTIF_ID), 6000);
}

chrome.runtime.onInstalled.addListener(async () => {
  const cur = await chrome.storage.local.get(DEFAULTS);
  await chrome.storage.local.set({ ...DEFAULTS, ...cur });
  await scheduleNext();
});

chrome.runtime.onStartup.addListener(scheduleNext);

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === EYE_ALARM) fireBreak();
  if (alarm.name === END_ALARM) endBreak();
});

chrome.notifications.onClicked.addListener((id) => {
  if (id === NOTIF_ID) chrome.notifications.clear(NOTIF_ID);
});

// Popup <-> background messaging.
chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (!msg || msg.target !== 'background') return;
  (async () => {
    switch (msg.cmd) {
      case 'getStatus': {
        const state = await getState();
        const alarm = await chrome.alarms.get(EYE_ALARM);
        sendResponse({ ...state, nextAt: alarm ? alarm.scheduledTime : null });
        break;
      }
      case 'setEnabled':
        await chrome.storage.local.set({ enabled: !!msg.value });
        await scheduleNext();
        sendResponse({ ok: true });
        break;
      case 'setInterval':
        await chrome.storage.local.set({ intervalMin: msg.value });
        await scheduleNext();
        sendResponse({ ok: true });
        break;
      case 'snooze':
        await chrome.alarms.clear(EYE_ALARM);
        chrome.alarms.create(EYE_ALARM, { delayInMinutes: msg.minutes });
        sendResponse({ ok: true });
        break;
      case 'breakNow':
        await fireBreak({ force: true });
        sendResponse({ ok: true });
        break;
      default:
        sendResponse({ ok: false });
    }
  })();
  return true; // async response
});

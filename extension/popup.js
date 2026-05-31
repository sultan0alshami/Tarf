// Popup control surface. All real work happens in background.js; the popup just
// reads status and sends commands.

const send = (cmd, extra = {}) =>
  chrome.runtime.sendMessage({ target: 'background', cmd, ...extra });

const $ = (id) => document.getElementById(id);

function renderStatus(state) {
  const el = $('status');
  if (!state.enabled) {
    el.textContent = 'Reminders are off';
    return;
  }
  if (!state.nextAt) {
    el.textContent = 'Scheduling…';
    return;
  }
  const ms = state.nextAt - Date.now();
  if (ms <= 0) {
    el.textContent = 'Next break is due';
    return;
  }
  const min = Math.floor(ms / 60000);
  const sec = Math.floor((ms % 60000) / 1000);
  el.textContent = `Next break in ${min}m ${sec.toString().padStart(2, '0')}s`;
}

async function refresh() {
  const state = await send('getStatus');
  if (!state) return;
  $('enabled').checked = !!state.enabled;
  $('interval').value = String(state.intervalMin);
  renderStatus(state);
}

$('enabled').addEventListener('change', async (e) => {
  await send('setEnabled', { value: e.target.checked });
  refresh();
});

$('interval').addEventListener('change', async (e) => {
  await send('setInterval', { value: Number(e.target.value) });
  refresh();
});

$('breakNow').addEventListener('click', async () => {
  await send('breakNow');
  window.close();
});

document.querySelectorAll('.snooze button').forEach((b) => {
  b.addEventListener('click', async () => {
    await send('snooze', { minutes: Number(b.dataset.min) });
    refresh();
  });
});

refresh();
setInterval(refresh, 1000);

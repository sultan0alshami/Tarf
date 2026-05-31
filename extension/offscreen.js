// Offscreen audio document. Plays a calm, synthesized 20-second break sound
// (no bundled audio file needed) using the Web Audio API, with a soft start
// chime, a gentle pad for the full duration, and a distinct end chime exactly
// at the end — so the sound ending is the cue that the break is over.

let ctx = null;
let nodes = [];
let stopTimer = null;

function stopAll() {
  if (stopTimer) {
    clearTimeout(stopTimer);
    stopTimer = null;
  }
  for (const n of nodes) {
    try {
      n.stop ? n.stop() : n.disconnect();
    } catch (_) {}
  }
  nodes = [];
  if (ctx) {
    ctx.close().catch(() => {});
    ctx = null;
  }
}

function chime(at, freq, gainPeak) {
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.type = 'sine';
  osc.frequency.value = freq;
  gain.gain.setValueAtTime(0.0001, at);
  gain.gain.exponentialRampToValueAtTime(gainPeak, at + 0.04);
  gain.gain.exponentialRampToValueAtTime(0.0001, at + 0.8);
  osc.connect(gain).connect(ctx.destination);
  osc.start(at);
  osc.stop(at + 0.9);
  nodes.push(osc, gain);
}

function pad(start, end) {
  const master = ctx.createGain();
  master.gain.setValueAtTime(0.0001, start);
  master.gain.exponentialRampToValueAtTime(0.05, start + 1.2); // gentle fade-in
  master.gain.setValueAtTime(0.05, end - 1.2);
  master.gain.exponentialRampToValueAtTime(0.0001, end); // fade-out
  master.connect(ctx.destination);
  for (const freq of [196.0, 261.63]) {
    const osc = ctx.createOscillator();
    osc.type = 'sine';
    osc.frequency.value = freq;
    osc.connect(master);
    osc.start(start);
    osc.stop(end);
    nodes.push(osc);
  }
  nodes.push(master);
}

function play(durationMs) {
  stopAll();
  ctx = new (self.AudioContext || self.webkitAudioContext)();
  const now = ctx.currentTime;
  const seconds = durationMs / 1000;
  chime(now + 0.05, 880, 0.18); // start chime
  pad(now + 0.2, now + seconds - 0.1);
  chime(now + seconds - 0.6, 1318.5, 0.22); // distinct end chime
  stopTimer = setTimeout(() => {
    stopAll();
    chrome.runtime.sendMessage({ target: 'background', cmd: 'audioDone' });
  }, durationMs + 200);
}

chrome.runtime.onMessage.addListener((msg) => {
  if (!msg || msg.target !== 'offscreen') return;
  if (msg.cmd === 'play') play(msg.durationMs || 20000);
  if (msg.cmd === 'stop') stopAll();
});

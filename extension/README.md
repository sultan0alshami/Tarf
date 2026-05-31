# Tarf — Chrome Extension (MV3)

A self-contained Manifest V3 extension that brings Tarf's core **activity-aware
20-20-20 eye break + dhikr** to the browser.

## Architecture

Per the design, the extension is a **native-JS service worker** that owns all
scheduling, notifications, and audio — because a Flutter-web build cannot run
timers/audio/notifications inside an MV3 service worker (it sleeps, has no DOM).

- `background.js` — service worker. `chrome.alarms` drives the 20-min schedule
  (survives SW termination). On fire it checks `chrome.idle` (activity
  awareness — never nags when you're away), shows a `chrome.notifications`
  cue carrying the dhikr, and plays the 20-second sound via an offscreen doc.
- `offscreen.js` — an `AUDIO_PLAYBACK` offscreen document that synthesizes a
  calm 20-second sound with the Web Audio API (start chime → gentle pad → end
  chime). No bundled audio file needed; the sound ending = break over.
- `popup.html/.js/.css` — the control surface (enable, interval, snooze, "take
  a break now", live next-break countdown). On-brand teal, light/dark.
- `dhikr.json` — the rotating, non-sectarian dhikr set (mirrors the app).

## Load it (unpacked)

1. Open `chrome://extensions`.
2. Toggle **Developer mode** (top right).
3. Click **Load unpacked** and select this `extension/` folder.
4. Pin Tarf, open the popup, and click **Take a break now** to see the
   notification + hear the 20-second sound. The scheduled break fires every
   20 minutes of active browsing.

## Package for the Chrome Web Store

```powershell
pwsh ./package.ps1   # produces tarf-extension.zip
```

Upload the zip in the Chrome Web Store Developer Dashboard. See
`../docs/store/chrome-web-store.md` for the single-purpose description and the
per-permission justifications (alarms, notifications, offscreen, storage, idle).

## Optional enhancement (post-v1)

The popup/side-panel can be upgraded to render the **Flutter-web** UI
(`flutter build web` output copied into `ui/`, CanvasKit, non-WASM, locally
bundled). The service worker remains the scheduling source of truth. This
extension intentionally ships the reliable plain-HTML popup first.

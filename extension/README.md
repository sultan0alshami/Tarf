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
  a break now", live next-break countdown). Arabic-first RTL, teal, light/dark.
  Includes a rotating dhikr line, quick links to tarf.app, and the honest
  "only while Chrome is open" limit statement.
- `i18n.js` — AR/EN string table + `window.TarfI18n` helper. Arabic is the
  default; a one-tap `EN` toggle switches language and persists direction/lang
  on the `<html>` element.
- `sidepanel.html/.js` — persistent timer/streak dashboard rendered in
  `chrome.sidePanel`. Shows next-break countdown, a "take a break now" button,
  and a rotating dhikr line. Reuses `popup.css` and `i18n.js`.
- `dhikr.json` — the fully-diacritized (tashkil), non-sectarian dhikr set
  (mirrors the app's reverence rules).

## Load it (unpacked)

1. Open `chrome://extensions`.
2. Toggle **Developer mode** (top right).
3. Click **Load unpacked** and select this `extension/` folder.
4. Pin Tarf, open the popup, and click **Take a break now** to see the
   notification + hear the 20-second sound. The scheduled break fires every
   20 minutes of active browsing.

## Develop

```bash
npm test              # node:test suite (dhikr + manifest + popup invariants; 13 tests)
npm run lint          # node --check on all JS files (syntax validation, no network)
npm run package       # cross-platform: produces tarf-extension.zip via Node (no native zip needed)
```

All tests use `node:test`/`node:assert` — **no npm runtime deps** and **no env
vars required**. The full suite runs offline.

## Package for the Chrome Web Store

```bash
npm run package       # cross-platform Node packager → tarf-extension.zip
# or on Windows:
pwsh ./package.ps1    # PowerShell packager (same output)
```

Upload `tarf-extension.zip` in the Chrome Web Store Developer Dashboard.
See `STORE_LISTING.md` for the single-purpose statement and the per-permission
justifications. Full submission guide: `../docs/store/chrome-web-store.md`.

Permissions (justified in STORE_LISTING.md):
`alarms`, `notifications`, `offscreen`, `storage`, `idle`, `sidePanel`.
No host permissions. No remote code. CSP: `script-src 'self'; object-src 'self'`.

## Localization (AR default, EN toggle)

Arabic is the default language. The popup and side panel expose an `EN` toggle
that calls `window.TarfI18n.toggle()` — switching language, text direction, and
all `data-i18n` elements without a page reload.

## Optional enhancement (post-v1)

The popup/side-panel can be upgraded to render the **Flutter-web** UI
(`flutter build web` output copied into `ui/`, CanvasKit, non-WASM, locally
bundled). The service worker remains the scheduling source of truth. This
extension intentionally ships the reliable plain-HTML popup first.

# Tarf (طَرْف) — Chrome Web Store submission guide

> Step-by-step for publishing the **Tarf Chrome extension** (MV3). The extension is **built + tested in this
> environment** per the spec: a **native-JS service worker owns ALL scheduling/notifications/audio**
> (`chrome.alarms` → `chrome.notifications` + `chrome.offscreen` AUDIO_PLAYBACK), while Flutter web (CanvasKit,
> locally bundled, `--no-web-resources-cdn`) renders only the popup + side panel. This guide centers on the
> Chrome Web Store's **single-purpose** rule and the **per-permission justifications** reviewers require.

---

## 1. Account, fees, prerequisites
- **Chrome Web Store developer account:** one-time **USD 5** registration at
  chrome.google.com/webstore/devconsole. KSA developers supported (Google payments profile).
- **Group publisher / verification:** verify your email and (if listing a website) your domain for the
  "verified" badge and to set the homepage URL.
- Package the extension as a **.zip** of the `extension/` build output (MV3 `manifest.json` at the root, plus
  `background.js`, `offscreen.html/js`, the locally-bundled Flutter web `/ui`, CSP-compliant assets).

## 2. Single-purpose statement (required by CWS policy)
The store requires a **single, narrow purpose**. Use:

> **Single purpose:** "Tarf is an eye-care break reminder that periodically reminds you to rest your eyes
> (the 20-20-20 method) with a calm remembrance (dhikr) screen and a 20-second audio cue, and provides a small
> focus/timer dashboard. Every permission exists solely to schedule and deliver those break reminders."

All declared permissions must serve this one purpose; anything that doesn't will be rejected.

## 3. Manifest permissions + the justification you give reviewers
In the Privacy practices tab you must justify **each** permission. Tarf's MV3 permissions and the exact
justifications:

| Permission | Why Tarf needs it (justification to paste) |
|---|---|
| **`alarms`** | "The service worker is the scheduling source of truth; `chrome.alarms` fires the eye-break at the configured interval even when the popup/side-panel UI is closed. No timer can be kept in a non-persistent MV3 worker without it." |
| **`notifications`** | "To show the break reminder via `chrome.notifications` when the user is on another tab, so they know to look away and rest their eyes." |
| **`offscreen`** | "MV3 service workers cannot play audio directly. We create a single `chrome.offscreen` document with reason `AUDIO_PLAYBACK` to play the 20-second break audio cue (sound-end = break-end). The offscreen document is created only for the break and closed after." |
| **`storage`** | "To persist the user's local settings (interval, sound on/off, streak/focus counters) so reminders work across browser restarts. Data stays in the browser; nothing is sent to a server in extension Guest use." |
| **`sidePanel`** | "To render a persistent timer/streak dashboard in `chrome.sidePanel` so the user can see and control the running break/focus session while browsing." |
| **`idle`** *(if used)* | "Activity-aware scheduling: `chrome.idle` (active/idle/locked) ensures we never nag the user when they are away from the screen — the core differentiator and the #1 complaint about competitors." |
| **Host permissions** | **Avoid.** Tarf needs **no** host permissions / `<all_urls>` / content scripts for the core loop. Do not request them (broad host access triggers heavy review and rejection). If a feature ever needs one, request the narrowest possible and justify it. |
| **Remote code** | **None.** All JS + the CanvasKit/WASM ship **inside** the package (locally bundled, `--no-web-resources-cdn`). CSP `script-src 'self' 'wasm-unsafe-eval'`. Declare **"does not use remote code."** |

> **Honest limitation to state in the listing:** the extension can only fire reminders **while Chrome (the
> profile) is open** — it cannot remind you when Chrome is closed. Communicate this clearly (per spec) so
> reviewers and users aren't surprised.

## 4. Data usage disclosures (Privacy practices tab)
- **Data collected:** if the extension is used **standalone/Guest**, it collects nothing off-device (settings in
  `chrome.storage` only). If it signs in / syncs via Firebase like the apps, disclose **email + user ID + usage
  stats** consistently with the Privacy Policy and the other stores' forms.
- Certify: **not sold to third parties; not used for unrelated purposes; not used for creditworthiness/lending.**
- **Privacy Policy URL:** `[[https://tarf.app/privacy]]` (required).

## 5. Listing metadata checklist
- **Name:** "Tarf — Eye-care + Dhikr break" (≤ store limit). **Summary** (≤132 chars).
- **Detailed description** (AR + EN): the 20-20-20 + dhikr value, no ads, privacy-respecting, the
  Chrome-open-only limitation stated.
- **Icon** 128×128. **Screenshots** 1280×800 (or 640×400), min 1, ideally 3–5: popup, side-panel dashboard, the
  break notification + overlay; provide **Arabic (RTL)** + English where possible.
- **Category:** Productivity (or Health). **Language:** Arabic + English.
- **Promotional images** (optional small/marquee tiles).

## 6. Packaging + technical checklist (MV3)
- [ ] `manifest_version: 3`; `background.service_worker: background.js` (type module if used).
- [ ] Only the permissions in §3; **no** host permissions / content scripts unless truly required.
- [ ] **No remote code**: CanvasKit + all scripts bundled; CSP `script-src 'self' 'wasm-unsafe-eval'`; built with
      `--no-web-resources-cdn`.
- [ ] Single `offscreen` document, reason `AUDIO_PLAYBACK`, created per break and closed after (don't leak
      offscreen docs).
- [ ] `sidePanel` registered (`side_panel.default_path`) + `action.default_popup` for the popup.
- [ ] Version bumped in `manifest.json` per release.
- [ ] Plain-HTML/JS fallback popup retained as contingency (per spec) but the shipped popup is the Flutter UI.

## 7. Submit & review
1. devconsole → **New item** → upload the .zip.
2. Fill listing, **single-purpose** statement, **per-permission justifications** (§3), data-usage disclosures,
   privacy policy URL, screenshots.
3. Submit for review. MV3 + clear single purpose + minimal permissions → faster review; broad permissions or
   remote code → slow/rejected.
4. Address reviewer feedback in the dashboard; resubmit with a bumped version.

## 8. Tarf-specific rejection-avoidance
- Keep permissions **minimal and justified**; never request host permissions for the core loop.
- Ship **all** code locally (no CDN/remote eval) to satisfy the no-remote-code rule.
- State the **Chrome-must-be-open** limitation honestly in the description.
- Keep data disclosures **consistent** with the Privacy Policy and the App Store / Play forms.

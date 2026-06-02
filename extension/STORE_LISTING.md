# Tarf — Chrome Web Store Listing

> Reviewer-facing copy. Master source: `docs/store/chrome-web-store.md`.

---

## Single-purpose statement

> **Single purpose:** "Tarf is an eye-care break reminder that periodically reminds you to rest your eyes
> (the 20-20-20 method) with a calm remembrance (dhikr) screen and a 20-second audio cue, and provides a small
> focus/timer dashboard. Every permission exists solely to schedule and deliver those break reminders."

All declared permissions serve this one purpose; anything that doesn't is not requested.

---

## Per-permission justifications

| Permission | Justification |
|---|---|
| **`alarms`** | The service worker is the scheduling source of truth; `chrome.alarms` fires the eye-break at the configured interval even when the popup/side-panel UI is closed. No timer can be kept in a non-persistent MV3 worker without it. |
| **`notifications`** | To show the break reminder via `chrome.notifications` when the user is on another tab, so they know to look away and rest their eyes. |
| **`offscreen`** | MV3 service workers cannot play audio directly. We create a single `chrome.offscreen` document with reason `AUDIO_PLAYBACK` to play the 20-second break audio cue (sound-end = break-end). The offscreen document is created only for the break and closed after. |
| **`storage`** | To persist the user's local settings (interval, sound on/off, streak/focus counters) so reminders work across browser restarts. Data stays in the browser; nothing is sent to a server in extension Guest use. |
| **`sidePanel`** | To render a persistent timer/streak dashboard in `chrome.sidePanel` so the user can see and control the running break/focus session while browsing. |
| **`idle`** | Activity-aware scheduling: `chrome.idle` (active/idle/locked) ensures we never nag the user when they are away from the screen — the core differentiator and the #1 complaint about competitors. |

**Host permissions:** None. Tarf requests **no** host permissions / `<all_urls>` / content scripts.
The core loop (scheduling, notifications, audio) needs no access to page content or any website.

**Remote code:** None. All JavaScript ships inside the package. CSP: `script-src 'self'; object-src 'self'`.
Declare **"does not use remote code."**

---

## Honest limitation

> **Important:** This extension can only fire reminders **while Chrome (the profile) is open**.
> It cannot remind you after you quit Chrome. This is a fundamental limit of the MV3 service worker model
> and is stated clearly in the popup and side panel.

---

## Privacy disclosures

- **Data collected (standalone/Guest):** settings only (stored in `chrome.storage.local`), never sent off-device.
- Certify: not sold to third parties; not used for unrelated purposes; not used for creditworthiness/lending.
- **Privacy Policy:** https://tarf.app/privacy

---

## Listing metadata

- **Name:** Tarf — Eye-care + Dhikr break
- **Summary (≤132 chars):** Activity-aware 20-20-20 eye breaks with a calm dhikr. No ads. Works while Chrome is open.
- **Category:** Productivity (or Health)
- **Languages:** Arabic (primary), English
- **Homepage URL:** https://tarf.app

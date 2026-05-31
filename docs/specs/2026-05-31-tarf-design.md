# Tarf (طَرْف) — Design Specification

- **Status:** Approved (2026-05-31)
- **App:** Tarf — طَرْف ("the blink of an eye", طرفة عين)
- **One-liner:** A free, Arabic-first, offline-first, Apple-minimal wellness app whose core is the
  activity-aware 20-20-20 eye break fused with a calm dhikr "repeat-after-me" screen, surrounded by a
  restrained productivity layer (Focus, Timer, Alarm, Stopwatch, Insights, To-dos).
- **Targets:** Android, iOS, Windows, macOS, Chrome Extension, Web/PWA.
- **Model:** Free, donation-funded, **zero ads — and never anything commercial adjacent to sacred text**.

---

## 1. Product vision & principles

Tarf reframes the 20-20-20 method (every ~20 min of **active** screen time, look ~20 ft / 6 m away for
20 s) as a spiritual micro-rest. When a break fires, a single authentic dhikr appears on a calm full-screen
overlay with audio that plays for the **full 20 seconds**, so the sound ending *is* the cue to look back.

**Three differentiators:**
1. vs. other 20-20-20 apps → **intelligent activity awareness** (never nags when the user is not at the
   screen — the #1 cause of 1-star reviews for competitors).
2. vs. secular focus apps → **the break is dhikr**.
3. vs. Islamic apps → a genuinely **best-in-class, calm, multi-platform** tool, not an ad-supported suite.

**Design principles:**
- One hero element per screen (large numerals / progress ring / the Arabic dhikr).
- Calm through restraint: near-monochrome + exactly **one warm accent** (default **teal-green**); whitespace
  over ornament; depth (subtle translucency) over borders, with solid high-contrast fallbacks.
- **Arabic-first, not Arabic-translated.** RTL from day one (EdgeInsetsDirectional, start/end, mirrored
  icons, TextAlign.start). Every layout tested with real Arabic copy.
- Reverence for sacred content: Arabic immutable + fully diacritized + never truncated (auto-fit) + never
  adjacent to any ad/upsell/popup. No gamification of worship.
- Gentle by default, escalate to strict: skippable breaks + heads-up countdown + capped snooze ship by
  default; full-screen Strict mode is explicit opt-in.
- Accessibility as default: WCAG 2.1 AA, ≥44pt targets, Reduce Motion / Reduce Transparency / Dynamic Type
  honored, screen-reader labels, never color-alone, every audio cue paired with a visual cue.

---

## 2. v1 scope

**In scope:**
- Activity-aware 20-20-20 eye-care engine + two-tier breaks (frequent eye micro-break + occasional longer
  stand/stretch break), all intervals user-editable.
- Dhikr break overlay + 20-second app-played audio (sound-end = break-end) with start/end chimes.
- Focus sessions (Pomodoro, configurable, hero/home) with daily-goal streak + optional bound to-do task.
- Multiple named Timers + recents; Alarms; Stopwatch (laps).
- Insights / daily progress + session history + CSV export.
- To-dos (estimated vs actual focus counts; tap a task → start a session bound to it).
- Full Settings (grouped, progressively disclosed).
- Guest mode (core loop, no login) + required sign-in (Google/Apple/Email) for everything else + cloud sync.
- Arabic-first i18n + true RTL + Material 3 light/dark + reduce-motion.
- Prayer-time pause; Hijri date option + Arabic-Indic numerals; loud-through-silence opt-in.
- Desktop tray (live countdown, pause/snooze/skip, launch-at-startup, hide-to-tray).
- Download website + Support/Donate page (Mada/Visa/Mastercard via pluggable gateway).
- In-app Licenses & Credits screen driven by an asset provenance ledger.

**Deferred (documented, fast-follow — NOT built in v1):** tasbih counter on break screen; posture/blink
reminders; world clock; wearables / Live Activity / home-screen widgets; Spotify/Apple Music link; advanced
desktop smart-pause (meeting / screen-recording / fullscreen-game detection); iOS Critical Alerts entitlement
submission (the toggle ships; the entitlement request is post-v1).

---

## 3. Information architecture

**One IA, three chromes.** Top-level destinations (nouns), identical order/icons/labels everywhere:
**Focus (home)** · **Timer** · **Alarm** · **Stopwatch** — plus **Insights** and **Settings** reached from a
profile/gear. **Eye-Care 20-20-20 is a persistent background engine** (configured in Settings, surfaced by a
running-status chip + the break overlay), NOT a tab. World Clock is dropped from v1.

- **Mobile (<600px):** floating bottom tab bar + a persistent "active session" accessory shelf above it
  (shows any running focus/timer/break with pause/stop). Never two bottom bars.
- **Desktop / Web / tablet-landscape (>600px):** collapsible left nav rail (Insights + Settings in footer)
  + an optional always-on-top mini-window + **system-tray** presence.
- **Chrome extension:** popup (`action.default_popup`) for quick start/stop/snooze/toggle; `chrome.sidePanel`
  for a persistent timer/streak dashboard. The **native-JS service worker is the scheduling source of truth**
  because the Flutter UI may not be running when a break fires.

**Modality rules:** nav stays visible while drilling into a section; only true modals hide it — the
full-screen running focus session, the alarm-ringing screen, and the eye-care break overlay. The
running-session accessory/mini-window persists across all navigation as the single global control.

---

## 4. Core engine

### 4.1 Activity-aware scheduling
Eye-breaks fire off **accumulated active time**, not wall-clock. Per-platform signal table (the test oracle;
honest about ceilings):

| Platform | Active signals | Pause/reset on | Ceiling (stated honestly) |
|---|---|---|---|
| Windows / macOS | system input-idle time; app/window focus | idle > threshold; lock | fullscreen/meeting detection deferred to fast-follow (needs scary perms) |
| Chrome extension | `chrome.idle` (active/idle/locked) | idle/locked | only while Chrome/profile open |
| Android | Tarf foreground, screen on/off, motion (stationary), DND/Focus | screen off; idle; call/media | cannot observe other apps (sandbox) |
| iOS | Tarf foreground, screen on/off (lifecycle), motion, Focus status | background/idle | cannot observe other apps (sandbox) |

### 4.2 `ReminderScheduler` abstraction
One shared Dart interface; per-platform impls: `MobileScheduler` (flutter_local_notifications +
android_alarm_manager_plus + workmanager catch-up), `DesktopScheduler` (timers + local_notifier +
window_manager + tray), `ExtensionBridgeScheduler` (JS-interop to `chrome.alarms`/`chrome.notifications`/
`chrome.offscreen`). Riverpod state + UI stay 100% shared.

### 4.3 Reminder-precedence state machine
Single deterministic state machine resolves: global pause (presets: 1h / 2h / until tomorrow / indefinitely),
working hours, Strict mode, Pomodoro break/idle, prayer-time pause, DND/Focus, merge-with-Pomodoro,
per-session snooze cap. Precedence table + exhaustive transition tests. The eye-break is a **dismissible
overlay that auto-resumes and NEVER pauses/resets the focus timer**; the eye cue is suppressed during a
Pomodoro break or idle. An optional "merge with Pomodoro breaks" consolidates interruptions.

### 4.4 The 20-second sound contract (tiered, honest)
Audio is played by the **app audio layer** (`just_audio` mobile/desktop · gesture-unlocked Web Audio web ·
`chrome.offscreen` AUDIO_PLAYBACK doc in the extension) — **never** the notification sound (short/unreliable/
unsupported cross-platform). Soft chime at start; distinct chime at second 20. Default respects silent/DND
unless the user opts into loud-through-silence.

| Context | Behavior |
|---|---|
| Active/foreground (all platforms) | Full-screen overlay + 20s audio → **guaranteed** sound-end = break-end |
| Backgrounded — Windows/macOS | Tray app plays 20s audio + notification ✅ |
| Backgrounded — Android | Foreground service + AlarmManager + full-screen intent plays 20s audio (battery-opt prompt) ✅ best-effort under Doze |
| Backgrounded — iOS < 26 | Local notification + short sound + overlay-when-active (**degraded, stated in-app + on store page**) |
| Backgrounded — iOS 26+ | AlarmKit ring-through-silence (dismissible) |
| Web / extension (Chrome closed) | Cannot fire; only while Chrome open (**communicated honestly**) |

**iOS minimum = 15.** No silent-keep-alive-session hack (rejection risk). Min Android = API 26; macOS 11+;
Windows 10+.

---

## 5. Dhikr content & audio

- **Content set (non-sectarian, universally agreed, short):** the 4 beloved words
  (SubḥānAllāh / Alḥamdulillāh / Lā ilāha illā-llāh / Allāhu akbar), SubḥānAllāhi wa bi-ḥamdihi,
  Astaghfirullāh, Lā ḥawla wa lā quwwata illā billāh, ṣalawāt. **Rotate** (not random-repeat).
- Each entry: Arabic (full tashkīl) + transliteration (toggle) + concise English + tiny source tag
  (**Hisn al-Muslim / sunnah.com** with exact reference). Stored as **immutable bundled JSON**.
- **Arabic font: Amiri or Scheherazade New (SIL OFL)** — KFGQPC avoided (restrictive license). UI font:
  **Inter** (SIL OFL) for SF-Pro-like feel with tabular figures; NOT actual SF Pro.
- **Audio:** bundle CC0/Pixabay recitation clip per dhikr where clearable; **Arabic TTS fallback**
  (`flutter_tts`, gated on `isLanguageInstalled('ar-SA')`); calm ambience + chimes. A **remote
  kill/replace switch** (Firebase Remote Config) can disable/swap a defective clip without a full release.
- **Provenance ledger** (`assets_ledger/ledger.json`): for every audio clip + font — source URL, license,
  license-text snapshot, download date, author, required attribution, signed-agreement path for any
  commissioned recitation. Drives the in-app Licenses screen.
- **Editorial gate (owner-provided before public release):** a named scholarly/editorial sign-off on the
  Arabic text, diacritics, transliteration scheme, translations, and references (tracked artifact). v1 ships
  only the universally-agreed phrases to stay non-sectarian.

---

## 6. Data, sync & auth

### 6.1 Storage
- **Local-first: Drift (SQLite)** is the on-device source of truth. The eye-care + dhikr core reads its
  config from local storage and works with **zero network, ever** (solves guest mode + airplane-mode first
  launch — the offline deadlock the critic flagged).
- **Signed-in: Cloud Firestore** with offline persistence (built-in local cache + automatic replay of queued
  writes on reconnect). On sign-in, local guest data **migrates/merges up** to Firestore once; thereafter
  Firestore (SDK-cached) is the synced store and the sync service mirrors changes back to Drift for the
  offline-core engine.

### 6.2 Firestore data model
```
/users/{uid}                      profile, displayName, createdAt, schemaVersion
/users/{uid}/settings/app         eyecare, focus, notifications, appearance, prayer, account (single doc)
/users/{uid}/dailyProgress/{yyyy-MM-dd}   { tz, focusMinutes, sessions, breaksTaken, breaksSkipped,
                                            goalPct }  // counters via FieldValue.increment
/users/{uid}/focusSessions/{id}   { startTs(server), endTs, workMin, breakMin, taskId?, reflection? }
/users/{uid}/todos/{id}           { title, done, estimatedSessions, actualSessions, createdAt, updatedAt }
```
- **Security rules:** every path locked to `request.auth.uid == uid`.
- **Conflict-safety:** `FieldValue.increment`/transactions for counters; per-field updates (no whole-doc
  overwrite) for settings; date-keyed daily docs carry an explicit **timezone**; append-only session logs.
- **Clock integrity:** `FieldValue.serverTimestamp()` when online; monotonic checks offline; streaks
  hardened against device-clock manipulation.
- **Schema versioning:** `schemaVersion` field + forward-migration plan.
- **Cost/scale:** Spark tier + App Check + write batching; instrument read/write counters; set Firebase
  budget alerts; documented user-count threshold + Blaze migration trigger.

### 6.3 Auth (guest peek + required sign-in)
- **Guest (no login):** eye-care 20-20-20 + dhikr break loop fully offline, local only.
- **Sign-in (one-time online):** Google + **Sign in with Apple** (peer option, not pre-selected) + Email/
  Password. Unlocks Focus, Timer, Alarm, Stopwatch, Insights, To-dos, and cloud sync. Cached FirebaseAuth
  session + Firestore cache then work offline.
- **Mandatory:** in-app **account deletion** (+ delete all Firestore data) and **data export** flow
  (App Store + Play requirement). Graceful re-login route when a privileged online action fails offline.
- Edge cases designed: cancelled/network sign-in failure; account-exists-with-different-credential;
  token-expired-while-offline; cleared-app-data wipes cached session.

---

## 7. Audience-specific features (v1)

- **Prayer-time pause (optional):** compute 5 daily prayer times locally via `adhan` (location + method +
  madhab settings); auto-pause/defer eye-break reminders around salah. Location permission primed with
  Arabic-first rationale; graceful fallback to manual times if location denied.
- **Hijri dates + Arabic-Indic numerals:** `hijri` package for an optional Islamic-date display on
  Insights/streaks; Eastern Arabic-Indic digits (٠١٢٣) in Arabic locale via `intl`, with a user toggle;
  tabular alignment preserved for both digit systems.
- **Loud-through-silence (opt-in):** Android high-importance channel + iOS audio-session override so the
  break sound can play through a muted device. Strictly opt-in (surprise loud audio is a top 1-star driver);
  the iOS Critical Alerts entitlement *submission* is deferred, but the toggle + plumbing ship.

---

## 8. Donations

- A hosted **Support / Donate** page on the website with a **pluggable KSA payment gateway** abstraction
  (`Moyasar` primary / `Tap` / `Stripe`) supporting **Mada + Visa + Mastercard**, via a serverless endpoint
  that creates the payment (owner's merchant API keys slotted in for live charges; sandbox/test mode default).
- **Non-iOS apps** (Android/Web/Windows/macOS) show a "Support" button linking out to that page.
- **iOS** shows a thank-you / share entry only — **no payment link** (App-Store-safe for a for-profit dev).
- The donation page is PCI-handled by the gateway (no raw card data touches our serverless code).

---

## 9. Compliance (release gates)

Hosted **privacy policy + terms** URL · Apple **App Privacy** labels + **PrivacyInfo.xcprivacy** (required-
reason APIs + bundled Firebase SDK manifests) · Google Play **Data Safety** form · in-app **account deletion
+ data export** · GDPR/CCPA lawful basis + documented **religion-as-sensitive-data** position (no special-
category processing / explicit consent) · export-compliance / encryption declaration
(`ITSAppUsesNonExemptEncryption`) · age rating (4+/Everyone) · app category · target-API compliance · a
**permissions UX matrix** (iOS notifications + provisional · Android 13+ **POST_NOTIFICATIONS** · exact-alarm
· full-screen-intent · battery-optimization exemption · macOS notifications · location for prayer times) with
just-in-time priming copy (AR+EN), granted path, **denied path + re-ask + Settings deep-link**, and a
first-class **notifications-denied degraded experience**.

---

## 10. Platforms — build reality (this environment is Windows)

- **Built + tested here in this sprint:** Web/PWA · **Chrome Extension** · **Windows desktop** (.exe + MSIX)
  · **Android APK** (Android SDK installed with approval).
- **Scaffolded + CI + store guides (final signed builds run by owner / CI):** **iOS** & **macOS** — full
  Flutter targets, Podfile/entitlements/signing placeholders, **GitHub Actions** matrix (Android/Windows/Web/
  extension on this repo; iOS/macOS on a macOS runner), and step-by-step App Store / Play Console / Microsoft
  Store / Chrome Web Store submission docs.
- Desktop distribution: signed/notarized macOS, MSIX (Windows), with an **auto-update channel** so dhikr/glyph
  fixes reach desktop users. Code-signing certs + Apple Developer membership are owner-provided deliverables.

---

## 11. Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3.35+ (CanvasKit web, non-WASM, for the extension UI only) |
| State | Riverpod 3.x (+ riverpod_generator) |
| Local store | Drift (SQLite) |
| Cloud / sync | Cloud Firestore (offline persistence) + App Check + Remote Config (kill switch) |
| Auth | firebase_auth: Google + sign_in_with_apple + Email/Password |
| Notifications (visual cue only) | flutter_local_notifications 21.x; local_notifier (desktop tray toasts); chrome.notifications (ext) |
| Background exec (Android) | android_alarm_manager_plus + workmanager + foreground service (declared FGS type) |
| Audio (the 20s clip) | just_audio (+ just_audio_background); chrome.offscreen (ext); Web Audio (web) |
| TTS (fallback) | flutter_tts (gated on ar-SA availability) |
| Desktop presence | window_manager · tray_manager · launch_at_startup · local_notifier |
| i18n / RTL | flutter_localizations + intl (ARB; Arabic primary, English secondary) |
| Theming | Material 3 ColorScheme.fromSeed (teal-green) + ThemeMode.system + dynamic_color (Android 12+) |
| Prayer / Hijri | adhan · hijri |
| Routing | go_router |
| Connectivity | connectivity_plus (drives sync) |

**Chrome extension architecture (highest risk):** native JS service worker owns ALL scheduling/notifications/
audio (`chrome.alarms` → `chrome.notifications` + `chrome.offscreen` AUDIO_PLAYBACK); Flutter web (CanvasKit,
`--no-web-resources-cdn`, locally bundled canvaskit) renders ONLY the popup/side-panel; UI ↔ SW via
`chrome.runtime` messaging. CSP `script-src 'self' 'wasm-unsafe-eval'`. **Plain-HTML/JS fallback popup** kept
as contingency. Flutter version pinned; a real spike is budgeted.

---

## 12. Repository layout (monorepo)

```
tarf/                       (= project root)
  app/                      Flutter app
    lib/
      core/                 ReminderScheduler, state machine, time/idle, audio, scheduler impls
      data/                 Drift (local), Firestore (cloud), sync service, repositories
      features/             eyecare, dhikr_break, focus, timer, alarm, stopwatch, insights, todos,
                            settings, onboarding, account
      l10n/                 ARB files (ar, en)
      theme/                tokens, light/dark, typography
      app.dart / main_*.dart
    test/                   unit + widget + integration; golden tests (RTL + Arabic)
    android/ ios/ windows/ macos/ web/
  extension/                MV3: manifest.json, background.js (SW), offscreen.html/js, fallback popup,
                            build of app web → /ui
  website/                  download site + Support/Donate + serverless donate function
  assets_ledger/            ledger.json + license snapshots
  docs/                     specs/, store-submission guides, compliance checklist, content sheet
  .github/workflows/        CI build matrix
```

---

## 13. Testing & QA

- Unit/integration tests for the `ReminderScheduler` interface + the precedence state machine (highest-risk
  code); a parallel JS test suite for the extension engine mirroring the Dart engine.
- Widget + **golden tests** for RTL/Arabic rendering (no Arabic split across TextSpans; verify on CanvasKit).
- Real-build verification of the here-buildable targets (Web, Windows, Android, extension) before "done".
- Field-safe telemetry (privacy-respecting, never near sacred text) verifying the two life-or-death promises:
  break fired on time, 20s audio played to completion.
- Beta channel plan (TestFlight / Play internal) before public release.

---

## 14. Deliverables

1. The Tarf app (all 6 targets — built here where possible, scaffolded + CI elsewhere).
2. The Chrome extension.
3. The download + Support/Donate website (with pluggable Mada/Visa/Mastercard gateway).
4. Asset provenance ledger + in-app Licenses screen.
5. Compliance pack (privacy policy/terms drafts, store metadata, permissions matrix, account-deletion flow).
6. CI workflows + store-submission guides for every platform.
7. A reusable **`Project_Sprint`** Claude skill capturing this entire end-to-end process.

---

## 15. Build sequence

Spec → implementation plan (writing-plans) → execute with parallel sub-agents per subsystem (core engine ·
break/dhikr UI · focus/timer/alarm/stopwatch · data/sync/auth · i18n/theme · extension-JS · website ·
compliance), each test-driven → integration → real build/run verification of here-buildable targets →
package the `Project_Sprint` skill.

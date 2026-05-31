# Tarf (طَرْف) — Comprehensive Project Description

> **Tarf** (طَرْف, *"the blink/glance of an eye"*) is a calm, reverent, **Arabic‑first**
> eye‑care companion. Its heart is the **20‑20‑20 method** — every **20 minutes** of active
> screen time, look **~6 m / 20 ft** away for **20 seconds** — fused with a gentle **dhikr**
> ("repeat after me") rest moment, so each break **cares for the eyes and the heart** at once.
> Around that spine sits a full, polished **clock suite** (Focus / Timer / Alarm / Stopwatch),
> light task tracking, and quiet progress insights.

This document is the single, comprehensive description of the project: the vision, **every
requirement the owner has stated**, the **features added to make the product whole** (clearly
marked), the design language, the technical architecture, the platforms and distribution plan,
monetization, privacy, and current build status.

**Companion documents** (do not duplicate — read alongside):
- [`design.md`](design.md) — the full **"Calm Sanctuary"** UI/UX design spec (palette, type, motion,
  RTL rules, component library, per‑screen Stitch prompts). This file references it; it is the
  source of truth for visuals.
- [`README.md`](README.md) — build/run instructions. · [`User_Actions.md`](User_Actions.md) — owner
  to‑do list (accounts, keys, sign‑offs). · [`docs/`](docs) — Firebase + store/account setup.

**Legend used below:** ✅ built & verified · 🟡 designed / partial · ⬜ planned / owner task ·
**[owner]** = stated by the owner · **[added]** = needed feature not explicitly requested, added to
complete the product.

---

## 1. Vision & non‑negotiables

**Vision.** A wellness app that protects eyesight during long screen sessions while turning each
mandated pause into a moment of remembrance (dhikr). It must feel **Apple‑minimal, modern, and
reverent** — never gimmicky, never commercial near sacred text.

**Non‑negotiable principles** (all **[owner]** unless noted):
1. **Free forever, donations only. Zero ads.** No paywalls, no commercial content — *ever* — and
   **nothing commercial anywhere near sacred text.**
2. **Reverence for the sacred.** Qur'anic/dhikr Arabic is fully vocalized, shown large in a Naskh
   face (Amiri), never decorated/blurred/letter‑spaced/truncated, and never adjacent to upsell.
   Dhikr selection requires **scholarly sign‑off** before release.
3. **Arabic‑first, truly RTL.** Arabic is the canonical layout; English is the secondary locale.
4. **Western digits (1234) are the default in every locale, including Arabic.** Per the owner:
   *"1234 are the Arabic numerals; ٠١٢٣ are the Hindi (Eastern Arabic‑Indic) numerals."* Eastern
   digits are an **optional Settings toggle only**. (See §7.)
5. **Local‑first & private.** The eye‑care core works fully offline as a guest; cloud sync and
   sign‑in are optional. Data export and delete‑all are always available. **[added: privacy posture]**
6. **Honesty over polish.** The UI never promises capability the platform can't deliver; degraded
   states (e.g. iOS background limits, extension only while Chrome is open) are stated calmly.
7. **All platforms, one product.** Android, iOS, Windows, macOS, Web/PWA, and a Chrome extension —
   one IA, one design, three "chromes" (mobile bar / desktop rail / extension popup).

---

## 2. Identity, audience, region

| Field | Value |
|---|---|
| Product name | **Tarf** (طَرْف) |
| App / bundle ID | `app.tarf` **[owner‑confirmed]** |
| Primary locale | Arabic (`ar`), then English (`en`) |
| Owner / publisher | **Individual, for‑profit**, based in **Saudi Arabia (KSA)** **[owner]** |
| Payments region | KSA — **Mada**, Visa, Mastercard **[owner]** |
| Audience | Arabic‑speaking, Muslim‑context users on long screen sessions (students, knowledge workers, devs); broadly useful to anyone wanting eye rest. |
| Tone | Calm, reverent, spacious, premium, content‑first, distraction‑free. |
| Inspiration | Apple iOS content‑first restraint + Microsoft Clock structure, tuned to **reverent**. (The "Calm Sanctuary" direction in `design.md` is the modern evolution of the initial Clock‑style brief.) |

---

## 3. The core: 20‑20‑20 eye‑care + dhikr break

This is the **spine** of the app — surfaced everywhere, not a tab.

### 3.1 The engine **[owner]** ✅
- Counts **active screen time** (foreground, non‑idle) and, at the chosen **interval (default 20 min)**,
  triggers a **break of the chosen duration (default 20 seconds)**.
- **Idle detection [added]:** continuous inactivity pauses accumulation (idle threshold) and, past a
  longer threshold, resets it — so the 20 minutes reflects *real* use, not wall‑clock.
- **Sound‑ends = break‑ends [owner]:** the break audio is played by the app for the full duration so
  the sound finishing is a real cue, in lockstep with the visual ring reaching zero.
- Implemented as a **pure precedence state machine** + an **active‑time tracker**, hosted by an
  in‑app foreground engine (works whenever the app/tab is open).

### 3.2 The dhikr rest moment **[owner]** ✅ (reverent peak)
The 20‑second eye break and the dhikr are **one screen**, reconciled honestly (see `design.md` §3):
- **Physiological task:** look ~6 m / 20 ft away (defocus). A soft **focal dot** gently recedes at
  the ring's center to give the eye somewhere to relax toward.
- **The dhikr is recited from memory, not read.** A short, familiar adhkār (e.g. *SubḥānAllāh*) is
  shown **large, static, centered, high‑contrast** in **Amiri** with full tashkīl — a prompt, not a
  reading task.
- **End cue is visual‑first:** ring‑to‑zero + a gentle bloom is authoritative; the chime + a brief
  haptic fire as **equal** cues (so silenced/Deaf‑HoH users are served). Haptic here is **opt‑out**.
- **Repeat‑after‑me** framing with optional recited audio.

### 3.3 Break audio & background sound **[owner]** 🟡
- Toggle between **calm music** and **recited dhikr** as the break soundtrack; "play through silent
  mode" option. **[owner]**
- A synthesized/bundled audio path exists; a full native audio backend (recitation clips, media
  controls, ducking) is an **owner/integration task**. ⬜

### 3.4 Eye‑care configuration ✅ (defaults match onboarding exactly)
| Setting | Default | Notes |
|---|---|---|
| Reminder interval | **20 min** | editable 5–60 **[owner: default 20]** |
| Break duration | **20 sec** | editable 10–60 **[owner: default 20s, chosen in onboarding]** |
| Longer stand/stretch break (two‑tier) | every ~50 min, 5 min | **[added]** advanced, Settings‑only |
| Strict mode (no skip) | off | **[added]** |
| Working hours (do‑not‑remind window) | off | **[added]** |
| Prayer‑time pause | off | pauses reminders around ṣalāh using computed prayer times (adhan) **[added, Islamic context]** |
| Sound / Haptics | on / on | paired cues **[added: accessibility]** |
| Snooze (with per‑session cap) | enabled | **[added]** |
| Show transliteration | on | persistent; wired into the break overlay ✅ |
| Pre‑break heads‑up | on | brief lead‑in before a break **[added]** |

> **Onboarding ↔ first launch consistency [owner]:** the interval and break duration chosen during
> onboarding are exactly what appear on first launch. Home leads with the eye‑care hero so they
> always match.

> **Edit from the main page [owner]:** an edit/tune affordance on Home opens the durations inline —
> no need to dig into Settings.

---

## 4. Feature set (beyond the core)

### 4.1 Home / Eye‑care **[owner]** ✅
The first tab. The **largest object is the eye‑care hero**: a live progress ring, "next eye break
in mm:ss", today's eye‑rests, and a pause control (the eye‑care status chip lives *inside* this
card). Below: a small **bento** of metrics (focus today, sessions, to‑dos) and **one** primary CTA
("Start focus session"). Tapping the hero rests now.

### 4.2 Focus (Pomodoro) **[owner]** ✅
Full‑screen pushed session: a large ring with the remaining time, daily‑goal dots, bound‑task chip,
Pause/Resume/Reset/Skip, and an inline durations editor (work / short / long / daily goal).
**Focus‑complete bloom [added]** celebrates a finished work session. The eye‑care break can appear
*over* a running focus session without disturbing it (separate controllers).

### 4.3 Timer **[owner]** ✅
A single editable countdown: tactile **H:M:S steppers** + quick‑preset pill chips (1/5/10/20 min) →
a ring with Pause/Reset while running. *(Multi‑timer "saved timers" list is a possible future
enhancement — the current engine is single‑timer.)* 🟡

### 4.4 Alarm **[owner]** ✅
Grouped rounded rows: large tabular time, label + repeat summary (Once / Daily / Weekdays /
Weekends / Custom), pill toggle, swipe‑to‑delete. **Foreground alarm watcher + full‑screen
ringing modal [added]** (Snooze re‑arms +5 min, Stop; one‑shot alarms self‑disable). **Background
ringing needs native scheduling** (owner task) — stated honestly in‑app. 🟡

### 4.5 Stopwatch **[owner]** ✅
Oversized tabular hero time; Lap / Start‑Stop / Reset; lap list with split + cumulative total and
**shape‑distinct** fastest/slowest marks (▲/▼, never color‑alone).

### 4.6 To‑dos / tasks **[owner]** ✅
Calm list with circular checkboxes, estimated‑vs‑actual session counts, and a play action that
starts a focus session (task‑to‑focus binding). Warm empty state.

### 4.7 Insights / daily progress **[owner]** ✅
Eye‑rests‑today hero + supportive copy, a calm **7‑day bar chart**, derivable metric cards
(focus today / this week), and **CSV export**. **No punitive streak language [added principle].**

### 4.8 Settings ✅
Grouped tonal sections: **Eye‑care** (interval, duration, strict, → more eye‑care settings),
**Dhikr & audio** (show transliteration, sound), **Appearance** (theme System/Light/Dark, language
AR/EN, reduce motion, **numerals 1234 / ٠١٢٣** toggle), and an **Account** row.

### 4.9 Account & sync 🟡
Guest by default ("your data stays on this device" + offline sync pill). Sign‑in buttons
(Google / Apple / Email) are present but **disabled with "Coming soon"** until Firebase is wired.
**Data export + delete‑all** are always reachable (mandatory). ⬜ real auth/sync is an owner task.

### 4.10 Onboarding **[owner]** ✅
Calm multi‑step: language + theme → value framing (with an **honest one‑liner** on background
limits) → **interval** dial (default 20 min) → **break duration** dial (default 20 sec) + "preview a
dhikr break" → reminders/working hours + "Begin as guest" vs "Sign in".

### 4.11 System surfaces & states ✅/🟡
- **Active‑session accessory shelf [added]** — a glass "now‑playing" strip above the tab bar while a
  focus session runs (live time, pause/resume/stop, tap to reopen); compact form in the desktop rail. ✅
- **Modals:** dhikr break overlay ✅, alarm‑ringing ✅, focus‑complete bloom ✅.
- **Empty states** (calm mark + warm line + one action) ✅.
- **Permission / degraded banner** (honest, warning‑tinted) 🟡.

---

## 5. Design language — "Calm Sanctuary"

Full spec in [`design.md`](design.md). Essentials:

- **Direction:** dark‑first, content‑first restraint + Material‑3‑Expressive physics, tuned reverent.
  **One hero per screen** floating in deep negative space; chrome recedes into a quiet floating glass
  layer. **Exactly one accent** (teal‑green) means *"this is alive / this is the action."*
- **Signature (authored, not generic):** the **Ambient Ring** (persistent eye‑care countdown that
  becomes the frame the dhikr sits within), **reverence margins**, and **Amiri typography** larger
  than the Latin UI.
- **Color tokens** (both themes ship; dark is canonical): accent `#0E7C66` seed → primary `#2FB89B`
  (dark) / `#0B6A57` (light); backgrounds, four tonal surface levels, AA‑verified text tiers, dhikr
  ground lifted off pure black. Functional success/warning/destructive are muted, never a 2nd brand
  color. Implemented as a Material 3 `ColorScheme` + a custom `TarfColors` `ThemeExtension`.
- **Type:** **Amiri** for Arabic/sacred (fully vocalized, line‑height ≥1.8/2.0, never letter‑spaced);
  **Inter** for Latin UI with **tabular figures** on all timers/numerals.
- **Motion:** calm near‑critically‑damped springs; two gentle Expressive springs only for the dhikr
  reveal + break bloom; breathing loops 3–6 s; full **reduce‑motion** table honored.
- **Components:** floating glass capsule tab bar, bento cards (tonal, no borders), pill buttons,
  segmented controls, tactile sliders with detents, grouped list rows with hairline dividers,
  bottom sheets (radius 28), the dhikr overlay.

---

## 6. Information architecture

- **Top‑level peers (tabs):** Focus(Home) · Timer · Alarm · Stopwatch. In RTL, **Focus is the
  right‑most** tab. **Insights & Settings** live behind a top‑corner profile/gear, not as tabs.
- **Eye‑care 20‑20‑20 is the background engine**, surfaced by the Ambient Ring + status chip +
  break overlay; Home's largest element is the eye‑care hero.
- **One IA, three chromes:** mobile bottom capsule bar · desktop/web left rail · extension popup —
  identical order, icons, and labels.
- **Three true modals only:** running focus full‑screen, alarm‑ringing, dhikr break overlay.
- **Auth gating:** guest runs eye‑care + dhikr fully offline; sign‑in unlocks sync + cross‑device.

---

## 7. Numerals & localization

- **Western digits (1234) are the DEFAULT everywhere, including Arabic** **[owner, emphatic]**.
  Eastern Arabic‑Indic (٠١٢٣) is an **optional toggle** in Settings.
- All timer/stopwatch numerals use OpenType **tabular** figures so columns never jitter. If the
  Eastern toggle is used, a numeral‑capable tabular Arabic font is required (e.g. IBM Plex Sans
  Arabic / Readex Pro) — flagged as an integration detail. **[added]**
- Localization via Flutter `flutter_localizations` + **ARB** files (`app_ar.arb` primary,
  `app_en.arb`), generated to typed getters. Arabic strings get ~25–40% extra width budget.
- True **RTL**: mirror nav/lists/linear‑progress; **do NOT mirror** the logo, media controls,
  clock/timer faces (the countdown ring depletes clockwise in both directions), or numerals.

---

## 8. Accessibility commitments **[added: formalized]**

- **WCAG 2.1 AA** on every screen; **AAA** for the dhikr Arabic line.
- ≥44×44 hit targets; Dynamic Type to AX5 with defined reflow (hero numerals auto‑fit).
- Never color‑alone (pair with icon/weight/shape); every audio cue has an **equal** visual cue.
- `prefers‑reduced‑motion` honored per the motion table; Reduce Transparency → frosting toward solid.
- Screen readers: the ring announces once (not per second); dhikr read in Arabic; logical RTL order.
- Mandatory **data export + account deletion** remain reachable and labelled.

---

## 9. Platforms & distribution **[owner: all platforms + website]**

| Platform | State | Notes |
|---|---|---|
| **Android** | ✅ builds | Native notification scheduling for background eye‑breaks/alarms ⬜ (owner/native task). |
| **iOS** | 🟡 | Background reminders need **iOS 26+**; below that, "reminds while open" — stated honestly. Critical Alerts / AlarmKit = separate decision. |
| **Windows** | ✅ builds | Requires Developer Mode for desktop build (done). Tray + always‑on‑top mini‑window for the active session 🟡. |
| **macOS** | 🟡 | Same desktop shelf/tray model. |
| **Web / PWA** | ✅ builds | CanvasKit; installable PWA. |
| **Chrome extension** | ⬜ | Popup chrome of the same IA; honest "only while Chrome is open." |
| **Download website** | ⬜ | Marketing + APK download + store badges + **donations**. (Stack: a static/Next.js site; deploy via Vercel.) |

**Per‑platform honesty [owner principle]:** background delivery limits are surfaced in onboarding
and a degraded banner — never hidden behind animation.

---

## 10. Monetization — donations only **[owner]**

- **No ads, no paid tiers, no commercial content.** Funding is **voluntary donations**.
- **Payments:** **Mada**, Visa, Mastercard for a **Saudi individual** publisher. Candidate
  gateways that support Mada: **Moyasar / Tap / PayTabs / HyperPay** **[added: options to evaluate]**.
- Donation UI lives on the **website** (and optionally a calm in‑app "support" link) — **never on or
  beside the dhikr/sacred screens.** ⬜ keys/merchant account are owner tasks.
- Framing should respect ṣadaqah/khayr sensibilities; no guilt, no nags. **[added]**

---

## 11. Privacy & data **[added: formalized policy]**

- **Local‑first:** all features work offline as a guest; data stored on‑device
  (`shared_preferences` JSON today; a sync layer mirrors the same writes later).
- **Export & delete:** CSV/JSON export and full **delete‑all** are always available.
- **Optional sync:** Firebase/Firestore designed but not wired; sign‑in (Google/Apple/Email) is
  opt‑in and only unlocks sync/back‑up. ⬜
- **No third‑party ad/tracking SDKs.** Any analytics must be privacy‑respecting and opt‑in (or omitted).
- Store/legal: a **Privacy Policy** and **Terms** are required for the stores and the donation flow. ⬜

---

## 12. Technical architecture

- **Framework:** Flutter 3.44 / Dart 3.12, **Material 3** + a `TarfColors` `ThemeExtension` for
  custom tokens; light + dark themes switchable via Settings (`themeMode`).
- **State:** **Riverpod 3** (`Notifier`/`NotifierProvider`, hand‑written to avoid codegen drift).
- **Routing:** **go_router 17** — `StatefulShellRoute` for the tabs + pushed routes for
  Insights/Settings/Account/To‑dos/eye‑care detail/focus session/alarm‑ringing; redirect gates
  onboarding.
- **Persistence:** local‑first via `shared_preferences` (JSON). Firebase/Firestore designed, not wired.
- **Audio:** `just_audio` path (synthesized/bundled today); recitation + media controls = owner task.
- **Prayer times:** `adhan` for the prayer‑pause window.
- **Eye‑care engine:** a pure precedence state machine + `ActiveTimeTracker`, driven by a foreground
  host (`EyeCareHost`) that presents the break overlay imperatively. A parallel `AlarmHost` watches
  and rings alarms while the app is open.
- **Shared UI kit:** `core/widgets/tarf_widgets.dart` —
  `TarfSectionHeader / TarfGroup / TarfListRow / TarfMetricCard / TarfSliderTile / TarfEmptyState /
  TarfPresetChip / TarfTimeText` + `ProgressRing` + the responsive `AppScaffold` (capsule bar / rail).
- **Debug affordances:** `--dart-define=SKIP_ONBOARDING=true` and `--dart-define=FORCE_THEME=light|dark`
  for testing/screenshots (no effect on normal builds).
- **Fonts:** bundled **Amiri** (OFL) for Arabic + **Inter** for UI.

### Repository layout (high level)
```
app/                      Flutter application
  lib/
    core/                 routing, settings, format (numerals), time, widgets, theme tokens
    features/
      eyecare/            engine, config, dhikr, break overlay, hosts
      focus/              Pomodoro controller + screens + active-session shelf
      timer/  alarm/  stopwatch/  todos/  insights/  settings/  account/  home/  onboarding/
    l10n/                 app_ar.arb (primary), app_en.arb, generated localizations
  test/                   widget + unit tests
website/                  download + donations site (planned)
extension/                Chrome extension (planned)
docs/                     firebase-setup.md, accounts.md
design.md  README.md  User_Actions.md  PROJECT.md (this file)
```

---

## 13. Quality & testing

- **Tests:** widget + unit tests (engine state machine, navigation, onboarding, focus, break overlay,
  alarm‑ringing, active‑session shelf). Currently **53 passing**. ✅
- **Static analysis:** `flutter analyze` clean. ✅
- **Builds:** web (dark + light) verified; Android/Windows build. ✅
- **CI/CD:** ⬜ recommended — analyze + test on PR, build artifacts, and website deploy (e.g. GitHub
  Actions + Vercel). **[added]**
- **Design QA:** real Arabic copy (not lorem), RTL on every screen, tabular‑column stability, dhikr
  legibility on CanvasKit/narrow screens.

---

## 14. Status & roadmap

**Built & verified (✅):** the eye‑care engine + dhikr break; the "Calm Sanctuary" design system
(light + dark); Home, Focus, Timer, Alarm, Stopwatch, Insights, To‑dos, Settings, Eye‑care settings,
Account, Onboarding; the active‑session shelf, alarm‑ringing modal + foreground watcher, and
focus‑complete bloom; numerals toggle; persistent transliteration toggle; bilingual l10n.

**Owner / integration tasks (⬜, tracked in [`User_Actions.md`](User_Actions.md)):**
1. **Native notifications & background scheduling** (Android/iOS/desktop) for eye‑breaks + alarms.
2. **Firebase project + sign‑in (Google/Apple/Email) + Firestore sync** (see `docs/firebase-setup.md`).
3. **Real break audio** (recitation clips/TTS + media controls + ducking).
4. **Donation gateway** (Mada via Moyasar/Tap/PayTabs/HyperPay) + merchant account + keys.
5. **Download website** (marketing, APK, store badges, donations) and **Chrome extension**.
6. **Store accounts & assets** (Apple Developer, Google Play, MS Store; icons, screenshots, AR+EN
   listings) — see `docs/accounts.md`.
7. **Scholarly sign‑off** on the dhikr set and translations.
8. **Privacy Policy + Terms** for stores and donations.
9. Desktop tray + always‑on‑top mini‑window; PWA polish.

**Future ideas [added]:** home‑screen widgets, a watch companion, multi‑timer list, richer Insights
(positive, non‑punitive), import/restore, and localized soundscapes.

---

## 15. Open decisions for the owner

- **Background eye‑breaks on iOS < 26 / web:** currently delivered only while the app/Chrome is open
  (surfaced honestly). Pursuing iOS Critical Alerts / AlarmKit is a separate decision.
- **Eastern Arabic‑Indic numerals:** default is Western 1234; enabling the Eastern toggle needs a
  verified tabular Arabic numeral font.
- **Donation gateway** choice (Moyasar vs Tap vs PayTabs vs HyperPay) and whether any in‑app support
  link appears (kept far from sacred screens).
- **Analytics:** none vs privacy‑respecting opt‑in.

---

## 16. Glossary

- **Dhikr (ذِكر):** remembrance of God; short, memorized phrases (e.g. *SubḥānAllāh*) recited during
  the break.
- **Tashkīl:** Arabic vocalization marks; shown in full on the sacred line for correct recitation.
- **20‑20‑20:** every 20 min, look 20 ft (~6 m) away for 20 s — the clinical eye‑rest guideline.
- **Mada:** the Saudi national debit/payment network.
- **Ambient Ring:** Tarf's signature persistent eye‑care countdown ring.
- **Calm Sanctuary:** the project's design direction (see `design.md`).
</content>

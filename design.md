# Tarf (طَرْف) — Design Specification for Google Stitch

> **Purpose of this file.** This is the single source of truth for Tarf's UI/UX, written to be
> (1) pasted into **Google Stitch** as the workspace design brief, and (2) used by the Flutter
> developer for the post‑export polish Stitch can't do (motion, RTL correctness, tabular digits,
> sacred‑text legibility). It is the *corrected* spec: every contrast value, RTL rule, and
> contradiction surfaced in design review has been resolved here.
>
> **How to use with Stitch:** read **§11 (Stitch authoring guide)** first — paste the **Global
> Theme Block** before generating, set the palette/fonts panel, then generate the screens in the
> 3 batches using the per‑screen prompts in **§8**.

---

## 1. Design direction — "Calm Sanctuary"

Dark‑first, Arabic‑first wellness. Apple iOS‑26 content‑first restraint meets Material‑3‑Expressive
physics, tuned all the way down to **reverent**. **One hero per screen** — a numeral block, a
progress ring, or a single line of sacred Arabic — floats in deep negative space while all chrome
recedes into a quiet floating glass layer. Depth comes from **tonal surface elevation + near‑
imperceptible gradients + selective translucency on transient layers only** (break overlay, sheets,
the active‑session shelf) — never behind sacred text or dense data, never as decoration. **Exactly
one accent** (teal‑green) carries every primary action, active state, and running ring; everything
else is low‑chroma neutral, so the accent always means *"this is alive / this is the action."*

**Explicitly anti‑dated:** no neumorphism, no skeuomorphic LED/glow clock fonts, no pure‑black
backgrounds, no multi‑accent rainbow, no full‑bleed glass that harms legibility, no streak‑shaming,
no spinning loaders, no jittering non‑tabular digits.

**Honest differentiation (read this).** A bento grid + progress ring + capsule tab bar is, by itself,
the most‑generated AI wellness layout of 2023‑24. Tarf's distinctiveness is therefore **authored on
purpose**, not assumed:
- **The Ambient Ring** — the eye‑care countdown is a *persistent, ambient* thin ring that lives at
  the screen's edge/halo across the app (not just on one screen); on the break it becomes the frame
  the dhikr is set *within*. This is Tarf's signature, not a per‑screen widget.
- **Reverence margins** — asymmetric, RTL‑keyed generous margins around sacred content; emptiness is
  the ornament.
- **Typographic care** — fully‑vocalized Amiri Arabic, sized larger than Latin, is the real luxury.
If a screen can't carry one of these, it stays conventional — and we say so honestly rather than
faking "premium."

---

## 2. Principles

1. **One hero per screen.** The ring, the oversized numerals, or the single dhikr line is the sole
   focal object in deep negative space. Never let two elements compete.
2. **Calm opaque content, floating glass chrome.** Blur lives only in chrome (tab bar, sheets, break
   veil, active‑session shelf) and always signals a temporary lifted layer — never behind text/data.
3. **Single‑accent discipline.** One teal‑green family carries primary actions, active/running
   states, the ring, and the single Insights data color. Success/warning/destructive are muted and
   functional only — never a second brand color.
4. **Depth via tonal layering,** four explicit surface levels, near‑imperceptible gradients — not
   heavy shadows. Background saturation < ~15%.
5. **Reverence through restraint.** Sacred Arabic is fully vocalized, larger than Latin, generously
   leaded, high‑contrast, and **never** decorated, blurred, gradient‑backed, letter‑spaced,
   truncated, or near any ad/upsell.
6. **Eye‑care is the SPINE, not a tab.** The 20‑20‑20 engine is configured in Settings and surfaced
   everywhere by the Ambient Ring + status chip + break overlay. **Home leads with the next eye
   break and today's eye‑rest progress**, matching onboarding exactly. **Defaults: interval = 20
   minutes, break = 20 SECONDS.**
7. **Calm motion by default, delight by exception.** Near‑critically‑damped springs for the utility
   surface; two gentle Expressive springs only for the dhikr reveal and break‑complete bloom;
   dhikr/break screens use only slow 3–6 s breathing. See the **Reduce‑Motion table (§4.4)**.
8. **Arabic‑first, truly RTL.** Canonical layout is right‑to‑left. Mirror nav, back arrows, list
   leading/trailing controls, **linear/bar** progress, carousels, swipe. **Do NOT mirror**: the
   logo, media transport controls, **clock/timer faces (incl. the countdown ring — it depletes
   clockwise in both directions)**, and **numerals**.
9. **Accessibility is the baseline.** WCAG 2.1 **AA** everywhere (AAA for the dhikr line). ≥44pt hit
   rects, Dynamic Type to AX5 with defined reflow, never color‑alone, every audio cue paired with an
   *equal* visual cue, `prefers-reduced-motion` honored on every animation.
10. **Honesty over polish.** The UI never promises capability the platform can't deliver. Degraded
    states (iOS < 26 background limits, extension only while Chrome is open) are stated calmly **in
    onboarding and in‑context**, never hidden behind a pretty animation.

---

## 3. The eye‑rest vs. dhikr resolution (important — was contradictory)

The 20‑second eye break and the dhikr are **one screen**, and the tasks are reconciled like this:

- **The physiological task is to look ~6 m / 20 ft away (defocus).** That is the point of the break.
- **The dhikr is recited from memory, not read.** The set is short, familiar adhkar (SubḥānAllāh …).
  The Arabic line is shown **large, static, centered, high‑contrast** as a gentle prompt — it does
  **not** invite close reading or scrolling. The user can glance once, then look into the distance
  and recite.
- A **calm soft focal dot** sits at the ring's center and **gently recedes** (a distance cue), giving
  the eye somewhere to relax toward without demanding reading.
- **The end cue is visual‑first:** the ring reaching zero **+** a gentle bloom is the authoritative
  signal; the chime and a brief haptic fire **simultaneously as equal cues**. On silenced/Deaf‑HoH
  devices the bloom + haptic is primary (haptic on this screen is **opt‑out**, not opt‑in).

---

## 4. Design system

### 4.1 Color tokens (dark is canonical; both themes ship)
All values verified for WCAG AA on their stated surfaces.

| Role | Light | Dark |
|---|---|---|
| accent / primary | `#0B6A57` | `#2FB89B` |
| accent‑anchor (seed, logo, charts) | `#0E7C66` | `#0E7C66` |
| on‑accent | `#FFFFFF` | `#04201A` |
| accent‑container (active chips, ring track tint) | `#C5EFE5` | `#0E3C32` |
| background (app base) | `#F7F5F0` | `#0B0F0E` |
| surface / card (L1) | `#FFFFFF` | `#14191A` |
| surface‑elevated (L2: raised cards, sheet body) | `#F1EEE7` | `#1C2322` |
| surface‑overlay (L3: glass tint, menus) | `#FBFAF6` | `#232B2A` |
| text‑primary | `#15201D` | `#F4F6F5` |
| text‑secondary | `#5A6562` | `#A7B2AF` |
| **text‑tertiary** (captions/disabled) **[corrected for AA]** | `#6E7672` | `#9AA4A1` |
| hairline / outline | `#E2DFD7` | `#323B39` |
| **dhikr ground** (most reverent surface) **[lifted off pure black]** | `#F7F5F0` | `#0E1A16` |
| ring‑track | `#E6E2D9` | `#23302C` |
| success | `#2E7D55` | `#5FCB94` |
| warning — **fills/icons only** | `#B5752A` | `#E0A65A` |
| **warning — text/copy** **[corrected]** | `#8A5410` | `#E0A65A` |
| destructive | `#C0473B` | `#F08379` |
| glass‑tint (before blur, ~80% opacity over content) | `#FFFFFFCC` | `#161D1CCC` |

**Dhikr‑screen text (no opacity tricks — composited solids, verifiable):** on the dark dhikr ground
`#0E1A16`: Arabic hero `#F4F6F5` (AAA), transliteration **solid `#C8CFCD`**, English **solid
`#A7B2AF`**, source tag **`#8B9491`** (AA). **Forbid opacity‑driven text on this screen.**

### 4.2 Typography
- **Arabic (sacred + Arabic UI): Amiri** (fully vocalized). **Latin UI: Inter** (tabular figures on).
- Arabic strings get **+25–40% horizontal budget**; line‑height **1.8** body / **2.0** for the dhikr.
- Mixed strings (e.g. `بومودورو 20:00`): apply a **per‑font baseline shift** so Amiri (sits lower)
  aligns with Inter; verify on `بومودورو 20:00` and the active‑session shelf.

| Role | Size | Weight |
|---|---|---|
| Dhikr Display (Amiri, auto‑fit, never truncate) | 40–64 sp auto‑fit | 400 (700 for a single beloved word) |
| Display L (huge timer/clock numerals, tabular) | 72–112 sp | 500 |
| Display M (break countdown center) | 56 sp | 500 |
| Headline / H1 (screen title, collapses on scroll) | 28 sp (AR 30–32) | 600 |
| Title / H2 | 20 sp (AR 22) | 600 |
| Body L | 16 sp (AR 18, lh 1.8) | 400/500 |
| Body M / Transliteration | 14 sp (AR 16) | 400 |
| Label / Button (tab labels 11 sp) | 13–15 sp | 600 |
| Caption / Source citation | 12–13 sp (floor 11) | 400/500 |

### 4.3 Numerals (per owner decision)
- **Western digits (1234) are the DEFAULT in every locale, including Arabic** — these are the digits
  used across the Arab world. Eastern Arabic‑Indic (٠١٢٣ "Hindi") digits are an **optional Settings
  toggle only**.
- Always apply OpenType `tnum`+`lnum` to timer/stopwatch numerals. **If the Eastern toggle is used**,
  Inter lacks tabular ٠–٩, so render digits with a numeral‑capable Arabic font that has equal advance
  widths (e.g. **IBM Plex Sans Arabic** or **Readex Pro** with `tnum`); QA must verify column
  stability at stopwatch hundredths speed for *both* systems.

### 4.4 Spacing, radii, motion

> **The full motion system** — duration/curve/spring tokens and the per-component Reduce-Motion table —
> is consolidated in the **Motion & interaction appendix (§13)**. The notes below are a quick reference.
- **Spacing (4pt grid):** 4 / 8 / 16 / 24 / 40 / 64. Edge gutter 20–24; card padding 16–20; section
  gaps 24–40. Dark mode uses ~20–30% more padding (calm signal).
- **Radii:** S 8 (chips) / M 16 (cards) / L 28 (sheets) / XL 40 (hero break/dhikr); buttons & tab bar
  full‑pill (capsule); continuous/squircle curvature where supported.
- **Ring:** stroke 10 (14 hero); diameter 260–320; rounded caps; track = ring‑track; arc = accent;
  **sweep starts 12 o'clock and depletes CLOCKWISE in BOTH LTR and RTL** (a timer face does not
  mirror). Only **linear/bar** fills mirror (grow from the right in RTL).
- **Timings:** fast 150 ms (taps) / normal 280 ms / slow 480 ms (screen change) / overlayFade 420 ms.
  Curves: standard `easeOutCubic`, emphasized `easeOutQuint`. Springs: utility near‑critically‑damped
  (damping ~0.9); two Expressive springs (damping ~0.8) **only** for dhikr reveal + break bloom.
- **Breathing loops:** active ring scale 1.0→1.02 over 3–4 s; dhikr focal dot opacity+scale 3–6 s.
  No bounce, no parallax on sacred/rest content.

**Reduce‑Motion table (true `prefers-reduced-motion` → ZERO motion where possible):**

| Element | Normal | Reduced |
|---|---|---|
| Breathing ring | scale 1.0→1.02 loop | **hold static 1.0, no loop** |
| Break‑complete bloom | spring scale+fade | **instant state change** |
| Dhikr reveal | gentle Expressive spring | **instant, or single ≤120 ms opacity fade** |
| Screen transitions | slide/spring 280–480 ms | **0 ms, or ≤100 ms crossfade only to avoid a flash** |
| Focal dot recede | slow scale | **static dot** |

### 4.5 Haptics & audio (paired, accessible)
Light tick on selection/step; medium on confirm/break‑start; heavy on completion. Soft chime at break
second 0 and second 20. **The authoritative end cue is the visual ring‑zero + bloom; chime + haptic
are equal simultaneous cues.** Haptic on the dhikr screen is **opt‑out**.

### 4.6 Touch targets (hit rect is a token, not prose)
Visual button heights XS 32 / S 40 / M 56 / L 96 / XL 136 are **padded to a ≥44×44 hit rect**. The
active‑session shelf is visually thin (≥40 tall) but its pause/stop controls carry **≥44×44** hit
areas. Tab items, the eye‑care chip pause, alarm toggles, and the transliteration toggle all
guarantee ≥44×44.

### 4.7 Dynamic Type / overflow (to AX5, no clipping)
Hero numerals **auto‑fit shrink‑to‑fit down**; at AX sizes the ring numerals may **break out into a
stacked `mm` over `ss` layout** with the ring becoming a thin perimeter, or cap growth and reflow the
surrounding layout. Tab labels at large sizes go **icon‑only with an accessible label**. **393 px is a
design reference, not a layout constraint** — every screen must reflow on narrower/wider/landscape.

---

## 5. Component library

- **Ambient / Countdown Ring (hero & signature):** circular, 260–320 (stroke 10; 14 full‑screen),
  rounded caps, track tonal, arc accent, centered **tabular** numerals (Display L for focus/timer,
  Display M for the 20 s break). Breathing pulse while running. **Does not mirror in RTL.**
- **Oversized numeral block (stopwatch/alarm):** Inter Display L, **always `tnum`** so digits never
  jitter. No LED/glow fonts.
- **Floating glass capsule tab bar:** translucent surface‑overlay + blur, floats, minimizes on
  scroll‑down. Order: **Focus(home) · Timer · Alarm · Stopwatch**; Insights & Settings live behind a
  top‑corner profile/gear. Active tab = accent pill behind icon + 11 sp label. **RTL: Focus is the
  right‑most tab.** Never two bottom bars.
- **Active‑session accessory shelf:** persistent thin strip docked **above** the tab bar (now‑playing
  style) with remaining time + pause/stop (≥44 hit). On running screens it **replaces** the Home hero
  CTA (single control stratum). Hidden inside true modals. Desktop → always‑on‑top mini‑window + tray.
- **Eye‑care status chip:** quiet pill on Home — "Next eye break in 14:32" + tiny progress sliver +
  pause. Lives **inside the Home hero card** (not a separate floating layer). Tapping → eye‑care
  settings.
- **Buttons (pill, 5 sizes):** filled (one hero CTA/screen, accent), filled‑tonal, outlined, text.
  Corner squishes on press via spring, restores on release.
- **Segmented control:** Focus/Timer/Alarm/Stopwatch peers & presets; selected segment morphs +
  squeezes neighbors; accent fill **and** bold label (never color‑alone).
- **Tactile sliders/steppers:** rounded track, value‑stop dots, detents + tiered haptics; large
  bottom thumb‑zone hit areas; always a typed/tap fallback. RTL: fill grows from the right.
- **Bento cards:** mixed‑size, radiusM 16, tonal fills (not borders), 12–16 gaps; bigger = higher
  priority; big number / small label.
- **List rows:** grouped inset rounded sections, hairline dividers, leading control on START,
  trailing chevron/toggle on END (mirrored RTL), min height 56, swipe + tap fallback.
- **Bottom sheet:** radiusL 28 top, surface‑elevated body, drag handle, spring, safe‑area padding;
  translucent only as a transient layer, content opaque.
- **Dhikr break overlay:** see §3 + the screen spec in §8.
- **Insights charts:** single accent data color, accent‑at‑10–15% gradient fill, muted grid,
  supportive copy. Pattern/shape + label, never color‑alone.
- **Empty states:** calm mark + one warm sentence + one primary action.
- **Permission / degraded banner:** calm inset card, honest copy (AR+EN), JIT rationale, Settings
  deep‑link; **warning‑text color** (`#8A5410` light / `#E0A65A` dark), never alarming.

---

## 6. Information architecture

- **One IA, three chromes** (mobile bottom‑bar / desktop+web left rail / extension popup), identical
  order, icons, labels.
- **Top‑level peers:** Focus (home) · Timer · Alarm · Stopwatch. **Insights & Settings** via top‑corner
  profile/gear, not tabs.
- **Eye‑care 20‑20‑20 = background engine**, surfaced by the Ambient Ring + status chip + overlay.
  Home's largest element is the eye‑care hero (next break + today's rests), so onboarding ↔ home match.
- **Defaults consistent (the two anchors):** interval **20 min**, duration **20 s**. The longer
  stand/stretch break is a **Settings‑only advanced** default (not introduced in onboarding).
- **Control‑stack rule (single stratum):** while a session runs, the active‑session shelf **replaces**
  the Home hero CTA; the eye‑care chip lives inside the hero card; true modals hide shelf + tab bar.
- **Three true modals only:** running focus full‑screen, alarm‑ringing, dhikr break overlay.
- **Auth gating:** guest runs eye‑care + dhikr fully offline; sign‑in (Google / Apple peer / Email)
  unlocks Focus/Timer/Alarm/Stopwatch/Insights/To‑dos/sync; Account carries data‑export + delete‑all.

---

## 7. Screen inventory & build order (3 Stitch batches)

- **Batch A** — Onboarding · Home/Eye‑care · Dhikr break overlay
- **Batch B** — Focus · Timer · Alarm · Stopwatch (shared ring/numeral language)
- **Batch C** — Insights · To‑dos · Settings · Account
- **Extra states** (mostly code‑only): alarm‑ringing modal, focus‑complete bloom, permission/degraded
  banner, empty states, account error/offline (prompts in §8.12).

> **Implementation status (synced with the shipped app).** Batches A–C plus the **active-session
> shelf**, the **alarm-ringing modal**, and the **focus-complete bloom** are **built**; their final
> as-shipped specs are in **§8.13** (they graduated from the §8.12 prompts). The **empty-state**
> pattern is built (`TarfEmptyState`). Still prompts only: the permission/degraded banner and the
> account error/offline variants. Motion for everything is consolidated in **§13**.

---

## 8. Screen specs & Stitch prompts

> Each Stitch prompt uses the four‑layer order: **CONTEXT → COMPONENTS → STYLE (exact hex) →
> PLATFORM (iOS, 393px, RTL with mirror rules).** Pass exact hex, never color names.

### 8.1 Onboarding (5 calm steps)
Steps: (1) language (Arabic primary / English) + theme (dark default); (2) value framing "rest your
eyes every 20 minutes" **+ an honest one‑liner on affected platforms**: *"On this device we remind
you while the app is open; full background reminders need iOS 26+."*; (3) **interval** dial (default
**20 min**, ticks 15/20/25/30); (4) **break duration** dial (default **20 sec**, ticks 10/15/20/30) +
a "Preview a dhikr break" link; (5) reminders/working‑hours + "Begin as guest" vs "Sign in".
**Stitch (step 4):** *Design a mobile onboarding screen for Tarf, a calm reverent Arabic‑first
eye‑care + dhikr app — step 4 of 5: the eye‑break duration. Top: a thin 5‑dot progress indicator (4th
filled) and a small Skip text button in the top‑start corner. Center: a large calm headline "How long
is each rest?" and a one‑line subline "We recommend 20 seconds, long enough to relax your eyes." Below:
a horizontal value dial showing 20 sec selected and centered with 10/15/20/30 ticks and a small teal
dot on the selected value. Below: a quiet "Preview a dhikr break" text link. Bottom: a full‑width pill
button "Continue" and a smaller "Begin as guest" text button. Background #0B0F0E with a faint vertical
gradient to #10211C; primary text #F4F6F5, secondary #A7B2AF; single accent teal‑green #2FB89B only on
the selected value, the dot, and Continue; on‑accent #04201A. Inter, tabular figures on "20". 28px
card radius, full‑pill buttons, generous whitespace. Mood: calm, spacious, premium, reverent. iOS,
393px, right‑to‑left Arabic layout — mirror the dots, Skip, and dial; keep the "20" numeral LTR.*

### 8.2 Home / Eye‑care
**Stitch:** *Design a mobile home screen for Tarf whose core feature is the 20‑20‑20 eye‑rest reminder.
Top: a large collapsing title "Tarf" with a small circular profile/gear button in the top‑end corner.
The HERO is the largest card at the top: an eye‑care status card with a soft circular progress ring on
its start side, a bold "Next eye break in 14:32", a secondary "11 eye rests today", and a small pause
icon button on its end side. Below, a bento grid of three smaller rounded cards: "Focus 1h 20m today",
"Sessions 3", "To‑dos 2 of 5". Below the grid one full‑width pill button "Start focus session". Bottom:
a floating translucent capsule tab bar with four items (Focus selected, Timer, Alarm, Stopwatch), line
icons + 11px labels, selected tab carrying a rounded teal indicator. Background #0B0F0E; cards #14191A
(tonal, no borders); text #F4F6F5 / secondary #A7B2AF / captions #9AA4A1; single accent teal‑green
#2FB89B only on the ring arc, selected tab, and primary button; on‑accent #04201A. Inter, tabular
figures. Card radius 16, full‑pill button/tab bar, 16px gaps. Mood: calm, premium, spacious,
content‑first, single hero. iOS, 393px, right‑to‑left — mirror the title, gear, card internals, and tab
order so Focus is the right‑most tab; keep numerals and the ring face un‑mirrored.*

### 8.3 Dhikr break overlay (the reverent peak — see §3)
**Stitch (use Experimental/Pro model):** *Design a full‑screen mobile rest‑moment overlay for Tarf — a
20‑second eye break with one dhikr. Calm full‑bleed deep‑teal‑near‑black ground #0E1A16. Centered: ONE
large line of fully‑vocalized Arabic (the dhikr "سُبْحَانَ اللّٰهِ" with full tashkīl) as the
unmistakable hero, very large (~56px, auto‑fit), regular weight, generous line‑height ~2.0, perfectly
centered, with NO decoration, no glow, no gradient behind it, no letter‑spacing. Beneath it, smaller
and calmer: a Latin transliteration "Subhan‑Allah" in solid #C8CFCD, then a concise English "Glory be
to Allah" in solid #A7B2AF, then a tiny source tag "Hisn al‑Muslim" in #8B9491. Above the Arabic, a
thin quiet circular countdown ring reading 0:18 in tabular figures, arc teal‑green slowly depleting,
with a soft small focal dot at its center. A low‑contrast guidance line "Look ~6 m away and recite".
Top‑end corner: a small frosted Skip text button. Arabic at AAA contrast on the dark ground. Use Amiri
for the Arabic and Inter for Latin + numerals. FORBID any image/gradient/overlay behind the Arabic, any
letter‑spacing on Arabic, any ad/banner/upsell, and any shrinking of the Arabic. Mood: reverent,
serene, spacious, hushed, almost still. iOS, 393px, right‑to‑left — Arabic centered; mirror the Skip to
the end corner; keep the ring face and numerals un‑mirrored.*

### 8.4 Focus (Pomodoro)
**Stitch:** *Design a mobile focus‑timer screen for Tarf. The single hero is a large circular progress
ring centered, ~300px, rounded caps, track #23302C, arc teal‑green #2FB89B. Inside the ring the
remaining time "24:30" in very large tabular figures (~88px, medium). Above the ring a small label
"Focus 1 of 4". Below, a quiet pill chip with the bound task "Write the report" and four small session
dots (one filled). Bottom: one full‑width pill button "Pause" in teal‑green with a smaller text "Reset"
beside it. No bottom tab bar (full‑screen running session). Background #0B0F0E with a faint radial
wash; time #F4F6F5; label/chip #A7B2AF; on‑accent #04201A. Inter, tabular figures. Full‑pill buttons,
generous negative space, single hero. Mood: calm, focused, premium. iOS, 393px, RTL — mirror label,
chip, button row; keep the ring sweep clockwise and the numerals LTR.*

### 8.5 Timer
**Stitch:** *Design a mobile multi‑timer screen for Tarf. Top: large title "Timers" + a circular "+"
in the top‑end corner. Setup state: a tactile time picker showing hours/minutes/seconds as three large
tabular‑figure steppers reading "00 : 05 : 00", with quick‑preset pill chips below (1, 5, 10, 20 min).
Below, a list of saved timers as rounded rows (name on start, remaining time tabular, play/pause on
end). Bottom: one full‑width pill "Start" + the floating capsule tab bar (Timer selected). Background
#0B0F0E; rows/picker #14191A; text #F4F6F5 / secondary #A7B2AF; accent teal #2FB89B on selected preset,
play icons, Start; on‑accent #04201A. Inter, tabular figures. Radius 16, full‑pill chips/button. Mood:
calm, precise, uncluttered. iOS, 393px, RTL — mirror title, add, rows, tab order; numerals LTR.*

### 8.6 Alarm
**Stitch:** *Design a mobile alarms screen for Tarf. Top: large title "Alarms" + circular "+". Body: a
grouped list of rounded rows; each shows a large tabular time "06:30" on the start side, a small label
+ repeat summary beneath ("Fajr, Daily"), and a pill toggle on the end side (some on, some off);
disabled alarms render dimmer. Bottom: floating capsule tab bar (Alarm selected). Background #0B0F0E;
rows #14191A; enabled time #F4F6F5, disabled #9AA4A1, labels #A7B2AF; toggle on‑state teal #2FB89B.
Inter, tabular times. Radius 16, ≥44px row targets. Mood: calm, legible, uncluttered. iOS, 393px, RTL —
mirror title, add, row internals so time is on the right and toggle on the left; numerals LTR; do not
mirror toggle on/off semantics.*

### 8.7 Stopwatch
**Stitch:** *Design a mobile stopwatch screen for Tarf. The single hero is an oversized running time
"01:24.36" centered in the upper area in very large tabular monospaced figures (~96px, medium) so
digits never shift. Below, two large pill buttons side by side: "Lap" (filled‑tonal) and "Stop" (filled
teal #2FB89B). Below, a scrollable list of lap rows (rounded): "Lap 3" on start, split "00:27.11"
tabular in the middle, cumulative total on end; mark fastest with a small up‑tick, slowest with a
down‑tick (not color‑alone). Bottom: floating capsule tab bar (Stopwatch selected). Background #0B0F0E;
hero numerals #F4F6F5; rows #14191A; secondary #A7B2AF; teal #2FB89B only on Stop; on‑accent #04201A.
Inter, strictly tabular. Radius 16, full‑pill. Mood: calm, precise, single hero. iOS, 393px, RTL —
mirror button order, row internals, tab order; numerals LTR.*

### 8.8 Insights
**Stitch:** *Design a mobile insights screen for Tarf. Top: large title "Insights" + a small
Gregorian/Hijri date toggle in the top‑end corner. Body: a hero bento card with a big "11" and caption
"eye rests today" plus a supportive subline "Nicely done — your eyes thank you." Below, a calm 7‑day
bar chart with seven rounded teal‑green bars of varying heights, a soft neutral gridline, day labels
beneath. Below, two smaller cards: "Focus 1h 20m" and "Longest session 25m" (big number + caption). No
punitive streak language. At the very bottom a quiet "Export CSV" text button. Background #0B0F0E;
cards #14191A; text #F4F6F5 / secondary #A7B2AF / captions #9AA4A1; teal #2FB89B as the SINGLE data
color. Inter, tabular metrics. Radius 16, 16px gaps, airy. Mood: calm, supportive, premium. iOS, 393px,
RTL — mirror title/toggle/card order and read the bars right‑to‑left; numerals LTR.*

### 8.9 To‑dos
**Stitch:** *Design a mobile to‑do list screen for Tarf. Top: large title "To‑dos" + circular "+".
Body: a clean list of rows separated by faint hairline dividers #323B39; each row has a circular
checkbox on the start side, the task title in the middle ("Write the report"), a small caption "2 of 4
sessions" beneath, and a small teal play (start focus) icon on the end side. One completed row shows a
filled checkbox with dimmed strikethrough title. Bottom: floating capsule tab bar. Background #0B0F0E;
titles #F4F6F5, captions #9AA4A1; teal #2FB89B only on the checked box and play icons; on‑accent
#04201A. Inter. ≥44px rows, airy. Mood: minimal, calm, airy. iOS, 393px, RTL — mirror checkbox to
start/right, play to end/left, right‑align titles; numerals LTR.*

### 8.10 Settings
**Stitch:** *Design a mobile settings screen for Tarf. Grouped inset rounded sections on tonal cards
with section headers and faint hairline dividers. Eye‑care group at top: "Break interval → 20 min",
"Break duration → 20 sec", "Longer stand break → Every 2h", "Working hours → ›", "Strict mode →
[toggle off]". Then a "Dhikr & audio" group start: "Show transliteration → [toggle on]", "Break sound →
›". Each row: small line icon on start, label, value/toggle/chevron on end. Background #0B0F0E; cards
#14191A; headers #A7B2AF, labels #F4F6F5, values #A7B2AF, dividers #323B39; toggle on‑state teal
#2FB89B. Inter, tabular on "20 min"/"20 sec". Radius 16, ≥44px rows. Mood: calm, organized,
progressively disclosed. iOS, 393px, RTL — mirror icons to start/right, values/chevrons to end/left,
right‑align labels; numerals LTR; do not mirror toggle semantics.*

### 8.11 Account & Sync
**Stitch (signed‑in):** *Design a mobile account & sync screen for Tarf, signed‑in state. Top: large
title "Account". A profile card with a circular avatar on the start side, name "Sara A." + email
beneath, and a small sync‑status pill on the end side reading "Synced just now" in teal. Below, a
grouped rounded section: "Export my data" (download icon + chevron) and "Delete account and all data"
in destructive red. Beneath, a quiet caption that deletion permanently removes all cloud data.
Background #0B0F0E; cards #14191A; text #F4F6F5 / secondary #A7B2AF / caption #9AA4A1; sync pill teal
#2FB89B; delete row red #F08379 (never teal). Inter. Radius 16, ≥44px rows. Mood: calm, trustworthy,
clear. iOS, 393px, RTL — mirror avatar to start/right, pill/chevrons to end/left; keep email/timestamp
LTR.*

### 8.12 Extra‑state prompts (not yet built)
> The **alarm-ringing modal** and **focus-complete bloom** graduated from these prompts to **shipped**
> features — see their final as-built specs in **§8.13** (alongside the active-session shelf). The
> prompts below remain for states not yet implemented.
- **Permission / degraded banner:** *…a calm inset card near the Home hero: warning‑tinted icon
  (#E0A65A on dark), one honest line "On this device, reminders work while Tarf is open. Enable
  notifications for more.", and a "Open Settings" text link. Never alarming.*
- **Empty state (To‑dos/Insights):** *…centered: a small calm brand mark, one warm line "We're here
  whenever you need a moment", and one pill primary action ("Add a task" / "Start your first session").*
- **Account error / offline:** *…signed‑out with an error toast "Sign‑in cancelled — try again", three
  equal sign‑in buttons (Google, Apple, Email — Apple NOT pre‑selected), and a "Continue as guest" text
  button; plus an offline variant with a sync pill "Offline — will sync".*

### 8.13 Implemented system states (as-shipped, built in Flutter — not Stitch-generated)

> Documented from the shipped code, not as generation prompts. Tokens reference the live
> `TarfColors`/`ColorScheme`; all motion is consolidated in **§13**.

**A. Active-session shelf (focus).** A persistent "now-playing" strip for a running focus session,
docked **above** the tab bar; absent when idle.
- *Container:* a floating glass capsule — `ClipRRect` radius **L (28)** + `BackdropFilter` blur **18** +
  `surfaceContainerHigh` @ 90% + a 60%-`outline` hairline border — visually matched to the capsule tab
  bar, with a `space2` bottom gap above the bar.
- *Full form (mobile):* a `Row` of → a 34 px depleting **ProgressRing** (stroke 4; accent = `primary`
  for work / `tertiary` for a break) · a 2-line block (phase label in `labelMedium`/`onSurfaceVariant`
  + remaining **mm:ss** in `titleMedium` w600, **tabular, forced LTR**) · a pause/resume `IconButton` ·
  a stop `IconButton`. Tapping the strip pushes the full-screen focus session.
- *Compact form (desktop rail, width < 220):* a `Column` — the ring (tap → open session) over one
  pause/resume button. (Desktop also gets the tray / mini-window per §5.)
- *Control-stack rule (§6):* while a session runs the shelf is the single live control stratum; it is
  hidden inside true modals (it lives in the shell, which modals cover).
- *RTL:* mirrors via `start`/`end`; the ring and numerals do **not** mirror.

**B. Alarm-ringing modal.** Full-screen `fullscreenDialog`, fades in over **280 ms**; no tab bar.
- *Layout (centered column on `surface`):* a 44 px `Icons.alarm` glyph in **accent** · the alarm time
  as an oversized **Display L** tabular numeral (`FittedBox` auto-fit, forced LTR) · the optional label
  in `titleMedium`/`onSurfaceVariant` · then two **stacked full-width pills**: **Snooze** (filled-tonal)
  over **Stop** (filled, accent), each ≥56 tall.
- *Behavior (shipped foreground watcher `AlarmHost`):* while the app is open, a 10 s ticker rings an
  enabled alarm when its `HH:MM` matches now (respecting repeat days) — **Snooze** re-arms it **+5 min**;
  **Stop** dismisses, and a **one-shot** alarm switches itself off so it can't repeat. Background
  ringing remains a native-scheduling owner task and is stated honestly in-app.
- *RTL:* numerals LTR; otherwise centered/mirrored.

**C. Focus-complete bloom.** A celebratory overlay shown when a **work** phase finishes (a `ref.listen`
catches the completion), over the running session.
- *Layout:* a dim **scrim** (`scrim` @ 60%) with a centered group → a 96 px accent-tinted disc holding a
  52 px check, then **"Session complete"** (`headlineSmall` w600), then **"{done} / {goal} sessions
  today"** (`bodyMedium`/`onSurfaceVariant`).
- *Motion:* scale **0.8 → 1.0** + fade over **320 ms** `easeOutBack`; **tap anywhere** dismisses and it
  **auto-dismisses after ~2.8 s**. Reduce-Motion → appears **instantly** (0 ms, no scale). See §13.

---

## 9. RTL & Arabic guide

- Arabic is the **canonical** layout. Author every screen RTL‑first: `start`/`end`,
  `EdgeInsetsDirectional`, `TextAlign.start`, mirrored directional icons.
- **Mirror:** nav order (Focus = right‑most tab), back arrows, **linear/bar** progress (grow from the
  right), carousels/onboarding swipe (right‑to‑left), list leading/trailing controls, sheet handles.
- **Do NOT mirror:** logo/wordmark, media transport, **clock/timer faces incl. the countdown ring
  (depletes clockwise in both directions)**, and **numerals**.
- Sacred Arabic: fully vocalized Amiri, ~25–40% larger than Latin, line‑height ≥1.8 (2.0 for heavy
  diacritics), weight ≥400, **never** letter‑spaced, **never** truncated (auto‑fit). Verify diacritics
  on narrow screens and on CanvasKit; never split an Arabic word across text spans.
- Test every screen with **real Arabic copy**, not lorem; budget +25–40% width.
- Mirror motion vectors with layout; honor reduced‑motion identically in both directions.

---

## 10. Accessibility acceptance criteria

- WCAG **2.1 AA** every screen; **AAA** for the dhikr Arabic line. Re‑run the contrast matrix on all
  three dark surfaces (card/elevated/overlay), not just the base.
- Touch ≥44×44 hit rects (see §4.6); Dynamic Type to AX5 with the reflow rules (§4.7).
- Never color‑alone (pair with icon/weight/shape). Every audio cue has an **equal** visual cue.
- `prefers-reduced-motion` per the §4.4 table; Reduce Transparency → frosting toward solid.
- VoiceOver/TalkBack: the ring/countdown announces **once** (not per second); the dhikr line is read in
  Arabic locale; logical RTL reading order.
- Mandatory account‑deletion + data‑export remain reachable and labelled.

---

## 11. Stitch authoring guide

**A. Paste this Global Theme Block first (workspace brief):**
> *Tarf — a calm, reverent, Arabic‑first eye‑care + dhikr wellness app. Tone: calm, reverent,
> spacious, premium, content‑first, single‑hero, distraction‑free. DARK is canonical. Single accent
> teal‑green; primary/seed #0E7C66, dark‑accent #2FB89B, on‑accent #04201A. Dark palette: bg #0B0F0E,
> card #14191A, elevated #1C2322, overlay #232B2A, text #F4F6F5 / #A7B2AF / #9AA4A1, hairline #323B39,
> dhikr ground #0E1A16. Light palette: bg #F7F5F0, card #FFFFFF, text #15201D / #5A6562 / #6E7672,
> accent #0B6A57. Type scale (px): Dhikr 40–64 / Display 72–112 / Display‑M 56 / H1 28 / H2 20 / Body
> 16 / Label 13–15 / Caption 12. Radii 8/16/28/40; buttons & tab bar full‑pill. 4pt spacing. Fonts:
> Inter (Latin, tabular figures) + Amiri (Arabic, fully vocalized, ≥1.8 line‑height, never
> letter‑spaced). RTL is canonical: mirror nav/back/linear‑progress/lists; do NOT mirror logo, media
> controls, clock/timer faces (the countdown ring depletes clockwise both directions), or numerals.
> Components: floating glass capsule tab bar, bento cards (tonal, no borders), pill buttons, segmented
> control, tactile sliders, list rows with hairline dividers, bottom sheets (radius 28). The dhikr
> screen forbids any image/gradient/overlay behind the Arabic, any letter‑spacing, any ad/upsell, and
> any shrinking of the Arabic.*

**B. Palette/fonts panel:** set seed/primary = #0E7C66 (override Stitch's blue), toggle to **Dark**,
fonts Inter + a high‑legibility Naskh (Amiri), corner radius 16.

**C. Always pass exact hex** (#2FB89B), never color names. Use design vocabulary (floating capsule tab
bar, bento card, pill chip, segmented control, tabular figures), never lay terms. **Lead every prompt
with the mood adjectives.**

**D. Generate in the 3 batches (§7), never all 11 at once.** After each batch, multi‑select the screens
and paste one unifying theme prompt. Then iterate **one change per prompt**; screenshot good states.

**E. Arabic mitigation (critical):** Stitch has documented RTL/BiDi bugs and renders Arabic too small.
In **every** prompt demand right‑to‑left layout, mirrored nav, and a large legible Arabic size (dhikr
~56px, line‑height ~2.0, never shrink). Plan to fix RTL correctness + sacred‑text legibility in
Figma/Flutter after export. Do **not** trust Stitch's default Arabic on the dhikr screen.

**F. Model choice:** Standard (Gemini 2.5 Flash) with Figma export for most screens; Experimental
(2.5 Pro) only for the dhikr/break hero. Plan the full screen list first to conserve the generation cap.

**G. Treat Stitch output as ~70% done.** It nails structure/flow; exact spacing, **motion**, RTL
correctness, tabular alignment, and dhikr legibility are post‑export polish in Figma or Flutter. Stitch
produces **static** screens — motion is documented here for the code stage, not for Stitch.

---

## 12. Open decisions for the owner
- **Background eye‑break on iOS < 26 / web:** delivered only while app/Chrome is open — surfaced
  honestly in onboarding + a degraded banner (§8.1, §8.12). Pursuing iOS Critical Alerts / AlarmKit is
  a separate decision.
- **Eastern Arabic‑Indic numerals:** default is **Western 1234**; the Eastern toggle needs a verified
  tabular Arabic numeral font (§4.3).
- **Distinctiveness:** the "Ambient Ring + reverence margins + Amiri typography" signature (§1) is what
  separates Tarf from a generic template — invest the polish budget there.

---

## 13. Motion & interaction appendix

> Consolidates the motion system (previously scattered across §4.4–§4.7 and the screen specs) into one
> reference, and records what is **shipped** vs **spec-only** so design and code stay honest.

### 13.1 Duration tokens
| Token | ms | Use |
|---|---|---|
| `fast` | 150 | taps, toggles, micro state-layer changes |
| `normal` | 280 | most state transitions (expand/collapse, segmented morph) |
| `slow` | 480 | full screen changes |
| `overlayFade` | 420 | dhikr break overlay enter/exit (shipped) |
| `alarmFade` | 280 | alarm-ringing modal enter (shipped) |
| `bloom` | 320 | focus-complete bloom scale+fade (shipped) |
| `breathe` | 3000–6000 | slow breathing loops on rest/sacred content |

Exit animations run at ~60–70% of their enter duration; no single transition exceeds 500 ms.

### 13.2 Curves & springs
- **Standard easing:** `easeOutCubic` (enter) / `easeIn` (exit). **Emphasized:** `easeOutQuint`.
- **Bloom:** `easeOutBack` — the only overshoot in the app (focus-complete only).
- **Springs:** utility surfaces use a near-critically-damped spring (damping ≈ 0.9); two *Expressive*
  springs (damping ≈ 0.8) are reserved for the **dhikr reveal** and the **break-complete bloom**.
- **Linear is banned** for UI transitions — except the steady countdown ring sweep, which is linear by
  nature, and **never mirrors** in RTL (it depletes clockwise in both directions).

### 13.3 Per-component motion  (✅ shipped · ◐ partial · ○ spec-only)
| Element | Motion | Status |
|---|---|---|
| Break countdown ring | linear depletion over the break duration; rounded cap | ✅ |
| Break breathing | whole ring scale 1.0→1.02, ~5 s loop (reverse) | ✅ |
| Break focal dot | opacity ~0.18, scale recede 1.0→0.55 across the break | ✅ |
| Break overlay enter | `overlayFade` 420 ms fade | ✅ |
| Break-complete bloom | Expressive spring scale+fade at zero | ○ (impl shows an instant done-state) |
| Dhikr reveal | gentle Expressive spring | ○ (impl fades in with the overlay) |
| Focus-complete bloom | scale 0.8→1.0 + fade, 320 ms `easeOutBack`, auto-dismiss ~2.8 s | ✅ |
| Alarm-ringing modal | `alarmFade` 280 ms fade, `fullscreenDialog` | ✅ |
| Active-session shelf | reveals/hides with session state; glass blur 18 | ✅ (no entrance spring) |
| Capsule tab bar | floating glass blur 18 | ◐ ("minimize on scroll-down" is spec-only) |
| Active ring (Home/Focus idle) | breathing scale 1.0→1.02 loop | ○ (ring is static today) |
| Button / card press | Material state layer + `InkSparkle` ripple | ◐ (spec's spring "corner squish" not custom) |
| Segmented control | selected segment morph + neighbor squeeze | ◐ (Material `SegmentedButton` default) |
| Sliders / steppers | detents + light haptic per step | ◐ (timer steppers fire haptics; slider detents spec-only) |
| Screen push/pop | directional slide (forward left/up, back right/down) | ◐ (go_router platform default; break/alarm fade) |
| Bottom sheet | spring slide-up, radius 28 | ✅ (Material default) |

### 13.4 Interaction & gesture feedback
- **Tap feedback within 100 ms**; input latency target < 100 ms; never block input during an animation,
  and keep every animation **interruptible** (a tap/gesture cancels it immediately).
- **Press:** a visible state-layer/ripple on every interactive surface; ≥44×44 hit rects (§4.6).
- **Drag/swipe:** real-time tracking with a small start threshold; swipe-to-delete on list rows
  (alarms) uses an `endToStart` affordance with a tap/long-press fallback.
- **Haptics (paired with audio, §4.5):** light tick on selection/step (shipped on timer steppers);
  medium on confirm / break-start; heavy on completion; on the break, a soft chime **and** a brief
  haptic fire as **equal** end cues (haptic there is **opt-out**).

### 13.5 Reduce-Motion  (true `prefers-reduced-motion` → zero motion where possible)
| Element | Normal | Reduced | Status |
|---|---|---|---|
| Break breathing ring | scale 1.0→1.02 loop | hold static 1.0, no loop | ✅ |
| Break focal dot recede | slow scale | static dot | ◐ (loop tied to breathe; recede follows the countdown) |
| Break-complete bloom | spring scale+fade | instant state change | ✅ (instant today) |
| Dhikr reveal | Expressive spring | instant / ≤120 ms opacity | ✅ |
| Focus-complete bloom | 320 ms scale+fade | **instant (0 ms), no scale** | ✅ (honors `reduceMotion`) |
| Screen transitions | slide/spring 280–480 ms | 0 ms or ≤100 ms crossfade | ○ (not yet gated on the flag) |
| Capsule bar minimize | slide | no minimize | ◐ (no minimize implemented) |

- Flag source of truth: `settings.reduceMotion` (Settings → Appearance); also honor the OS
  `MediaQuery.disableAnimations` where Material applies it automatically.
- **Reduce Transparency:** glass/blur layers (tab bar, shelf, sheets, break veil) move toward solid
  `surfaceContainerHigh`/`overlay`.

### 13.6 Motion backlog (to fully realize this spec)
The ○/◐ rows are the open work: the break-complete bloom + dhikr-reveal Expressive springs, the
Home/Focus active-ring breathing, press-scale springs, the scroll-to-minimize tab bar, slider detent
haptics, and gating screen transitions on Reduce-Motion.
</content>

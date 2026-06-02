# Dhikr recitation clips — drop-in contract

This folder holds the **sacred** break-screen recitation audio: one short clip per
dhikr, played during the eye-care break while the remembrance is on screen.

**No clips ship in the repo today** (only `.gitkeep`). The clips, and the scholarly /
editorial sign-off that gates their release, are the owner's to supply. Everything in
the app is already wired so that **dropping a correctly-named file here makes it play**
— no code or JSON changes required.

> Reverence: this is the audio behind the dhikr break. Nothing commercial, nothing
> decorative. One coherent reciter, clean and calm. Treat it like the Amiri line itself.

---

## How playback finds your clip (zero-config)

When the dhikr set loads, `DhikrRepository.load()`
(`app/lib/features/eyecare/data/dhikr_repository.dart`) reads the bundle's
`AssetManifest` and, **for any dhikr whose `audio` is still `null`**, auto-assigns a clip
named `<dhikr-id>.<ext>` from this folder. The break player
(`JustAudioBreakPlayer.start`) then plays that asset on the `breakBed` channel for the
whole break; the visual countdown ring drives the length, so the clip can be short.

Rules the resolver follows:

- **Exact match on the full path** `assets/audio/recitation/<id>.<ext>`. A file named
  `la-hawla-extra.ogg` will **not** match the id `la-hawla`. Name it exactly `<id>.<ext>`.
- **Extension preference order** (first match wins if you drop more than one for an id):
  `ogg` → `oga` → `m4a` → `aac` → `mp3` → `wav`.
- **An explicit `"audio"` in `dhikr.json` always wins** over a dropped file. Leave the
  9 entries' `"audio": null` to use this drop-in path; set a path only to override.
- A missing/unreadable manifest never blocks the break — it falls back to the calm synth
  bed (or whatever `dhikr.json` declared).

So the entire owner workflow is: **encode 9 files, name them `<id>.<ext>`, drop them
here, rebuild.** That's it.

---

## The 9 required filenames

One clip per dhikr id below. Use ONE container extension for all 9 (preferred: `.ogg`
Opus, or `.m4a` AAC). Filenames are case-sensitive and must match the id exactly.

| File (preferred `.ogg`) | Dhikr id | Arabic |
|---|---|---|
| `subhanallah.ogg` | `subhanallah` | سُبْحَانَ اللّٰهِ |
| `alhamdulillah.ogg` | `alhamdulillah` | الْحَمْدُ لِلّٰهِ |
| `la-ilaha-illallah.ogg` | `la-ilaha-illallah` | لَا إِلٰهَ إِلَّا اللّٰهُ |
| `allahu-akbar.ogg` | `allahu-akbar` | اللّٰهُ أَكْبَرُ |
| `subhanallah-wa-bihamdihi.ogg` | `subhanallah-wa-bihamdihi` | سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ |
| `subhanallah-azim.ogg` | `subhanallah-azim` | سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ، سُبْحَانَ اللّٰهِ الْعَظِيمِ |
| `astaghfirullah.ogg` | `astaghfirullah` | أَسْتَغْفِرُ اللّٰهَ |
| `la-hawla.ogg` | `la-hawla` | لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ |
| `salawat.ogg` | `salawat` | اللّٰهُمَّ صَلِّ وَسَلِّمْ عَلَىٰ نَبِيِّنَا مُحَمَّدٍ |

The ids are the source of truth in `app/assets/dhikr/dhikr.json`. If an id ever changes
there, rename the matching clip to match.

---

## Encoding spec

| Property | Value |
|---|---|
| **Channels** | Mono |
| **Loudness** | Normalized to ~ **-16 LUFS** integrated (consistent level across all 9) |
| **True peak** | ≤ -1 dBTP (no clipping) |
| **Container / codec** | **OGG/Opus** (`.ogg`) *or* **M4A/AAC** (`.m4a`) — small, broadly supported. `.mp3`/`.wav` work but are not preferred. |
| **Sample rate** | 48 kHz (Opus) or 44.1 kHz (AAC) is fine |
| **Length** | About the phrase **plus a short tail** (roughly 2–6 s). The break duration and the visual ring drive how long the break lasts, **not** the clip — a short clip is correct; it simply plays once and the ring continues. Do not pad to 20 s. |
| **Onset/offset** | Trim leading silence; apply a tiny fade-out so the tail is click-free. |
| **Reciter** | **ONE** coherent reciter across all 9, calm and clear, fully vocalized, no music/effects. |

Keep the recitation faithful and unembellished — these are remembrances, not a
performance.

---

## LICENSE + sign-off gate (BLOCKING before release)

Per `app/assets/dhikr/dhikr.json` `_meta.note`, the dhikr content **REQUIRES
scholarly/editorial sign-off before any public release**, and the asset-provenance
process must record the source/license of every bundled clip. Two gates apply to the
audio here, both BLOCKING:

1. **License / provenance.** Every clip must be either **commissioned** (a written
   agreement stored at `assets_ledger/audio-agreements/<id>.pdf`) or under a clearly
   compatible license. Record each clip's reciter, source, and license in
   `assets_ledger/ledger.json` (the `recitation` section), replacing the `[[FILL]]`
   fields. Bundling a clip with unverified rights is not permitted.

2. **Scholarly / editorial sign-off.** The recitation must be reviewed alongside the
   dhikr text by a named reviewer; record it in `assets_ledger/dhikr-signoff.md`
   (currently **PENDING**). Confirm pronunciation/tashkil of the recited phrase matches
   the vocalized Arabic in `dhikr.json`. This is the same BLOCKING gate the text is under
   per `docs/store/release-checklist.md §B`.

Do not enable these clips in a public build until **both** are recorded as complete.

---

## Owner steps to add the recitation (summary)

1. Commission ONE reciter for all 9 phrases (see the Sourcing notes below for why
   commissioning is preferred over stitching Commons clips).
2. Encode 9 mono, ~-16 LUFS clips per the spec; name each exactly `<id>.ogg`
   (or one consistent supported extension).
3. Drop the 9 files into this folder (`app/assets/audio/recitation/`). They bundle
   automatically — the folder is already registered in `app/pubspec.yaml`.
4. Leave the 9 `"audio": null` entries in `dhikr.json` as-is (the resolver fills them).
   Only set an explicit `"audio"` path if you want to override the auto-match.
5. Fill the `recitation` section of `assets_ledger/ledger.json` (reciter, source,
   license, sign-off status) and complete `assets_ledger/dhikr-signoff.md`.
6. Rebuild and verify on device: take a break; the dhikr's clip should play on the
   break bed.

---

## Sourcing notes (research outcome — 2026-06-02)

Researched Wikimedia Commons for openly-licensed pronunciations of the 9 phrases:

- **Clean coverage exists for only 3 of 9**, as flat *dictionary-pronunciation* clips
  from **mixed speakers** (not one coherent reciter):
  - `alhamdulillah` — `Ar-الحمد_لله.ogg` (CC BY-SA 3.0, uploader *ArabicAudios*)
  - `astaghfirullah` — `Ar-أستغفر_الله.ogg` (CC BY-SA 3.0, uploader *ArabicAudios*)
  - `allahu-akbar` — `Ar-eg-الله_أكبر.oga` (CC BY-SA, Egyptian-dialect dictionary entry)
- The remaining 6 phrases have **no clean, single-source, reverent** Commons clip.
- Even the 3 available are **different speakers** with a dictionary cadence, not a calm
  recitation, and would clash on the sacred break.

**Decision: COMMISSION one reciter for all 9** rather than bundle mismatched Commons
clips. A single coherent voice is both more reverent and avoids per-clip attribution and
mixed-license bookkeeping. If any Commons clip is ever used as an interim, its CC BY-SA
attribution and license must be recorded in the ledger first, and it still requires the
scholarly sign-off above.

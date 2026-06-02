# Tarf (طَرْف) — Dhikr Scholarly / Editorial Sign-off

> **STATUS: PENDING** — This file must be completed and signed before any public release.
> Shipping dhikr content without a recorded sign-off is a **BLOCKING** gate per
> `docs/store/release-checklist.md §B`.

---

## What needs sign-off

A named reviewer must confirm, for **every entry** in `app/assets/dhikr/dhikr.json`:

1. **Arabic text** — correct, fully vocalized (full tashkil / diacritics), immutable.
2. **Transliteration** — follows the project's ALA-LC-lite scheme consistently, suitable for
   repetition by non-Arabic speakers.
3. **English translation** — accurate, reverent, non-sectarian tone.
4. **Source reference** — correct hadith number and collection (Sahih al-Bukhari / Sahih Muslim /
   Hisn al-Muslim); verifiable via sunnah.com.
5. **Virtue text** — faithful to the hadith / scholarly summary, no exaggeration.
6. **Scope statement** — all 9 entries are universally-agreed, non-sectarian adhkar appropriate
   for a general Muslim audience.

---

## Sign-off record (fill on completion)

| Field | Value |
|---|---|
| **Reviewer name** | [[FILL — full name]] |
| **Reviewer credentials** | [[FILL — e.g. "Islamic studies graduate, Al-Azhar University" or "hafiz, verified by ..."] |
| **Date of review** | [[FILL — e.g. 2026-06-15]] |
| **Scope** | All 9 dhikr entries in `app/assets/dhikr/dhikr.json` version 1 |
| **Outcome** | [[APPROVED / APPROVED WITH CORRECTIONS — list any corrections applied]] |
| **Corrections applied** | [[None / list each correction with the entry id and what changed]] |
| **Contact for follow-up** | [[FILL — email or other contact]] |

---

## Entries reviewed

| Entry id | Arabic | Reference | Approved? |
|---|---|---|---|
| subhanallah | سُبْحَانَ اللّٰهِ | Sahih al-Bukhari 6406; Sahih Muslim 2694 | [[PENDING]] |
| alhamdulillah | الْحَمْدُ لِلّٰهِ | Sahih Muslim 223 | [[PENDING]] |
| la-ilaha-illallah | لَا إِلٰهَ إِلَّا اللّٰهُ | Sahih al-Bukhari; Sahih Muslim | [[PENDING]] |
| allahu-akbar | اللّٰهُ أَكْبَرُ | Sahih al-Bukhari; Sahih Muslim | [[PENDING]] |
| subhanallah-wa-bihamdihi | سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ | Sahih al-Bukhari 6405; Sahih Muslim 2691 | [[PENDING]] |
| subhanallah-azim | سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ، سُبْحَانَ اللّٰهِ الْعَظِيمِ | Sahih al-Bukhari 6406; Sahih Muslim 2694 | [[PENDING]] |
| astaghfirullah | أَسْتَغْفِرُ اللّٰهَ | Sahih Muslim 2702 | [[PENDING]] |
| la-hawla | لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ | Sahih al-Bukhari 6384; Sahih Muslim 2704 | [[PENDING]] |
| salawat | اللّٰهُمَّ صَلِّ وَسَلِّمْ عَلَىٰ نَبِيِّنَا مُحَمَّدٍ | Sahih Muslim 408 | [[PENDING]] |

---

## Instructions for the reviewer

- Verify each Arabic phrase against a printed or digitally-authenticated Hisn al-Muslim or the
  relevant hadith collection (sunnah.com is an acceptable verification source).
- Confirm the tashkil (diacritics) matches the referenced text exactly.
- Check that no phrase has sectarian or contested status; only universally-accepted adhkar are included.
- Note any corrections clearly with the entry `id` and the exact change needed.
- Sign your name and date in the table above.
- Return this completed file to the project owner for integration into the release.

---

*This sign-off is a permanent part of the project's asset provenance record. Do not delete or
modify the completed version after signing.*

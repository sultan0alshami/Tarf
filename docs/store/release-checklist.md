# Tarf (طَرْف) — Master Pre-Publish Release Checklist

> The single gate that must be **fully green** before publishing Tarf to **any** store. References every
> compliance doc, every store guide, the **dhikr scholarly sign-off**, the **audio provenance ledger**, and the
> **iOS < 26 degraded break-sound disclosure**. Treat each `[ ]` as a hard gate; do not ship with open items in
> the "Blocking" sections.

Owner: individual / for-profit developer, KSA. App code lives under `app/` (owned by another dev) — verify the
items below **with** that developer; do not assume.

---

## 0. Build reality (per spec §10)
- **Built + verified here:** Web/PWA, Chrome Extension, Windows (.exe + MSIX), Android (APK/AAB).
- **Scaffolded + CI, final signed builds by owner/CI on macOS:** iOS, macOS.
- [ ] CI matrix green (GitHub Actions: Android/Windows/Web/extension on this repo; iOS/macOS on a macOS runner).

---

## A. BLOCKING — Legal & compliance (all platforms)
- [ ] **Privacy Policy** finalized (all `[[PLACEHOLDERS]]` filled), hosted at `[[https://tarf.app/privacy]]`
      (+ Arabic at `…/ar/privacy`). → `compliance/privacy-policy.md`
- [ ] **Terms of Service** finalized + hosted at `[[https://tarf.app/terms]]` (+ Arabic). Reviewed by a
      KSA-qualified lawyer. → `compliance/terms-of-service.md`
- [ ] **GDPR Art. 9 religion-as-sensitive-data position** confirmed and reflected identically in the Privacy
      Policy, Apple App Privacy, Play Data Safety, and CWS disclosures (we do **not** process special-category
      data; prayer-time location stays on-device). → `compliance/privacy-policy.md` §4
- [ ] **Lawful basis, retention, international-transfer** statements consistent across all forms.
- [ ] **Account deletion + data export** implemented in-app on **every** platform and tested end-to-end on a real
      account (server docs + Auth user gone); **public web deletion URL** live and reachable without the app.
      → `compliance/account-deletion.md`
- [ ] **Permissions UX matrix** implemented: every permission just-in-time, AR+EN priming, granted/denied/re-ask/
      Settings-deep-link/permanently-denied paths, and the **notifications-denied degraded experience** (status
      chip + foreground-only honesty). → `compliance/permissions-matrix.md`
- [ ] **Data-safety / privacy answers cross-checked** for consistency across Apple ↔ Play ↔ CWS ↔ Policy.
      → `compliance/apple-privacy.md`, `compliance/google-play-data-safety.md`
- [ ] **No ads, no ad SDK, no advertising ID, no cross-app tracking** — verified in the SDK/linked-libraries
      reports on every platform; therefore **no iOS ATT prompt**.

---

## B. BLOCKING — Sacred content integrity (the irreducible Tarf gate)
- [ ] **Dhikr scholarly / editorial sign-off** obtained: a **named** reviewer has approved the Arabic text, full
      tashkīl (diacritics), transliteration scheme, English translations, and every source reference
      (Hisn al-Muslim / sunnah.com with exact references). The sign-off is a **tracked, dated artifact**
      (signer name + date + scope) stored at `[[assets_ledger/dhikr-signoff.md or PDF]]`. Spec §5 editorial gate.
- [ ] v1 ships **only the universally-agreed, non-sectarian** phrases (no contested content).
- [ ] Arabic is **immutable, fully diacritized, never truncated** (auto-fit verified via golden tests), and
      **never adjacent to any ad/upsell/popup**. No gamification of worship.
- [ ] **Audio provenance ledger** complete and accurate: `assets_ledger/ledger.json` lists, for **every** audio
      clip and font — source URL, license (CC0/Pixabay/SIL OFL/etc.), license-text snapshot, download date,
      author, required attribution, and a signed-agreement path for any commissioned recitation. → spec §5
- [ ] In-app **Licenses & Credits** screen renders the ledger correctly (fonts: Amiri/Scheherazade New SIL OFL;
      Inter SIL OFL; audio attributions). No KFGQPC font (restrictive license).
- [ ] **Remote kill/replace switch** (Firebase Remote Config) verified to disable/swap a defective dhikr clip
      without a full release. → spec §5
- [ ] Arabic TTS fallback gated on `isLanguageInstalled('ar-SA')`; graceful when unavailable.

---

## C. BLOCKING — The two life-or-death promises (spec §13 telemetry)
- [ ] **Break fires on time** (activity-aware, off accumulated active time) — verified per platform.
- [ ] **20-second audio plays to completion** (sound-end = break-end) in the foreground on **all** platforms, and
      in the documented background modes (desktop tray ✅; Android FGS+alarm best-effort ✅).
- [ ] **iOS < 26 degraded break-sound disclosure** present and honest: stated **in-app** (status/Settings copy)
      **and on the iOS store page**, that backgrounded iOS < 26 uses a local notification + short sound (degraded),
      while iOS 26+ uses AlarmKit ring-through-silence. **No silent-keep-alive hack** shipped. → spec §4.4
- [ ] **Web/extension** Chrome-must-be-open limitation disclosed in the CWS listing and in-app.
- [ ] **Activity-awareness** verified: never nags when the user is away from the screen (the #1 competitor 1-star
      cause).

---

## D. Per-store gates (complete the matching guide before each submission)
- [ ] **Apple App Store + Mac App Store** → `store/app-store.md`
  - Developer Program active; signing/notarization done; `PrivacyInfo.xcprivacy` shipped; bundled SDK manifests
    verified; `ITSAppUsesNonExemptEncryption=false`; **no payment in iOS binary** (thank-you/share only); Sign in
    with Apple offered as a peer option; account deletion in Settings; AR+EN RTL screenshots; demo creds / Guest
    note in review notes; age rating 4+.
- [ ] **Google Play** → `store/google-play.md`
  - $25 account + identity verified; closed-testing (12 testers/14 days) satisfied; AAB via Play App Signing;
    Data Safety + content rating + ads=No + target-audience done; **exact-alarm + foreground-service-type +
    full-screen-intent declarations** completed and justified; targetSdk meets current requirement; minSdk 26;
    AR+EN RTL screenshots; deletion web URL provided; staged rollout planned.
- [ ] **Microsoft Store (Windows)** → `store/microsoft-store.md`
  - Partner Center account; identity reserved; MSIX identity matches reservation; privacy policy URL set; IARC
    age rating; minimal capabilities; AR+EN RTL screenshots; Support link opens external donation page; tray
    behavior verified in the packaged MSIX.
- [ ] **Chrome Web Store** → `store/chrome-web-store.md`
  - $5 account; single-purpose statement; **per-permission justifications** (alarms/notifications/offscreen/
    storage/sidePanel/idle); no host permissions; **no remote code** (locally bundled CanvasKit, CSP
    `script-src 'self' 'wasm-unsafe-eval'`); data disclosures consistent; Chrome-open-only limitation stated.

---

## E. Donations (spec §8)
- [ ] **Non-iOS** apps (Android/Web/Windows/macOS) show a **Support** button linking to the external website
      donation page; **iOS** shows **thank-you/share only, no payment link**.
- [ ] Website donation flow uses the pluggable KSA gateway (**Moyasar primary / Tap / Stripe**), supports
      **Mada + Visa + Mastercard**, defaults to **sandbox/test** until live keys are slotted; **no raw card data
      touches our serverless code** (PCI handled by the gateway).
- [ ] Donations described as **voluntary, non-refundable gifts granting no features** (ToS §4).

---

## F. Quality, accessibility, i18n (spec §1, §13)
- [ ] **RTL/Arabic golden tests** pass (no Arabic split across TextSpans; verified on CanvasKit); real Arabic copy
      everywhere (no lorem/placeholder).
- [ ] **WCAG 2.1 AA**: ≥44pt targets, Reduce Motion / Reduce Transparency / Dynamic Type honored, screen-reader
      labels, never color-alone, every audio cue paired with a visual cue.
- [ ] Material 3 light/dark; teal-green accent; solid high-contrast fallbacks for translucency.
- [ ] **Firestore security rules** lock every path to `request.auth.uid == uid`; **App Check** enabled; budget
      alerts set; Spark-tier cost headroom + documented Blaze migration trigger. (spec §6)
- [ ] Auth edge cases handled (cancelled sign-in, account-exists-different-credential, token-expired-offline,
      cleared-app-data wipes session); graceful re-login for privileged offline actions.
- [ ] Beta channel exercised (TestFlight / Play internal & closed) before public release.

---

## G. Final sign-off
- [ ] All **Blocking** sections (A, B, C) green.
- [ ] Each target store's per-store gate (D) green for the platforms being released this cycle.
- [ ] Version numbers bumped consistently across platforms; "What's new" written AR+EN.
- [ ] Owner records the release (date, versions, store statuses) and archives the dhikr sign-off + ledger snapshot
      for this version.

**Reference index:** `compliance/privacy-policy.md` · `compliance/terms-of-service.md` ·
`compliance/permissions-matrix.md` · `compliance/apple-privacy.md` · `compliance/google-play-data-safety.md` ·
`compliance/account-deletion.md` · `store/app-store.md` · `store/google-play.md` · `store/microsoft-store.md` ·
`store/chrome-web-store.md` · `assets_ledger/ledger.json` · `[[dhikr scholarly sign-off artifact]]`.

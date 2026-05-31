# Tarf (طَرْف) — Apple App Store + Mac App Store submission guide

> Step-by-step for an **individual / for-profit developer in Saudi Arabia** to ship the **iOS** and **macOS**
> builds. Final signed builds run on a **macOS machine / macOS CI runner** (per the spec: iOS/macOS are
> scaffolded here, archived by the owner/CI). The app code is under `app/` (owned by another dev) — this guide
> covers accounts, signing/notarization, metadata, and review.

---

## 1. Accounts, fees, prerequisites
- **Apple Developer Program membership:** **USD 99/year** (individual is fine for a sole developer; you can
  enroll as an individual and your legal name shows as the seller, or as an org if you have a D-U-N-S number).
  Enroll at developer.apple.com. KSA developers are supported; you'll need a valid payment method and tax forms.
- **Mac required** for final Xcode archive, signing, notarization (or a macOS CI runner — GitHub Actions
  `macos-latest`).
- **Xcode** latest stable; **Apple ID** with the Developer Program; **App Store Connect** access.
- **Bundle IDs:** register e.g. `app.tarf.ios` and `app.tarf.mac` (or a shared base) in
  Certificates, Identifiers & Profiles. Enable capabilities: **Sign in with Apple**, **Push/Notifications**,
  and (macOS) **App Sandbox**.
- **Tax/Banking (App Store Connect → Agreements):** accept the Paid/Free agreements; complete **tax forms**
  (W-8BEN for a non-U.S. individual) and **banking** even for a free app (required to transact). KSA bank
  details supported.

## 2. Signing — iOS
- **Certificates:** Apple Distribution certificate; **App Store** provisioning profile for `app.tarf.ios`.
- Prefer **automatic signing** in Xcode (Runner target → Signing & Capabilities → check "Automatically manage
  signing", select your Team). For CI, use **App Store Connect API key** + `fastlane match` or `xcodebuild`
  with a manually-installed cert/profile.
- Capabilities to enable on the App ID + entitlements: **Sign in with Apple**, **Push Notifications** (for
  local+future remote), and the **associated background modes** only if actually used (avoid the silent-audio
  keep-alive hack — rejection risk per spec).
- Set `ITSAppUsesNonExemptEncryption = false` in `Info.plist` (see `compliance/apple-privacy.md` §4).
- Ship `ios/Runner/PrivacyInfo.xcprivacy` + confirm bundled SDK manifests (see `compliance/apple-privacy.md`).

## 3. Signing + notarization — macOS
Two distribution routes — pick per your plan (the spec lists **macOS** as a store target **and** a
signed/notarized direct-download desktop build):
- **Mac App Store:** Apple Distribution (Mac) cert + Mac App Store provisioning profile; **App Sandbox** entitlement
  required; submit via Xcode/Transporter like iOS.
- **Direct download (notarized .dmg/.app, outside the store):** **Developer ID Application** certificate → sign
  the `.app` (`codesign --options runtime --timestamp`), staple, then **notarize**:
  `xcrun notarytool submit Tarf.dmg --apple-id … --team-id … --password … --wait` then
  `xcrun stapler staple Tarf.dmg`. Hardened Runtime is required for notarization.
- The spec's **auto-update channel** (so dhikr/glyph fixes reach desktop users) applies to the direct-download
  build; the Mac App Store build updates via the store.

## 4. Build & upload
1. On macOS: `flutter build ipa` (iOS) / `flutter build macos` then archive in Xcode (Product → Archive).
2. Validate the archive (Xcode Organizer → Validate App) — fixes most metadata/signing/privacy issues early.
3. Upload via **Xcode Organizer** or **Transporter** or `xcrun altool`/`notarytool` + Transporter for App Store.
4. Build appears in App Store Connect → TestFlight after processing (minutes).

## 5. App Store Connect — metadata checklist
- **App name:** "Tarf" (consider localized «طَرْف» as the Arabic display name). **Subtitle** (30 chars).
- **Primary language:** **Arabic** (Arabic-first product); add **English** localization.
- **Category:** Primary **Health & Fitness** (or **Productivity**); Secondary the other. (Pick one; matches the
  spec's "app category" gate.)
- **Privacy Policy URL:** `[[https://tarf.app/privacy]]` (required). **Support URL** + **Marketing URL**.
- **App Privacy** nutrition label: fill exactly per `compliance/apple-privacy.md` §1; **tracking = No**.
- **Age rating:** complete the questionnaire → expected **4+** (no objectionable content). Religious/reference
  content is fine; declare honestly.
- **Description / keywords / promotional text** in **AR + EN** (Arabic primary). Emphasize: free, no ads, offline
  eye-care + dhikr break, calm design.
- **Screenshots:** required sizes — **6.7"/6.9" iPhone** and **iPad 12.9"/13"** (and any others Apple currently
  requires); provide **Arabic (RTL)** and English sets; show the dhikr break overlay, Focus, Insights. Use real
  Arabic copy (no lorem). Optional app preview video.
- **App icon** 1024×1024, no alpha, no rounded corners baked in.
- **Export compliance:** answered via the `Info.plist` key (no per-build prompt).
- **Sign-in info for review:** provide a **demo account** (email/password) OR clearly note that the **core
  eye-care + dhikr loop works in Guest mode with no login** (helps review). If reviewers must test sign-in,
  supply working test credentials in App Review notes.

## 6. Review-risk notes specific to Tarf
- **Account deletion in-app** must be present (Guideline 5.1.1(v)) — verify before submitting (see
  `compliance/account-deletion.md`).
- **No payments on iOS:** the iOS app must show **only a thank-you/share** screen — **no donate button, no
  external payment link** (a for-profit app linking to external donations risks 3.1.1 IAP issues). Keep all
  payment flows out of the iOS binary. Donations live on the website for non-iOS only.
- **Reminder honesty:** the iOS < 26 background break-sound is **degraded**; disclose it in-app and (optionally)
  on the store page so reviewers/users aren't surprised. Do **not** use silent-keep-alive hacks.
- **Sign in with Apple** must be offered as a **peer** option (not pre-selected) wherever Google sign-in is
  offered (Guideline 4.8) — already in the spec.
- **Religious content:** present respectfully with sources; avoid anything that could read as proselytizing in
  metadata. Keep description factual.

## 7. Submit
1. Attach the build, complete all metadata + App Privacy + age rating + export compliance.
2. Set pricing = **Free**; choose **all territories** (or per plan).
3. Add **App Review notes** (Guest mode explanation + demo creds + "account deletion is in Settings → Account").
4. Submit for Review. Typical review: ~24–48h. Respond to any reviewer messages in Resolution Center.
5. Choose **manual or automatic release** after approval.

## 8. Beta first (recommended by spec)
- Use **TestFlight** (internal + external testers) before public release. External testing needs a Beta App
  Review. Validate: break fires + 20s audio completes, RTL/Arabic rendering, account deletion, sign-in.

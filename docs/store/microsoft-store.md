# Tarf (طَرْف) — Microsoft Store (Windows) submission guide

> Step-by-step for an **individual / for-profit developer in Saudi Arabia** to ship the **Windows** build as an
> **MSIX** package to the Microsoft Store. Windows is **built + tested in this environment** (.exe + MSIX per
> the spec). The app code is under `app/` (owned by another dev) — this covers the account, MSIX packaging,
> identity, metadata, and certification.

---

## 1. Account, fees, prerequisites
- **Microsoft Partner Center developer account.** Registration fee: **one-time ~USD 19** for an **individual**
  account (vs ~USD 99 for a company). KSA individuals are supported; complete identity/tax/payout setup.
- **Windows 10/11 machine** with **Flutter Windows desktop** toolchain (Visual Studio with "Desktop development
  with C++"). Builds run here in this environment.
- Decide distribution: **Microsoft Store** (this guide) and/or **direct download** of a signed MSIX (the spec's
  auto-update desktop channel). Both can coexist.

## 2. Reserve identity
1. In Partner Center → **Apps and games → New product → MSIX/PWA app**.
2. **Reserve the app name** "Tarf" (and/or «طَرْف») — this reserves the name and gives you the **Package
   Identity** values you must build into the MSIX:
   - **Package/Identity/Name** (e.g. `12345Publisher.Tarf`),
   - **Publisher** (e.g. `CN=…` from Partner Center → Product identity),
   - **Publisher display name**.
   Copy these from Product management → **Product identity**.

## 3. Build the MSIX
Use the Flutter `msix` package (or `flutter pub run msix:create`) configured in `app/`'s `pubspec.yaml`. The
**identity values must exactly match** the Partner Center reservation:
- `msix_config`:
  - `display_name: Tarf`
  - `publisher_display_name: [[from Partner Center]]`
  - `identity_name: [[12345Publisher.Tarf]]`
  - `publisher: [[CN=… exact string]]`
  - `msix_version: 1.0.0.0` (four-part; bump per release)
  - `logo_path`, `capabilities` (declare only what's needed; desktop notifications/audio generally need **no**
    special restricted capability — avoid over-declaring, especially restricted capabilities that trigger extra
    review), `languages: ar, en`.
- For **Store** submission you do **not** sign the MSIX yourself — the Store re-signs with the trusted Store
  certificate, so build the MSIX **without** your own signing for the Store upload (or sign for sideload/direct
  download separately — see §6).
- Output: `app/build/windows/.../tarf.msix`.

## 4. Submission — Partner Center
- **Packages:** upload the `.msix` (or `.msixupload`). Partner Center validates identity + manifest.
- **Pricing and availability:** **Free**; markets = KSA + global as planned; choose release schedule.
- **Properties:**
  - **Category:** Health & fitness (or Productivity).
  - **Privacy policy URL:** `[[https://tarf.app/privacy]]` (**required** because the app handles personal data /
    accounts).
  - **Support contact info / website.**
- **Age ratings:** Microsoft uses **IARC** — complete the questionnaire → expected **Everyone / 3+**. Declare
  religious reference content honestly; no objectionable content.
- **Store listing (per language — AR + EN):** description, what's new, **screenshots** (min 1, 1366×768 or larger;
  provide RTL Arabic + English sets showing the dhikr break overlay, Focus, Insights), app **logo/tile** assets,
  keywords/search terms.
- **Notes for certification:** state that **core eye-care + dhikr works in Guest mode (no login)**; if reviewers
  need sign-in, provide demo credentials. Note the donation **Support** link opens the external website (allowed
  on Windows; not Apple). Confirm account deletion + data export are in Settings → Account.

## 5. Donations on Windows
- Per spec, the Windows app shows a **"Support"** button that **links out** to the website donation page
  (Mada/Visa/Mastercard via the gateway). This is permitted on the Microsoft Store (external link, not
  Microsoft commerce). Keep raw card handling entirely on the gateway/website.

## 6. Direct-download signed MSIX (optional, for the auto-update channel)
- For distribution **outside** the Store, sign the MSIX with a **code-signing certificate** (an OV/EV cert from a
  CA, or for internal testing a self-signed cert the user must trust). The Store path (§3) does **not** need this.
- `SignTool sign /fd SHA256 /a /f cert.pfx /p [[pwd]] tarf.msix`.
- Provide an **auto-update** mechanism (App Installer `.appinstaller` file pointing at your update URL) so dhikr/
  glyph fixes reach direct-download users, as the spec requires.

## 7. Certification & release
1. Submit; Microsoft runs automated + manual certification (typically hours to ~1–3 days).
2. Address any certification report failures (common: missing privacy policy, capability over-declaration, crash
   on launch, screenshot issues).
3. On pass, choose release timing. Updates = new MSIX version (bump `msix_version`) re-submitted the same way.

## 8. Tarf-specific checklist
- [ ] Identity values in `msix_config` exactly match Partner Center.
- [ ] Privacy policy URL set (required).
- [ ] Age rating (IARC) completed.
- [ ] Only necessary capabilities declared (no restricted-capability over-reach).
- [ ] AR + EN listing with real Arabic RTL screenshots.
- [ ] Guest-mode note + demo creds in certification notes.
- [ ] Account deletion + data export verified in the Windows build.
- [ ] Tray behavior (live countdown, pause/snooze/skip, launch-at-startup, hide-to-tray) works in the packaged
      MSIX (not just `flutter run`).

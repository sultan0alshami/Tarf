# Tarf — Your Action Checklist

Everything **you** need to do to take Tarf from "working in dev" to "published".
Ordered roughly by when you'll need it. Items marked **(I can do it)** are things
you can hand back to me — the rest need your accounts, machines, or decisions.

Detailed references: [`README.md`](README.md) · [`docs/accounts.md`](docs/accounts.md) ·
[`docs/firebase-setup.md`](docs/firebase-setup.md) · [`docs/store/`](docs/store/) ·
[`docs/compliance/`](docs/compliance/).

---

## 0. Decisions to confirm
- [ ] **App/bundle ID** — currently `app.tarf`. Confirm or change before stores.
- [ ] **Donation entity** — individual vs registered nonprofit (affects iOS donation rules).
- [ ] **iOS minimum version** — plan targets iOS 15 (tiered break-sound). Confirm.
- [ ] **Which platforms to launch first** (recommended cheapest path: Web + Chrome extension).

---

## 1. Local development setup (this machine)
- [ ] **Enable Windows Developer Mode** (needed for `flutter build windows`). In an **Administrator** PowerShell:
  ```
  reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"
  ```
  (or Settings → Privacy & security → For developers → Developer Mode → On)
- [ ] Sanity check: `cd app && flutter run -d chrome` opens the app; load `extension/` at `chrome://extensions`.

---

## 2. Accounts to create
*(Full details + costs in [`docs/accounts.md`](docs/accounts.md).)*
- [x] **GitHub** — done (`github.com/sultan0alshami/Tarf`).
- [ ] **Firebase / Google Cloud** (free) — for sign-in + cloud sync.
- [ ] **Apple Developer Program** ($99/yr) — required even just for *Sign in with Apple*; also iOS/macOS.
- [ ] **Payment gateway** — Moyasar (recommended) or Tap, for **Mada + Visa + Mastercard**. *Requires a Saudi commercial registration (CR) or freelance/professional license.*
- [ ] **Domain** (~$15/yr, e.g. `tarf.app`) — needed for the hosted privacy-policy URL + site.
- [ ] **Website host** — Vercel or Netlify (free).
- [ ] **Google Play Console** ($25 one-time) — Android.
- [ ] **Microsoft Partner Center** (~$19 one-time) — Windows.
- [ ] **Chrome Web Store** developer ($5 one-time) — the extension.

---

## 3. Cloud sync + sign-in (Firebase)
*(Full steps in [`docs/firebase-setup.md`](docs/firebase-setup.md).)*
- [ ] Create a Firebase project named `tarf`.
- [ ] Enable **Auth**: Google, Apple, Email/Password.
- [ ] Create **Firestore** (production mode) in a nearby region.
- [ ] Publish rules: `firebase deploy --only firestore:rules --project tarf` (from `app/firebase/firestore.rules`).
- [ ] Run `flutterfire configure --project=tarf` inside `app/` (generates config files).
- [ ] Enable **App Check** + set a **billing budget alert**.
- [ ] **(I can do it)** Once your project exists, hand me the config and I'll wire the live `AuthService` + Drift↔Firestore sync + cloud account-deletion.

---

## 4. Donations (Mada / Visa / Mastercard)
- [ ] Onboard with Moyasar/Tap (needs your CR/license) and get **API keys** (test + live).
- [ ] Buy the domain + deploy `website/` to Vercel/Netlify.
- [ ] Add gateway keys as env vars (see `website/README.md`).
- [ ] **(I can do it)** Tell me which gateway + give me test keys and I'll finish/verify the `/api/donate` flow and the Support page wiring.

---

## 5. Content & legal (before public release)
- [ ] **Dhikr scholarly/editorial sign-off** — have a named scholar verify the Arabic text, diacritics, transliteration, translations, and references in `app/assets/dhikr/dhikr.json`. **(Hard gate for a faith app.)**
- [ ] Host **privacy policy + terms** at a public URL (drafts in `docs/compliance/`).
- [ ] Fill **Apple App Privacy** + add `PrivacyInfo.xcprivacy` (content in `docs/compliance/apple-privacy.md`).
- [ ] Fill **Google Play Data Safety** form (`docs/compliance/google-play-data-safety.md`).
- [ ] Prepare store **screenshots** (Arabic + English) and metadata.

---

## 6. Build & publish per platform
*(Step-by-step guides in [`docs/store/`](docs/store/). CI is in `.github/workflows/`.)*
- [ ] **Web/PWA** — deploy `app/build/web` (or via CI) to your host. *(Cheapest first launch.)*
- [ ] **Chrome extension** — run `pwsh extension/package.ps1`, upload `tarf-extension.zip` to the Chrome Web Store; add the single-purpose statement + permission justifications (`docs/store/chrome-web-store.md`).
- [ ] **Android** — `flutter build appbundle`; create app in Play Console; complete the closed-testing requirement; submit.
- [ ] **Windows** — (after Dev Mode) `flutter build windows`; package MSIX; submit to Microsoft Store.
- [ ] **iOS / macOS** — on a **Mac**: `flutter build ipa` / macOS; sign + notarize; submit (`docs/store/app-store.md`). CI workflow `build-apple.yml` is ready — add your signing secrets.

---

## 7. Optional engineering I can take next (just ask me)
- [ ] **(I can do it)** Backgrounded **native notifications** + **desktop tray** (`flutter_local_notifications`, `android_alarm_manager_plus`, tray) — needs you to device-test after.
- [ ] **(I can do it)** Live **Firebase** auth + sync wiring (after step 3).
- [ ] **(I can do it)** A **location picker** for prayer times (currently defaults to Riyadh / Umm al-Qura).
- [ ] **(I can do it)** Bundle the **Amiri Arabic font** + Inter as assets (currently using system fallback) and add golden tests.
- [ ] **(I can do it)** Tasbih counter on the break screen, posture/blink reminders, wearable/widget support (fast-follows).

---

### Recommended order
1. Step 1 (Dev Mode) → 2 (Firebase + domain + host accounts) → 3 (Firebase setup).
2. Ship **Web + Chrome extension** first (Step 6, cheapest).
3. Add **donations** (Step 4) once your CR/gateway is ready.
4. Then **Android**, then **iOS/macOS/Windows** as you create those accounts.
5. Do **Step 5 (content + legal)** before any public store listing.

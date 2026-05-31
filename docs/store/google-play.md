# Tarf (طَرْف) — Google Play submission guide

> Step-by-step for an **individual / for-profit developer in Saudi Arabia** to ship the **Android** build
> (AAB) to Google Play. The app code is under `app/` (owned by another dev) — this guide covers the account,
> signing, Play Console declarations, metadata, and the staged rollout.

---

## 1. Account, fees, prerequisites
- **Google Play Developer account:** one-time **USD 25** registration at play.google.com/console.
- **Identity verification:** Google now requires **identity + (for individuals) D-U-N-S is not required, but
  identity/address verification is** — complete it early; for newer accounts there is also a **closed-testing
  requirement** (testing with **≥ 12 testers for ≥ 14 days**) before you can apply for production access.
  Budget for this timeline.
- **Payments profile:** required to receive anything; for a free app you still set up the account. (Donations
  are website-only, not Play Billing — fine, because they are external and not for in-app digital goods.)
- **App created** in Play Console with package name e.g. `app.tarf.android`.

## 2. Signing
- Use **Play App Signing** (recommended/default): you upload an **AAB** signed with your **upload key**; Google
  manages the **app signing key**. Generate an upload keystore:
  `keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 9125 -alias upload`.
  Keep `upload.jks` + passwords **secret and backed up** (store in CI secrets for the GitHub Actions Android job).
- Build: `flutter build appbundle --release` → `app/build/app/outputs/bundle/release/app-release.aab`.
- (APK is built/tested in this environment per the spec, but **Play requires the AAB** for distribution.)

## 3. Play Console declarations (App content) — REQUIRED, common rejection points
Complete **all** of these under **App content**:
- **Privacy Policy URL:** `[[https://tarf.app/privacy]]`.
- **Data safety form:** fill exactly per `compliance/google-play-data-safety.md` (mark deletion URL + encrypted-
  in-transit + optional account).
- **App access:** if any feature is behind login, provide **demo credentials** OR state that the **core eye-care
  + dhikr loop is fully usable in Guest mode without login** (recommended — speeds review).
- **Ads:** declare **"No, my app does not contain ads."**
- **Content rating (IARC questionnaire):** complete it → expected **Everyone / PEGI 3 / "3+"**. Declare religious
  reference content honestly; no objectionable content.
- **Target audience & content:** target **13+ / general audience**, **not** "Designed for Families." Confirm app
  is not directed at children.
- **News / COVID / Government / Financial-features:** No.
- **Permissions declarations (Sensitive/Restricted) — critical for Tarf:**
  - **Exact alarm** (`USE_EXACT_ALARM`/`SCHEDULE_EXACT_ALARM`): complete the **Alarms & reminders** declaration;
    justify that alarms/timers + precise break timing are a **core function**.
  - **Foreground service**: declare the **FGS type** matching the manifest; justify the background break-timing /
    audio service. Mismatch or weak justification = rejection.
  - **Full-screen intent** (`USE_FULL_SCREEN_INTENT`): justify (Strict-mode full break screen).
  - **Notifications** (`POST_NOTIFICATIONS`): standard, no special form but must be runtime-requested (see
    `compliance/permissions-matrix.md`).
  - **Location** (`ACCESS_COARSE_LOCATION`): if you ship the prayer feature, complete any location declaration and
    state in the data-safety form it is **on-device only / not collected**.
- **Government apps / Health:** Not a health/medical app — do not claim medical function (see ToS disclaimer).

## 4. Store listing metadata checklist
- **App name** (≤30): "Tarf — طَرْف" (or localized). **Default language:** consider **Arabic** primary +
  **English** as an additional listing language (Arabic-first product).
- **Short description** (≤80) + **Full description** (≤4000), in **AR + EN**: free, no ads, offline eye-care +
  calm dhikr break, Focus/Timer/Alarm/Stopwatch, privacy-respecting.
- **App icon** 512×512 PNG; **Feature graphic** 1024×500.
- **Phone screenshots** (min 2; 16:9 or 9:16; ≥320px): show dhikr break overlay, Focus home, Insights, Settings;
  provide **Arabic (RTL)** + English sets with real Arabic copy. Add **7"/10" tablet** screenshots if you list
  tablet support.
- **Category:** **Health & Fitness** (or Productivity). **Tags.** **Contact email** (+ optional phone/website).
- **Countries/regions:** select (KSA + global as planned). **Pricing: Free.**

## 5. Releases & staged rollout (matches the spec's beta plan)
1. **Internal testing** track first (instant, up to 100 testers) — smoke test the AAB.
2. **Closed testing** — satisfy the **12 testers / 14 days** new-account requirement; gather feedback; verify the
   two core promises (break fires + 20s audio), RTL/Arabic, account deletion, sign-in, exact alarms under Doze.
3. **Open testing** (optional) → **Production** with a **staged rollout** (e.g. 10% → 50% → 100%); monitor Android
   vitals (ANRs/crashes) and the foreground-service/battery behavior across OEMs.
4. Set **minSdk = 26** (per spec) and ensure **targetSdk** meets Google's current target-API requirement
   (rejection if below the required level).

## 6. Tarf-specific rejection-avoidance
- Foreground-service type + exact-alarm justifications must be airtight (top rejection causes for timer apps).
- Battery-optimization-exemption prompt (if shipped) must follow policy — prefer guiding the user to settings
  over the direct allow-list prompt; justify in the FGS/permissions declarations.
- Data-safety answers must match the Privacy Policy and Apple label.
- No ad SDKs / no advertising ID — confirm in the SDK report.
- Account deletion present in-app **and** the public web URL provided.

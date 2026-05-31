# Tarf (طَرْف) — Apple App Privacy + PrivacyInfo.xcprivacy + Encryption

> Everything needed for the **App Store Connect → App Privacy** "nutrition label", the
> `ios/Runner/PrivacyInfo.xcprivacy` privacy manifest (required-reason APIs + bundled SDK manifests), and the
> `ITSAppUsesNonExemptEncryption` export-compliance declaration. The app code is under `app/` (owned by another
> dev) — this file is the **spec/contract** to hand to that dev and to enter in App Store Connect.

---

## 1. App Privacy "nutrition label" answers (App Store Connect → App Privacy)

App Store Connect asks, per **data type**, whether you **collect** it and, if so, the **purpose**, whether it
is **linked to the user**, and whether it is used for **tracking**. Answer for **the worst case across the
shipped build** (signed-in mode included).

**Global answers:**
- **Do you or your third-party partners use data for tracking?** → **No.** (No ads, no ad SDKs, no cross-app/
  website tracking, no IDFA, no data brokers.) → therefore **App Tracking Transparency is not required.**
- **Guest mode** collects nothing off-device; the label still reflects what the **signed-in** mode can collect.

| Apple data type | Collected? | Linked to user? | Used for tracking? | Purpose(s) |
|---|---|---|---|---|
| **Contact Info → Email Address** | **Yes** | **Yes** (to the account) | No | **App Functionality** (account creation, auth, sync). Includes Apple "Hide My Email" relay |
| **Identifiers → User ID** | **Yes** | **Yes** | No | **App Functionality** (Firebase UID ties your synced data to you) |
| **Usage Data → Product Interaction** | **Yes** | **Yes** | No | **App Functionality** (focus minutes, sessions, breaks taken/skipped, daily-goal % for Insights/sync) |
| **User Content → Other (to-do titles, reflection notes)** | **Yes** | **Yes** | No | **App Functionality** (provide the to-dos/reflection features you opted into) |
| **Diagnostics → Crash / Performance** | **[[Yes ONLY if you ship a crash SDK; else No]]** | [[Not linked if anonymized]] | No | **App Functionality / Analytics** (fix crashes; verify break fired + 20s audio completed). **If v1 ships no analytics/crash SDK, answer No.** |
| **Location → Coarse Location** | **No (not collected by us)** | — | — | Prayer-time computation is **on-device only and never transmitted to us**; under Apple's definition we do **not** "collect" it. We still provide `NSLocationWhenInUseUsageDescription`. [[If any analytics SDK ever received coarse location, this would flip to Yes — confirm it does not.]] |
| Financial Info (payment) | **No** | — | — | Donations are **website-only**, handled by the gateway; the **iOS app has no payment** and processes no financial data |
| Health & Fitness | **No** | — | — | Tarf is wellness, not a medical device; collects no health data |
| Browsing History, Search History, Contacts, Photos, Audio Data, Sensitive Info, Purchases, Advertising Data | **No** | — | — | Not collected |

> **Religion / sensitive info:** Apple's "Sensitive Info" category covers data revealing religious beliefs.
> We answer **No** — Tarf does not collect data revealing your religious beliefs (dhikr content is bundled and
> identical for all users; prayer-time location stays on-device; we record no per-user religiosity). See
> Privacy Policy §4 for the GDPR Art. 9 position that mirrors this.

**Privacy Policy URL** (required field): `[[https://tarf.app/privacy]]`.

---

## 2. `ios/Runner/PrivacyInfo.xcprivacy` — privacy manifest

Apple requires a privacy manifest declaring: **collected data types**, **tracking domains** (none for us), and
**required-reason API** usage with approved reason codes. Tarf and several of its dependencies touch
required-reason APIs (e.g. `UserDefaults`, file-timestamp APIs). Provide this file in the Runner target (and
ensure each **bundled SDK ships its own** `.xcprivacy` — see §3).

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- We do NOT track users across apps/sites owned by other companies -->
  <key>NSPrivacyTracking</key>
  <false/>

  <!-- No tracking domains -->
  <key>NSPrivacyTrackingDomains</key>
  <array/>

  <!-- Data the APP ITSELF collects. (SDKs declare their own in their bundled manifests.) -->
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeEmailAddress</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeUserID</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeProductInteraction</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeOtherUserContent</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
    <!-- Add a CrashData entry ONLY if a crash/analytics SDK is shipped -->
  </array>

  <!-- Required-reason APIs that the Runner itself uses -->
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <!-- UserDefaults (e.g. shared_preferences / plugin storage) -->
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>CA92.1</string></array> <!-- access info only accessible to the app itself -->
    </dict>
    <dict>
      <!-- File timestamp APIs (e.g. Drift/SQLite, path_provider, file caching) -->
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>C617.1</string></array> <!-- timestamp of files inside app container -->
    </dict>
    <!-- Add ONLY if actually used by the Runner or a non-manifested dependency: -->
    <!-- DiskSpace (E174.1), SystemBootTime (35F9.1 for monotonic anti-clock-tamper), etc. -->
  </array>
</dict>
</plist>
```

**Required-reason API notes (verify against the real dependency tree under `app/`):**
- **UserDefaults** → reason **`CA92.1`** ("access info only accessible to the app itself").
- **File timestamp** → reason **`C617.1`** (timestamps of files within the app's own container — used by local DB/cache).
- **System boot time** → if the streak-integrity / monotonic-clock check reads `systemUptime`/boot time, declare
  **`SystemBootTime`** with reason **`35F9.1`**.
- **Disk space** → if any cache-sizing reads free disk space, declare **`DiskSpace`** with reason **`E174.1`**.
- Do **not** declare reasons you do not actually use; do **not** omit ones you do (Apple emails an `ITMS-91053`
  warning and may reject).

---

## 3. Bundled SDK privacy manifests (Firebase et al.)

Apple maintains a list of SDKs that **must** ship a privacy manifest and be **signed**. Tarf bundles several:

| SDK | Action |
|---|---|
| **Firebase (Auth, Firestore, Core, App Check, Remote Config)** | Use a Firebase iOS SDK version that **ships per-pod `.xcprivacy` manifests** (Firebase added them in recent releases). Do **not** hand-write these — they come inside the pods. Verify each pod contains a `PrivacyInfo.xcprivacy` after `pod install`. |
| **GoogleSignIn / GTMSessionFetcher / GoogleUtilities / abseil / gRPC / leveldb / nanopb** (Firebase transitive deps) | These are on or adjacent to Apple's "commonly used SDK" + "required-reason" lists. Ensure pinned versions include their bundled manifests. |
| **just_audio / audio_session** | Touch audio-session APIs; confirm they (or your Runner manifest) cover any required-reason API they hit. |
| **path_provider / sqlite3 (Drift) / shared_preferences** | File-timestamp + UserDefaults reasons — covered by the Runner manifest above **if** the plugin does not ship its own; prefer plugin-provided manifests where available. |
| **sign_in_with_apple** | No special data collection beyond the relay email already declared. |

**Verification step (owner / CI on macOS):** after `pod install`, run a grep for `PrivacyInfo.xcprivacy` across
`ios/Pods/` and confirm the privacy report in Xcode (Product → Archive → "Generate Privacy Report") aggregates
without missing-manifest warnings. Resolve any `ITMS-91053`/`ITMS-91065` upload warnings before release.

---

## 4. `ITSAppUsesNonExemptEncryption` — export-compliance declaration

Tarf uses encryption **only** in the standard, exempt ways: HTTPS/TLS for network calls and Apple/OS-provided
encryption for data at rest (Keychain, file protection). It implements **no proprietary or non-standard
cryptography** and is not designed to perform encryption as a primary function.

**Recommended declaration:** Tarf qualifies for the standard exemption. Set in `ios/Runner/Info.plist`:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

This means: "my app uses encryption, but only exempt encryption (standard HTTPS/TLS and platform-provided
crypto)," so **no annual self-classification report (CCATS/ERN) or French declaration is required**, and App
Store Connect will **not** prompt for export compliance on each build.

**Caveats / owner confirmation:**
- This is correct **as long as** Tarf does not add any non-exempt cryptography (e.g. a custom cipher, a VPN,
  proprietary E2E encryption). Standard TLS + Firebase + Keychain are all exempt.
- If that ever changes, set the key to `true` and complete the export-compliance questionnaire + documentation
  (and note KSA/U.S. export rules). For v1 as specified, **`false` is the right value.**
- Alternatively you can omit the key and answer the App Store Connect export-compliance question per upload,
  but setting `false` in `Info.plist` is cleaner and avoids the repeated prompt.

---

## 5. Owner action checklist (Apple)
- [ ] Fill the App Privacy questionnaire exactly as §1 (worst-case across the signed-in build), set tracking = No.
- [ ] Paste Privacy Policy URL `[[https://tarf.app/privacy]]`.
- [ ] Ship `ios/Runner/PrivacyInfo.xcprivacy` (§2); verify reason codes against the real dependency tree.
- [ ] Confirm every bundled SDK has a signed privacy manifest (§3); regenerate the Xcode privacy report clean.
- [ ] Set `ITSAppUsesNonExemptEncryption = false` (§4) after confirming only exempt encryption is used.
- [ ] Confirm **no ATT** prompt is shipped (tracking = No) and no IDFA/ad SDK is linked.
- [ ] Re-confirm with the `app/` developer that location is never sent off-device (keeps Location = "Not collected").

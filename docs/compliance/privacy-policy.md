# Tarf (طَرْف) — Privacy Policy (Draft)

> **STATUS:** DRAFT for owner/legal review before publishing. Replace every `[[PLACEHOLDER]]`.
> This document must be hosted at a stable public URL (e.g. `https://tarf.app/privacy`) and that
> URL pasted into App Store Connect, Google Play Console, Microsoft Partner Center, and the Chrome
> Web Store listing. Keep an Arabic translation hosted at `https://tarf.app/ar/privacy`.

- **Effective date:** [[EFFECTIVE_DATE — e.g. 2026-06-15]]
- **Last updated:** [[LAST_UPDATED_DATE]]
- **App / service:** Tarf (طَرْف) — a free, donation-funded eye-care + dhikr wellness app.
- **Data controller:** [[LEGAL_NAME / TRADE NAME]], an individual developer / sole proprietor based in
  the Kingdom of Saudi Arabia.
- **Contact:** [[privacy@tarf.app]] · [[postal address, KSA]]
- **Languages:** This policy is published in Arabic (primary) and English (secondary). If the two
  versions conflict, the **[[Arabic / English — pick one]]** version prevails.

---

## 1. Summary (plain language)

Tarf is **offline-first**. You can use the core feature — the 20-20-20 eye break with the dhikr
"repeat-after-me" screen — **without any account and with no network connection at all**, as a Guest.
In Guest mode we collect **nothing** and send **nothing** off your device.

If you choose to **sign in** (to unlock Focus/Pomodoro, Timer, Alarm, Stopwatch, Insights, To-dos and
cloud sync), we collect the **minimum** needed to run those features and sync them across your devices:
your **email + authentication identifier** and your **usage/productivity data tied to your account ID**.

We show **no ads**. We **never** sell or share your data for advertising or marketing. We place **no
commercial content next to sacred text, ever.** Donations are processed by a third-party payment
gateway — **we never see or store your card number.**

You can **export** your data and **delete your account** (and all associated server data) at any time,
from inside the app or via a web request.

---

## 2. Who we are

Tarf is built and operated by an individual / for-profit independent developer in Saudi Arabia. For the
purposes of GDPR and similar laws, that developer is the **data controller**. Where we use processors
(Google Firebase, the payment gateway), they act on our instructions.

| Role | Party |
|---|---|
| Data controller | [[LEGAL_NAME]], KSA |
| Cloud / sync / auth processor | Google LLC / Google Ireland Ltd (Firebase: Authentication, Cloud Firestore, App Check, Remote Config) |
| Payment processor (website donations only) | [[Moyasar (primary) / Tap / Stripe]] |
| App distribution | Apple, Google, Microsoft, the Chrome Web Store (each is an independent controller for the data they collect through their stores) |

---

## 3. The data we collect, why, and the lawful basis

We practice **data minimization**. We do **not** collect device contacts, photos, precise advertising
identifiers, browsing history, or biometric data.

### 3.1 Guest mode (no account) — collected: **nothing leaves your device**
- Your eye-care settings, dhikr preferences, and any local timers live **only** in local on-device
  storage (Drift/SQLite). They are never transmitted to us.
- No analytics, no crash reporting tied to you, no account.

### 3.2 Signed-in mode

| Data category | Specific data | Why we collect it | Lawful basis (GDPR Art. 6) |
|---|---|---|---|
| **Account / identity** | Email address; authentication user ID (Firebase UID); provider identifier (Google / Apple / Email); display name (optional) | To create and secure your account and sync your data across devices | **Contract** — Art. 6(1)(b): you ask us to provide the signed-in service |
| **Apple "Hide My Email" relay** | A private relay email (if you use Sign in with Apple and choose to hide your email) | Same as above; we treat the relay address as your email | Contract — Art. 6(1)(b) |
| **Usage / productivity stats (tied to UID)** | Daily focus minutes, number of focus sessions, eye-breaks taken vs. skipped, daily-goal percentage, timezone | To power Insights, streaks, daily goals, and cross-device continuity | Contract — Art. 6(1)(b) |
| **To-dos** | Task titles you type, done/undone state, estimated vs. actual focus counts | To provide the to-do feature you opted into | Contract — Art. 6(1)(b) |
| **Focus session logs** | Start/end timestamps (server timestamp when online), work/break minutes, optional bound task, optional reflection note | To build session history and Insights | Contract — Art. 6(1)(b) |
| **Settings** | Eye-care / focus / notification / appearance / prayer / account preferences | To remember your configuration across devices | Contract — Art. 6(1)(b) |
| **Integrity / anti-abuse** | App Check attestation token | To protect the backend from abuse and fraud | **Legitimate interests** — Art. 6(1)(f): securing our service |
| **Diagnostics (if enabled)** | [[Crash logs / non-personal performance counters — only if you opt in; see §6]] | To fix crashes and verify the two core promises (break fired on time, 20s audio completed) | **Consent** — Art. 6(1)(a), opt-in |

We do **not** collect your location to track you. Location is used **only** for the optional
prayer-time feature, and **only on your device** (see §4).

### 3.3 Donations (website only)
If you donate via our website Support page, the **payment gateway** collects and processes your payment
details (card number, etc.) under **its own** privacy policy. **We never receive or store your full card
number.** We may receive a confirmation that a donation succeeded plus a masked reference. The iOS app
shows **only** a thank-you screen and contains **no payment link**, so no donation data is processed
through the iOS app.

---

## 4. Special-category (sensitive) data — our religion position (GDPR Art. 9)

Tarf displays **dhikr** (short, universally-agreed Islamic remembrances). We have deliberately designed
the product so that **using Tarf does not create special-category personal data about you under GDPR
Article 9** (data revealing religious beliefs):

- The dhikr content is **bundled, immutable, identical for every user**. It is **our** content, not data
  *about you*. Which phrase rotates onto the screen is not derived from, and does not reveal, your beliefs.
- We **do not** record which dhikr you saw, store any "religiosity" profile, count tasbih on the server,
  gamify worship, or infer religion from your behavior.
- Choosing to install or use a wellness app is **not**, by itself, processing of Art. 9 data, and we take
  the position that **Tarf does not process special-category data**. Accordingly we do **not** rely on the
  Art. 9(2)(a) "explicit consent" condition, because no Art. 9 processing occurs.
- The optional **prayer-time** feature could, in principle, be seen as indicating a religious practice.
  We mitigate this fully: prayer times are **computed locally on your device** from a coarse location and
  your chosen calculation method; **the prayer feature sends nothing to our servers.** Your location and
  computed prayer times are **never transmitted to or stored by us.** If you decline the location
  permission, the feature gracefully falls back to **manually-entered times** kept only on your device.

If a regulator nonetheless considered any of the above to be Art. 9 data, our condition would be
**Art. 9(2)(a) — your explicit, informed consent**, which you give by enabling the optional feature, and
which you can withdraw at any time by disabling it.

---

## 5. Children

Tarf is a general-audience wellness app rated for everyone (4+/Everyone). It is **not directed at
children** and we do **not knowingly** collect personal data from children under **[[16 — or the digital-
consent age in the user's country]]**. We do not build profiles of children or target them. If you believe
a child has provided us personal data through a signed-in account, contact us at [[privacy@tarf.app]] and
we will delete the account and its data. Children may use **Guest mode**, which collects nothing.

---

## 6. Analytics, crash reporting & tracking

- **No advertising. No ad SDKs. No ad identifiers. No cross-app/website tracking.** We do **not** use the
  iOS App Tracking Transparency tracking mechanisms because we do not track you across other companies'
  apps or sites.
- Any diagnostics are **privacy-respecting, opt-in, and never tied to sacred content.** [[Specify whether
  you ship crash reporting in v1. If you DO NOT ship any analytics/crash SDK, state plainly:
  "Tarf v1 ships with no analytics or crash-reporting SDK."]]
- Firebase **App Check** sends an attestation token to protect the backend; it is an anti-abuse signal,
  not behavioral tracking.

---

## 7. How your data is stored and protected

- **On device:** local data is stored in the app's private sandboxed storage (Drift/SQLite, platform
  Keychain/Keystore for auth tokens).
- **In the cloud (signed-in only):** Cloud Firestore, with **security rules that lock every document to
  your own authentication ID** (`request.auth.uid == uid`) — one user cannot read another's data.
- **Encryption:** data is encrypted **in transit** (TLS/HTTPS) and **at rest** by Google Firebase's
  infrastructure. Tarf itself uses only standard platform encryption and does **not** implement any
  proprietary or non-exempt cryptography (see export-compliance note in the Apple submission docs).
- **Region:** Firebase data is stored in **[[Firestore location — e.g. eur3 / nam5 / asia-* — set this and
  state it]]**. We will not move your data to a less-protective region without notice.

No method of transmission or storage is 100% secure, but we apply reasonable, industry-standard safeguards.

---

## 8. Sharing & disclosure

We do **not sell** your personal data. We do **not share** it for advertising. We disclose data only:

- **To processors** acting on our instructions: Google Firebase (auth/sync/integrity/remote-config) and,
  for **website** donations, the payment gateway. Each is bound by its own data-protection terms.
- **To app stores** to the extent they independently collect data through their distribution channels.
- **For legal reasons** if required by valid law, court order, or to protect rights, safety, or security.
- **On a business transfer** (merger/acquisition), with notice and continued protection.

### International transfers
Because we use Google Firebase and may store data outside your country, your data may be transferred
internationally. Such transfers rely on appropriate safeguards (e.g. **Standard Contractual Clauses** and
Google's data-processing terms). Contact us for details.

---

## 9. Data retention

| Data | Retention |
|---|---|
| Guest-mode local data | Until you clear app data / uninstall; **never sent to us** |
| Account + signed-in cloud data | For as long as your account is active |
| After you delete your account | Server data deleted **promptly, within [[30]] days**; backups purged on their normal cycle (≤ [[90]] days) |
| Donation confirmation records (website) | Retained per tax/accounting law in KSA (typically [[10 years]]); held by the gateway/our records, **without full card numbers** |
| Diagnostics (if any) | [[e.g. 90 days, then deleted/aggregated]] |

---

## 10. Your rights

Depending on where you live (GDPR/EEA/UK, KSA **PDPL**, CCPA/CPRA in California, and others), you may have
the right to:

- **Access** the personal data we hold about you (and receive a copy / **export**);
- **Rectify** inaccurate data;
- **Erase** your data ("right to be forgotten") — see §11;
- **Restrict** or **object** to certain processing;
- **Data portability** — receive your data in a structured, machine-readable format;
- **Withdraw consent** at any time (e.g. disable diagnostics or the prayer feature) without affecting prior
  lawful processing;
- **Not be subject to advertising-based tracking** — which we do not do anyway;
- **Lodge a complaint** with your supervisory authority (in KSA: **SDAIA**; in the EEA: your national DPA).

**California (CCPA/CPRA):** we do **not** "sell" or "share" personal information as those terms are defined,
and we do not process sensitive personal information for inferring characteristics. You have rights to know,
delete, correct, and to non-discrimination.

To exercise any right, use the in-app controls (§11) or email **[[privacy@tarf.app]]**. We respond within
the legally required time (generally **30 days**; **45 days** for CCPA). We may need to verify your identity
via your signed-in account.

---

## 11. Account deletion & data export (always available)

In line with Apple App Store and Google Play requirements, **account deletion and data export are built
directly into the app** and also available on the web:

- **In-app:** Settings → Account → **Export my data** (downloads a machine-readable file of your data) and
  **Delete my account** (a clearly-labelled, confirm-gated flow that deletes your authentication record and
  **all** your Firestore data).
- **On the web:** a public deletion-request page at **[[https://tarf.app/delete-account]]** for users who
  cannot access the app, plus the email route above.

Deleting your account removes your cloud data within **[[30]] days** (backups within **[[90]] days**).
Local Guest-mode data is removed when you clear app data or uninstall. See the in-app/web flow specification
in our internal `account-deletion.md`.

---

## 12. Cookies & the website

Our marketing/download/Support website may use **strictly necessary** cookies and, only with your consent,
basic analytics. The donation flow loads the payment gateway, which sets its own cookies governed by its
policy. The **app itself** is not a website and does not use advertising cookies.

---

## 13. Changes to this policy

We may update this policy. Material changes will be announced in-app and/or on the website, and the
"Last updated" date will change. Continued use after an update means you accept the revised policy where
permitted by law; where consent is required, we will ask again.

---

## 14. Contact

- **Privacy / data requests:** [[privacy@tarf.app]]
- **General support:** [[support@tarf.app]]
- **Postal:** [[POSTAL ADDRESS, Kingdom of Saudi Arabia]]
- **KSA supervisory authority:** Saudi Data & AI Authority (**SDAIA**) — for PDPL complaints.

---

### Appendix A — Processor inventory (keep current)
| Processor | Purpose | Data categories | Policy |
|---|---|---|---|
| Google Firebase Authentication | Sign-in / identity | email, UID, provider id | policies.google.com/privacy |
| Google Cloud Firestore | Sync of settings, progress, todos, sessions | usage stats, todos, settings tied to UID | firebase.google.com/support/privacy |
| Firebase App Check | Anti-abuse attestation | attestation token | firebase.google.com/support/privacy |
| Firebase Remote Config | Kill/replace defective dhikr audio | config fetch (no personal data) | firebase.google.com/support/privacy |
| [[Moyasar / Tap / Stripe]] (website only) | Donation payments | card data (gateway only), confirmation | [[gateway policy URL]] |

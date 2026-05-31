# Tarf (طَرْف) — Account Deletion & Data Export

> Requirements + flow spec for the **in-app and web** account-deletion and data-export features. Both Apple
> ("Account deletion within the app") and Google Play ("provide a way to request deletion, in-app + a web URL")
> mandate this. The app code is under `app/` (owned by another dev) — this is the contract to implement against.

---

## 1. Why this is mandatory
- **Apple App Store Review Guideline 5.1.1(v):** any app that supports account creation **must** let the user
  **initiate account deletion from within the app** (a web link alone is not enough), and must delete the
  account + associated data (not merely deactivate).
- **Google Play:** apps with account creation must provide an **in-app** path to request deletion **and** a
  **publicly reachable web URL** to request account + data deletion, even without reinstalling. The web URL is
  entered in the Data Safety form.
- **GDPR Art. 17 / KSA PDPL / CCPA:** right to erasure + right to access/portability (export).

Guest mode creates **no account** and stores data **only locally**, so it needs no server deletion; uninstall
/ "clear local data" suffices, and we say so.

---

## 2. In-app deletion flow (required, all platforms)

**Location:** Settings → Account → **Delete my account** (clearly labelled, not buried). Mirror an Arabic-first
label «حذف الحساب».

1. **Entry.** User taps "Delete my account". If offline, show: "You need to be online to delete your account"
   (AR: «تحتاج اتصالًا بالإنترنت لحذف حسابك») and offer a graceful re-login route (the spec's "graceful re-login
   when a privileged online action fails offline").
2. **Explain consequences (screen).** Plain list of what will be permanently deleted:
   - account + sign-in, all settings, Insights/streaks, focus-session history, to-dos, daily progress;
   - state it is **irreversible**; offer **"Export my data first"** (see §4) as a one-tap detour.
3. **Re-authenticate.** Firebase requires a **recent login** to delete a user. Prompt the user to re-enter
   their password / re-run Google or Apple sign-in (`reauthenticateWithCredential`) to prove it's them.
4. **Confirm.** A confirm-gated action (type-to-confirm or a clear two-step button), never a single accidental tap.
5. **Delete server data, then auth record (order matters):**
   - Delete all Firestore documents under `/users/{uid}/**` (settings, dailyProgress/*, focusSessions/*,
     todos/*, and `/users/{uid}`). Prefer a **callable Cloud Function** (or batched recursive delete) so the
     server authoritatively removes everything even if the client dies mid-delete; do **not** rely on the client
     alone to clean every subcollection.
   - Delete the Firebase **Auth** user (`user.delete()` or Admin SDK from the function).
   - Wipe local Drift/cache + cached auth session on-device.
6. **Confirmation + sign-out.** Show "Your account and data have been deleted." (AR: «تم حذف حسابك وبياناتك».)
   Return to the Guest/onboarding screen. Optionally email a confirmation to the (now-deleted) address.
7. **Failure handling.** If the server delete partially fails, surface a retry and queue a server-side cleanup;
   never report success unless the auth record + all user docs are gone.

> **Implementation note for `app/` dev:** because recursive subcollection deletion is not atomic from the
> client, the recommended pattern is a **Cloud Function** `deleteAccount` that (a) recursively deletes
> `/users/{uid}`, then (b) deletes the Auth user via the Admin SDK, returning success only when both complete.

---

## 3. Web deletion request (required public URL)

Host a public page at **`[[https://tarf.app/delete-account]]`** (and `…/ar/delete-account`) for users who can't
open the app (lost device, uninstalled, etc.). It must be reachable **without** logging into the app and is the
URL entered in Play's Data Safety form. Options to offer:

- **Self-service:** "Sign in to delete" — the page authenticates with Firebase (Google/Apple/Email) and calls
  the same `deleteAccount` function. Preferred: fully automated, no human in the loop.
- **Request form / email fallback:** a form (or `delete@tarf.app`) collecting the account email; you verify
  ownership (e.g. a confirmation link to that email) before deleting. Document the SLA on the page:
  **deletion within [[30]] days, backups purged within [[90]] days.**

The page must clearly state **what** gets deleted and the **timeline**, matching the Privacy Policy.

---

## 4. Data export flow (required for portability)

**Location:** Settings → Account → **Export my data** (AR: «تصدير بياناتي»), plus available via the web page.

1. Gather the user's data from Firestore (settings, dailyProgress, focusSessions, todos, profile).
2. Produce a **machine-readable** file — JSON (full fidelity) and/or **CSV** (aligns with the spec's existing
   Insights CSV export). Include a small README describing fields.
3. Deliver via the platform share sheet / file save (mobile/desktop) or a download (web). For large exports, a
   Cloud Function can assemble and return a signed download link emailed to the user.
4. Export must be possible **before** deletion (offered inline in the deletion flow) and **independently** at any
   time. It contains only the requesting user's own data (enforced by `request.auth.uid == uid`).

---

## 5. Deletion-request checklist (run before each store submission)

- [ ] In-app **Delete my account** present in Settings → Account on **every** platform (iOS, Android, Windows,
      macOS, Web). (Apple specifically checks the iOS build.)
- [ ] Re-authentication step before deletion implemented (`reauthenticate*`).
- [ ] Server-side recursive delete of `/users/{uid}/**` + Auth user removal (Cloud Function recommended), verified
      end-to-end on a test account (confirm in Firebase console that **all** docs + the Auth user are gone).
- [ ] Local data + cached session wiped on-device after deletion.
- [ ] Offline attempt handled gracefully (clear message + re-login route; no false "success").
- [ ] **Export my data** present in-app (JSON/CSV) and works before deletion.
- [ ] Public **web deletion URL** live (`[[https://tarf.app/delete-account]]`), reachable without the app, states
      scope + timeline.
- [ ] Web URL entered in **Play Data Safety** form and consistent with the Privacy Policy.
- [ ] Retention timeline (server ≤ [[30]] days, backups ≤ [[90]] days) consistent across Privacy Policy, web page,
      and in-app copy.
- [ ] Guest-mode statement present: "Guest data is local only; uninstall or 'clear data' removes it; no account to
      delete." (AR: «بيانات الضيف محلية فقط؛ تُحذف بإلغاء التثبيت أو مسح البيانات».)
- [ ] Confirmation messaging (success/failure) localized AR + EN, RTL-correct.
- [ ] Donation records caveat noted: financial/tax records held by the gateway/our accounting are retained per KSA
      law and are **not** part of in-app account data (no card numbers stored by us).

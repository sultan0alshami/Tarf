# Firebase setup (owner action)

Tarf runs **fully offline in guest mode today** (all data in the local Drift
store). Cloud sync + sign-in require a Firebase project, which only you can
create with your account. This is a ~15-minute, one-time setup.

## 1. Create the project
1. <https://console.firebase.google.com> → **Add project** → name it `tarf`.
2. Disable Google Analytics for now (optional; adds disclosure obligations).

## 2. Enable Authentication
**Build → Authentication → Get started**, then enable:
- **Google** (provide a support email).
- **Apple** (required by App Store Guideline 4.8 because Google is offered; needs
  an Apple Developer account + a Services ID — see `docs/store/app-store.md`).
- **Email/Password**.

## 3. Create Firestore
**Build → Firestore Database → Create database** → **production mode** → pick the
region closest to your users (e.g. `me-central` for Saudi Arabia if available).

Then publish the rules from `app/firebase/firestore.rules`:
```bash
# with the Firebase CLI (npm i -g firebase-tools; firebase login)
firebase deploy --only firestore:rules --project tarf
```

## 4. Wire the Flutter app
Install FlutterFire and generate config (this creates `app/lib/firebase_options.dart`,
`android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist` —
all git-ignored):
```bash
dart pub global activate flutterfire_cli
cd app
flutterfire configure --project=tarf \
  --platforms=android,ios,macos,web,windows
```
Then add `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`,
`sign_in_with_apple`, `firebase_app_check` to `pubspec.yaml` and initialize in
`main.dart` (guarded so guest mode still works if config is absent).

## 5. App Check (free abuse protection)
**Build → App Check** → register the apps (Play Integrity / DeviceCheck /
reCAPTCHA for web). Enforce on Firestore once verified working.

## Data model (per user, `/users/{uid}`)
| Path | Contents |
|---|---|
| `settings/app` | eyecare, focus, notifications, appearance, prayer, account (single doc) |
| `dailyProgress/{yyyy-MM-dd}` | `{ tz, focusMinutes, sessions, breaksTaken, breaksSkipped }` — counters via `FieldValue.increment` |
| `focusSessions/{id}` | `{ startTs(serverTimestamp), endTs, workMin, breakMin, taskId?, reflection? }` |
| `todos/{id}` | `{ title, done, estimatedSessions, actualSessions, createdAt, updatedAt }` |

**Conflict-safety:** use `FieldValue.increment`/transactions for counters,
per-field updates (never whole-doc overwrites) for settings, and
`FieldValue.serverTimestamp()` for ordering. Each daily doc stores its timezone.

## Cost (Spark / free tier)
Spark = 50k reads / 20k writes / 1 GB per **day total across all users**. Keep
within it by: caching reads (Firestore offline persistence is on by default),
batching writes, preferring one-shot `get()` over live listeners where possible,
and using aggregate daily docs. Set a **budget alert** in Google Cloud Billing
and pre-plan the Blaze (pay-as-you-go) switch before you scale past a few
thousand active users.

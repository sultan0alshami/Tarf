# Firebase setup (owner action)

Tarf runs **fully offline in guest mode today** (all data in the local
`shared_preferences` JSON store, behind the `TarfRepository` seam). Cloud sync +
sign-in require a Firebase project, which only you can create with your account.
This is a ~15-minute, one-time setup.

> Phase 4 is fully buildable and testable WITHOUT this live project — see the
> **Local Emulator Suite** section below. The live project is only needed to ship
> real cloud sync to users.

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

## Local Emulator Suite (no live project needed for development/CI)

Everything in Phase 4 is buildable and testable WITHOUT creating the real
Firebase project. Use the emulators (project id `demo-tarf` — the `demo-`
prefix means no credentials are required).

> **Prerequisite: JDK 21+.** firebase-tools 15 runs the Firestore/Auth
> emulators on a bundled Java process that requires JDK **21 or newer**. If
> `firebase emulators:start` errors with *"no longer supports Java version
> before 21"*, install a JDK 21+ (e.g. Temurin 21) and point `JAVA_HOME` at it.
> The fast Dart unit tests below need NO Java and cover all sync/auth/merge
> logic via fakes.

### One-time tooling
```bash
npm i -g firebase-tools          # provides the emulators (needs JDK 21+ to run)
# (optional) rules tests deps:
cd app/firebase/rules-tests && npm install
```

### Start the emulators
```bash
cd app/firebase
firebase emulators:start --project=demo-tarf --only auth,firestore
# Auth: 127.0.0.1:9099 · Firestore: 127.0.0.1:8080 · UI: 127.0.0.1:4000
```

### Run the tests
```bash
# Fast Dart unit tests (no emulator, no Java) — fakes cover all sync/merge/auth
# logic; this is the local-first regression gate and must stay green:
cd app && flutter test

# Firestore security-rules tests (Node; boots its own emulator, needs JDK 21+):
cd app/firebase/rules-tests && npm test

# Flutter integration tests against the running emulators (needs JDK 21+):
cd app
flutter test integration_test/emulator -d chrome --dart-define=TARF_CLOUD=true

# Or one-shot (boots + tears down emulators around the run):
cd app/firebase
firebase emulators:exec --project=demo-tarf --only auth,firestore \
  "cd .. && flutter test integration_test/emulator -d chrome --dart-define=TARF_CLOUD=true"
```

### Enabling cloud in the app
- Cloud is OFF by default (`FirebaseFlags`). Sign-in buttons stay disabled
  ("Coming soon") until BOTH are true: built with `--dart-define=TARF_CLOUD=true`
  AND `firebase_options.dart` is generated (owner runs `flutterfire configure`).
- After `flutterfire configure`, set `configPresent = true` in `app/lib/main.dart`
  and wire the Firebase provider overrides (FirebaseAuthService,
  FirestoreCloudMirror, FirestoreCloudAccount) as shown in
  `app/integration_test/emulator/`.
- What the emulator CANNOT do: Google/Apple OAuth (need real client config) and
  App Check enforcement. Verify those manually on a real project before release;
  Email/Password is fully emulator-testable.

## Data model (per user, `/users/{uid}`)

Phase 4 ships a **blob-per-key** layout: each `StorageKey` JSON blob is mirrored
verbatim to one document at `users/{uid}/state/{key}`, wrapped in a last-write-
wins envelope `{ payload: <json>, updatedAt: <int millis> }`. This is why P1
(sound settings) and P3 (prayer location, saved timers) needed NO schema change.

| Path | Contents |
|---|---|
| `users/{uid}/state/settings` | app settings blob (`tarf.app_settings.v1`) |
| `users/{uid}/state/eyecareConfig` | eye-care + prayer config blob (`tarf.eyecare_config.v1`) |
| `users/{uid}/state/focusConfig` | focus config blob (`tarf.focus_config.v1`) |
| `users/{uid}/state/progress` | day-keyed progress map (`tarf.progress.v1`) — per-day MAX merge on sign-in |
| `users/{uid}/state/todos` | todos array (`tarf.todos.v1`) |
| `users/{uid}/state/alarms` | alarms array (`tarf.alarms.v1`) |
| `users/{uid}/state/timers` | saved-timers array (`tarf.saved_timers.v1`) |

### Earlier (pre-Phase-4) sketch — superseded by the blob layout above
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

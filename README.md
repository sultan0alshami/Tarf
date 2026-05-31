# Tarf — طَرْف

> *"the blink of an eye"* (طرفة عين) — a free, Arabic-first, offline-first,
> Apple-minimal wellness app whose core is the **activity-aware 20-20-20 eye
> break** fused with a calm **dhikr "repeat-after-me"** screen, surrounded by
> Focus (Pomodoro), Timer, Alarm, Stopwatch, Insights, and To-dos.

Free · donation-funded · **zero ads — and never anything commercial near sacred text**.
Targets: **Android · iOS · Windows · macOS · Web/PWA · Chrome extension** from one
Flutter codebase.

---

## Status at a glance

| Area | State |
|---|---|
| **Foundation** (theme, Arabic-first RTL i18n, routing shell, settings, local store) | ✅ Built, tested, web-verified |
| **Eye-care engine** (activity-aware precedence, active-time tracker) | ✅ Built, 15+ unit tests |
| **Dhikr break overlay** (20s ring, auto-fit Arabic, audio abstraction, sound-end=break-end) | ✅ Built, widget-tested |
| **Focus / Timer / Stopwatch** | ✅ Built, working, tested |
| **Chrome extension** (MV3, idle-gated alarms, notification + 20s Web-Audio break) | ✅ Built, loads unpacked, packaged |
| **Download website** (Arabic-first RTL, donate via Mada/Visa/MC gateway) | ✅ Built, verified |
| **Compliance pack + store guides** (App Store / Play / MS Store / Chrome) | ✅ Drafted |
| **CI** (GitHub Actions: analyze/test/build web+apk+windows, apple, extension) | ✅ Authored |
| **Project_Sprint skill** (`~/.claude/skills/Project_Sprint`) | ✅ Authored |
| **Cloud sync + auth** (Firebase/Firestore) | 🟡 Designed + rules + setup guide; **needs your Firebase project** (app runs offline/guest today) |
| **Native notifications / background audio / tray / prayer times** | 🟡 Specified; code/integration pending (mobile/desktop) |
| **Insights, To-dos, Alarm screens** | 🟡 Routed placeholders; controllers/UI pending |
| **iOS / macOS signed builds, store submission** | 🔴 Need a Mac + Apple Developer account (see `docs/store/`) |
| **Windows desktop build** | 🔴 Needs Developer Mode enabled (one toggle — see below) |
| **Bundled audio + dhikr scholarly sign-off** | 🔴 Owner-provided (synth tone ships in the extension; app uses an audio abstraction) |

✅ = built & verified here · 🟡 = ready/scaffolded, needs work or your config · 🔴 = blocked on your accounts/keys/toggle

---

## Repository layout

```
app/            Flutter app (lib/core, lib/features/*, lib/theme, lib/l10n, test/)
extension/      Chrome MV3 extension (service worker + offscreen audio + popup)
website/        Arabic-first static download + Support/Donate site (+ serverless donate fn)
docs/           specs/ · superpowers/plans/ · compliance/ · store/ · firebase-setup.md
.github/        CI workflows
_setup/         toolchain install scripts + logs
```

## Run & build (from `app/`)

```bash
flutter pub get
flutter analyze            # clean
flutter test               # 41 tests passing
flutter run -d chrome      # live web dev
flutter build web --no-web-resources-cdn   # -> build/web (PWA)
flutter build apk --debug                  # Android (SDK installed)
flutter build windows                      # needs Windows Developer Mode (below)
```

**Windows desktop build** needs Developer Mode (for plugin symlinks). One time,
in an **Administrator** PowerShell:
```
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"
```
(or Settings → Privacy & security → For developers → Developer Mode → On).

**Chrome extension:** `chrome://extensions` → Developer mode → **Load unpacked**
→ select `extension/`. Run `pwsh extension/package.ps1` to produce the Web-Store zip.

**Website:** any static server, or `vercel dev` for the donate function. See
`website/README.md`.

## What you must do to ship

1. **Windows builds** → enable Developer Mode (above).
2. **Cloud sync** → create a Firebase project and run `flutterfire configure`
   (15 min) — see [`docs/firebase-setup.md`](docs/firebase-setup.md). Until then
   the app works fully in **guest/offline** mode.
3. **iOS/macOS** → a Mac + Apple Developer Program ($99/yr); CI is ready in
   `.github/workflows/build-apple.yml` (add signing secrets). See `docs/store/app-store.md`.
4. **Store accounts** → Apple ($99), Google Play ($25), Microsoft (~$19),
   Chrome Web Store ($5). Step-by-step guides in `docs/store/`.
5. **Donations** → insert your Mada/Visa/Mastercard gateway keys (Moyasar/Tap/
   Stripe) per `website/README.md`.
6. **Dhikr content** → obtain a named scholarly/editorial sign-off on the bundled
   adhkar (`app/assets/dhikr/dhikr.json`) before public release.
7. **Audio** → optionally commission/clear CC0 recitation clips and record them
   in the asset provenance ledger (the extension already ships a synthesized,
   license-free 20s sound).

## Architecture highlights

- **Offline-first:** the eye-care + dhikr core reads from a local store and works
  with zero network — even guest, even airplane-mode first launch.
- **Activity-aware:** breaks fire on *accumulated active time*, pause on idle,
  reset after long absence — the #1 thing competitors get wrong.
- **Pure precedence state machine:** one deterministic, fully-tested function
  decides whether a break fires (pause/snooze/working-hours/prayer/idle/media/
  pomodoro/DND).
- **Sound-end = break-end:** audio is played by the app/extension audio layer
  (never the notification sound), for exactly the break duration.
- **One IA, three chromes:** identical destinations on mobile bottom-bar, desktop
  rail, and the extension popup.

## Documents

- Design spec → [`docs/specs/2026-05-31-tarf-design.md`](docs/specs/2026-05-31-tarf-design.md)
- Implementation plan → [`docs/superpowers/plans/2026-05-31-tarf-implementation-plan.md`](docs/superpowers/plans/2026-05-31-tarf-implementation-plan.md)
- Firebase setup → [`docs/firebase-setup.md`](docs/firebase-setup.md)
- Compliance & stores → [`docs/compliance/`](docs/compliance/), [`docs/store/`](docs/store/)

## License

App code: MIT (proposed). Fonts: Inter & Amiri under SIL OFL. Sacred text is
treated as immutable and is not the property of this project. See
`website/licenses.html` and the asset provenance ledger.

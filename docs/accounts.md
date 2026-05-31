# Accounts to create (to ship Tarf)

Ordered by how soon you need them. Costs as of 2026 — verify current pricing.

## Already done
- ✅ **GitHub** — `github.com/sultan0alshami/Tarf` (code is pushed).

## Core backend (needed for sign-in + cloud sync)
| Account | Cost | Why | Notes |
|---|---|---|---|
| **Firebase / Google Cloud** | Free (Spark) → Blaze pay-as-you-go later | Auth (Google/Apple/Email) + Firestore offline sync | One Google account. Set a billing **budget alert** before enabling Blaze. See `docs/firebase-setup.md`. |
| **Apple Developer Program** | **$99 / year** | Required for **Sign in with Apple** (a Firebase auth provider) — even if you delay the iOS app. Also iOS/macOS builds + notarization. | Needs an Apple ID + (for a company) a D-U-N-S number; individual is fine. Create a **Services ID** + key for Sign in with Apple. |

## Donations (Mada / Visa / Mastercard)
| Account | Cost | Why | Notes |
|---|---|---|---|
| **Payment gateway** — Moyasar (recommended) or Tap | Per-transaction fee; no/low monthly | Process Mada + Visa + Mastercard on the website Support page | **Requires a Saudi commercial registration (CR) or freelance/professional license** to onboard. Moyasar & Tap are KSA-native and support Mada. Stripe works internationally but Mada support is limited. |
| **Domain name** (e.g. `tarf.app`) | ~$10–20 / year | Stores require a **hosted privacy-policy URL**; also your download + donate site | Any registrar (Namecheap, Cloudflare, GoDaddy). |
| **Website host** — Vercel or Netlify | Free tier | Host the static site + the `/api/donate` serverless function | Vercel pairs well with the included `website/vercel.json`. |

## App stores (create when you're ready to publish each platform)
| Account | Cost | Platform |
|---|---|---|
| **Google Play Console** | **$25 one-time** | Android (AAB). Also a closed-testing requirement (12 testers / 14 days) for new personal developer accounts. |
| **Apple Developer Program** | (the $99/yr above) | iOS + macOS App Store. Needs a **Mac** for the final signed/notarized build. |
| **Microsoft Partner Center** | **~$19 one-time** (individual) | Windows (MSIX) via the Microsoft Store. |
| **Chrome Web Store** developer | **$5 one-time** | The Chrome extension. |

## Optional / later
- **Windows code-signing certificate** (OV/EV, recurring) — only if you distribute the `.exe`/MSIX *outside* the Microsoft Store and want to avoid SmartScreen warnings. The Store signs for you.
- **Google Cloud billing** — only when you outgrow Firebase Spark (see the cost plan in `docs/firebase-setup.md`).

## Minimum to launch, per platform
- **Web/PWA + Chrome extension:** domain + host + Chrome Web Store ($5). (No Apple/Google/MS needed.)
- **Android:** + Google Play ($25) + Firebase.
- **iOS/macOS:** + Apple Developer ($99/yr) + a Mac.
- **Windows:** + Microsoft Partner Center (~$19).
- **Donations live:** + payment gateway (needs your CR/freelance license) + domain + host.

**Cheapest first milestone:** ship the **Web app + Chrome extension** (domain + free host + $5 Chrome dev), with Firebase free tier for sync — then add the native stores as you go.

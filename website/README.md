# Tarf (طَرْف) — Website

The public **download + Support/Donate** site for Tarf: a free, donation-funded,
Arabic-first, offline-first wellness app whose core is the activity-aware
20-20-20 eye break fused with a calm dhikr "repeat-after-me" screen.

This is a **static site** (plain HTML/CSS/vanilla JS — no build step) plus a
single serverless function for donations. It hosts anywhere.

- **Arabic-first:** every page loads in Arabic, right-to-left (`dir="rtl"`), with
  a one-tap **EN** toggle in the nav. The choice is remembered in `localStorage`.
- **Apple-minimal design system:** near-monochrome + one teal-green accent
  (`#0E7C66`), generous whitespace, light/dark via `prefers-color-scheme`.

---

## Contents

```
website/
  index.html        Landing page (hero, 20-20-20 story, features, CTAs)
  download.html     Store/PWA/extension cards (placeholders + "coming soon")
  support.html      Donation page → POSTs to /api/donate
  privacy.html      Privacy policy (offline-first, religion-as-sensitive-data)
  terms.html        Terms of use
  licenses.html     Fonts (Inter/Amiri OFL) + audio provenance table
  assets/
    styles.css      Design system (teal-green, light/dark, responsive, RTL-aware)
    i18n.js         Vanilla-JS AR/EN toggle + all visible copy (ar + en)
    logo.svg        Brand mark
  api/
    donate.js       Serverless donation endpoint (pluggable payment gateway)
  vercel.json       Routes /api/donate to the function (for Vercel)
```

---

## Run locally

It's a static site, so any static server works. The donation endpoint only runs
under a serverless host (Vercel/Netlify) or `vercel dev`.

### Plain static preview (UI, i18n, design)

Pick one:

```bash
# Python (already on most machines)
cd website
python -m http.server 8080
# -> http://localhost:8080

# Node
npx serve website

# PHP
php -S localhost:8080 -t website
```

The donation form will POST to `/api/donate`. Under a plain static server that
route doesn't exist, so you'll see the network-error message — that's expected.
To exercise the full donate flow locally, use `vercel dev` (below).

### Full local run incl. the donate function

```bash
npm i -g vercel
cd website
vercel dev
# -> http://localhost:3000  (serves the static pages AND /api/donate)
```

With **no gateway keys set**, `/api/donate` runs in **TEST MODE**: it returns a
synthetic sandbox redirect and makes **no real charge**. The page shows a
"test mode" notice, then redirects so you can see the complete flow.

---

## Deploy

### Vercel (recommended — static pages + the function, zero config)

```bash
cd website
vercel            # preview
vercel --prod     # production
```

`vercel.json` maps `/api/donate` to `api/donate.js`. Everything else is served
as static files.

### Netlify

Static files deploy as-is. For the donate endpoint, either:

1. Move `api/donate.js` to `netlify/functions/donate.js` and adapt the export to
   Netlify's `exports.handler = async (event) => {...}` signature (parse
   `event.body`, return `{ statusCode, body }`), **or**
2. Add a redirect so `/api/donate` points at your function:
   ```
   # netlify.toml
   [build]
     publish = "."
   [[redirects]]
     from = "/api/donate"
     to = "/.netlify/functions/donate"
     status = 200
   ```

### Any other static host (GitHub Pages, S3, Cloudflare Pages, nginx…)

The HTML/CSS/JS pages work anywhere. Host the donation function separately
(Cloudflare Worker, a small Node server, etc.) and update the `fetch("/api/donate")`
URL in `support.html` to point at it.

---

## Payment gateway env keys

The donation function (`api/donate.js`) uses a **pluggable `PaymentGateway`**
abstraction. **Moyasar** is the primary (Mada-capable, KSA); **Tap** and
**Stripe** are provided with the same interface.

PCI: card data **never** touches this code. The function asks the gateway to
create a payment and returns the gateway's **hosted/redirect URL**; the donor
enters their card on the gateway's own PCI-compliant page.

Set these in your host's dashboard (Vercel: Project → Settings → Environment
Variables; Netlify: Site settings → Environment):

| Variable | Purpose |
|---|---|
| `PAYMENT_GATEWAY` | `moyasar` (default), `tap`, `stripe`, or `stub` |
| `SITE_URL` | e.g. `https://tarf.app` — used to build the post-payment callback URL |
| `MOYASAR_SECRET_KEY` | Moyasar secret key — `sk_test_…` (sandbox) or `sk_live_…` (live). Dashboard → Settings → API keys. |
| `TAP_SECRET_KEY` | Tap secret key (if `PAYMENT_GATEWAY=tap`). |
| `STRIPE_SECRET_KEY` | Stripe secret key (if `PAYMENT_GATEWAY=stripe`). Note: Stripe does **not** support Mada — Visa/Mastercard fallback only. |
| `PAYMENT_GATEWAY=stub` | Offline stub — no keys needed, no network, always TEST MODE. Use for CI and local demo. |

**Where the owner inserts merchant keys:** you do **not** edit `donate.js` —
just set the environment variables above. The file reads them via
`process.env.*`. If the selected gateway has no key, the function automatically
runs in **TEST MODE** (no real charge) so the site can deploy immediately.

### Going live with Moyasar (primary path)

1. Create a Moyasar account → enable **Mada**, Visa, Mastercard on the merchant.
2. Copy your **live** secret key (`sk_live_…`).
3. Set `MOYASAR_SECRET_KEY=sk_live_…`, `PAYMENT_GATEWAY=moyasar`,
   `SITE_URL=https://your-domain`.
4. Redeploy. Test with a small real donation, then refund it from the dashboard.

> Verify current Moyasar/Tap API field names against their live docs before the
> first production charge — the Tap and Stripe paths are stubs you should confirm.

---

## Wire the real store / APK links

All download links in `download.html` are `href="#"` placeholders carrying a
"coming soon" badge and `aria-disabled="true"`. When a build is published:

1. Open `website/download.html`.
2. Find the relevant `<article class="store-card">` and replace `href="#"` with
   the real URL (App Store, Google Play, Microsoft Store, your hosted PWA, or the
   Chrome Web Store listing).
3. Remove that card's `<span class="badge-soon" …>` line and the
   `aria-disabled="true"` attribute on its button.

For the **direct APK**, drop the signed `.apk` into `website/` (or a CDN) and
point the APK card's link at it.

---

## Editing copy / translations

All visible text lives in `assets/i18n.js` under the `STRINGS.ar` and
`STRINGS.en` tables, keyed by `data-i18n="…"` attributes in the HTML. To change
copy, edit both language entries for that key. Arabic is the default; English is
the secondary. The toggle sets `<html lang>` + `<html dir>` and persists to
`localStorage` under `tarf-lang`.

Translations are injected via `textContent` only (never `innerHTML`), so copy
can never inject markup — XSS-safe by construction.

---

## Running the test suite

```bash
npm test          # node --test test/  (donate + webhook + static-guard suites)
npm run lint      # node --check on all four api files
npm run build     # no-op (static site)
```

All tests use `node:test`/`node:assert`/`node:crypto` — **no npm runtime deps**
and **no env vars required**. The full suite runs offline.

### Stub gateway (offline TEST MODE)

To run the donation flow with no real keys set `PAYMENT_GATEWAY=stub`:

```bash
PAYMENT_GATEWAY=stub vercel dev
```

The `stub` adapter is always "configured" (`isConfigured() → true`), makes no
network calls, and returns a synthetic `testMode=1&gateway=stub` redirect. Use it
for CI and local demo. Keys for `moyasar`/`tap`/`stripe` are only needed for
production charges.

---

## Webhook env keys

`api/webhook.js` verifies the gateway's HMAC callback signature. The owner sets
one variable per gateway (never committed — use the Vercel environment dashboard):

| Variable | Purpose |
|---|---|
| `MOYASAR_WEBHOOK_SECRET` | Moyasar webhook signing secret. Dashboard → Settings → Webhooks. |
| `TAP_WEBHOOK_SECRET` | Tap webhook signing secret. |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret (`whsec_…`). |

With **no webhook secret set**, the route accepts in **TEST MODE** — safe until
the owner adds the secret. Once set, every callback is verified via a
constant-time HMAC-SHA256 compare; unverified requests receive `400`.

---

## Notes for reviewers / compliance

- **No raw card fields** anywhere on the site — payment is redirect/hosted-fields
  via the gateway (PCI handled by the provider).
- **iOS**: per Apple policy, the iOS app shows only a thank-you/share — no
  donation link. This website is where non-iOS users donate.
- **No ads, no trackers** are present; nothing commercial sits beside sacred text.

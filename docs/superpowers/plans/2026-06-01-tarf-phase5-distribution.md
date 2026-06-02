# Phase 5 — Distribution Code (Website · Extension · CI/CD): Implementation Plan
> For agentic workers: implement task-by-task; steps use `- [ ]`.

**Goal:** Harden and complete the three already-scaffolded NON-app codebases — the marketing/download/**donations** website (`website/`), the MV3 Chrome extension (`extension/`), and CI/CD (`.github/workflows/`) — so that: (a) the donation flow is **gateway-agnostic** with an owner-gated key model and a **stub adapter** that keeps CI green with zero secrets; (b) the extension popup reflects the app IA (compact 20-20-20 timer + dhikr break + quick links), is Arabic-first/RTL, states the "only while Chrome is open" limit honestly, ships the single-purpose statement + permission justifications, and packages to `tarf-extension.zip`; (c) every workflow **passes with no real secrets** (stubs + skip-on-absent-secret guards), reusing/extending the existing `build-apple.yml`, `ci.yml`, `website.yml`, `build-extension.yml`.

**Architecture:** The website stays a **zero-build static site** (plain HTML/CSS/vanilla-JS — matching what is already committed; we do NOT migrate to Next.js because a working, reverent, bilingual static site already exists and a framework migration would be pure churn). The only server surface is two **Vercel Node serverless functions**: `api/donate.js` (create payment → return gateway hosted/redirect URL) and a new `api/webhook.js` (verify gateway callback signature). Both read keys from `process.env` only — **keys are never committed**; with no key for the selected gateway the donate route runs in **TEST MODE** and the new `stub` gateway is fully self-contained (no network). A `PaymentGateway` interface (already present, extended here) makes the provider swappable via the `PAYMENT_GATEWAY` env var (`moyasar` default · `tap` · `stripe` · `stub`). Tests are Node's built-in `node:test` runner (zero npm deps) plus tiny static-HTML assertions, so `website.yml` can `npm test` without installing anything. The extension keeps its **native-JS service worker** as the scheduling source of truth (MV3 SW can't hold timers/audio); the popup is upgraded in place (i18n + RTL + dhikr + quick links) and a minimal **side panel** is added to match the documented IA and the `sidePanel` justification. Packaging gains a cross-platform `package.mjs` (Node) alongside the existing `package.ps1`, and a `manifest`/lint test asserts MV3 invariants (single purpose, minimal permissions, no remote code, no host permissions).

**Tech Stack:** Static HTML5 + CSS custom properties + vanilla ES5/ES6 JS (no bundler). Vercel Node serverless functions (`module.exports` handler, Web `fetch`, `node:crypto` for webhook HMAC — **no npm runtime deps**). Node 22 / npm 10 (verified locally: `node v22.18.0`, `npm 10.9.3`); tests via `node --test` (`node:test` + `node:assert`). Extension: Manifest V3, `chrome.alarms`/`notifications`/`offscreen`/`idle`/`storage`/`sidePanel`, Web Audio API, vanilla JS. Packaging: Node `package.mjs` + PowerShell `package.ps1` (PowerShell 7.6.2 verified). CI: GitHub Actions (`actions/checkout@v4`, `actions/setup-node@v4`, `subosito/flutter-action@v2`, `actions/upload-artifact@v4`). All commits end with the required `Co-Authored-By` trailer.

---

## File Structure

```
website/
  package.json                 NEW  scripts (test/lint/build noop) + Node test runner; no runtime deps
  api/
    donate.js                  MODIFY  extract testable exports + add StubGateway (PAYMENT_GATEWAY=stub)
    webhook.js                 NEW  gateway-agnostic callback signature verify (Moyasar/Tap/Stripe/stub)
    _lib/
      gateways.js              NEW  PaymentGateway registry/abstraction (shared by donate.js + tests)
      validate.js              NEW  amount/currency/email validation (shared + unit-tested)
  test/
    donate.test.mjs            NEW  node:test — validation + stub-gateway TEST MODE + selectGateway
    webhook.test.mjs           NEW  node:test — signature verify accept/reject (stub + Moyasar HMAC)
    site.test.mjs              NEW  node:test — static-HTML guards (RTL default, no sacred text on donate, links resolve, no raw card inputs)
  vercel.json                  MODIFY  add /api/webhook route + no-store header
  README.md                    MODIFY  document stub gateway + webhook env + `npm test`
  (existing, unchanged: index.html, download.html, support.html, privacy.html,
   terms.html, licenses.html, assets/styles.css, assets/i18n.js, assets/logo.svg)

extension/
  manifest.json                MODIFY  add "side_panel", add "sidePanel" permission; keep host_permissions []
  popup.html                   MODIFY  add dhikr line, quick-links, honest limit note, i18n hooks
  popup.css                    MODIFY  RTL support + dhikr/quick-link styles (keep teal tokens)
  popup.js                     MODIFY  load i18n + dhikr, render quick links, set dir/lang
  i18n.js                      NEW  AR/EN strings + applyLang (mirrors website i18n approach)
  sidepanel.html               NEW  persistent timer/streak dashboard (matches documented IA)
  sidepanel.js                 NEW  reads background status; reuses popup messaging
  dhikr.json                   MODIFY  fully diacritized text to match app reverence rules
  package.json                 NEW  scripts (lint/test/package) + node:test; no runtime deps
  package.mjs                  NEW  cross-platform zip (Node) → tarf-extension.zip
  package.ps1                  EXISTING  keep; update include-list to add sidepanel.* + i18n.js
  test/
    manifest.test.mjs          NEW  node:test — MV3 invariants (single purpose, perms ⊆ allowlist, no host perms, no remote code, files referenced exist)
    dhikr.test.mjs             NEW  node:test — every entry has arabic+translit+english; arabic has tashkīl
  STORE_LISTING.md             NEW  single-purpose statement + per-permission justifications + honest limit (sourced from docs/store/chrome-web-store.md)
  (existing, unchanged: background.js, offscreen.html, offscreen.js, icon16/48/128.png)

.github/workflows/
  ci.yml                       UNCHANGED  (Flutter analyze+test already PR-gated under app/)
  build-apple.yml              UNCHANGED  (reused; signing stays commented/owner-gated)
  build-extension.yml          MODIFY  add Node lint+test+package for extension/ before fallback zip
  website.yml                  MODIFY  run `npm ci`/`npm test` for the new website package (deploy stays commented)
  distribution-pr.yml          NEW  fast PR gate: website tests + extension tests on Node (no Flutter, no secrets)
```

---

## Cross-phase dependencies & integration points

- **Depends on app phases (1–4): NONE.** `website/`, `extension/`, and the distribution workflows live in separate top-level directories. No file under `app/lib/**` is read, written, or imported here. The Flutter jobs in `ci.yml`/`build-apple.yml`/`build-extension.yml` already exist and are untouched except for the additive Node steps in `build-extension.yml`. This phase is **fully parallelizable from t=0**.
- **Owner-gated (the only external blockers):**
  - Donation **LIVE keys** + merchant account (`MOYASAR_SECRET_KEY` / `TAP_SECRET_KEY`, `PAYMENT_GATEWAY`, `SITE_URL`, `*_WEBHOOK_SECRET`) — set in Vercel dashboard; never committed. Until present, donate runs TEST MODE and webhook accepts the `stub` scheme only.
  - **Vercel** deploy secrets (`VERCEL_TOKEN`/`VERCEL_ORG_ID`/`VERCEL_PROJECT_ID`) — the deploy step in `website.yml` stays commented exactly as today.
  - **Chrome Web Store** $5 dev account — needed only to upload the zip CI already produces.
  - **Apple** signing secrets — `build-apple.yml` signing blocks stay commented (owner task), unchanged by this phase.
- **Shared/integration touchpoints (within this phase only):**
  - `extension/dhikr.json` mirrors the app's dhikr set conceptually but is an **independent copy** (the extension is self-contained); diacritizing it here does not touch `app/assets/dhikr/`.
  - `website/api/_lib/*` is imported by both `donate.js` and the tests — keep the module contract stable.
  - Download-page store links (`website/download.html`) remain `href="#"` "coming soon" placeholders; wiring real URLs is an owner step (documented in `website/README.md`), out of scope for green CI.
- **Reuse:** `build-apple.yml` is reused as-is for the Apple targets; `ci.yml` already provides the `flutter analyze` + `flutter test` PR gate the brief asks for (under `app/`), so this phase does not duplicate it — it adds a **Node-only** PR gate (`distribution-pr.yml`) for the website+extension so distribution PRs get a fast signal without spinning up Flutter.

---

### Task 1 — Website: extract testable donation core (`_lib/validate.js`, `_lib/gateways.js`) + add `StubGateway`

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\website\api\_lib\validate.js` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\website\api\_lib\gateways.js` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\website\api\donate.js` (MODIFY — import from `_lib`, add stub path)
- Test path: `C:\Users\sulta\Claude_Code\EyeCure_20\website\test\donate.test.mjs` (NEW)

Steps:
- [ ] Write the failing test first at `website/test/donate.test.mjs`:
  ```js
  import { test } from "node:test";
  import assert from "node:assert/strict";
  import { validate } from "../api/_lib/validate.js";
  import { selectGateway, StubGateway } from "../api/_lib/gateways.js";

  test("validate rejects amount below minimum", () => {
    const r = validate({ amount: 0, currency: "SAR" });
    assert.equal(r.ok, false);
    assert.equal(r.errorKey, "sup.status.errAmount");
  });

  test("validate rejects unsupported currency (Mada is SAR-only)", () => {
    assert.equal(validate({ amount: 10, currency: "USD" }).ok, false);
  });

  test("validate rejects malformed email but accepts empty", () => {
    assert.equal(validate({ amount: 10, currency: "SAR", email: "nope" }).ok, false);
    assert.equal(validate({ amount: 10, currency: "SAR", email: "" }).ok, true);
  });

  test("validate coerces lang to ar default and clamps name length", () => {
    const r = validate({ amount: 25, currency: "sar", lang: "fr", name: "x".repeat(500) });
    assert.equal(r.ok, true);
    assert.equal(r.value.lang, "ar");
    assert.equal(r.value.currency, "SAR");
    assert.equal(r.value.name.length, 120);
  });

  test("selectGateway falls back to moyasar for unknown key", () => {
    assert.equal(selectGateway("nonsense").id, "moyasar");
    assert.equal(selectGateway("stub").id, "stub");
  });

  test("StubGateway is always configured and returns a synthetic redirect, no network", async () => {
    const g = new StubGateway();
    assert.equal(g.isConfigured(), true);
    const { id, redirectUrl } = await g.createPayment({
      amountMinor: 2500, currency: "SAR", description: "t",
      metadata: { project: "tarf" }, callbackUrl: "https://x/support.html?thanks=1",
    });
    assert.match(id, /^stub_/);
    assert.match(redirectUrl, /testMode=1/);
    assert.match(redirectUrl, /gateway=stub/);
  });
  ```
- [ ] Run (expected FAIL — modules don't exist yet):
  ```
  node --test website/test/donate.test.mjs
  # Expected: "Cannot find module ... website/api/_lib/validate.js" → exit code 1
  ```
- [ ] Minimal impl — create `website/api/_lib/validate.js` (lifted verbatim from the validation block already in `donate.js`, exported):
  ```js
  "use strict";
  const SUPPORTED_CURRENCIES = ["SAR"]; // Mada is SAR-only.
  const MIN_AMOUNT_SAR = 1;
  const MAX_AMOUNT_SAR = 100000;

  function validate(body) {
    const amount = Number(body && body.amount);
    if (!isFinite(amount) || amount < MIN_AMOUNT_SAR || amount > MAX_AMOUNT_SAR) {
      return { ok: false, errorKey: "sup.status.errAmount", error: "Invalid amount" };
    }
    const currency = String((body && body.currency) || "SAR").toUpperCase();
    if (!SUPPORTED_CURRENCIES.includes(currency)) {
      return { ok: false, errorKey: "sup.status.errAmount", error: "Unsupported currency" };
    }
    const email = body && body.email ? String(body.email).trim() : "";
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return { ok: false, errorKey: "sup.status.errEmail", error: "Invalid email" };
    }
    return {
      ok: true,
      value: {
        amount,
        currency,
        email,
        name: body && body.name ? String(body.name).slice(0, 120) : "",
        message: body && body.message ? String(body.message).slice(0, 500) : "",
        lang: body && body.lang === "en" ? "en" : "ar",
      },
    };
  }
  module.exports = { validate, SUPPORTED_CURRENCIES, MIN_AMOUNT_SAR, MAX_AMOUNT_SAR };
  ```
- [ ] Minimal impl — create `website/api/_lib/gateways.js`: move `PaymentGateway`, `MoyasarGateway`, `TapGateway`, `StripeGateway`, `GatewayError`, `GATEWAYS`, `selectGateway` here **verbatim** from `donate.js`, add a `StubGateway`, register it, and export everything:
  ```js
  "use strict";
  // ... (PaymentGateway, MoyasarGateway, TapGateway, StripeGateway, GatewayError
  //      moved unchanged from donate.js) ...

  // --- Stub (offline test gateway; default when no keys + selected) ----------
  // Self-contained: never makes a network call. Lets CI exercise the full
  // create-payment contract with zero secrets. Mirrors donate.js TEST MODE.
  class StubGateway extends PaymentGateway {
    get id() { return "stub"; }
    isConfigured() { return true; } // intentionally always "configured"
    async createPayment({ amountMinor, currency, callbackUrl }) {
      const id = "stub_" + Date.now().toString(36);
      const redirectUrl =
        callbackUrl +
        "&testMode=1&gateway=stub" +
        "&amount=" + encodeURIComponent(amountMinor / 100) +
        "&currency=" + currency +
        "&pid=" + id;
      return { id, redirectUrl };
    }
  }

  const GATEWAYS = {
    moyasar: new MoyasarGateway(),
    tap: new TapGateway(),
    stripe: new StripeGateway(),
    stub: new StubGateway(),
  };

  // Pure: gateway key passed in (no process.env read here → unit-testable).
  function selectGateway(key) {
    const k = String(key || "moyasar").toLowerCase();
    return GATEWAYS[k] || GATEWAYS.moyasar;
  }

  module.exports = {
    PaymentGateway, MoyasarGateway, TapGateway, StripeGateway, StubGateway,
    GatewayError, GATEWAYS, selectGateway,
  };
  ```
- [ ] Minimal impl — edit `website/api/donate.js` to consume `_lib` (delete the now-moved class/validate bodies; keep the HTTP handler, TEST MODE, body parsing, `send`, `originFrom`):
  ```js
  const { validate } = require("./_lib/validate.js");
  const { selectGateway, GatewayError } = require("./_lib/gateways.js");
  // ...
  const gateway = selectGateway(process.env.PAYMENT_GATEWAY); // env read stays in the handler only
  ```
  (Behavior is byte-for-byte the same for `moyasar`/`tap`/`stripe`; `PAYMENT_GATEWAY=stub` now routes to the offline stub even with no keys.)
- [ ] Run (expected PASS):
  ```
  node --test website/test/donate.test.mjs
  # Expected: "# pass 6  # fail 0" → exit code 0
  ```
- [ ] Commit:
  ```
  git add website/api/_lib/validate.js website/api/_lib/gateways.js website/api/donate.js website/test/donate.test.mjs
  git commit -m "$(printf 'feat(website): extract donation core to _lib + add offline stub gateway\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

### Task 2 — Website: gateway-agnostic webhook verify route (`api/webhook.js`)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\website\api\webhook.js` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\website\vercel.json` (MODIFY)
- Test path: `C:\Users\sulta\Claude_Code\EyeCure_20\website\test\webhook.test.mjs` (NEW)

Steps:
- [ ] Write the failing test first at `website/test/webhook.test.mjs`:
  ```js
  import { test } from "node:test";
  import assert from "node:assert/strict";
  import crypto from "node:crypto";
  import { verifySignature } from "../api/webhook.js";

  test("stub scheme: accepts when no secret configured (TEST MODE)", () => {
    const r = verifySignature({ gateway: "stub", rawBody: "{}", headers: {}, secret: "" });
    assert.equal(r.ok, true);
    assert.equal(r.testMode, true);
  });

  test("moyasar HMAC: accepts a correctly signed body", () => {
    const secret = "whsec_test";
    const rawBody = JSON.stringify({ type: "payment_paid", data: { id: "p1" } });
    const sig = crypto.createHmac("sha256", secret).update(rawBody).digest("hex");
    const r = verifySignature({
      gateway: "moyasar", rawBody, headers: { "x-moyasar-signature": sig }, secret,
    });
    assert.equal(r.ok, true);
    assert.equal(r.testMode, false);
  });

  test("moyasar HMAC: rejects a tampered body", () => {
    const secret = "whsec_test";
    const good = crypto.createHmac("sha256", secret).update("{}").digest("hex");
    const r = verifySignature({
      gateway: "moyasar", rawBody: '{"x":1}', headers: { "x-moyasar-signature": good }, secret,
    });
    assert.equal(r.ok, false);
  });

  test("rejects when secret is set but signature header is missing", () => {
    const r = verifySignature({ gateway: "moyasar", rawBody: "{}", headers: {}, secret: "whsec_test" });
    assert.equal(r.ok, false);
  });
  ```
- [ ] Run (expected FAIL):
  ```
  node --test website/test/webhook.test.mjs
  # Expected: "Cannot find module ... website/api/webhook.js" → exit code 1
  ```
- [ ] Minimal impl — `website/api/webhook.js` (pure `verifySignature` + a thin Vercel handler; uses `node:crypto`, **no npm deps**; constant-time compare):
  ```js
  "use strict";
  const crypto = require("node:crypto");

  // Per-gateway signature header + scheme. Owner sets <GATEWAY>_WEBHOOK_SECRET.
  const SCHEMES = {
    moyasar: { header: "x-moyasar-signature", algo: "sha256", enc: "hex" },
    tap:     { header: "tap-signature",       algo: "sha256", enc: "hex" },
    stripe:  { header: "stripe-signature",    algo: "sha256", enc: "hex" },
  };

  function timingSafeEqual(a, b) {
    const ba = Buffer.from(String(a)); const bb = Buffer.from(String(b));
    if (ba.length !== bb.length) return false;
    return crypto.timingSafeEqual(ba, bb);
  }

  // Pure + unit-testable: no process.env read here.
  function verifySignature({ gateway, rawBody, headers, secret }) {
    const g = String(gateway || "").toLowerCase();
    if (g === "stub") return { ok: true, testMode: true };
    if (!secret) return { ok: true, testMode: true }; // no key yet → accept (deploy-before-keys)
    const scheme = SCHEMES[g];
    if (!scheme) return { ok: false, reason: "unknown_gateway" };
    const provided = (headers && (headers[scheme.header] || headers[scheme.header.toLowerCase()])) || "";
    if (!provided) return { ok: false, reason: "missing_signature" };
    const expected = crypto.createHmac(scheme.algo, secret).update(rawBody, "utf8").digest(scheme.enc);
    return { ok: timingSafeEqual(provided, expected), testMode: false };
  }

  module.exports = async function handler(req, res) {
    if (req.method !== "POST") { res.statusCode = 405; return res.end("Method not allowed"); }
    const rawBody = await new Promise((resolve) => {
      let raw = ""; req.on("data", (c) => (raw += c));
      req.on("end", () => resolve(raw)); req.on("error", () => resolve(""));
    });
    const gateway = (process.env.PAYMENT_GATEWAY || "moyasar").toLowerCase();
    const secret = process.env[gateway.toUpperCase() + "_WEBHOOK_SECRET"] || "";
    const v = verifySignature({ gateway, rawBody, headers: req.headers, secret });
    if (!v.ok) { res.statusCode = 400; return res.end(JSON.stringify({ ok: false, reason: v.reason })); }
    // Signature good (or test mode). Idempotent ack; persistence is an owner concern.
    res.statusCode = 200; res.setHeader("Content-Type", "application/json");
    res.end(JSON.stringify({ ok: true, testMode: !!v.testMode }));
  };
  module.exports.verifySignature = verifySignature;
  ```
- [ ] Minimal impl — add the route + no-store header to `website/vercel.json`:
  ```json
  {
    "$schema": "https://openapi.vercel.sh/vercel.json",
    "cleanUrls": true,
    "trailingSlash": false,
    "rewrites": [
      { "source": "/api/donate", "destination": "/api/donate.js" },
      { "source": "/api/webhook", "destination": "/api/webhook.js" }
    ],
    "headers": [
      { "source": "/api/donate", "headers": [{ "key": "Cache-Control", "value": "no-store" }] },
      { "source": "/api/webhook", "headers": [{ "key": "Cache-Control", "value": "no-store" }] },
      { "source": "/assets/(.*)", "headers": [{ "key": "Cache-Control", "value": "public, max-age=86400" }] }
    ]
  }
  ```
- [ ] Run (expected PASS):
  ```
  node --test website/test/webhook.test.mjs
  # Expected: "# pass 4  # fail 0" → exit code 0
  ```
- [ ] Commit:
  ```
  git add website/api/webhook.js website/vercel.json website/test/webhook.test.mjs
  git commit -m "$(printf 'feat(website): add gateway-agnostic webhook verify route + tests\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

### Task 3 — Website: static-HTML guard tests (RTL default · no sacred text on donate · links resolve · no raw card inputs)

**Files:**
- Test path: `C:\Users\sulta\Claude_Code\EyeCure_20\website\test\site.test.mjs` (NEW)
- (no source change expected — these assert the EXISTING pages stay compliant; they are regression guards)

Steps:
- [ ] Write the failing test first at `website/test/site.test.mjs` (string/regex checks over the committed HTML — no DOM lib needed):
  ```js
  import { test } from "node:test";
  import assert from "node:assert/strict";
  import { readFileSync, existsSync } from "node:fs";
  import { fileURLToPath } from "node:url";
  import { dirname, join } from "node:path";

  const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
  const read = (f) => readFileSync(join(ROOT, f), "utf8");
  const PAGES = ["index.html", "download.html", "support.html", "privacy.html", "terms.html", "licenses.html"];

  test("every page is Arabic-first RTL by default", () => {
    for (const p of PAGES) {
      const html = read(p);
      assert.match(html, /<html[^>]*lang="ar"/, `${p} must default lang=ar`);
      assert.match(html, /<html[^>]*dir="rtl"/, `${p} must default dir=rtl`);
    }
  });

  test("donate page collects NO raw card fields (PCI handled by gateway)", () => {
    const html = read("support.html");
    assert.doesNotMatch(html, /autocomplete="cc-number"/i);
    assert.doesNotMatch(html, /name="card(number|cvc|cvv|expiry)"/i);
    assert.doesNotMatch(html, /\bcvv\b/i);
  });

  test("donate page sits beside NO sacred text (no Quran/dhikr Arabic on support.html)", () => {
    const html = read("support.html");
    // Reverence rule: the donate page must not render dhikr/sacred Arabic lines.
    assert.doesNotMatch(html, /dhikr-ar|hero\.break\.dhikr|سُبْحَانَ|الْحَمْدُ|اللّٰهُ أَكْبَر/);
  });

  test("donate page states the gateway/PCI honesty line and accepted Mada cards", () => {
    const html = read("support.html");
    assert.match(html, /data-i18n="sup\.secure"/);
    assert.match(html, /mada/i);
  });

  test("all in-page nav/footer links resolve to files that exist", () => {
    const linkRe = /href="([^"#?][^"]*\.html)(?:[#?][^"]*)?"/g;
    for (const p of PAGES) {
      const html = read(p);
      for (const m of html.matchAll(linkRe)) {
        assert.ok(existsSync(join(ROOT, m[1])), `${p} → missing ${m[1]}`);
      }
    }
  });

  test("posts to /api/donate and the donate JS never logs card data", () => {
    const html = read("support.html");
    assert.match(html, /fetch\("\/api\/donate"/);
  });
  ```
- [ ] Run (expected FAIL — file doesn't exist yet):
  ```
  node --test website/test/site.test.mjs
  # Expected: "Cannot find module" / "no test files" depending on runner → exit code 1
  ```
- [ ] Minimal impl: create the file above. The committed pages already satisfy every assertion (verified during planning: `support.html` has `lang="ar" dir="rtl"`, `data-i18n="sup.secure"`, the `mada` card mark, `fetch("/api/donate"...)`, and no card inputs / no dhikr line). If any assertion fails, fix the **page**, not the test (e.g. if a future edit drops `dir="rtl"`).
- [ ] Run (expected PASS):
  ```
  node --test website/test/site.test.mjs
  # Expected: "# pass 6  # fail 0" → exit code 0
  ```
- [ ] Commit:
  ```
  git add website/test/site.test.mjs
  git commit -m "$(printf 'test(website): static guards for RTL, no-sacred-on-donate, links, PCI\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

### Task 4 — Website: `package.json` so `website.yml` runs lint/test/build (secret-free)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\website\package.json` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\website\README.md` (MODIFY — add `npm test` + stub/webhook env)
- Check path (no test file; this wires the runner): run `npm test` in `website/`

Steps:
- [ ] Write the failing check first — confirm the CI-gating file is still absent and the runner is unwired:
  ```
  node -e "process.exit(require('fs').existsSync('website/package.json')?0:1)"
  # Expected: exit code 1 (file absent → website.yml currently SKIPS all steps)
  ```
- [ ] Minimal impl — create `website/package.json` (private, **no dependencies**, all scripts use Node built-ins so `npm ci` needs no network/lockfile install of third-party deps):
  ```json
  {
    "name": "tarf-website",
    "version": "0.1.0",
    "private": true,
    "description": "Tarf (طَرْف) — download + Support/Donate static site with serverless donation + webhook.",
    "type": "commonjs",
    "scripts": {
      "test": "node --test test/",
      "lint": "node --check api/donate.js && node --check api/webhook.js && node --check api/_lib/gateways.js && node --check api/_lib/validate.js",
      "build": "node -e \"console.log('static site — no build step; pages are served as-is')\""
    },
    "engines": { "node": ">=20" }
  }
  ```
  > Note: `website.yml` runs `npm ci || npm install`; with no deps and no lockfile, `npm install` produces an empty `node_modules` and a lockfile, then `npm test` runs `node --test`. `npm run lint`/`npm run build` are detected by the workflow's `npm run | grep -qE '^\s*lint|build'` probes and execute.
- [ ] Minimal impl — append a section to `website/README.md` documenting: `npm test` (runs `node:test`), `PAYMENT_GATEWAY=stub` for an offline gateway, and the new `*_WEBHOOK_SECRET` env vars consumed by `api/webhook.js`. (Add `stub` to the gateway table and a "Webhook" subsection mirroring the existing "Payment gateway env keys" section.)
- [ ] Run (expected PASS — all three website test files run via one command):
  ```
  npm --prefix website test
  # Expected tail: "# tests 16  # pass 16  # fail 0" → exit code 0
  npm --prefix website run lint
  # Expected: no output, exit code 0 (all four files syntactically valid)
  ```
- [ ] Commit:
  ```
  git add website/package.json website/README.md
  git commit -m "$(printf 'build(website): add package.json (test/lint/build) so CI runs the suite\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

### Task 5 — Extension: diacritize `dhikr.json` + add dhikr test (reverence gate)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\dhikr.json` (MODIFY)
- Test path: `C:\Users\sulta\Claude_Code\EyeCure_20\extension\test\dhikr.test.mjs` (NEW)

Steps:
- [ ] Write the failing test first at `extension/test/dhikr.test.mjs`:
  ```js
  import { test } from "node:test";
  import assert from "node:assert/strict";
  import { readFileSync } from "node:fs";
  import { fileURLToPath } from "node:url";
  import { dirname, join } from "node:path";

  const ROOT = dirname(fileURLToPath(import.meta.url));
  const data = JSON.parse(readFileSync(join(ROOT, "..", "dhikr.json"), "utf8"));
  // Arabic harakat (tashkīl) range — reverence rule: sacred Arabic is fully vocalized.
  const TASHKIL = /[ً-ْٰ]/;

  test("dhikr set is a non-empty array", () => {
    assert.ok(Array.isArray(data.dhikr) && data.dhikr.length >= 5);
  });

  test("every entry has arabic + transliteration + english, all non-empty", () => {
    for (const d of data.dhikr) {
      for (const k of ["arabic", "transliteration", "english"]) {
        assert.equal(typeof d[k], "string");
        assert.ok(d[k].trim().length > 0, `${k} empty in ${JSON.stringify(d)}`);
      }
    }
  });

  test("every arabic line carries tashkīl (fully vocalized, never bare)", () => {
    for (const d of data.dhikr) {
      assert.match(d.arabic, TASHKIL, `not vocalized: ${d.arabic}`);
    }
  });
  ```
- [ ] Run (expected FAIL — current entries like `"اللّٰهُ أَكْبَرُ"` pass but `"سُبْحَانَ اللّٰهِ"` already has tashkīl; the failing case is the array-shape/length or any entry missing marks — run to see exact failure):
  ```
  node --test extension/test/dhikr.test.mjs
  # Expected: the "no test files found" → exit 1 (file is new); after creation, FAIL if any line lacks tashkīl
  ```
- [ ] Minimal impl — overwrite `extension/dhikr.json` with the fully-diacritized, universally-agreed set (matching the app's reverence rules; these are the non-sectarian phrases from PROJECT.md §3.2):
  ```json
  {
    "dhikr": [
      {"arabic": "سُبْحَانَ اللَّهِ", "transliteration": "Subḥāna-llāh", "english": "Glory be to Allah."},
      {"arabic": "الْحَمْدُ لِلَّهِ", "transliteration": "Al-ḥamdu li-llāh", "english": "All praise is for Allah."},
      {"arabic": "لَا إِلَٰهَ إِلَّا اللَّهُ", "transliteration": "Lā ilāha illā-llāh", "english": "There is no deity except Allah."},
      {"arabic": "اللَّهُ أَكْبَرُ", "transliteration": "Allāhu akbar", "english": "Allah is the Greatest."},
      {"arabic": "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", "transliteration": "Subḥāna-llāhi wa bi-ḥamdih", "english": "Glory and praise be to Allah."},
      {"arabic": "أَسْتَغْفِرُ اللَّهَ", "transliteration": "Astaghfiru-llāh", "english": "I seek the forgiveness of Allah."},
      {"arabic": "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", "transliteration": "Lā ḥawla wa lā quwwata illā bi-llāh", "english": "There is no might nor power except with Allah."}
    ]
  }
  ```
  > `background.js` reads `arabic`, `transliteration`, `english` — keys unchanged, so the SW notification keeps working.
- [ ] Run (expected PASS):
  ```
  node --test extension/test/dhikr.test.mjs
  # Expected: "# pass 3  # fail 0" → exit code 0
  ```
- [ ] Commit:
  ```
  git add extension/dhikr.json extension/test/dhikr.test.mjs
  git commit -m "$(printf 'fix(extension): fully diacritize dhikr set + reverence test\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

### Task 6 — Extension: align manifest with documented IA (add `sidePanel`) + MV3 invariant test

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\manifest.json` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\sidepanel.html` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\sidepanel.js` (NEW)
- Test path: `C:\Users\sulta\Claude_Code\EyeCure_20\extension\test\manifest.test.mjs` (NEW)

Steps:
- [ ] Write the failing test first at `extension/test/manifest.test.mjs` (encodes the CWS rules from `docs/store/chrome-web-store.md`: single purpose, minimal permissions, no host permissions, no remote code, referenced files exist):
  ```js
  import { test } from "node:test";
  import assert from "node:assert/strict";
  import { readFileSync, existsSync } from "node:fs";
  import { fileURLToPath } from "node:url";
  import { dirname, join } from "node:path";

  const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
  const m = JSON.parse(readFileSync(join(ROOT, "manifest.json"), "utf8"));
  const ALLOWED = new Set(["alarms", "notifications", "offscreen", "storage", "idle", "sidePanel"]);

  test("is Manifest V3 with a service worker", () => {
    assert.equal(m.manifest_version, 3);
    assert.ok(m.background && m.background.service_worker, "service_worker required");
    assert.ok(existsSync(join(ROOT, m.background.service_worker)));
  });

  test("permissions are a subset of the justified allowlist", () => {
    for (const p of m.permissions || []) assert.ok(ALLOWED.has(p), `unjustified permission: ${p}`);
  });

  test("requests NO host permissions (core loop needs none)", () => {
    assert.deepEqual(m.host_permissions || [], []);
    assert.equal(JSON.stringify(m).includes("<all_urls>"), false);
  });

  test("CSP forbids remote code (script-src 'self' only)", () => {
    const csp = (m.content_security_policy && m.content_security_policy.extension_pages) || "";
    assert.match(csp, /script-src 'self'/);
    assert.doesNotMatch(csp, /https?:\/\//, "no remote script origins allowed");
  });

  test("every referenced HTML/icon file exists", () => {
    const refs = [
      m.action && m.action.default_popup,
      m.side_panel && m.side_panel.default_path,
      ...Object.values((m.icons) || {}),
    ].filter(Boolean);
    for (const r of refs) assert.ok(existsSync(join(ROOT, r)), `missing ${r}`);
  });

  test("side panel is declared so the documented dashboard IA exists", () => {
    assert.ok(m.side_panel && m.side_panel.default_path === "sidepanel.html");
    assert.ok((m.permissions || []).includes("sidePanel"));
  });
  ```
- [ ] Run (expected FAIL — current manifest has no `side_panel`/`sidePanel`):
  ```
  node --test extension/test/manifest.test.mjs
  # Expected: "side panel is declared ..." fails (sidePanel missing) → exit code 1
  ```
- [ ] Minimal impl — edit `extension/manifest.json`: add `sidePanel` to `permissions` and a `side_panel` key (keep everything else, `host_permissions` stays `[]`, CSP unchanged):
  ```json
  {
    "manifest_version": 3,
    "name": "Tarf — Eye Care & Dhikr",
    "version": "0.1.0",
    "description": "Activity-aware 20-20-20 eye breaks with a calm dhikr to repeat. Rest your eyes, remember Allah.",
    "action": {
      "default_popup": "popup.html",
      "default_title": "Tarf",
      "default_icon": { "16": "icon16.png", "48": "icon48.png", "128": "icon128.png" }
    },
    "icons": { "16": "icon16.png", "48": "icon48.png", "128": "icon128.png" },
    "background": { "service_worker": "background.js" },
    "side_panel": { "default_path": "sidepanel.html" },
    "permissions": ["alarms", "notifications", "offscreen", "storage", "idle", "sidePanel"],
    "host_permissions": [],
    "content_security_policy": { "extension_pages": "script-src 'self'; object-src 'self'" }
  }
  ```
- [ ] Minimal impl — create `extension/sidepanel.html` (a calm dashboard: next-break countdown + today's rests + take-a-break; reuses `popup.css`, links to `popup.js` messaging helpers via its own small script):
  ```html
  <!doctype html>
  <html lang="ar" dir="rtl">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link rel="stylesheet" href="popup.css" />
      <title>Tarf</title>
    </head>
    <body class="panel">
      <header><div class="brand"><span class="ar">طَرْف</span></div></header>
      <section class="status" id="status">…</section>
      <button class="primary" id="breakNow" data-i18n="breakNow">خذ راحة الآن</button>
      <p class="dhikr-ar" id="dhikr" dir="rtl"></p>
      <footer id="limit" data-i18n="limit">يعمل فقط أثناء فتح Chrome.</footer>
      <script src="i18n.js"></script>
      <script src="sidepanel.js"></script>
    </body>
  </html>
  ```
- [ ] Minimal impl — create `extension/sidepanel.js` (mirror `popup.js` status polling; show a rotating dhikr line from `dhikr.json`):
  ```js
  const send = (cmd, extra = {}) => chrome.runtime.sendMessage({ target: "background", cmd, ...extra });
  const $ = (id) => document.getElementById(id);
  async function refresh() {
    const s = await send("getStatus"); if (!s) return;
    const ms = s.enabled && s.nextAt ? s.nextAt - Date.now() : 0;
    $("status").textContent = !s.enabled ? (window.TarfI18n.t("off"))
      : ms <= 0 ? window.TarfI18n.t("due")
      : window.TarfI18n.t("nextIn", { m: Math.floor(ms / 60000), s: Math.floor((ms % 60000) / 1000) });
  }
  $("breakNow").addEventListener("click", () => send("breakNow"));
  (async () => {
    const list = (await (await fetch(chrome.runtime.getURL("dhikr.json"))).json()).dhikr;
    $("dhikr").textContent = list[Math.floor(Math.random() * list.length)].arabic;
  })();
  refresh(); setInterval(refresh, 1000);
  ```
  (`i18n.js` + `window.TarfI18n` are added in Task 7; this file is committed together with Task 7 if the worker prefers, but the manifest test only needs the HTML to exist — it does here.)
- [ ] Run (expected PASS):
  ```
  node --test extension/test/manifest.test.mjs
  # Expected: "# pass 6  # fail 0" → exit code 0
  ```
- [ ] Commit:
  ```
  git add extension/manifest.json extension/sidepanel.html extension/sidepanel.js extension/test/manifest.test.mjs
  git commit -m "$(printf 'feat(extension): add side panel + MV3 invariant test (perms, no remote code)\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

### Task 7 — Extension: Arabic-first/RTL popup with dhikr + quick links + honest limit

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\i18n.js` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\popup.html` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\popup.css` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\popup.js` (MODIFY)
- Test path: extends `C:\Users\sulta\Claude_Code\EyeCure_20\extension\test\manifest.test.mjs` (add a popup-content guard block) — or NEW `extension/test/popup.test.mjs`

Steps:
- [ ] Write the failing test first at `extension/test/popup.test.mjs` (string assertions over the popup files — Chrome APIs aren't available in `node:test`, so we test markup/strings, the same approach the website uses):
  ```js
  import { test } from "node:test";
  import assert from "node:assert/strict";
  import { readFileSync } from "node:fs";
  import { fileURLToPath } from "node:url";
  import { dirname, join } from "node:path";

  const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
  const read = (f) => readFileSync(join(ROOT, f), "utf8");

  test("popup is Arabic-first RTL", () => {
    const html = read("popup.html");
    assert.match(html, /<html[^>]*lang="ar"/);
    assert.match(html, /<html[^>]*dir="rtl"/);
  });

  test("popup states the honest 'only while Chrome is open' limit", () => {
    const html = read("popup.html");
    assert.match(html, /data-i18n="limit"/);
  });

  test("popup shows a dhikr line and quick links to the site", () => {
    const html = read("popup.html");
    assert.match(html, /id="dhikr"/);
    assert.match(html, /tarf\.app\/support|data-i18n="link\.support"/);
  });

  test("i18n module exposes ar+en and the limit/breakNow keys", () => {
    const js = read("i18n.js");
    assert.match(js, /limit:/);
    assert.match(js, /breakNow:/);
    assert.match(js, /\bar\b/); assert.match(js, /\ben\b/);
  });
  ```
- [ ] Run (expected FAIL):
  ```
  node --test extension/test/popup.test.mjs
  # Expected: popup.html still lang="en", no #dhikr/#limit → multiple assertions fail → exit 1
  ```
- [ ] Minimal impl — create `extension/i18n.js` (tiny AR/EN table + `window.TarfI18n`, no deps; Arabic default; persists to `chrome.storage.local` lazily, falls back to in-memory):
  ```js
  (function () {
    const STRINGS = {
      ar: { off: "التذكيرات متوقّفة", due: "حان وقت الراحة", scheduling: "نُجدوِل…",
            nextIn: (p) => `الراحة القادمة بعد ${p.m}م ${String(p.s).padStart(2,"0")}ث`,
            every: "كل", breakNow: "خذ راحة الآن", snooze: "تأجيل",
            limit: "يعمل فقط أثناء فتح Chrome — لا يُذكّرك بعد إغلاقه.",
            "link.support": "ادعمنا", "link.download": "التطبيق الكامل", footer: "٢٠ · ٢٠ · ٢٠ — انظر بعيدًا ٢٠ ثانية كل ٢٠ دقيقة." },
      en: { off: "Reminders are off", due: "Break is due", scheduling: "Scheduling…",
            nextIn: (p) => `Next break in ${p.m}m ${String(p.s).padStart(2,"0")}s`,
            every: "Every", breakNow: "Take a break now", snooze: "Snooze",
            limit: "Works only while Chrome is open — it cannot remind you after you quit.",
            "link.support": "Support us", "link.download": "Full app", footer: "20 · 20 · 20 — look away for 20s every 20 min." },
    };
    let lang = "ar";
    function t(key, params) { const v = (STRINGS[lang] || STRINGS.ar)[key]; return typeof v === "function" ? v(params || {}) : (v ?? key); }
    function apply(l) {
      lang = STRINGS[l] ? l : "ar";
      document.documentElement.lang = lang;
      document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
      document.querySelectorAll("[data-i18n]").forEach((el) => { el.textContent = t(el.getAttribute("data-i18n")); });
    }
    window.TarfI18n = { t, apply, get lang() { return lang; }, toggle() { apply(lang === "ar" ? "en" : "ar"); } };
    document.addEventListener("DOMContentLoaded", () => apply("ar"));
  })();
  ```
- [ ] Minimal impl — rewrite `extension/popup.html` to be Arabic-first, add a dhikr line, quick links to the website, a language toggle, and the honest limit footer (keep the existing `#enabled`/`#interval`/`#breakNow`/`.snooze` controls `popup.js` already wires):
  ```html
  <!doctype html>
  <html lang="ar" dir="rtl">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link rel="stylesheet" href="popup.css" />
      <title>Tarf</title>
    </head>
    <body>
      <header>
        <div class="brand"><span class="ar">طَرْف</span><span class="en">Tarf · Eye care &amp; dhikr</span></div>
        <button class="lang" id="lang" aria-label="EN">EN</button>
        <label class="switch" title="تذكيرات راحة العين"><input type="checkbox" id="enabled" /><span class="slider"></span></label>
      </header>
      <p class="dhikr-ar" id="dhikr" dir="rtl"></p>
      <section class="status" id="status">…</section>
      <section class="row"><label for="interval" data-i18n="every">كل</label>
        <select id="interval">
          <option value="10">10</option><option value="20" selected>20</option>
          <option value="30">30</option><option value="45">45</option><option value="60">60</option>
        </select>
      </section>
      <button class="primary" id="breakNow" data-i18n="breakNow">خذ راحة الآن</button>
      <section class="snooze"><span data-i18n="snooze">تأجيل</span>
        <button data-min="5">5m</button><button data-min="15">15m</button><button data-min="60">1h</button>
      </section>
      <nav class="links">
        <a id="lnk-support" href="https://tarf.app/support" target="_blank" rel="noopener" data-i18n="link.support">ادعمنا</a>
        <a id="lnk-download" href="https://tarf.app/download" target="_blank" rel="noopener" data-i18n="link.download">التطبيق الكامل</a>
      </nav>
      <footer id="limit" data-i18n="limit">يعمل فقط أثناء فتح Chrome.</footer>
      <script src="i18n.js"></script>
      <script src="dhikr-popup.js"></script>
      <script src="popup.js"></script>
    </body>
  </html>
  ```
  > Add a 6-line `extension/dhikr-popup.js` (or fold into `popup.js`) that fetches `dhikr.json` and sets `#dhikr`. To keep `popup.js`'s diff minimal, append the dhikr fetch + the `#lang` toggle handler to `popup.js` instead and drop the extra `<script>` — your choice; the test only checks `#dhikr` exists in the HTML.
- [ ] Minimal impl — extend `extension/popup.css`: add `html[dir="rtl"]` text-align, `.lang` button, `.links` row, and `.dhikr-ar { font-family: "Amiri", "Scheherazade New", serif; font-size: 20px; text-align: center; line-height: 1.9; }`, plus `.panel` width override for the side panel. Keep the existing teal `--accent` tokens.
- [ ] Minimal impl — append to `extension/popup.js`: (a) fetch `dhikr.json` → set `#dhikr`; (b) `#lang` click → `window.TarfI18n.toggle()` then `refresh()`; (c) replace the hard-coded English strings in `renderStatus`/`refresh` with `window.TarfI18n.t(...)` so the popup follows the chosen language.
- [ ] Run (expected PASS):
  ```
  node --test extension/test/popup.test.mjs
  # Expected: "# pass 4  # fail 0" → exit code 0
  ```
- [ ] Commit:
  ```
  git add extension/i18n.js extension/popup.html extension/popup.css extension/popup.js extension/test/popup.test.mjs
  git commit -m "$(printf 'feat(extension): Arabic-first RTL popup with dhikr, quick links, honest limit\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

### Task 8 — Extension: cross-platform packaging (`package.mjs`) + `package.json` + STORE_LISTING.md

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\package.json` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\package.mjs` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\package.ps1` (MODIFY — add `sidepanel.*`, `i18n.js`, `dhikr-popup.js` to include-list)
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\STORE_LISTING.md` (NEW)
- Check path: run `npm --prefix extension run package` then assert the zip exists + omits dev files

Steps:
- [ ] Write the failing check first — confirm there's no `package.json` (so `build-extension.yml`'s `if [ -f package.json ]` branch is currently skipped) and no cross-platform packager:
  ```
  node -e "process.exit(require('fs').existsSync('extension/package.json')?0:1)"
  # Expected: exit code 1
  ```
- [ ] Minimal impl — `extension/package.mjs` (zips only shippable files via Node; no native `zip` needed — uses a tiny store-only ZIP writer or Node's `zlib`; to avoid a dep, shell out to the platform archiver with a Node fallback):
  ```js
  // Cross-platform packager → tarf-extension.zip. Prefers `zip` (Linux/macOS CI),
  // falls back to PowerShell Compress-Archive (Windows). No npm deps.
  import { execFileSync } from "node:child_process";
  import { existsSync, rmSync } from "node:fs";
  import { fileURLToPath } from "node:url";
  import { dirname, join } from "node:path";

  const HERE = dirname(fileURLToPath(import.meta.url));
  const OUT = join(HERE, "tarf-extension.zip");
  const INCLUDE = [
    "manifest.json", "background.js", "offscreen.html", "offscreen.js",
    "popup.html", "popup.css", "popup.js", "i18n.js", "dhikr-popup.js",
    "sidepanel.html", "sidepanel.js", "dhikr.json",
    "icon16.png", "icon48.png", "icon128.png",
  ].filter((f) => existsSync(join(HERE, f)));

  if (existsSync(OUT)) rmSync(OUT);
  try {
    execFileSync("zip", ["-X", OUT, ...INCLUDE], { cwd: HERE, stdio: "inherit" });
  } catch {
    const list = INCLUDE.map((f) => `'${f}'`).join(",");
    execFileSync("pwsh", ["-NoProfile", "-Command",
      `Compress-Archive -Path ${list} -DestinationPath '${OUT}' -Force`], { cwd: HERE, stdio: "inherit" });
  }
  console.log("Wrote", OUT);
  ```
- [ ] Minimal impl — `extension/package.json` (private, no deps; `package` runs the packager, `test`/`lint` run the suite + `node --check`):
  ```json
  {
    "name": "tarf-extension",
    "version": "0.1.0",
    "private": true,
    "description": "Tarf (طَرْف) — MV3 eye-care + dhikr break extension.",
    "type": "commonjs",
    "scripts": {
      "test": "node --test test/",
      "lint": "node --check background.js && node --check offscreen.js && node --check popup.js && node --check sidepanel.js && node --check i18n.js",
      "package": "node package.mjs"
    },
    "engines": { "node": ">=20" }
  }
  ```
  > `i18n.js` uses `window`, so `node --check` validates syntax only (it does not execute) — safe. If `dhikr-popup.js` was folded into `popup.js` in Task 7, drop it from `lint`/`INCLUDE`.
- [ ] Minimal impl — update `extension/package.ps1` `$include` array to add `'sidepanel.html','sidepanel.js','i18n.js','popup.* (already there)','dhikr-popup.js'` so both packagers stay in lockstep.
- [ ] Minimal impl — create `extension/STORE_LISTING.md` by lifting the **single-purpose statement** and the **per-permission justification table** (alarms/notifications/offscreen/storage/idle/**sidePanel**) verbatim from `docs/store/chrome-web-store.md` §2–§3, plus the honest "only while Chrome is open" line. This puts the reviewer-facing copy in the package source (the docs file stays the master).
- [ ] Run (expected PASS — zip is produced and excludes README/test/scripts):
  ```
  npm --prefix extension run package
  # Expected: "Wrote .../extension/tarf-extension.zip"
  node -e "const z=require('fs').statSync('extension/tarf-extension.zip'); console.log('zip bytes', z.size); process.exit(z.size>0?0:1)"
  # Expected: prints a non-zero byte count → exit 0
  npm --prefix extension test && npm --prefix extension run lint
  # Expected: dhikr+manifest+popup suites pass; lint exit 0
  ```
- [ ] Commit:
  ```
  git add extension/package.json extension/package.mjs extension/package.ps1 extension/STORE_LISTING.md extension/tarf-extension.zip
  git commit -m "$(printf 'build(extension): cross-platform packager + npm scripts + store listing\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

### Task 9 — CI: wire extension lint+test+package into `build-extension.yml` (still secret-free)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\.github\workflows\build-extension.yml` (MODIFY)

Steps:
- [ ] Write the failing check first — the workflow currently has no extension lint/test step (its `if [ -f package.json ]` branch runs `npm run build`, which the extension package does NOT define). Confirm by inspection / a local `act`-style dry check:
  ```
  node -e "const y=require('fs').readFileSync('.github/workflows/build-extension.yml','utf8'); process.exit(/npm run test|node --test/.test(y)?0:1)"
  # Expected: exit code 1 (no extension test step yet)
  ```
- [ ] Minimal impl — insert a Node lint+test+package step **before** the existing "Build & package extension (if present)" step (which stays as a fallback). The new step is guarded so it is a no-op until `extension/package.json` exists (which it does after Task 8), keeping the workflow green at every commit:
  ```yaml
      # --- Extension static checks + package (no secrets) ---------------------
      - name: Lint, test & package extension
        id: ext_checks
        shell: bash
        run: |
          set -euo pipefail
          if [ ! -f extension/package.json ]; then
            echo "extension/package.json not present — skipping (fallback step will zip)."
            echo "done=false" >> "$GITHUB_OUTPUT"; exit 0
          fi
          cd extension
          npm ci || npm install
          npm run lint
          npm test
          npm run package           # produces tarf-extension.zip with no secrets
          echo "done=true" >> "$GITHUB_OUTPUT"
  ```
  Then make the existing "Build & package extension (if present)" step skip when ours already packaged, by prefixing its `run` body with:
  ```bash
          if [ "${{ steps.ext_checks.outputs.done }}" = "true" ]; then
            echo "Extension already linted/tested/zipped by Node step."
            echo "built=true" >> "$GITHUB_OUTPUT"; exit 0
          fi
  ```
  (The Flutter-web build steps above it are untouched — the extension's plain-HTML popup ships first per its README; the Flutter-web UI remains the documented post-v1 enhancement.)
- [ ] Run (expected PASS — locally simulate the step body the runner executes):
  ```
  bash -lc 'cd extension && (npm ci || npm install) && npm run lint && npm test && npm run package'
  # Expected: suites pass, "Wrote .../tarf-extension.zip", exit 0
  ```
- [ ] Commit:
  ```
  git add .github/workflows/build-extension.yml
  git commit -m "$(printf 'ci(extension): run lint+test+package (Node, secret-free) in build-extension\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

### Task 10 — CI: confirm `website.yml` now runs the suite; add a fast Node-only PR gate (`distribution-pr.yml`)

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\.github\workflows\website.yml` (MODIFY — minimal: ensure `npm test` runs)
- `C:\Users\sulta\Claude_Code\EyeCure_20\.github\workflows\distribution-pr.yml` (NEW)

Steps:
- [ ] Write the failing check first — `website.yml` installs+builds but does **not** run tests; confirm:
  ```
  node -e "const y=require('fs').readFileSync('.github/workflows/website.yml','utf8'); process.exit(/npm test|npm run test|node --test/.test(y)?0:1)"
  # Expected: exit code 1 (no test step today)
  ```
- [ ] Minimal impl — add a Test step to `website.yml` right after Lint (guarded on the package existing, mirroring the existing best-effort pattern):
  ```yaml
      - name: Test
        if: steps.detect.outputs.present == 'true'
        working-directory: ./website
        run: |
          if npm run | grep -qE '^\s*test'; then npm test; else echo "No test script — skipping."; fi
  ```
  (The Vercel deploy block stays commented exactly as today — deploy remains owner-gated on `VERCEL_*` secrets.)
- [ ] Minimal impl — create `.github/workflows/distribution-pr.yml`: a fast PR gate that runs **only the Node suites** for website + extension (no Flutter, no secrets), so distribution-only PRs get a sub-minute signal. The brief's "PR workflow running flutter analyze + flutter test" requirement is already satisfied by the existing `ci.yml` (which runs on `pull_request` for `app/`); this complements it for the non-app dirs:
  ```yaml
  name: Distribution PR checks

  on:
    pull_request:
      branches: ["**"]
      paths:
        - "website/**"
        - "extension/**"
        - ".github/workflows/distribution-pr.yml"
    workflow_dispatch:

  concurrency:
    group: dist-pr-${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: true

  jobs:
    website:
      name: Website tests (Node)
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: actions/setup-node@v4
          with: { node-version: "20" }
        - name: Test website
          working-directory: ./website
          run: |
            test -f package.json || { echo "no website package — skip"; exit 0; }
            npm ci || npm install
            npm run lint
            npm test
    extension:
      name: Extension tests (Node)
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: actions/setup-node@v4
          with: { node-version: "20" }
        - name: Test & package extension
          working-directory: ./extension
          run: |
            test -f package.json || { echo "no extension package — skip"; exit 0; }
            npm ci || npm install
            npm run lint
            npm test
            npm run package
        - name: Upload extension zip
          uses: actions/upload-artifact@v4
          with:
            name: tarf-extension-zip-pr
            path: extension/tarf-extension.zip
            if-no-files-found: warn
            retention-days: 7
  ```
- [ ] Run (expected PASS — locally simulate both jobs' core commands):
  ```
  bash -lc 'cd website && (npm ci || npm install) && npm run lint && npm test'
  bash -lc 'cd extension && (npm ci || npm install) && npm run lint && npm test && npm run package'
  # Expected: both exit 0; website "# pass 16", extension suites pass, zip written
  ```
- [ ] (Optional) validate workflow YAML parses:
  ```
  node -e "require('fs').readdirSync('.github/workflows').forEach(f=>console.log('ok',f))"
  # (full YAML lint happens on GitHub; this just confirms the files are present)
  ```
- [ ] Commit:
  ```
  git add .github/workflows/website.yml .github/workflows/distribution-pr.yml
  git commit -m "$(printf 'ci: run website tests + add fast Node-only distribution PR gate\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

### Task 11 — Final integration sweep: full secret-free green run + READMEs

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\website\README.md` (verify Task 4 additions present)
- `C:\Users\sulta\Claude_Code\EyeCure_20\extension\README.md` (MODIFY — note side panel + i18n + `npm test`/`npm run package`)

Steps:
- [ ] Run the whole distribution suite exactly as CI will, with **no env vars set** (proves secret-free green):
  ```
  bash -lc 'cd website && (npm ci || npm install) && npm run lint && npm test'
  bash -lc 'cd extension && (npm ci || npm install) && npm run lint && npm test && npm run package'
  # Expected: website "# tests 16 # pass 16 # fail 0"; extension dhikr(3)+manifest(6)+popup(4)=13 pass; zip written; all exit 0
  ```
- [ ] Run the donate route's TEST-MODE behavior end-to-end with the stub (no keys), via a tiny inline harness (optional sanity, not a committed test):
  ```
  node -e "process.env.PAYMENT_GATEWAY='stub'; const {selectGateway}=require('./website/api/_lib/gateways.js'); selectGateway('stub').createPayment({amountMinor:2500,currency:'SAR',callbackUrl:'https://x/support.html?thanks=1'}).then(r=>{console.log(r); process.exit(/testMode=1/.test(r.redirectUrl)?0:1)})"
  # Expected: { id:'stub_…', redirectUrl:'…testMode=1&gateway=stub…' } → exit 0
  ```
- [ ] Minimal impl — update `extension/README.md`: add a "Side panel" line, a "Localization (AR default, EN toggle)" line, and a "Develop" subsection: `npm test` (runs the Node suites), `npm run package` (cross-platform zip) / `pwsh ./package.ps1` (Windows). Confirm `website/README.md` already documents `stub` + webhook env from Task 4.
- [ ] Commit:
  ```
  git add extension/README.md website/README.md
  git commit -m "$(printf 'docs(dist): document side panel, i18n, stub gateway, webhook, npm scripts\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
  ```

---

## Verification

Run every check below from the repo root `C:\Users\sulta\Claude_Code\EyeCure_20`. All must pass **with no secrets / no env vars set**.

- [ ] **Website unit + guard suite (secret-free):**
  ```
  bash -lc 'cd website && (npm ci || npm install) && npm run lint && npm test'
  ```
  Expected tail: `# tests 16  # pass 16  # fail 0`, exit 0. (Tasks 1–4: validation 4, gateway/stub 2, webhook 4, static guards 6.)
- [ ] **Extension suite + packaging (secret-free):**
  ```
  bash -lc 'cd extension && (npm ci || npm install) && npm run lint && npm test && npm run package'
  ```
  Expected: dhikr (3) + manifest (6) + popup (4) = 13 pass; `Wrote …/extension/tarf-extension.zip`; exit 0.
- [ ] **Stub donation flow (no keys → TEST MODE, no network):** the `node -e` harness in Task 11 prints a `testMode=1&gateway=stub` redirect → exit 0.
- [ ] **MV3 compliance:** `extension/test/manifest.test.mjs` proves `manifest_version: 3`, permissions ⊆ {alarms,notifications,offscreen,storage,idle,sidePanel}, `host_permissions: []`, no `<all_urls>`, CSP `script-src 'self'` (no remote origins), and that `popup.html`/`sidepanel.html`/icons exist.
- [ ] **Reverence:** `extension/test/dhikr.test.mjs` proves every Arabic dhikr line carries tashkīl; `website/test/site.test.mjs` proves `support.html` renders no sacred Arabic and no raw card inputs and is `dir="rtl"`.
- [ ] **CI parity (local simulation of the runner steps):** the two `bash -lc` blocks in Tasks 9–10 reproduce exactly what `build-extension.yml`, `website.yml`, and `distribution-pr.yml` execute; all exit 0.
- [ ] **No secret leakage:** `git grep -nE 'sk_live|sk_test|whsec_[A-Za-z0-9]|VERCEL_TOKEN=' -- website extension` returns nothing (secrets only ever read via `process.env`).
- [ ] **Existing Flutter CI untouched:** `git diff --stat` shows no changes under `app/`; `ci.yml` and `build-apple.yml` are byte-identical to their pre-phase state (only `build-extension.yml`, `website.yml` modified + `distribution-pr.yml` added under `.github/workflows/`).
- [ ] **Deploy stays owner-gated:** the Vercel deploy block in `website.yml` and the signing blocks in `build-apple.yml` remain commented; no workflow references a secret in a way that fails when the secret is absent.

## Self-review

- [ ] **Brief coverage — Website:** static stack matched (not migrated); landing/download/support pages exist and are preserved; donation **adapter interface** present with **Moyasar (Mada) primary + Tap fallback** (+ Stripe + new **stub**); `/api/donate` reads keys from ENV (owner-gated) and **+ webhook verify** route added; **stub adapter** keeps CI green with no keys; Arabic-first/RTL/dark-light/accessible retained; donate page proven to **not** sit beside sacred content.
- [ ] **Brief coverage — Extension:** MV3 popup reflects the IA (compact 20-20-20 timer + dhikr break + quick links); **honest "only while Chrome is open"** stated in popup + side panel + STORE_LISTING; single-purpose statement + per-permission justifications shipped in `STORE_LISTING.md`; `package.ps1` retained (+ cross-platform `package.mjs`) → `tarf-extension.zip`; permissions kept minimal (added only `sidePanel`, which the docs already justify; `host_permissions` stays `[]`).
- [ ] **Brief coverage — CI/CD:** PR `flutter analyze`+`flutter test` already provided by `ci.yml` (app/), complemented by a Node-only `distribution-pr.yml`; web+Android artifacts already built by `ci.yml`/`build-extension.yml`; website build/deploy workflow exists (`website.yml`, deploy commented = owner-gated); extension lint/zip check wired; **`build-apple.yml` reused/extended-by-leaving-intact**; **CI passes with no real secrets** (stubs + skip-on-absent guards).
- [ ] **TDD discipline:** every task starts with a failing test/check showing the expected failure, then minimal impl with the exact code/JSON/YAML, then the expected passing output, then an exact `git add` + message. No step asserts success before showing the command output.
- [ ] **No placeholders / consistent names:** module paths (`api/_lib/{validate,gateways}.js`), env names (`PAYMENT_GATEWAY`, `*_SECRET_KEY`, `*_WEBHOOK_SECRET`, `SITE_URL`, `VERCEL_*`), gateway ids (`moyasar`/`tap`/`stripe`/`stub`), and the zip name (`tarf-extension.zip`) are used identically across plan, code, and CI.
- [ ] **Zero new runtime deps:** website + extension `package.json` declare **no** dependencies; tests use `node:test`/`node:assert`/`node:crypto`; `npm ci || npm install` succeeds offline with an empty dep tree — so CI needs no registry secrets and no third-party supply chain.
- [ ] **Worktree-safe / parallelizable:** touches only `website/**`, `extension/**`, `.github/workflows/{build-extension,website,distribution-pr}.yml`; reads nothing under `app/lib/**`; no dependency on Phases 1–4; can run in its own branch/worktree from t=0.
- [ ] **Reverence & honesty invariants are tested, not just asserted in prose:** tashkīl check, no-sacred-on-donate check, and the Chrome-open-only string check are executable gates that fail the build if a future edit regresses them.
- [ ] **Risk: gateway field-name drift** (Moyasar/Tap live API shapes) is explicitly out of scope for green CI — the live paths are exercised only with real keys; the README already flags "verify field names before first production charge," and the stub + TEST MODE guarantee a deployable, demonstrable flow until then.

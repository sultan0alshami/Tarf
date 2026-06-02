// =============================================================================
// Tarf — Donation serverless function  (Vercel / Netlify-style)
//
// POST /api/donate
//   body: { amount: number(SAR), currency: "SAR", name?, email?, message?, lang? }
//   ->   200 { redirectUrl, paymentId, testMode }   (client redirects the donor)
//   ->   400 { error, errorKey }                    (validation failure)
//   ->   502 { error, errorKey }                    (gateway failure)
//
// DESIGN
// ------
// * A pluggable `PaymentGateway` abstraction so the owner can switch providers
//   without touching the route. Moyasar is the PRIMARY (Mada-capable, KSA).
//   Tap and Stripe are stubbed with the same interface. `stub` is offline-only.
// * PCI: this function NEVER sees raw card data. It asks the gateway to create
//   a payment and returns the gateway's HOSTED / REDIRECT URL. The donor enters
//   their card on the gateway's page.
// * TEST MODE: if the selected gateway has no secret key in the environment,
//   the function returns a synthetic sandbox redirect so the full flow can be
//   demoed/deployed before real keys are slotted in. No charge is ever made.
//   PAYMENT_GATEWAY=stub always runs in TEST MODE (offline, no keys needed).
//
// ENVIRONMENT VARIABLES (set these in your host's dashboard — see website/README.md)
//   PAYMENT_GATEWAY        "moyasar" (default) | "tap" | "stripe" | "stub"
//   SITE_URL               e.g. https://tarf.app   (used to build callback URLs)
//
//   # Moyasar (primary)  --> https://dashboard.moyasar.com  (Settings > API keys)
//   MOYASAR_SECRET_KEY     sk_live_xxx (or sk_test_xxx for sandbox)
//
//   # Tap (alternative)  --> https://www.tap.company
//   TAP_SECRET_KEY         sk_live_xxx / sk_test_xxx
//
//   # Stripe (alternative) --> https://dashboard.stripe.com/apikeys
//   STRIPE_SECRET_KEY      sk_live_xxx / sk_test_xxx
//
// This file uses only the Web/Node fetch API and standard Node — no npm deps.
// Compatible with Vercel Node functions (module.exports default handler) and
// adaptable to Netlify (see README).
// =============================================================================

"use strict";

const { validate } = require("./_lib/validate.js");
const { selectGateway, GatewayError } = require("./_lib/gateways.js");

// ---------------------------------------------------------------------------
// Body parsing (works whether the host pre-parses JSON or hands us a stream)
// ---------------------------------------------------------------------------
async function readJsonBody(req) {
  if (req.body && typeof req.body === "object") return req.body; // Vercel pre-parsed
  if (typeof req.body === "string" && req.body.length) {
    try { return JSON.parse(req.body); } catch (e) { return {}; }
  }
  // Fallback: read the raw stream.
  return await new Promise((resolve) => {
    let raw = "";
    req.on("data", (c) => { raw += c; });
    req.on("end", () => { try { resolve(JSON.parse(raw || "{}")); } catch (e) { resolve({}); } });
    req.on("error", () => resolve({}));
  });
}

function send(res, status, payload) {
  res.statusCode = status;
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");
  res.end(JSON.stringify(payload));
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------
module.exports = async function handler(req, res) {
  if (req.method !== "POST") {
    return send(res, 405, { error: "Method not allowed" });
  }

  const body = await readJsonBody(req);
  const v = validate(body);
  if (!v.ok) {
    return send(res, 400, { error: v.error, errorKey: v.errorKey });
  }

  // env read stays in handler scope only — gateway classes are pure/testable
  const gateway = selectGateway(process.env.PAYMENT_GATEWAY);
  const siteUrl = (process.env.SITE_URL || "").replace(/\/+$/, "") || originFrom(req);
  const callbackUrl = siteUrl + "/support.html?thanks=1";
  const amountMinor = Math.round(v.value.amount * 100); // SAR -> halalas

  const metadata = {
    project: "tarf",
    donor_name: v.value.name,
    donor_email: v.value.email,
    message: v.value.message,
    lang: v.value.lang,
  };
  const description = "Tarf donation / تبرّع لتطبيق طَرْف";

  // ---- TEST MODE: no keys configured for the selected gateway -------------
  if (!gateway.isConfigured()) {
    // Synthesize a sandbox "hosted page" so the full client flow can be tested
    // and the site can deploy before real merchant keys exist. No real charge.
    const fakeId = "test_" + Date.now().toString(36);
    const redirectUrl =
      callbackUrl +
      "&testMode=1&gateway=" + gateway.id +
      "&amount=" + encodeURIComponent(v.value.amount) +
      "&currency=" + v.value.currency +
      "&pid=" + fakeId;
    return send(res, 200, {
      testMode: true,
      gateway: gateway.id,
      paymentId: fakeId,
      redirectUrl,
    });
  }

  // ---- LIVE / sandbox-with-keys: ask the gateway to create the payment ----
  try {
    const { id, redirectUrl } = await gateway.createPayment({
      amountMinor,
      currency: v.value.currency,
      description,
      metadata,
      callbackUrl,
    });
    if (!redirectUrl) throw new GatewayError("Gateway returned no redirect URL");
    return send(res, 200, {
      testMode: false,
      gateway: gateway.id,
      paymentId: id,
      redirectUrl,
    });
  } catch (err) {
    // Never leak secrets; log server-side, return a translatable key client-side.
    console.error("[donate] gateway error:", gateway.id, err && err.message);
    return send(res, 502, {
      error: "Payment gateway error",
      errorKey: "sup.status.errNetwork",
    });
  }
};

// Best-effort origin if SITE_URL is unset (local dev / preview).
function originFrom(req) {
  const proto = (req.headers["x-forwarded-proto"] || "https").split(",")[0];
  const host = req.headers["x-forwarded-host"] || req.headers.host || "localhost:3000";
  return proto + "://" + host;
}

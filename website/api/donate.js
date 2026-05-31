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
//   Tap and Stripe are stubbed with the same interface.
// * PCI: this function NEVER sees raw card data. It asks the gateway to create
//   a payment and returns the gateway's HOSTED / REDIRECT URL. The donor enters
//   their card on the gateway's page.
// * TEST MODE: if the selected gateway has no secret key in the environment,
//   the function returns a synthetic sandbox redirect so the full flow can be
//   demoed/deployed before real keys are slotted in. No charge is ever made.
//
// ENVIRONMENT VARIABLES (set these in your host's dashboard — see website/README.md)
//   PAYMENT_GATEWAY        "moyasar" (default) | "tap" | "stripe"
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

const SUPPORTED_CURRENCIES = ["SAR"]; // Mada is SAR-only; keep the gateway honest.
const MIN_AMOUNT_SAR = 1;
const MAX_AMOUNT_SAR = 100000; // sanity ceiling

// ---------------------------------------------------------------------------
// PaymentGateway abstraction
// ---------------------------------------------------------------------------
// Every gateway implements:
//   id
//   isConfigured()                        -> boolean (are env keys present?)
//   createPayment({ amountMinor, currency, description, metadata, callbackUrl })
//        -> Promise<{ id, redirectUrl }>
// amountMinor is the smallest unit (halalas for SAR; cents for others).
// ---------------------------------------------------------------------------

class PaymentGateway {
  get id() { return "abstract"; }
  isConfigured() { return false; }
  // eslint-disable-next-line no-unused-vars
  async createPayment(_args) {
    throw new Error("createPayment not implemented");
  }
}

// --- Moyasar (PRIMARY, Mada + Visa + Mastercard, KSA) ----------------------
// Docs: https://docs.moyasar.com/  — Payments API, hosted/redirect via 3DS.
// We create a payment with source.type = "creditcard" is NOT used here because
// that needs card data. Instead we use the *Invoice* API which returns a hosted
// payment page URL — keeping all card entry on Moyasar's PCI-compliant page.
class MoyasarGateway extends PaymentGateway {
  get id() { return "moyasar"; }

  isConfigured() {
    return !!process.env.MOYASAR_SECRET_KEY;
  }

  async createPayment({ amountMinor, currency, description, metadata, callbackUrl }) {
    const secret = process.env.MOYASAR_SECRET_KEY;
    // HTTP Basic auth: secret key as username, empty password.
    const auth = "Basic " + Buffer.from(secret + ":").toString("base64");

    // Moyasar Invoices return a `url` (hosted payment page). Mada is enabled on
    // the merchant account; no card data passes through us.
    const res = await fetch("https://api.moyasar.com/v1/invoices", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: auth,
      },
      body: JSON.stringify({
        amount: amountMinor,           // halalas
        currency: currency,            // "SAR"
        description: description,
        callback_url: callbackUrl,     // donor returns here after paying
        metadata: metadata,
      }),
    });

    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      const msg = (data && (data.message || data.type)) || `Moyasar error ${res.status}`;
      throw new GatewayError(msg);
    }
    return { id: data.id, redirectUrl: data.url };
  }
}

// --- Tap (alternative KSA/GCC gateway) -------------------------------------
// Docs: https://developers.tap.company/  — Charges API returns transaction.url.
// STUB: wired with the same shape; verify field names against current Tap docs
// before going live, and enable Mada on your Tap account.
class TapGateway extends PaymentGateway {
  get id() { return "tap"; }

  isConfigured() {
    return !!process.env.TAP_SECRET_KEY;
  }

  async createPayment({ amountMinor, currency, description, metadata, callbackUrl }) {
    const secret = process.env.TAP_SECRET_KEY;
    const amountMajor = amountMinor / 100; // Tap expects major units (decimal)

    const res = await fetch("https://api.tap.company/v2/charges", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer " + secret,
      },
      body: JSON.stringify({
        amount: amountMajor,
        currency: currency,
        description: description,
        // source.id "src_all" lets the donor pick Mada/Visa/Mastercard on Tap's page
        source: { id: "src_all" },
        redirect: { url: callbackUrl },
        metadata: metadata,
      }),
    });

    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      const msg = (data && (data.errors ? JSON.stringify(data.errors) : data.message)) || `Tap error ${res.status}`;
      throw new GatewayError(msg);
    }
    const url = data.transaction && data.transaction.url;
    if (!url) throw new GatewayError("Tap did not return a redirect URL");
    return { id: data.id, redirectUrl: url };
  }
}

// --- Stripe (alternative, non-Mada fallback) -------------------------------
// Docs: https://stripe.com/docs/api/checkout/sessions
// STUB: uses Stripe Checkout Sessions (hosted page). Note Stripe does NOT
// support Mada; use this only as a Visa/Mastercard fallback for non-KSA donors.
class StripeGateway extends PaymentGateway {
  get id() { return "stripe"; }

  isConfigured() {
    return !!process.env.STRIPE_SECRET_KEY;
  }

  async createPayment({ amountMinor, currency, description, metadata, callbackUrl }) {
    const secret = process.env.STRIPE_SECRET_KEY;

    // Stripe expects application/x-www-form-urlencoded.
    const form = new URLSearchParams();
    form.set("mode", "payment");
    form.set("success_url", callbackUrl + "?status=success");
    form.set("cancel_url", callbackUrl + "?status=cancelled");
    form.set("line_items[0][quantity]", "1");
    form.set("line_items[0][price_data][currency]", currency.toLowerCase());
    form.set("line_items[0][price_data][unit_amount]", String(amountMinor));
    form.set("line_items[0][price_data][product_data][name]", description);
    Object.keys(metadata || {}).forEach((k) => {
      if (metadata[k]) form.set("metadata[" + k + "]", String(metadata[k]));
    });

    const res = await fetch("https://api.stripe.com/v1/checkout/sessions", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: "Bearer " + secret,
      },
      body: form.toString(),
    });

    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      const msg = (data && data.error && data.error.message) || `Stripe error ${res.status}`;
      throw new GatewayError(msg);
    }
    return { id: data.id, redirectUrl: data.url };
  }
}

class GatewayError extends Error {}

// Registry + selector.
const GATEWAYS = {
  moyasar: new MoyasarGateway(),
  tap: new TapGateway(),
  stripe: new StripeGateway(),
};

function selectGateway() {
  const key = (process.env.PAYMENT_GATEWAY || "moyasar").toLowerCase();
  return GATEWAYS[key] || GATEWAYS.moyasar;
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------
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

  const gateway = selectGateway();
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

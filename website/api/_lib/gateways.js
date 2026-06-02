"use strict";
// =============================================================================
// PaymentGateway registry + abstraction.
// Shared by api/donate.js and the test suite.
// Keys are read from process.env ONLY in donate.js (handler scope) — never here.
// =============================================================================

// Append query params to a URL that may already carry a query string, choosing
// `?` or `&` correctly — so a callback base like `…/support.html?thanks=1`
// never produces a malformed `?thanks=1?status=success`.
function appendParams(url, params) {
  const sep = String(url).includes("?") ? "&" : "?";
  const qs = Object.keys(params)
    .filter((k) => params[k] !== undefined && params[k] !== null && params[k] !== "")
    .map((k) => encodeURIComponent(k) + "=" + encodeURIComponent(params[k]))
    .join("&");
  return qs ? url + sep + qs : url;
}

class PaymentGateway {
  get id() { return "abstract"; }
  isConfigured() { return false; }
  // eslint-disable-next-line no-unused-vars
  async createPayment(_args) {
    throw new Error("createPayment not implemented");
  }
}

// --- Moyasar (PRIMARY, Mada + Visa + Mastercard, KSA) ----------------------
// Docs: https://docs.moyasar.com/ — Invoice API returns a hosted payment URL.
// Card entry happens on Moyasar's PCI-compliant hosted page, never here.
class MoyasarGateway extends PaymentGateway {
  get id() { return "moyasar"; }
  isConfigured() { return !!process.env.MOYASAR_SECRET_KEY; }

  async createPayment({ amountMinor, currency, description, metadata, callbackUrl }) {
    const secret = process.env.MOYASAR_SECRET_KEY;
    const auth = "Basic " + Buffer.from(secret + ":").toString("base64");
    const res = await fetch("https://api.moyasar.com/v1/invoices", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: auth },
      body: JSON.stringify({
        amount: amountMinor, currency, description,
        callback_url: callbackUrl, metadata,
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
// Docs: https://developers.tap.company/ — Charges API returns transaction.url.
// STUB: verify field names against current Tap docs before going live.
class TapGateway extends PaymentGateway {
  get id() { return "tap"; }
  isConfigured() { return !!process.env.TAP_SECRET_KEY; }

  async createPayment({ amountMinor, currency, description, metadata, callbackUrl }) {
    const secret = process.env.TAP_SECRET_KEY;
    const amountMajor = amountMinor / 100; // Tap expects major units
    const res = await fetch("https://api.tap.company/v2/charges", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: "Bearer " + secret },
      body: JSON.stringify({
        amount: amountMajor, currency, description,
        source: { id: "src_all" },
        redirect: { url: callbackUrl },
        metadata,
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
// Note: Stripe does NOT support Mada — Visa/Mastercard only.
class StripeGateway extends PaymentGateway {
  get id() { return "stripe"; }
  isConfigured() { return !!process.env.STRIPE_SECRET_KEY; }

  async createPayment({ amountMinor, currency, description, metadata, callbackUrl }) {
    const secret = process.env.STRIPE_SECRET_KEY;
    const form = new URLSearchParams();
    form.set("mode", "payment");
    form.set("success_url", appendParams(callbackUrl, { status: "success" }));
    form.set("cancel_url", appendParams(callbackUrl, { status: "cancelled" }));
    form.set("line_items[0][quantity]", "1");
    form.set("line_items[0][price_data][currency]", currency.toLowerCase());
    form.set("line_items[0][price_data][unit_amount]", String(amountMinor));
    form.set("line_items[0][price_data][product_data][name]", description);
    Object.keys(metadata || {}).forEach((k) => {
      if (metadata[k]) form.set("metadata[" + k + "]", String(metadata[k]));
    });
    const res = await fetch("https://api.stripe.com/v1/checkout/sessions", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded", Authorization: "Bearer " + secret },
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

class GatewayError extends Error {}

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
  GatewayError, GATEWAYS, selectGateway, appendParams,
};

"use strict";
// =============================================================================
// Tarf — Webhook signature verify  (Vercel / Netlify-style)
//
// POST /api/webhook
//   Verifies the gateway's HMAC signature and acknowledges idempotently.
//   If no webhook secret is configured yet, accepts in TEST MODE (safe before
//   the owner sets MOYASAR_WEBHOOK_SECRET / TAP_WEBHOOK_SECRET / etc.).
//
// ENVIRONMENT VARIABLES
//   PAYMENT_GATEWAY              "moyasar" (default) | "tap" | "stripe" | "stub"
//   MOYASAR_WEBHOOK_SECRET       Moyasar webhook signing secret (owner-provided)
//   TAP_WEBHOOK_SECRET           Tap webhook signing secret (owner-provided)
//   STRIPE_WEBHOOK_SECRET        Stripe webhook signing secret (owner-provided)
//
// This file uses only node:crypto — no npm deps.
// =============================================================================

const crypto = require("node:crypto");

// Per-gateway signature header + scheme. Owner sets <GATEWAY>_WEBHOOK_SECRET.
const SCHEMES = {
  moyasar: { header: "x-moyasar-signature", algo: "sha256", enc: "hex" },
  tap:     { header: "tap-signature",       algo: "sha256", enc: "hex" },
  stripe:  { header: "stripe-signature",    algo: "sha256", enc: "hex" },
};

function timingSafeEqual(a, b) {
  const ba = Buffer.from(String(a));
  const bb = Buffer.from(String(b));
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
  if (req.method !== "POST") {
    res.statusCode = 405;
    return res.end("Method not allowed");
  }
  const rawBody = await new Promise((resolve) => {
    let raw = "";
    req.on("data", (c) => (raw += c));
    req.on("end", () => resolve(raw));
    req.on("error", () => resolve(""));
  });
  const gateway = (process.env.PAYMENT_GATEWAY || "moyasar").toLowerCase();
  const secret = process.env[gateway.toUpperCase() + "_WEBHOOK_SECRET"] || "";
  const v = verifySignature({ gateway, rawBody, headers: req.headers, secret });
  if (!v.ok) {
    res.statusCode = 400;
    return res.end(JSON.stringify({ ok: false, reason: v.reason }));
  }
  if (v.testMode && gateway !== "stub") {
    // Loud signal: an UNSIGNED callback was accepted only because no webhook
    // secret is set yet. Set <GATEWAY>_WEBHOOK_SECRET before production so
    // forged "payment_paid" callbacks can't be accepted (deploy-before-keys).
    console.warn(
      "[webhook] ACCEPTING UNSIGNED callback in TEST MODE — set " +
        gateway.toUpperCase() + "_WEBHOOK_SECRET before going live."
    );
  }
  // Signature good (or test mode). Idempotent ack; persistence is an owner concern.
  res.statusCode = 200;
  res.setHeader("Content-Type", "application/json");
  res.setHeader("Cache-Control", "no-store");
  res.end(JSON.stringify({ ok: true, testMode: !!v.testMode }));
};
module.exports.verifySignature = verifySignature;

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

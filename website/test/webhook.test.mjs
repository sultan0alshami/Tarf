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

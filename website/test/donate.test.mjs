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

import { test } from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { appendParams } = require("../api/_lib/gateways.js");

test("appendParams uses ? when the base URL has no query string", () => {
  assert.equal(appendParams("https://x.test/p", { a: 1 }), "https://x.test/p?a=1");
});

test("appendParams uses & when the base URL already has a query string", () => {
  // Regression for the Stripe callback bug: callbackUrl is built as
  // …/support.html?thanks=1, so a second append must use & — never a malformed
  // `?thanks=1?status=success`.
  const out = appendParams("https://x.test/support.html?thanks=1", { status: "success" });
  assert.equal(out, "https://x.test/support.html?thanks=1&status=success");
  assert.doesNotMatch(out, /\?[^?]*\?/); // no double `?`
});

test("appendParams skips empty/undefined values and encodes the rest", () => {
  assert.equal(
    appendParams("https://x.test/p?z=0", { a: "a b", b: "", c: undefined, d: 2 }),
    "https://x.test/p?z=0&a=a%20b&d=2"
  );
});

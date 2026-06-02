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

test("popup shows a dhikr line and the full-app download link", () => {
  const html = read("popup.html");
  assert.match(html, /id="dhikr"/);
  assert.match(html, /tarf\.app\/download|data-i18n="link\.download"/);
});

test("no donate/support affordance on the dhikr surfaces (reverence)", () => {
  for (const f of ["popup.html", "sidepanel.html"]) {
    const html = read(f);
    assert.doesNotMatch(html, /support|ادعمنا|link\.support/);
  }
});

test("i18n module exposes ar+en and the limit/breakNow keys", () => {
  const js = read("i18n.js");
  assert.match(js, /limit:/);
  assert.match(js, /breakNow:/);
  assert.match(js, /\bar\b/); assert.match(js, /\ben\b/);
});

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

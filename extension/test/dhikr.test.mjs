import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const ROOT = dirname(fileURLToPath(import.meta.url));
const data = JSON.parse(readFileSync(join(ROOT, "..", "dhikr.json"), "utf8"));
// Arabic harakat (tashkil) range — reverence rule: sacred Arabic is fully vocalized.
const TASHKIL = /[ً-ْٰ]/;

test("dhikr set is a non-empty array", () => {
  assert.ok(Array.isArray(data.dhikr) && data.dhikr.length >= 5);
});

test("every entry has arabic + transliteration + english, all non-empty", () => {
  for (const d of data.dhikr) {
    for (const k of ["arabic", "transliteration", "english"]) {
      assert.equal(typeof d[k], "string");
      assert.ok(d[k].trim().length > 0, `${k} empty in ${JSON.stringify(d)}`);
    }
  }
});

test("every arabic line carries tashkil (fully vocalized, never bare)", () => {
  for (const d of data.dhikr) {
    assert.match(d.arabic, TASHKIL, `not vocalized: ${d.arabic}`);
  }
});

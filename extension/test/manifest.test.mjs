import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const m = JSON.parse(readFileSync(join(ROOT, "manifest.json"), "utf8"));
const ALLOWED = new Set(["alarms", "notifications", "offscreen", "storage", "idle", "sidePanel"]);

test("is Manifest V3 with a service worker", () => {
  assert.equal(m.manifest_version, 3);
  assert.ok(m.background && m.background.service_worker, "service_worker required");
  assert.ok(existsSync(join(ROOT, m.background.service_worker)));
});

test("permissions are a subset of the justified allowlist", () => {
  for (const p of m.permissions || []) assert.ok(ALLOWED.has(p), `unjustified permission: ${p}`);
});

test("requests NO host permissions (core loop needs none)", () => {
  assert.deepEqual(m.host_permissions || [], []);
  assert.equal(JSON.stringify(m).includes("<all_urls>"), false);
});

test("CSP forbids remote code (script-src 'self' only)", () => {
  const csp = (m.content_security_policy && m.content_security_policy.extension_pages) || "";
  assert.match(csp, /script-src 'self'/);
  assert.doesNotMatch(csp, /https?:\/\//, "no remote script origins allowed");
});

test("every referenced HTML/icon file exists", () => {
  const refs = [
    m.action && m.action.default_popup,
    m.side_panel && m.side_panel.default_path,
    ...Object.values((m.icons) || {}),
  ].filter(Boolean);
  for (const r of refs) assert.ok(existsSync(join(ROOT, r)), `missing ${r}`);
});

test("side panel is declared so the documented dashboard IA exists", () => {
  assert.ok(m.side_panel && m.side_panel.default_path === "sidepanel.html");
  assert.ok((m.permissions || []).includes("sidePanel"));
});

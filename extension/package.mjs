// Cross-platform packager → tarf-extension.zip. Prefers `zip` (Linux/macOS CI),
// falls back to PowerShell Compress-Archive (Windows). No npm deps.
import { execFileSync } from "node:child_process";
import { existsSync, rmSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT = join(HERE, "tarf-extension.zip");
const INCLUDE = [
  "manifest.json", "background.js", "offscreen.html", "offscreen.js",
  "popup.html", "popup.css", "popup.js", "i18n.js",
  "sidepanel.html", "sidepanel.js", "dhikr.json",
  "icon16.png", "icon48.png", "icon128.png",
].filter((f) => existsSync(join(HERE, f)));

if (existsSync(OUT)) rmSync(OUT);

try {
  execFileSync("zip", ["-X", OUT, ...INCLUDE], { cwd: HERE, stdio: "inherit" });
} catch {
  // Windows fallback: PowerShell Compress-Archive
  const list = INCLUDE.map((f) => `'${join(HERE, f).replace(/\\/g, "/")}'`).join(",");
  execFileSync("pwsh", ["-NoProfile", "-Command",
    `Compress-Archive -Path @(${list}) -DestinationPath '${OUT.replace(/\\/g, "/")}' -Force`,
  ], { cwd: HERE, stdio: "inherit" });
}

console.log("Wrote", OUT);

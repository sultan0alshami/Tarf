# Phase 6 — Release Readiness: Implementation Plan
> For agentic workers: implement task-by-task; steps use `- [ ]`.

**Goal:** Produce every store-readiness artifact for Tarf (طَرْف) that does NOT require owner
credentials or a Mac: a single Tarf mark exported to every platform icon/splash slot; a per-store
screenshot pipeline (AR+EN × light+dark across the key routes) built on the existing
`app/_setup/shots.ps1`; finalized AR+EN store metadata; concrete compliance artifacts
(`PrivacyInfo.xcprivacy`, a Play Data-Safety answer map, an aligned permissions matrix, hosting-ready
privacy/terms); and an actionable, ordered release checklist that cleanly separates "I can prep" from
"owner submits." Actual submissions, account forms, and code signing remain owner tasks (Apple/Google/
Microsoft accounts + a macOS machine/runner for iOS/macOS).

**Architecture:** Asset/config/docs only — no app source logic changes. A single set of authored SVG
masters (the طَرْف / eye-blink glyph in the "Calm Sanctuary" teal) is rasterized with the locally
available `rsvg-convert` (v2.61.1) into a 1024 px master PNG; `flutter_launcher_icons` +
`flutter_native_splash` then fan that master out to Android adaptive layers (foreground / background /
monochrome), the iOS `AppIcon.appiconset`, the macOS iconset, the Windows `.ico`, the web/PWA icons
(incl. maskable) and the favicon — writing into the exact platform paths Flutter already scaffolds.
Screenshots reuse the proven headless-Chrome recipe (IPv4 bind, `--user-data-dir`, `--headless`,
`#/route` deep links, `SKIP_ONBOARDING=true` + `FORCE_THEME=light|dark` dart-defines), extended with a
locale dart-define, a per-store device-size matrix, and a shot manifest. Compliance artifacts are
generated verbatim from the already-written `docs/compliance/*` (the `apple-privacy.md` plist is copied
into `ios/Runner/PrivacyInfo.xcprivacy`; the data-safety doc becomes a structured answer map). Metadata
is finalized AR+EN building on `docs/store/*`.

**Tech Stack:** Flutter 3.44 / Dart 3.12 (`C:\dev\flutter\bin\flutter.bat`) · `flutter_launcher_icons`
· `flutter_native_splash` · `rsvg-convert` 2.61.1 (`C:\msys64\mingw64\bin\rsvg-convert.exe`, SVG→PNG at
exact sizes) · Python `http.server` (`C:\msys64\mingw64\bin\python.exe`) · headless Chrome
(`C:\Program Files\Google\Chrome\Application\chrome.exe`) · PowerShell 7. Design tokens (from
`design.md` / P0 `tokens.dart`): seed `#0E7C66`; primary `#2FB89B` dark / `#0B6A57` light; dark bg
`#0B0F0E`; warm-paper light bg `#F7F5F0`; fonts Amiri (sacred) + Inter (UI).

> **TOOLING REALITY (verified on this machine, drives the whole asset task):**
> `magick`/ImageMagick is **NOT installed** (`convert.exe` on PATH is the Windows *volume-format*
> utility — never call it); Inkscape, Pillow, and cairosvg are **absent**. The only SVG rasterizer is
> **`rsvg-convert`**, which renders an SVG to an exact `-w×-h` PNG. Therefore: author masters as SVG,
> rasterize with `rsvg-convert`, and let `flutter_launcher_icons`/`flutter_native_splash` build the
> platform sets and the Windows `.ico` from the master PNG (no ImageMagick needed anywhere).

> **HONESTY / OWNERSHIP:** Everything in Tasks 1–9 is **I can prep** (assets, config, docs, manifests,
> the screenshot pipeline + captured PNGs). The acts that need accounts/keys/Mac — App Store Connect /
> Play Console / Partner Center / CWS form entry, code signing, notarization, `flutterfire configure`,
> hosting the policy URLs, the dhikr scholarly sign-off — are **owner submits** and are listed (not
> performed) in Task 9.

---

## File Structure

```
app/
  pubspec.yaml                         # MODIFY: add dev-deps + flutter_icons + flutter_native_splash config
  assets/
    brand/                             # NEW — authored masters + exported intermediates
      tarf-mark.svg                    # master glyph (square, full-bleed motif)
      tarf-mark-padded.svg             # glyph with safe-area padding (for iOS/macOS/legacy/web)
      tarf-foreground.svg              # Android adaptive FG (glyph in inner 66% safe zone)
      tarf-background.svg              # Android adaptive BG (flat teal field)
      tarf-monochrome.svg              # Android 13+ themed-icon (single-color silhouette + alpha)
      tarf-mark-1024.png               # rasterized master for launcher_icons (generated)
      tarf-foreground-1024.png         # rasterized FG layer (generated)
      tarf-monochrome-1024.png         # rasterized monochrome layer (generated)
      splash-logo.png                  # centered splash logo, transparent (generated, ~1152px)
      splash-branding.png              # optional bottom wordmark for splash (generated)
      README.md                        # NEW — regeneration commands + provenance (OFL/own-work)
  _setup/
    shots.ps1                          # MODIFY: add -Locale, per-store device matrix, manifest output
    build-shot-bundle.ps1              # NEW — compiles the 4 web builds (ar/en × light/dark) for shots
    rasterize-brand.ps1                # NEW — rsvg-convert wrapper: SVG masters -> the PNGs above
    shots/                             # capture output root (gitignored except manifest)
      manifest.json                    # NEW — generated list of every shot (route,store,size,locale,theme)
  android/app/src/main/res/mipmap-*/   # MODIFY (generated): ic_launcher.png + adaptive XML + monochrome
  android/app/src/main/res/values*/    # MODIFY (generated): ic_launcher_background color + styles
  ios/Runner/Assets.xcassets/AppIcon.appiconset/   # MODIFY (generated) full icon set + Contents.json
  ios/Runner/PrivacyInfo.xcprivacy     # NEW — privacy manifest (verbatim from apple-privacy.md §2)
  ios/Runner/Info.plist                # MODIFY (doc-guided): ITSAppUsesNonExemptEncryption + loc strings note
  macos/Runner/Assets.xcassets/AppIcon.appiconset/ # MODIFY (generated) iconset + Contents.json
  windows/runner/resources/app_icon.ico            # MODIFY (generated) multi-size .ico
  web/icons/                           # MODIFY (generated) Icon-192/512 + maskable-192/512
  web/favicon.png                      # MODIFY (generated)
  web/manifest.json                    # MODIFY: name/short_name/description/theme/bg color (de-stock)
  web/index.html                       # MODIFY: <title>, description, apple-mobile-web-app-title
docs/
  store/
    metadata.md                        # NEW — finalized AR+EN listings, all stores, single source
    screenshots.md                     # NEW — per-store size table + shot matrix + capture runbook
    release-checklist.md               # MODIFY — re-author into ordered, per-platform, prep/owner split
  compliance/
    google-play-data-safety-answers.json   # NEW — structured Play Data-Safety answer map
    permissions-matrix.md              # MODIFY — align with Phase 2's real permission set + status table
    privacy-policy.md                  # MODIFY — fill placeholders that don't need legal/owner sign-off
    terms-of-service.md                # MODIFY — same: fill non-owner placeholders, flag the rest
    apple-privacy.md                   # (read-only source for PrivacyInfo.xcprivacy; no edit needed)
```

---

## Cross-phase dependencies & integration points

- **INDEPENDENT / parallelizable from the start.** This is an assets+docs+config phase; it touches no
  Dart logic and shares no mutable runtime state with other phases.
- **Soft dependency — Phase 2 (background) permissions ↔ this phase's permission artifacts.**
  `docs/superpowers/plans/2026-06-01-tarf-phase2-background.md` **does not exist yet** (verified: only
  `2026-05-31-tarf-implementation-plan.md` is present). The authoritative permission list therefore
  comes from **P4 of `2026-05-31-tarf-implementation-plan.md`** and **`docs/compliance/permissions-matrix.md`**, which already agree:
  `POST_NOTIFICATIONS`, `USE_EXACT_ALARM` (+ `SCHEDULE_EXACT_ALARM` fallback), `USE_FULL_SCREEN_INTENT`,
  `FOREGROUND_SERVICE` + a typed `FOREGROUND_SERVICE_*`, `ACCESS_COARSE_LOCATION`,
  `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (optional), `RECEIVE_BOOT_COMPLETED`, `VIBRATE`. Two values are
  **still open** and must be reconciled when Phase 2 lands: (a) the exact `foregroundServiceType`
  (`specialUse` vs `mediaPlayback`), and (b) whether `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` actually
  ships. Task 7 records these as `⟦phase2-confirm⟧` markers — a minor, late alignment, **not** a blocker.
- **Screenshot pipeline ↔ the built web app.** `shots.ps1` captures whatever the current `flutter build
  web` renders. Routes used (`/focus`, `/timer`, `/alarm`, `/stopwatch`, `/insights`, `/tasks`,
  `/settings`, `/settings/eyecare`, `/settings/account`, `/eyecare/break`) already exist in the script
  and match `go_router` (PROJECT.md §6). The dart-defines `SKIP_ONBOARDING` + `FORCE_THEME` are P0 debug
  affordances (PROJECT.md §12) and are honored by the build, not the screenshot script — so locale +
  theme are baked at **build** time, captured at **shot** time (Task 2).
- **Icon background color ↔ design tokens.** The Android adaptive background and `flutter_native_splash`
  colors must equal the P0 token values (dark `#0B0F0E`, light `#F7F5F0`, seed `#0E7C66`) so the launcher
  icon and splash match the in-app first frame. No coupling beyond reusing the hex values.
- **Compliance artifacts ↔ already-written docs.** `PrivacyInfo.xcprivacy` is copied verbatim from
  `apple-privacy.md §2`; the Play answer map is a 1:1 transcription of `google-play-data-safety.md`. These
  must stay mutually consistent (the release checklist's cross-check gate enforces it).
- **Shared files (other phases may also touch):** `app/pubspec.yaml` (P0 owns deps — append a dev-deps
  block + two top-level config keys, do not reorder existing entries), `web/manifest.json` +
  `web/index.html` (P0 scaffold — de-stock only), `ios/Runner/Info.plist` +
  `android/.../AndroidManifest.xml` (P4/Phase 2 own permissions — this phase only adds the encryption key
  / icon refs / app label, never permissions). See "## Self-review" for worktree guidance.

---

### Task 1 — Author the Tarf mark + generate every platform icon & splash

Single source of truth = a few hand-authored SVGs in `app/assets/brand/`; `rsvg-convert` rasterizes
them; `flutter_launcher_icons` + `flutter_native_splash` fan them into the platform paths. No master
mark exists today (verified: every current icon is the stock Flutter placeholder), so we author one.

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\assets\brand\tarf-mark.svg` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\assets\brand\tarf-mark-padded.svg` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\assets\brand\tarf-foreground.svg` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\assets\brand\tarf-background.svg` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\assets\brand\tarf-monochrome.svg` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\assets\brand\README.md` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\_setup\rasterize-brand.ps1` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\pubspec.yaml` (MODIFY)
- generated → `app\android\app\src\main\res\mipmap-*\`, `app\android\app\src\main\res\values*\`,
  `app\ios\Runner\Assets.xcassets\AppIcon.appiconset\`,
  `app\macos\Runner\Assets.xcassets\AppIcon.appiconset\`, `app\windows\runner\resources\app_icon.ico`,
  `app\web\icons\`, `app\web\favicon.png`

**Steps:**
- [ ] **(I can prep)** Author `tarf-mark.svg` — a 1024×1024 viewBox, full-bleed. Motif: the **طَرْف /
  eye-blink** — a calm almond eye-aperture formed by two opposing arcs with a single concentric
  "Ambient Ring" (the app's signature, design.md §"Signature"), a soft focal dot at center. Palette:
  ground = vertical gradient `#0B6A57`→`#0E7C66`; arcs/ring = `#2FB89B`; focal dot = `#F7F5F0` at low
  opacity. Pure vector (no raster `<image>`), no text, geometry centered in the inner 80%. Reverent,
  minimal, one accent only.
- [ ] **(I can prep)** Author `tarf-mark-padded.svg` — same glyph scaled to the **inner ~72%** on the
  teal ground (Apple/macOS bake their own mask/rounding; this guarantees the motif never clips).
- [ ] **(I can prep)** Author the three Android adaptive layers:
  - `tarf-background.svg` — flat `#0E7C66` field, 1024×1024 (no transparency).
  - `tarf-foreground.svg` — glyph (arcs + ring + dot, no ground) centered within the inner **66%**
    (Android's adaptive safe zone), fully transparent outside; 1024×1024.
  - `tarf-monochrome.svg` — single-color **white** silhouette of the glyph on transparent (Android 13+
    themed icons tint by alpha); inner 66%; 1024×1024.
- [ ] **(I can prep)** Write `app/assets/brand/README.md`: state the mark is **original work for Tarf**
  (no third-party license), record the exact `rasterize-brand.ps1` invocation, and note "all platform
  icons are GENERATED — never hand-edit the files under `res/`, `Assets.xcassets`, `web/icons`."
- [ ] **(I can prep)** Write `app/_setup/rasterize-brand.ps1` to rasterize masters → PNGs with
  `rsvg-convert` (the only available rasterizer). Exact body:
  ```powershell
  $ErrorActionPreference = "Stop"
  $rsvg = "C:\msys64\mingw64\bin\rsvg-convert.exe"
  $brand = "C:\Users\sulta\Claude_Code\EyeCure_20\app\assets\brand"
  function Raster($svg, $png, $px) {
    & $rsvg -w $px -h $px "$brand\$svg" -o "$brand\$png"
    if (-not (Test-Path "$brand\$png")) { throw "rasterize failed: $png" }
  }
  Raster "tarf-mark-padded.svg" "tarf-mark-1024.png"        1024  # launcher_icons master (iOS/mac/web/win)
  Raster "tarf-foreground.svg"  "tarf-foreground-1024.png"  1024  # Android adaptive FG
  Raster "tarf-monochrome.svg"  "tarf-monochrome-1024.png"  1024  # Android 13+ themed icon
  Raster "tarf-mark.svg"        "splash-logo.png"           1152  # native_splash centered logo
  "rasterized: tarf-mark-1024 / tarf-foreground-1024 / tarf-monochrome-1024 / splash-logo (1152)"
  ```
  Run it: `& 'C:\Users\sulta\Claude_Code\EyeCure_20\app\_setup\rasterize-brand.ps1'`
  Expected output: the final line printed and four PNGs present in `assets\brand\`.
- [ ] **(verify)** Confirm the master rasterized to the exact size:
  `& 'C:\dev\flutter\bin\dart.bat' --version` (sanity Flutter toolchain), then inspect with the Read
  tool — open `app/assets/brand/tarf-mark-1024.png` and confirm it renders as a 1024×1024 teal Tarf
  glyph (not blank, not the Flutter logo).
- [ ] **(I can prep)** In `app/pubspec.yaml`, append `flutter_launcher_icons` + `flutter_native_splash`
  to `dev_dependencies`, and add the two top-level config blocks (do **not** touch existing deps/order):
  ```yaml
  dev_dependencies:
    # ...existing...
    flutter_launcher_icons: ^0.14.4
    flutter_native_splash: ^2.4.6

  flutter_launcher_icons:
    image_path: "assets/brand/tarf-mark-1024.png"
    android: "ic_launcher"
    adaptive_icon_background: "#0E7C66"
    adaptive_icon_foreground: "assets/brand/tarf-foreground-1024.png"
    adaptive_icon_monochrome: "assets/brand/tarf-monochrome-1024.png"
    min_sdk_android: 26
    remove_alpha_ios: true
    ios: true
    image_path_ios: "assets/brand/tarf-mark-1024.png"
    web:
      generate: true
      image_path: "assets/brand/tarf-mark-1024.png"
      background_color: "#0B0F0E"
      theme_color: "#0E7C66"
    windows:
      generate: true
      image_path: "assets/brand/tarf-mark-1024.png"
      icon_size: 256
    macos:
      generate: true
      image_path: "assets/brand/tarf-mark-1024.png"

  flutter_native_splash:
    color: "#F7F5F0"            # light warm-paper ground
    color_dark: "#0B0F0E"       # dark canonical ground
    image: "assets/brand/splash-logo.png"
    android_12:
      image: "assets/brand/splash-logo.png"
      color: "#F7F5F0"
      color_dark: "#0B0F0E"
    web: false                  # PWA uses manifest theme/bg, not a splash image
  ```
- [ ] **(I can prep)** Fetch packages: `& 'C:\dev\flutter\bin\flutter.bat' pub get` (run with the
  `app` dir as cwd). Expected: "Got dependencies!" with no version-solve error.
- [ ] **(I can prep)** Generate launcher icons:
  `& 'C:\dev\flutter\bin\dart.bat' run flutter_launcher_icons`
  Expected output: "✓ Successfully generated launcher icons" for android/ios/web/windows/macos.
- [ ] **(I can prep)** Generate splash:
  `& 'C:\dev\flutter\bin\dart.bat' run flutter_native_splash:create`
  Expected: "Native splash complete." and updated `launch_background.xml` / `styles.xml`.
- [ ] **(verify — Android adaptive)** Confirm the generated adaptive XML + monochrome exist:
  `Get-ChildItem app\android\app\src\main\res -Recurse -Include ic_launcher*.xml,*launcher*foreground*,*monochrome*`
  Expected: `mipmap-anydpi-v26\ic_launcher.xml` referencing `@drawable/ic_launcher_foreground`,
  `@color/ic_launcher_background`, and a `<monochrome>` entry; per-density `ic_launcher.png` rewritten.
  Then Read one density `ic_launcher.png` and confirm it is the teal glyph, not the stock Flutter icon.
- [ ] **(verify — iOS)** Read `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` and the
  1024 png; confirm all slots present and `Icon-App-1024x1024@1x.png` is the Tarf glyph with **no alpha**
  (`remove_alpha_ios: true`). Confirm filenames still match the pre-existing `Contents.json` slot names.
- [ ] **(verify — macOS / Windows / Web)** Confirm: `macos/.../AppIcon.appiconset` has `app_icon_16…1024`
  regenerated; `windows/runner/resources/app_icon.ico` modified (Read → not the default Flutter feather);
  `web/icons/Icon-192/512.png` + both `Icon-maskable-*.png` + `web/favicon.png` regenerated to the glyph.
- [ ] **(verify — visual)** Send the four key produced PNGs to the user for a one-glance sanity check
  (Android `mipmap-xxxhdpi/ic_launcher.png`, iOS 1024, web maskable-512, the splash logo).

---

### Task 2 — Extend `shots.ps1` into a per-store, AR+EN, light+dark capture pipeline

Reuse the proven recipe (IPv4 bind, `--user-data-dir`, `--headless`, `#/route`, scale-factor 2). Add
(a) a **locale + theme build bundle** (the defines are baked at build time), (b) a **per-store device
matrix** (window sizes → device-frame PNGs), and (c) a **shot manifest**.

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\_setup\build-shot-bundle.ps1` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\_setup\shots.ps1` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\_setup\shots\manifest.json` (generated)
- `C:\Users\sulta\Claude_Code\EyeCure_20\docs\store\screenshots.md` (NEW; full runbook in Task 6)

**Steps:**
- [ ] **(I can prep)** Write `build-shot-bundle.ps1` that produces **four** web builds (locale × theme)
  into distinct output dirs, baking the defines at build time:
  ```powershell
  $ErrorActionPreference = "Stop"
  $flutter = "C:\dev\flutter\bin\flutter.bat"
  $app = "C:\Users\sulta\Claude_Code\EyeCure_20\app"
  $out = "C:\Users\sulta\Claude_Code\EyeCure_20\_setup\webbuilds"
  foreach ($loc in @("ar","en")) {
    foreach ($theme in @("light","dark")) {
      $dir = "$out\$loc-$theme"
      & $flutter build web --release `
        --dart-define=SKIP_ONBOARDING=true `
        --dart-define=FORCE_THEME=$theme `
        --dart-define=FORCE_LOCALE=$loc `
        --output "$dir"
      if (-not (Test-Path "$dir\index.html")) { throw "build failed: $loc-$theme" }
      "BUILT $loc-$theme"
    }
  }
  ```
  > **Dependency note:** `FORCE_LOCALE` is the only new define. If P0 has not yet wired a `FORCE_LOCALE`
  > reader (it currently ships `SKIP_ONBOARDING` + `FORCE_THEME` per PROJECT.md §12), mark this
  > `⟦p0-confirm⟧`: either P0 adds a one-line `FORCE_LOCALE` override beside `FORCE_THEME`, or fall back
  > to building once and switching locale via the in-app Settings → Language toggle before capture (the
  > pipeline still captures both, just less hermetically). Do not edit P0 source here; file the request.
- [ ] **(I can prep)** Modify `shots.ps1` signature to accept the build bundle + a store profile and a
  locale, and to point `$web` at the locale/theme build dir:
  ```powershell
  param(
    [ValidateSet("light","dark")] [string]$Theme = "dark",
    [ValidateSet("ar","en")]      [string]$Locale = "ar",
    [ValidateSet("iphone67","iphone65","iphone55","ipad129","androidphone","androidtablet","windows","mac","pwa")]
      [string]$Store = "iphone67",
    [int]$Port = 8770,
    [string]$OutRoot = "C:\Users\sulta\Claude_Code\EyeCure_20\_setup\shots"
  )
  $web = "C:\Users\sulta\Claude_Code\EyeCure_20\_setup\webbuilds\$Locale-$Theme"
  ```
- [ ] **(I can prep)** Add the **device matrix** (CSS window size + device-scale → exact store px). Keep
  the existing per-route loop; drive window-size/scale from `$Store`:
  ```powershell
  # name => @{ w; h; scale }  -> emitted PNG = (w*scale) x (h*scale)
  $devices = @{
    iphone67     = @{ w=430; h=932; scale=3 }   # 1290x2796  (6.7")
    iphone65     = @{ w=414; h=896; scale=3 }   # 1242x2688  (6.5")
    iphone55     = @{ w=414; h=736; scale=3 }   # 1242x2208  (5.5")
    ipad129      = @{ w=1024; h=1366; scale=2 } # 2048x2732  (iPad 12.9")
    androidphone = @{ w=412; h=915; scale=3 }   # 1236x2745 -> crop/letterbox to 1080x1920+ (16:9/9:16)
    androidtablet= @{ w=800; h=1280; scale=2 }  # 1600x2560  (7"/10" tablet)
    windows      = @{ w=1366; h=768; scale=1 }  # 1366x768   (MS Store min)
    mac          = @{ w=1280; h=800; scale=2 }  # 2560x1600  (Mac App Store 16:10)
    pwa          = @{ w=412; h=915; scale=3 }    # PWA / generic phone
  }
  $d = $devices[$Store]
  # in the chrome call: --force-device-scale-factor=$($d.scale) --window-size=$($d.w),$($d.h)
  # output dir: $OutRoot\$Store\$Locale-$Theme\<route>.png
  ```
- [ ] **(I can prep)** Keep the existing route set; the eye-care/dhikr matrix is the headline shot. Map
  the alarm variants by deep-link query so both "standard" and "prayer-pause" alarm states are captured:
  ```powershell
  $routes = [ordered]@{
    home          = "/focus"
    dhikrbreak    = "/eyecare/break"
    focus         = "/focus?demo=running"        # running session hero (if demo flag exists; else /focus)
    timer         = "/timer"
    alarm         = "/alarm"
    alarmprayer   = "/settings/eyecare?prayer=1" # prayer-pause surface
    stopwatch     = "/stopwatch"
    insights      = "/insights"
  }
  ```
  > `?demo=` / `?prayer=` are optional convenience flags; if P0 hasn't wired them, capture the plain
  > route (`/focus`, `/alarm`) — the shot is still valid. Mark `⟦p0-confirm⟧` and do not add app code.
- [ ] **(I can prep)** Append a **manifest writer** to `shots.ps1` so each run records what it produced:
  after the route loop, append one object per shot (`{store, locale, theme, route, file, w, h, bytes}`)
  into `"$OutRoot\manifest.json"` (merge, don't clobber other store/locale runs).
- [ ] **(I can prep)** Build the bundle once:
  `& 'C:\Users\sulta\Claude_Code\EyeCure_20\app\_setup\build-shot-bundle.ps1'`
  Expected: four "BUILT …" lines and four `index.html` files under `_setup\webbuilds\*`.
- [ ] **(I can prep)** Capture the full matrix (8 store profiles × ar/en × light/dark). Loop:
  ```powershell
  foreach ($s in "iphone67","iphone65","iphone55","ipad129","androidphone","androidtablet","windows","mac","pwa") {
    foreach ($l in "ar","en") { foreach ($t in "light","dark") {
      & 'C:\Users\sulta\Claude_Code\EyeCure_20\app\_setup\shots.ps1' -Store $s -Locale $l -Theme $t -Port 8770
    }}}
  ```
  Expected: a stream of `OK  <route>.png  (NNNN bytes)` lines; no `MISS`. (≈ 8×2×2×8 ≈ 256 PNGs; trim
  per store to the store's required count in Task 6.)
- [ ] **(verify — size)** Pick one shot and confirm exact pixels with Flutter's bundled tooling-free
  check via PowerShell + .NET image decode:
  ```powershell
  Add-Type -AssemblyName System.Drawing
  $img = [System.Drawing.Image]::FromFile("C:\Users\sulta\Claude_Code\EyeCure_20\_setup\shots\iphone67\ar-dark\dhikrbreak.png")
  "$($img.Width)x$($img.Height)"   # expect 1290x2796
  $img.Dispose()
  ```
  Expected output: `1290x2796`.
- [ ] **(verify — RTL/theme)** Read `…\iphone67\ar-dark\dhikrbreak.png` and `…\en-light\home.png`;
  confirm (a) Arabic shot shows the dhikr line in Amiri, RTL layout (nav mirrored), dark `#0B0F0E`-ish
  ground; (b) English shot is LTR on the warm-paper light ground. Spot-check `windows\en-dark\insights.png`
  is landscape 1366×768.
- [ ] **(verify — manifest)** Read `_setup\shots\manifest.json`; confirm one entry per produced PNG with
  correct `w/h/store/locale/theme/route` and non-zero `bytes`.
- [ ] **(I can prep — optional)** Branded marketing frames: a calm template (teal ground, one-line AR/EN
  headline above the device PNG) for the App Store/Play "feature" slots. Compose with `rsvg-convert` from
  a parametric `frame.svg` that `<image>`-embeds the raw screenshot; keep reverent, never near the dhikr
  text. Mark optional; skip if time-boxed.

---

### Task 3 — Finalize store metadata (AR + EN, all stores) → `docs/store/metadata.md`

Build on `docs/store/{app-store,google-play,microsoft-store,chrome-web-store}.md`; consolidate every
listing field into one authoritative file with both languages, respecting char limits, reverent + honest
tone, and the "no payment in the iOS binary / Chrome-open-only" truths.

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\docs\store\metadata.md` (NEW)

**Steps:**
- [ ] **(I can prep)** Header block: app name `Tarf` + display `طَrف` handling per store; bundle/package
  ids (`app.tarf`, `app.tarf.ios`, `app.tarf.mac`, `app.tarf.android`); primary language **Arabic**, add
  **English**; categories (primary **Health & Fitness**, secondary **Productivity**); content rating
  target (4+/Everyone/PEGI 3); pricing **Free**.
- [ ] **(I can prep)** **App Store** section: Name (≤30), Subtitle (≤30) AR+EN; Promotional text (≤170)
  AR+EN; Description (≤4000) AR+EN; Keywords (≤100 chars, comma-sep, no spaces) AR+EN; What's New (≤4000)
  AR+EN for v1.0.0; Support URL `[[https://tarf.app/support]]`, Marketing URL `[[https://tarf.app]]`,
  Privacy URL `[[https://tarf.app/privacy]]`. Include the **iOS honesty line** (background reminders on
  iOS < 26 are degraded; no payment in app — thank-you/share only).
- [ ] **(I can prep)** **Google Play** section: Title (≤30), Short description (≤80), Full description
  (≤4000) AR+EN; the exact-alarm / FGS / full-screen-intent **declaration justifications** (paste-ready);
  ads = No; data-safety pointer to Task 5; contact email `[[support@tarf.app]]`.
- [ ] **(I can prep)** **Microsoft Store** section: description, "what's new", search terms AR+EN; note
  the external **Support** donation link is allowed on Windows; tray/Guest-mode certification notes.
- [ ] **(I can prep)** **Chrome Web Store** section: Name "Tarf — Eye-care + Dhikr break", Summary (≤132)
  AR+EN, Detailed description AR+EN with the **Chrome-must-be-open** limitation; the verbatim
  **single-purpose statement** and the **per-permission justifications** table (alarms / notifications /
  offscreen / storage / sidePanel / idle) copied from `chrome-web-store.md §2–3`.
- [ ] **(I can prep)** A short **tone & review-safety** note: reverent, factual, no proselytizing in
  metadata; real Arabic copy (no lorem); donations framed as ṣadaqah/khayr, never guilt; consistent claims
  across all four stores.
- [ ] **(verify)** Lint char counts with a deterministic check (no external tool):
  ```powershell
  $m = Get-Content "C:\Users\sulta\Claude_Code\EyeCure_20\docs\store\metadata.md" -Raw
  # eyeball the fenced `name:` / `short:` blocks; assert each labelled field ≤ its stated limit
  ```
  Expected: every field annotated with `(NN/limit)` and no value exceeding its limit; `[[PLACEHOLDER]]`
  used only for owner-supplied URLs/emails.

---

### Task 4 — Generate `ios/Runner/PrivacyInfo.xcprivacy` + Info.plist encryption key

The plist content already exists, finalized, in `apple-privacy.md §2`. Copy it verbatim into the Runner
target (this is a static manifest, no Mac needed to author it) and record the `Info.plist` keys the owner
must confirm on macOS.

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\ios\Runner\PrivacyInfo.xcprivacy` (NEW)
- `C:\Users\sulta\Claude_Code\EyeCure_20\app\ios\Runner\Info.plist` (MODIFY)

**Steps:**
- [ ] **(I can prep)** Create `PrivacyInfo.xcprivacy` with the exact plist from `apple-privacy.md §2`:
  `NSPrivacyTracking=false`, empty `NSPrivacyTrackingDomains`, four `NSPrivacyCollectedDataType` entries
  (EmailAddress, UserID, ProductInteraction, OtherUserContent — all Linked=true, Tracking=false, purpose
  AppFunctionality), and two `NSPrivacyAccessedAPIType` entries (UserDefaults `CA92.1`, FileTimestamp
  `C617.1`). Add the inline comment that CrashData / SystemBootTime `35F9.1` / DiskSpace `E174.1` are
  added **only** if those APIs are actually used (per the doc's caveats).
- [ ] **(I can prep)** Read `app/ios/Runner/Info.plist`; if `ITSAppUsesNonExemptEncryption` is absent,
  add `<key>ITSAppUsesNonExemptEncryption</key><false/>` (justified in `apple-privacy.md §4` — only
  exempt TLS/Keychain crypto). Do **not** add or remove any permission usage-description here (those are
  P4/Phase 2's `NSLocationWhenInUseUsageDescription` territory) — only the encryption key. If the key is
  already present, leave it and note "already set."
- [ ] **(verify — well-formed plist)** Validate XML without a Mac, using PowerShell:
  ```powershell
  [xml]$x = Get-Content "C:\Users\sulta\Claude_Code\EyeCure_20\app\ios\Runner\PrivacyInfo.xcprivacy" -Raw
  $x.plist.dict.key   # expect: NSPrivacyTracking, NSPrivacyTrackingDomains, NSPrivacyCollectedDataTypes, NSPrivacyAccessedAPITypes
  ```
  Expected: the four top-level keys print and no XML parse error is thrown.
- [ ] **(verify — counts)** Confirm 4 collected-type dicts and 2 accessed-API dicts:
  ```powershell
  ([regex]::Matches($x.OuterXml,'NSPrivacyCollectedDataType<')).Count    # 4
  ([regex]::Matches($x.OuterXml,'NSPrivacyAccessedAPIType<')).Count       # 2
  ```
  Expected: `4` and `2`. (Owner re-verifies reason codes against the real pod tree on macOS — Task 9.)

---

### Task 5 — Build the Play Data-Safety answer map → `google-play-data-safety-answers.json`

`google-play-data-safety.md` already specifies every answer; transcribe it into a structured JSON the
owner pastes/keys into Play Console, so the human form-fill is mechanical and provably consistent with
the Apple label.

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\docs\compliance\google-play-data-safety-answers.json` (NEW)

**Steps:**
- [ ] **(I can prep)** Emit top-level answers: `collectsOrShares=true` (signed-in worst case),
  `encryptedInTransit=true`, `deletionMethod="in-app + web URL"`,
  `deletionUrl="[[https://tarf.app/delete-account]]"`, `privacyPolicyUrl="[[https://tarf.app/privacy]]"`,
  `familiesPolicy=false`.
- [ ] **(I can prep)** Per-type array mirroring the doc tables — for each: `{type, collected, shared,
  ephemeral, optional, purposes[]}`. Collected (all Shared=false, purpose App functionality / Account
  management): Email; User IDs; App interactions; Other user content (to-dos/notes). Explicitly **Not
  collected**: Approximate location (on-device only), Precise location, Financial/Payment, Religious
  beliefs, Advertising ID, Crash/Diagnostics (`crashSdkShipped=false` flag → if v1 ships none).
- [ ] **(I can prep)** Add a `consistencyAssertions` block listing the three forms that MUST match
  (Apple label / this map / Privacy Policy) and the four "No" answers that are the common rejection traps
  (location-not-collected, no-ad-ID, religion-not-collected, payment-website-only).
- [ ] **(verify — valid JSON + parity)** Parse and assert the no-tracking/no-ads invariants:
  ```powershell
  $j = Get-Content "C:\Users\sulta\Claude_Code\EyeCure_20\docs\compliance\google-play-data-safety-answers.json" -Raw | ConvertFrom-Json
  $j.encryptedInTransit                                   # True
  ($j.dataTypes | Where-Object { $_.type -eq "Advertising ID" }).collected   # False
  ($j.dataTypes | Where-Object { $_.type -match "Religious" }).collected     # False
  ```
  Expected: `True`, `False`, `False`, and `ConvertFrom-Json` throws no error.

---

### Task 6 — Author the screenshot runbook → `docs/store/screenshots.md`

Document the exact sizes each store requires, the shot matrix, which captured file maps to which store
slot, and the end-to-end capture commands (so the pipeline from Task 2 is reproducible by the owner or CI).

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\docs\store\screenshots.md` (NEW)

**Steps:**
- [ ] **(I can prep)** **Per-store required sizes** table (the authoritative spec):
  | Store | Required device sizes (px, portrait unless noted) | Min count | Notes |
  |---|---|---|---|
  | App Store iOS | 6.7" **1290×2796** (req), 6.5" **1242×2688**, 5.5" **1242×2208** | 1 set (6.7" mandatory) | AR(RTL)+EN; ≤10 each |
  | App Store iPad | 12.9"/13" **2048×2732** | 1 set if iPad supported | AR+EN |
  | Google Play phone | **1080×1920**+ (9:16), 2–8 | 2 | AR+EN; +feature graphic 1024×500 |
  | Google Play tablet | 7": **1600×2560**, 10": larger | optional | only if tablet listed |
  | Microsoft Store | **1366×768**+ (landscape) | 1 | AR+EN |
  | Mac App Store | **2560×1600** (16:10) | 1 | AR+EN |
  | Chrome Web Store | **1280×800** (or 640×400) | 1 (3–5 ideal) | AR+EN where possible |
  | PWA (web listing) | **1080×1920** generic phone | — | for the download website |
- [ ] **(I can prep)** **Shot matrix:** routes × {ar,en} × {light,dark}. Headline order per store:
  `dhikrbreak` (the reverent peak) → `home` (eye-care hero) → `focus` → `insights` → `timer` →
  `alarm`/`alarmprayer` → `stopwatch`. Note Apple/Play want the dhikr-break + Insights up front.
- [ ] **(I can prep)** **File→slot map:** `_setup/shots/<store>/<locale>-<theme>/<route>.png` → e.g.
  "App Store 6.7" AR set = `iphone67/ar-dark/{dhikrbreak,home,focus,insights,timer}.png`". Recommend the
  **dark** theme as the primary store set (canonical), light as the alternate.
- [ ] **(I can prep)** **Capture runbook:** the two commands (`build-shot-bundle.ps1` then the capture
  loop from Task 2), the `System.Drawing` size-check snippet, the manifest location, and the Android
  9:16 crop note (Play wants 9:16/16:9; the `androidphone` 1236×2745 is letterboxed/cropped to 1080×1920
  — document the crop, do not stretch).
- [ ] **(I can prep)** **Honesty captions:** suggested AR+EN caption lines for the iOS background-limit
  and the Chrome-open-only states, to use if a store allows caption text (kept reverent).
- [ ] **(verify)** Cross-check the table against `app-store.md §5`, `google-play.md §4`,
  `microsoft-store.md §4`, `chrome-web-store.md §5`: Read each and confirm every size/min-count in the
  table matches its source guide (no contradictions). Note any store that has since changed a size as
  `⟦verify-current⟧` for the owner to re-confirm at submit time.

---

### Task 7 — Align `permissions-matrix.md` with Phase 2's real permission set

The matrix is already thorough; add a concrete, single **"Implemented permission set"** table tied to
the manifest, and mark the two values Phase 2 must finalize. Do **not** edit `AndroidManifest.xml` /
`Info.plist` permissions here — that is P4/Phase 2's job; this aligns the *contract*.

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\docs\compliance\permissions-matrix.md` (MODIFY)

**Steps:**
- [ ] **(I can prep)** Append a section **"E. Implemented permission set (status vs Phase 2)"** — a table
  of every Android permission with: manifest string, the matching Play Console declaration, status, and
  current manifest reality. Source the list from P4 of `2026-05-31-tarf-implementation-plan.md` +
  matrix §C (they agree):
  | Permission | Play declaration | Phase-2 status | In manifest today? |
  |---|---|---|---|
  | `POST_NOTIFICATIONS` | runtime, no special form | Phase 2 adds | No (verified: stock manifest) |
  | `USE_EXACT_ALARM` | Alarms & reminders | Phase 2 adds | No |
  | `SCHEDULE_EXACT_ALARM` | revocable fallback | Phase 2 adds | No |
  | `USE_FULL_SCREEN_INTENT` | justify (Strict mode) | Phase 2 adds | No |
  | `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_⟦type⟧` | FGS type | Phase 2 adds | No |
  | `ACCESS_COARSE_LOCATION` | on-device only | Phase 2 (prayer) | No |
  | `RECEIVE_BOOT_COMPLETED` | reschedule after reboot | Phase 2 adds | No |
  | `VIBRATE` | none | Phase 2 adds | No |
  | `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | sensitive — only if shipped | ⟦phase2-confirm⟧ | No |
- [ ] **(I can prep)** Record the two **open** values explicitly as `⟦phase2-confirm⟧`:
  (1) the `foregroundServiceType` — `specialUse` vs `mediaPlayback` (matrix §B-7 already flags this);
  (2) whether `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` ships. State that the **iOS** side adds only
  `NSLocationWhenInUseUsageDescription` (AR+EN) + the notification capability — no background-location.
- [ ] **(I can prep)** Add a one-line **dependency note** at the top of the new section: "The Phase 2
  background plan (`2026-06-01-tarf-phase2-background.md`) is **not yet written** as of this phase; this
  table is the agreed contract from the original implementation plan P4 and must be re-checked against
  Phase 2's final manifest before submission. Minor, late alignment — not a release blocker."
- [ ] **(verify)** Read back the appended section; confirm all nine rows present and both
  `⟦phase2-confirm⟧` markers visible. Cross-check the permission names against
  `2026-05-31-tarf-implementation-plan.md` P4 (`Grep` for `POST_NOTIFICATIONS|USE_EXACT_ALARM|FOREGROUND_SERVICE|FULL_SCREEN_INTENT`)
  — expect the same set.

---

### Task 8 — Finalize hosting-ready Privacy Policy + Terms (fill non-owner placeholders)

Make the drafts hosting-ready: fill every placeholder that does **not** require the owner's legal
identity, gateway choice, or a lawyer. Leave true owner/legal blanks clearly marked. Do not invent legal
facts.

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\docs\compliance\privacy-policy.md` (MODIFY)
- `C:\Users\sulta\Claude_Code\EyeCure_20\docs\compliance\terms-of-service.md` (MODIFY)

**Steps:**
- [ ] **(I can prep)** Privacy policy — fill the **safe** placeholders with the project's known values:
  app description, controller country (KSA), processor inventory (Firebase + "payment gateway"),
  retention defaults (server **30** days, backups **90** days), children age default (**16** or
  digital-consent age), the "v1 ships **no** analytics/crash SDK" statement (consistent with the
  data-safety `crashSdkShipped=false`), and the Art. 9 religion position (already written — leave intact).
  Set canonical URLs to `https://tarf.app/...` placeholders only where they are genuinely owner-owned.
- [ ] **(I can prep)** Leave **owner/legal** blanks explicitly marked and listed at the top:
  `[[LEGAL_NAME]]`, postal address, contact emails, Firestore region, the prevailing-language choice,
  the gateway name (Moyasar/Tap/Stripe), effective/last-updated dates. Add a one-line banner: "Fields in
  `[[…]]` require owner/legal input before publishing; everything else is finalized."
- [ ] **(I can prep)** Terms of service — same treatment: fill the donations-are-non-refundable-gifts
  language, the no-medical-claim disclaimer, governing law = KSA (already implied), and mark
  `[[LEGAL_NAME]]` / dates / lawyer-review as owner items. Keep the "reviewed by a KSA-qualified lawyer"
  gate visible (it is in the release checklist).
- [ ] **(verify — remaining placeholders are intentional)** Enumerate every remaining `[[ ]]` so the
  owner sees exactly what's left:
  ```powershell
  Select-String -Path "C:\Users\sulta\Claude_Code\EyeCure_20\docs\compliance\privacy-policy.md",`
    "C:\Users\sulta\Claude_Code\EyeCure_20\docs\compliance\terms-of-service.md" -Pattern '\[\[[^\]]+\]\]' -AllMatches |
    ForEach-Object { $_.Matches.Value } | Sort-Object -Unique
  ```
  Expected: only genuine owner/legal items remain (names, addresses, emails, dates, region, gateway,
  prevailing language) — no leftover technical/product placeholders.

---

### Task 9 — Re-author the master release checklist (ordered, per-platform, prep vs owner)

Turn `release-checklist.md` into an actionable, ordered, per-platform checklist that visibly separates
**"I can prep"** (done/doable in this phase) from **"owner submits"** (accounts/keys/Mac/legal). Preserve
the existing Blocking gates (legal, sacred-content, the two life-or-death promises) and reference every
artifact produced in Tasks 1–8.

**Files:**
- `C:\Users\sulta\Claude_Code\EyeCure_20\docs\store\release-checklist.md` (MODIFY — re-author in place)

**Steps:**
- [ ] **(I can prep)** Section **"Phase 6 — prepped here"** listing the concrete outputs with paths:
  brand SVGs + generated icon/splash sets (Task 1), `shots.ps1`/`build-shot-bundle.ps1` + captured matrix
  + `manifest.json` (Task 2), `metadata.md` (Task 3), `PrivacyInfo.xcprivacy` + Info.plist key (Task 4),
  `google-play-data-safety-answers.json` (Task 5), `screenshots.md` (Task 6), aligned
  `permissions-matrix.md` (Task 7), hosting-ready policy/terms (Task 8). Each as a `- [ ]` with **(I can
  prep)**.
- [ ] **(I can prep)** Preserve the existing **Blocking** sections A/B/C verbatim (legal & compliance;
  sacred-content integrity incl. the **dhikr scholarly sign-off** hard gate; the two promises + iOS<26
  honesty), tagging each item **(owner)** or **(I can prep)** appropriately. The dhikr sign-off, lawyer
  review, hosting the URLs, and the live deletion endpoint stay **(owner)**.
- [ ] **(I can prep)** **Per-platform ordered checklist**, each split into "Prep (here)" then "Owner
  submits", referencing the matching guide:
  - **Web/PWA** (cheapest first): prep = de-stocked manifest/index + icons + PWA shots; owner = deploy +
    host policy URLs.
  - **Chrome Web Store**: prep = metadata + single-purpose + permission justifications + 1280×800 shots;
    owner = $5 account, package zip upload, form entry.
  - **Android/Play**: prep = icons (adaptive+monochrome) + AR/EN listing + data-safety JSON + shot sets +
    permission contract; owner = $25 account + identity, AAB signing (Play App Signing), exact-alarm/FGS/
    full-screen-intent declarations, 12-testers/14-days closed test, staged rollout.
  - **Windows/MS Store**: prep = icon `.ico` + landscape shots + metadata; owner = Partner Center (~$19),
    reserve identity, `msix_config` identity values, MSIX build/submit. (Note: `msix` tooling is **not**
    in pubspec yet — flag as an owner/engineering add, cross-ref `microsoft-store.md §3`.)
  - **iOS/macOS**: prep = `PrivacyInfo.xcprivacy` + `ITSAppUsesNonExemptEncryption=false` + AR/EN listing
    + 6.7"/6.5"/5.5"/iPad/Mac shots; owner = Apple Developer ($99/yr), **Mac/macOS runner**, signing +
    notarization, App Privacy label, pod-manifest verification, demo-creds/Guest note.
- [ ] **(I can prep)** A final **"Cross-form consistency gate"** item: Apple label ↔ Play data-safety
  JSON ↔ Privacy Policy must agree (no-tracking, no-ad-ID, religion-not-collected, payment-website-only,
  deletion URL + retention windows) — reference Tasks 4/5/8.
- [ ] **(verify)** Read back the file; confirm (a) Blocking A/B/C still present, (b) every Task 1–8
  artifact path is referenced at least once, (c) each line carries either **(I can prep)** or **(owner)**.
  `Grep` for `(I can prep)` and `(owner)` and confirm both appear many times and no platform subsection
  lacks an owner-submit step.

---

## Verification

End-to-end, run after all tasks. Each line states the exact command + expected result.

- [ ] **Toolchain present:** `& 'C:\dev\flutter\bin\flutter.bat' --version` prints Flutter 3.44.x /
  Dart 3.12.x; `& 'C:\msys64\mingw64\bin\rsvg-convert.exe' --version` prints `2.61.1`.
- [ ] **Brand rasterized:** `Test-Path C:\Users\sulta\Claude_Code\EyeCure_20\app\assets\brand\tarf-mark-1024.png`
  → `True`; Read it → a 1024² teal Tarf glyph (not blank/not Flutter logo).
- [ ] **Icons generated (not stock):** Read `app\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png`,
  `app\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png`,
  `app\web\icons\Icon-maskable-512.png`, `app\windows\runner\resources\app_icon.ico` → all show the Tarf
  glyph; none is the default Flutter feather.
- [ ] **Adaptive + monochrome present:**
  `Test-Path app\android\app\src\main\res\mipmap-anydpi-v26\ic_launcher.xml` → `True`; the XML contains
  `<foreground>`, `<background>`, and `<monochrome>`.
- [ ] **Web de-stocked:** Read `app\web\manifest.json` → `name`/`short_name` = Tarf, `description` ≠ "A
  new Flutter project", `theme_color`/`background_color` are the teal/dark tokens (not `#0175C2`);
  `app\web\index.html` `<title>` = Tarf.
- [ ] **Splash generated:** `Test-Path app\android\app\src\main\res\drawable\launch_background.xml` and it
  references the splash logo / token colors; `flutter_native_splash` reported "complete".
- [ ] **Screenshots — count & size:** `(Get-Content _setup\shots\manifest.json | ConvertFrom-Json).Count`
  ≥ the per-store minimum across the matrix; the `System.Drawing` check on `iphone67/ar-dark/dhikrbreak.png`
  returns `1290x2796`; `windows/en-dark/insights.png` returns `1366x768`.
- [ ] **Screenshots — RTL/theme correctness:** Read `iphone67/ar-dark/dhikrbreak.png` (Amiri dhikr, RTL,
  dark ground) and `iphone67/en-light/home.png` (LTR, warm-paper light) → both correct.
- [ ] **PrivacyInfo valid:** the `[xml]` parse in Task 4 succeeds; collected-type count = 4, accessed-API
  count = 2; `NSPrivacyTracking` = false.
- [ ] **Data-safety JSON valid:** Task 5 `ConvertFrom-Json` succeeds; `encryptedInTransit` = True;
  Advertising-ID and Religious-beliefs `collected` = False.
- [ ] **Permissions matrix aligned:** new section "E" lists all nine permissions with both
  `⟦phase2-confirm⟧` markers; names match implementation-plan P4.
- [ ] **Metadata within limits:** every labelled field in `metadata.md` annotated `(NN/limit)`, none over;
  AR+EN present for all four stores.
- [ ] **Policy/terms placeholders intentional:** Task 8 placeholder enumeration returns only
  owner/legal items.
- [ ] **Checklist actionable:** `release-checklist.md` has Blocking A/B/C, references every Task 1–8
  artifact, and tags every line **(I can prep)** or **(owner)**.
- [ ] **No app logic touched / analyzer clean:** `& 'C:\dev\flutter\bin\flutter.bat' analyze` (cwd `app`)
  reports no **new** errors introduced by the config changes (pre-existing P0/P1 state unchanged).

---

## Self-review

- **Scope fidelity:** All five scoped deliverables are covered — icons+splash (Task 1), screenshot
  pipeline (Task 2 + runbook Task 6), metadata (Task 3), compliance artifacts (Tasks 4/5/7/8), release
  checklist (Task 9). Only Read/Glob/Grep were used to investigate; the plan itself is the single Write.
- **Honesty gate respected:** every step is explicitly **(I can prep)** or **(owner submits)**. No step
  pretends to submit to a store, sign a binary, run on a Mac, host a URL, obtain the dhikr sign-off, or
  `flutterfire configure`. Those are enumerated in Tasks 4/9 as owner items.
- **Tooling realism (the big risk):** verified on this machine — **no ImageMagick** (`convert.exe` is the
  Windows volume tool, explicitly forbidden), no Inkscape/Pillow/cairosvg; **`rsvg-convert` 2.61.1** is
  the only rasterizer and renders exact sizes directly, and `flutter_launcher_icons` builds the Windows
  `.ico` from the master PNG — so the asset pipeline needs **no** ImageMagick anywhere. Flutter confirmed
  at `C:\dev\flutter\bin\flutter.bat`; Python + Chrome confirmed for the shot recipe.
- **State-of-the-world checks:** all current icons are stock Flutter placeholders; web manifest is stock
  `#0175C2`/"A new Flutter project"; `AndroidManifest.xml` has the app label "tarf" and **zero**
  permissions today; **no** `flutter_launcher_icons`/`flutter_native_splash`/`msix` in pubspec — every
  one of these is reflected in the verification steps so "generated, not stock" is provable.
- **Phase 2 dependency handled correctly:** `2026-06-01-tarf-phase2-background.md` does **not exist** yet;
  the permission source is therefore P4 of the original implementation plan + `permissions-matrix.md`
  (which agree). The two genuinely-open values (`foregroundServiceType`, battery-opt) are marked
  `⟦phase2-confirm⟧` as a minor late alignment, never a blocker — matching the brief's "soft dependency."
- **Shared-file safety:** `pubspec.yaml`, `web/manifest.json`, `web/index.html`, `Info.plist`,
  `AndroidManifest.xml` are owned by P0/P4 — this phase only **appends** (dev-deps, two config keys) or
  **de-stocks** (manifest/title) or adds the **encryption key** (Info.plist), never touching permissions
  or reordering existing entries, so a worktree merge is low-conflict. Note: running
  `flutter_launcher_icons`/`native_splash` **regenerates** many platform files — coordinate so this runs
  after P0's scaffold is stable (it already is) and is not interleaved with another agent editing the same
  `res/`/`Assets.xcassets` trees.
- **Reverence + Arabic-first:** the mark is the طَرْف/eye + Ambient-Ring motif in the canonical teal, one
  accent only, no text near sacred content; the dhikr-break screenshot leads every store set in AR(RTL)
  first; metadata is AR-primary, reverent, honest about background/Chrome-open limits; nothing commercial
  sits beside the dhikr.
- **Gaps / residual risk:** (1) `FORCE_LOCALE` and the optional `?demo=/?prayer=` deep-link flags may not
  be wired in P0 — flagged `⟦p0-confirm⟧` with a no-code fallback (Settings toggle / plain route).
  (2) Android 9:16 crop for Play is documented, not automated (rsvg has no crop step) — the owner/CI crops
  or the captured letterboxed shot is used. (3) Final store size requirements drift over time — flagged
  `⟦verify-current⟧` in the screenshot runbook for re-confirmation at submit.

> Commit message (when the owner asks to commit):
> `docs(phase6): release-readiness plan — icons/splash, screenshot pipeline, metadata, compliance artifacts, checklist`
> `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`

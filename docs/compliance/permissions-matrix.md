# Tarf (طَرْف) — OS Permissions UX Matrix

> Engineering + UX contract for **every** OS permission Tarf requests. Each permission is requested
> **just-in-time** (at the moment it is needed, never at first launch), preceded by a **priming screen**
> in Arabic (primary) and English (secondary), with explicit **granted**, **denied (+ re-ask + Settings
> deep-link)**, and **permanently-denied fallback** paths. The **notifications-denied degraded experience**
> is treated as first-class (see §A and the notes after each notification row).
>
> Golden rules:
> 1. **Never** trigger the OS permission dialog cold. Always show our priming sheet first; only call the OS
>    API if the user taps the affirmative ("Enable") on our sheet.
> 2. Guest mode requires **zero** permissions to run the core eye-care + dhikr loop while the app is in the
>    foreground.
> 3. Every denial is **recoverable** and the app **stays useful** without the permission.
> 4. RTL-correct: Arabic copy uses `TextAlign.start`, mirrored icons, `EdgeInsetsDirectional`.

---

## A. The notifications-denied degraded experience (read first)

Notifications are how Tarf surfaces a break when the app is **not in the foreground**. If the user denies
or never grants notifications, **the app must still be fully usable**:

- **Foreground always works without any permission.** While Tarf (or the desktop tray app, or the open
  Chrome tab) is in the foreground/active, breaks fire as a **full-screen in-app overlay + the 20-second
  audio** with **no OS permission required**. This is the guaranteed path.
- **What is lost when notifications are denied:** background/closed-app reminders. We show a persistent,
  non-nagging **status chip**: *"Background reminders off — Tarf will only remind you while it's open."*
  (AR: «التنبيهات في الخلفية متوقّفة — سيُذكّرك طَرْف أثناء فتحه فقط».)
- **We never fake it.** We do not loop a silent audio session or abuse a foreground service purely to keep
  alive (rejection risk). We tell the truth in the status chip, in Settings, and on the store page.
- **One gentle re-ask, then Settings.** After a denial we do not nag. We offer a single contextual re-ask
  later (e.g. when the user opens Settings → Notifications, or after they manually complete a foreground
  break and might want background coverage), and otherwise deep-link to OS Settings.
- **iOS specifics:** we may request **provisional** authorization first (delivers quietly to Notification
  Center with no dialog) so the user experiences value before we ask for full/alert authorization.

---

## B. Matrix

Legend: **JIT** = just-in-time trigger. **Deep-link** = open the exact OS settings page.

### 1) iOS — Notifications (alert authorization)
| Field | Detail |
|---|---|
| OS API | `UNUserNotificationCenter.requestAuthorization([.alert, .sound, .badge])` (via flutter_local_notifications) |
| Why | Deliver the eye-break cue + 20s-audio trigger when Tarf is backgrounded (iOS < 26) and a heads-up countdown |
| When (JIT) | When the user enables background reminders, Strict mode, or finishes onboarding the eye-care engine — never at cold launch |
| Priming — AR | «حتى يصلك تذكير الراحة وأنت خارج التطبيق، يحتاج طَرْف إذنك بالإشعارات. بدونها سيُذكّرك أثناء فتحه فقط.» [زر: تفعيل] [زر: لاحقًا] |
| Priming — EN | "To remind you to rest your eyes even when Tarf is closed, we need notification permission. Without it, Tarf reminds you only while open." [Enable] [Not now] |
| Granted | Schedule local notifications; hide the "background off" chip; confirm with a subtle toast |
| Denied | Keep foreground overlay working; show the "background reminders off" status chip; **one** contextual re-ask later; provide a "Open Settings" button that deep-links to `UIApplication.openSettingsURLString` |
| Permanently denied | iOS shows no second system prompt after first denial. Persist the degraded-mode chip; the only re-enable route is **Settings → Tarf → Notifications**, surfaced via our deep-link + a short illustrated how-to |

### 2) iOS — Provisional notifications (quiet trial)
| Field | Detail |
|---|---|
| OS API | `requestAuthorization([.provisional, .alert, .sound, .badge])` |
| Why | Deliver quietly to Notification Center with **no dialog**, letting the user experience reminders before we ask for full alert authorization |
| When (JIT) | Optionally at the moment the eye-care engine first becomes active, as a no-friction default |
| Priming — AR | لا يظهر حوار نظام؛ نعرض لاحقًا بطاقة لطيفة: «تصلك تذكيرات هادئة في مركز الإشعارات. تريد تنبيهات أوضح؟» [ترقية] |
| Priming — EN | No system dialog; later a gentle card: "You're getting quiet reminders in Notification Center. Want louder, banner alerts?" [Upgrade] |
| Granted (provisional) | Quiet delivery active; offer an in-context **Upgrade to prominent** action that calls full `requestAuthorization` |
| Denied / user disables | User can downgrade from the notification's "..." menu; we detect via `getNotificationSettings` and reflect status; fall back to foreground-only + chip |
| Permanently denied | Same as row 1 fallback (Settings → Tarf → Notifications) |

### 3) Android 13+ (API 33+) — `POST_NOTIFICATIONS`
| Field | Detail |
|---|---|
| OS API | Runtime request of `android.permission.POST_NOTIFICATIONS` (manifest-declared) |
| Why | Required on Android 13+ to post the eye-break notification + foreground-service notification |
| When (JIT) | When the user enables background reminders / activates the eye-care engine — not at cold launch |
| Priming — AR | «يحتاج طَرْف إذن الإشعارات لتذكيرك براحة عينيك في الوقت المناسب.» [تفعيل] [لاحقًا] |
| Priming — EN | "Tarf needs notification permission to remind you to rest your eyes on time." [Enable] [Not now] |
| Granted | Post notifications via a high-importance channel (and a separate low channel for the FGS); remove the chip |
| Denied (1st/2nd) | Foreground overlay still works; show "background reminders off" chip. On next contextual moment, re-show OUR priming, then the system dialog (the OS allows a limited number of prompts) |
| Permanently denied | After the OS stops showing the dialog (`shouldShowRequestPermissionRationale` false), switch to **deep-link**: `Settings.ACTION_APP_NOTIFICATION_SETTINGS` with `EXTRA_APP_PACKAGE`; show an illustrated how-to; persist degraded mode |

### 4) Android 12+ — `SCHEDULE_EXACT_ALARM`
| Field | Detail |
|---|---|
| OS API | Manifest: `SCHEDULE_EXACT_ALARM` (revocable on Android 13+; user grant via `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`). Check `AlarmManager.canScheduleExactAlarms()` at runtime. |
| Why | The **Alarm** feature and precise eye-break timing need exact alarms (`AlarmManager.setExactAndAllowWhileIdle`) to fire on time under Doze |
| Policy note | Tarf ships Alarm + Timer + precise break timing, making exact scheduling a **core function**. We declare `SCHEDULE_EXACT_ALARM` (the user-revocable, general-purpose path). If Play policy later allows `USE_EXACT_ALARM` for our profile, that switch is a one-line manifest change — for now `SCHEDULE_EXACT_ALARM` is the shipped permission. **Owner must complete the Play "Alarms & reminders" declaration and justification.** |
| When (JIT) | When the user creates the first **Alarm**, or enables exact-timing for eye breaks |
| Priming — AR | «لكي يرنّ المنبّه/تذكير الراحة في وقته بالضبط، يحتاج طَرْف إذن التنبيهات الدقيقة.» [السماح] [استخدام تنبيه تقريبي] |
| Priming — EN | "So your alarm / break reminder rings at the exact time, Tarf needs the 'exact alarms' permission." [Allow] [Use inexact instead] |
| Granted | Use exact alarms; `AlarmManager.canScheduleExactAlarms()` returns true |
| Denied | Fall back to **inexact** alarms (`setAndAllowWhileIdle`) + WorkManager catch-up; warn that timing may drift by minutes under battery saver; offer deep-link |
| Permanently denied | Deep-link to `Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM` (per-app "Alarms & reminders"); keep inexact fallback so the feature still works |

> **Note:** `VIBRATE` and `WAKE_LOCK` are normal permissions (no runtime grant dialog) declared in the manifest to support notification vibration and keep the CPU alive during a break. `RECEIVE_BOOT_COMPLETED` reschedules alarms after device reboot — also normal, no dialog.

### 5) Android — `USE_FULL_SCREEN_INTENT`
| Field | Detail |
|---|---|
| OS API | Manifest `USE_FULL_SCREEN_INTENT`; notification with `setFullScreenIntent`. On Android 14+ this is **gated** — for non-call/alarm apps the OS may downgrade it to a heads-up notification, and access is checkable via `NotificationManager.canUseFullScreenIntent()` / requestable via `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` |
| Why | Present the full-screen break overlay (with 20s audio) over the lock screen / other apps when a break fires in the background |
| When (JIT) | When the user enables **Strict mode** or background full-screen breaks |
| Priming — AR | «في الوضع الصارم يعرض طَرْف شاشة الراحة كاملة فوق التطبيقات. يتطلب ذلك إذن \"الإشعارات بملء الشاشة\".» [تفعيل] [إشعار عادي يكفيني] |
| Priming — EN | "In Strict mode, Tarf shows the full break screen over other apps. This needs the 'full-screen notifications' permission." [Enable] [A normal notification is fine] |
| Granted | Use full-screen intent for breaks |
| Denied / downgraded by OS | Fall back to a high-priority **heads-up** notification + in-app overlay when foreground; Strict mode still functions in a softer form; explain the difference |
| Permanently denied | Deep-link to `Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT`; keep heads-up fallback |

### 6) Android — Battery-optimization exemption (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`)
| Field | Detail |
|---|---|
| OS API | `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (or open `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`). Declaring `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` in manifest is **Play-policy sensitive** — only for apps that genuinely need it; be ready to justify, and prefer pointing the user to settings over the direct prompt where possible |
| Why | Improve reliability of background eye-break delivery under aggressive OEM Doze/battery-saver |
| When (JIT) | **Only** if the user reports/experiences missed background reminders, or opts into "maximize reliability" — never proactively at launch |
| Priming — AR | «بعض الهواتف توقف التذكيرات لتوفير البطارية. لتذكير أكثر موثوقية، استثنِ طَرْف من تحسين البطارية (اختياري).» [فتح الإعدادات] [تجاهل] |
| Priming — EN | "Some phones pause reminders to save battery. For more reliable reminders, exempt Tarf from battery optimization (optional)." [Open settings] [Skip] |
| Granted | More reliable background delivery; note we still cannot defeat all OEM killers |
| Denied | Keep best-effort delivery (FGS + exact/inexact alarms + WorkManager); be honest that some OEMs may still delay reminders |
| Permanently denied | Deep-link to battery-optimization settings + a short OEM-specific help link (e.g. dontkillmyapp.com guidance); never block the app |

### 7) Android — `VIBRATE`, `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED` (normal permissions)
| Permission | Purpose |
|---|---|
| `VIBRATE` | Vibrate the device when a break notification is posted (accompanies sound) |
| `WAKE_LOCK` | Briefly hold a partial wake lock during exact-alarm delivery to ensure the break fires even under Doze; released immediately after the notification is posted |
| `RECEIVE_BOOT_COMPLETED` | Reschedule exact alarms after device reboot (Android cancels all `AlarmManager` alarms on reboot) |

These are **normal** permissions (no runtime dialog, no priming screen needed). They are declared in `AndroidManifest.xml` and require no Play Console declaration beyond what is already covered by the scheduling permission (§4).

> **Phase 4 note — Foreground Service:** If a foreground service (FGS) is added in Phase 4 for background audio playback during a break, you must add `FOREGROUND_SERVICE` + the appropriate typed permission (e.g. `FOREGROUND_SERVICE_MEDIA_PLAYBACK`) and complete the FGS Play Console declaration. That decision belongs to Phase 4. For v1 as shipped, Tarf uses `WorkManager` + exact alarms + `SCHEDULE_EXACT_ALARM` without a persistent FGS.

### 8) macOS — Notifications
| Field | Detail |
|---|---|
| OS API | `UNUserNotificationCenter.requestAuthorization` (macOS 11+) via the desktop notifier; tray app is the primary delivery |
| Why | Deliver break cue + 20s-audio trigger when the desktop app is in the tray/background |
| When (JIT) | When the user enables background/tray reminders, not at first launch |
| Priming — AR | «ليصلك تذكير الراحة وطَرْف في الخلفية، اسمح بالإشعارات.» [تفعيل] [لاحقًا] |
| Priming — EN | "To get break reminders while Tarf runs in the background, allow notifications." [Enable] [Not now] |
| Granted | Post notifications; tray app plays the 20s audio reliably (desktop is the strongest platform) |
| Denied | Tray app still plays audio + shows its own window/overlay when possible; show degraded chip in the app + tray menu |
| Permanently denied | Deep-link via `x-apple.systempreferences:com.apple.preference.notifications`; keep tray-window fallback. (Windows note: equivalent toast permission is managed in Windows Settings → Notifications; provide a deep-link there too.) |

### 9) Location — for prayer times (optional)
| Field | Detail |
|---|---|
| OS API | iOS `CLLocationManager.requestWhenInUseAuthorization`; Android `ACCESS_COARSE_LOCATION` (coarse is enough). **Request when-in-use / coarse only — never background, never fine/precise** |
| Why | Compute the 5 daily prayer times **locally on-device** (via `adhan`) to auto-pause/defer eye-break reminders around salah |
| Privacy stance | Location is used **only on the device**; it is **never sent to or stored by our servers** (state this in the priming sheet, Privacy Policy §4, and store data-safety forms) |
| When (JIT) | Only when the user **turns on** the prayer-time pause feature in Settings |
| Priming — AR | «لحساب أوقات الصلاة وإيقاف التذكير حولها، يحتاج طَرْف موقعك التقريبي — ويُحسب على جهازك فقط ولا يُرسل لأي خادم.» [السماح مرة واحدة/أثناء الاستخدام] [إدخال المدينة يدويًا] |
| Priming — EN | "To compute prayer times and pause reminders around them, Tarf needs your approximate location — computed on your device only, never sent to any server." [Allow while using] [Enter city manually] |
| Granted | Compute prayer times locally; show them on Insights if enabled |
| Denied | **Graceful fallback to manual location/city or manually-entered prayer times** kept only on-device; feature stays fully usable |
| Permanently denied | Keep manual-entry mode as the default for this feature; offer a Settings deep-link (iOS app settings / Android app location settings) if the user wants to switch to automatic later. Coarse-precision note (Android 12+): if the user grants "Approximate" we proceed; if they downgrade fine→coarse it makes no difference since we request coarse only |

---

## C. Platform manifest / Info.plist declaration checklist (owner verifies — `app/` is owned by another dev)

> These are the **declarations** the permissions above require. The app code lives under `app/` (do not edit);
> this list is the compliance contract to verify with that developer before submission.

- **iOS `Info.plist`:** `NSLocationWhenInUseUsageDescription` (AR + EN via `InfoPlist.strings`), notification
  capability, and (if/when loud-through-silence ships fully) audio background mode justification. **No**
  `NSLocationAlwaysUsageDescription` (we never request background location).
- **Android `AndroidManifest.xml` — final declared set:**
  - `POST_NOTIFICATIONS` — runtime permission (Android 13+); Play declaration needed
  - `SCHEDULE_EXACT_ALARM` — runtime permission (Android 12+); Play "Alarms & reminders" declaration + justification needed
  - `USE_FULL_SCREEN_INTENT` — manifest permission; Play declaration needed for Strict mode full-screen break overlay
  - `RECEIVE_BOOT_COMPLETED` — normal permission; reschedules alarms after reboot
  - `VIBRATE` — normal permission; notification vibration
  - `WAKE_LOCK` — normal permission; momentary hold during exact-alarm delivery
  - `ACCESS_COARSE_LOCATION` — runtime permission; **only** if the prayer-times feature is shipped; Play data-safety: on-device only, not collected
  - `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` — **optional, policy-sensitive**; add only if the battery-reliability opt-in feature is built; justify in Play Console
  - **NOT declared:** `USE_EXACT_ALARM` (reserved for apps whose primary function is alarms; may be added post-launch if Play approves), `FOREGROUND_SERVICE` (not used in v1; add in Phase 4 if a persistent background audio service is built).
  - Each runtime permission requires a matching **Play Console declaration/justification** and our JIT priming UX.
- **macOS entitlements:** notifications; App Sandbox; (location entitlement only if the prayer feature is built
  for macOS).
- **Localized permission strings:** every usage-description string is provided in **Arabic and English** and
  is reviewed for tone (calm, honest, non-coercive).

---

## D. Reusable copy tokens (for `l10n` ARB — to hand to the `app/` developer)

| Key | AR | EN |
|---|---|---|
| `perm.notif.title` | تذكيرات الراحة | Break reminders |
| `perm.notif.body` | للتذكير وأنت خارج التطبيق، فعّل الإشعارات. بدونها نُذكّرك أثناء الفتح فقط. | To remind you when Tarf is closed, enable notifications. Otherwise we remind you only while open. |
| `perm.exactalarm.body` | ليرنّ في وقته بالضبط، فعّل التنبيهات الدقيقة. | So it rings exactly on time, enable exact alarms. |
| `perm.fullscreen.body` | لعرض شاشة الراحة كاملة فوق التطبيقات (الوضع الصارم). | To show the full break screen over other apps (Strict mode). |
| `perm.battery.body` | لموثوقية أعلى، استثنِ طَرْف من تحسين البطارية (اختياري). | For higher reliability, exempt Tarf from battery optimization (optional). |
| `perm.location.body` | موقعك التقريبي لحساب أوقات الصلاة — على جهازك فقط ولا يُرسل لأي خادم. | Approximate location for prayer times — on your device only, never sent to any server. |
| `perm.cta.enable` | تفعيل | Enable |
| `perm.cta.later` | لاحقًا | Not now |
| `perm.cta.settings` | فتح الإعدادات | Open settings |
| `status.bgRemindersOff` | التنبيهات في الخلفية متوقّفة — سيُذكّرك طَرْف أثناء فتحه فقط. | Background reminders off — Tarf will only remind you while it's open. |

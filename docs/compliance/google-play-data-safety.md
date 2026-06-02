# Tarf (طَرْف) — Google Play Data Safety form answers

> Exact answers for **Play Console → App content → Data safety**. Answer for the **worst case across the
> shipped build** (signed-in mode). Guest mode collects nothing, but the form reflects what signed-in mode
> can collect. Keep in sync with the Privacy Policy and the Apple App Privacy label.

---

## 1. Top-level questions

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** (signed-in mode: email, user ID, app activity, app-content to-dos) |
| Is all of the user data encrypted in transit? | **Yes** (TLS/HTTPS to Firebase) |
| Do you provide a way for users to request that their data be deleted? | **Yes** — in-app (Settings → Account → Delete my account) **and** web (`[[https://tarf.app/delete-account]]`). Provide this URL in the form. |
| Privacy Policy URL | `[[https://tarf.app/privacy]]` |

> "Collect" = transmitted off the device. "Share" = transferred to a third party. For Tarf:
> - We **collect** account + usage data (sent to Firebase, our processor — processor transfer is **not**
>   "sharing" under Play's definition, so answer **collected: yes / shared: no** for those types).
> - We do **not** share data with third parties for their own use, and we do **not** use data for ads.

---

## 2. Per-data-type answers

For each collected type Play asks: **Collected? Shared? Processed ephemerally? Required or optional? Purposes?**
Unless noted, **Shared = No**, **Ephemeral = No**, and the purpose is **App functionality / Account management**.

### Personal info
| Data type | Collected | Shared | Optional? | Purposes |
|---|---|---|---|---|
| **Email address** | Yes | No | Optional (only if you create an account; Guest needs none) | App functionality; Account management |
| **User IDs** (Firebase UID, provider id) | Yes | No | Optional (account only) | App functionality; Account management |
| Name (display name) | [[Yes if you store displayName; else No]] | No | Optional | App functionality; Account management |
| Other personal info / Address / Phone / Race / Ethnicity / Political or religious beliefs / Sexual orientation | **No** | No | — | — |

> **Religious beliefs:** answer **No / Not collected.** Dhikr content is bundled and identical for all users;
> we record no per-user religiosity; prayer-time location stays on-device and is never transmitted. See
> Privacy Policy §4.

### Financial info
| Data type | Collected | Notes |
|---|---|---|
| Payment info, Purchase history, Credit score, Other financial info | **No** | Donations are **website-only**, handled by the payment gateway; **the Android app contains no payment flow and processes no financial data.** |

### Location
| Data type | Collected | Notes |
|---|---|---|
| Approximate location | **No (not collected by us)** | Used **only on-device** by the prayer-time feature and **never transmitted to or stored by us.** Under Play's definition (collect = sent off device), we do **not** collect it. The `ACCESS_COARSE_LOCATION` permission is declared and justified separately. |
| Precise location | **No** | We never request fine/precise or background location. |

### App activity
| Data type | Collected | Shared | Optional? | Purposes |
|---|---|---|---|---|
| **App interactions** (focus minutes, sessions, breaks taken/skipped, daily-goal %, settings) | Yes | No | Optional (account only) | App functionality |
| In-app search history, Installed apps, Other user-generated content, Other actions | **No** | — | — | — |

### App info & performance
| Data type | Collected | Notes |
|---|---|---|
| Crash logs / Diagnostics / Other performance data | **[[Yes ONLY if a crash/analytics SDK ships; else No]]** | If shipped: Collected = Yes, Shared = No, Optional (opt-in), Purpose = App functionality / Analytics. **If v1 ships no analytics/crash SDK, answer No for all three.** |

### App content / User content
| Data type | Collected | Shared | Optional? | Purposes |
|---|---|---|---|---|
| **Other user content** (to-do titles, reflection notes) | Yes | No | Optional | App functionality |

### Messages, Photos/Videos, Audio files, Files & docs, Calendar, Contacts, Health & fitness, Web browsing, Device/other IDs (advertising ID)
| — | **No / Not collected** | We collect none of these. **No advertising ID.** |

---

## 3. Data-handling practices to tick
- [x] **Data is encrypted in transit.**
- [x] **Users can request data deletion** (in-app + web URL). Provide the deletion URL.
- [x] **Account creation is optional** — core feature works in Guest mode with no data collection.
- [ ] **Committed to the Play Families policy?** — Tarf is **not** designed for children; target a general/teen
  audience, not "Designed for Families."

---

## 4. Consistency / rejection-avoidance checklist
- [ ] Data Safety answers match the **Privacy Policy** and the **Apple App Privacy** label (Google cross-checks).
- [ ] Every declared **manifest permission** has a coherent reason and, where required, a **Play Console
  declaration**: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM` (Alarms & reminders), `USE_FULL_SCREEN_INTENT`.
  Normal permissions (`VIBRATE`, `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED`) need no special declaration form.
  See `permissions-matrix.md` for the complete set.
- [ ] **Exact-alarm declaration** completed and justified (`SCHEDULE_EXACT_ALARM`; Alarm/Timer + precise break timing is a core function). If `USE_EXACT_ALARM` is added later, update the Play declaration to match.
- [ ] **Foreground-service declaration** — only required if Phase 4 adds a foreground service; if not present in the v1 manifest, no declaration is needed. Verify before submission.
- [ ] Location declared as **on-device only / not collected**; if any SDK ever receives it, update this form.
- [ ] No advertising ID, no ad SDK — confirm in the linked SDKs report.
- [ ] Re-confirm with the `app/` developer that no extra data leaves the device beyond what is listed here.

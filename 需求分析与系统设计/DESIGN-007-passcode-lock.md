---
title: Passcode Lock
status: Accepted
author: 吕加年
date: 2026-06-02
version: 1.0
---

# Passcode Lock

DESIGN-007

---

## 1. Requirements

- User can set a 4-6 digit passcode
- App locks when going to background
- Re-enter passcode to unlock
- Settings: set / change / remove passcode

## 2. Implementation

| Component | File |
|-----------|------|
| Provider | `lib/providers/passcode_provider.dart` |
| Lock screen | `lib/pages/lock/lock_page.dart` |
| Settings toggle | `lib/pages/settings/settings_page.dart` |
| App lifecycle | `lib/app.dart` |

## 3. Data Flow

```
Set passcode:
  Settings -> enable passcode -> enter 4-6 digits -> confirm
  -> hash stored in Hive `settings` box

Lock:
  App goes to background (AppLifecycleState.paused)
  -> lockPageShown = true

Unlock:
  App resumes -> show LockPage -> enter correct PIN -> dismiss
```

## 4. Passcode Storage

- Passcode stored as SHA256 hash in Hive `settings` box
- Never store plaintext

## 5. Acceptance

| # | Scenario | Expected |
|---|----------|---------|
| 1 | Set passcode | Enters 4 digits, confirms, enabled |
| 2 | Lock on background | Home -> recent apps -> back shows lock screen |
| 3 | Unlock with correct PIN | Enter correct PIN -> enters app |
| 4 | Unlock with wrong PIN | Shows error, retry |
| 5 | Change passcode | Old PIN -> new PIN -> confirm |
| 6 | Remove passcode | Enter old PIN -> disable |

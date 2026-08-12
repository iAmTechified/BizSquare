# Mobile Application Architecture Specification

**Project Name:** Akawo  
**Module:** Cross-Platform Native Mobile Client  
**Framework:** Flutter (Dart)  
**Target Platforms:** iOS 14+ & Android 8.0+  

---

## 1. System Overview
The Akawo mobile application is the primary user interface and native bridge for the network. It is built in Flutter to maintain a single, high-performance codebase while requiring deep native access to the device's OS-level address book and intent-sharing capabilities.

The app acts as a "dumb client" for the heavy matchmaking logic (which is handled by the Fly.io backend) but acts as a "smart client" for hardware-level contact management and gamified intent capture.

---

## 2. Core Modules & User Journeys

### 2.1 The Interest Graph (Gamified Onboarding)
Instead of static forms, users declare their business supply and demand through interactive swipes.
* **The UI Component:** A stack of Tinder-style scenario cards (`flutter_card_swiper` or custom gesture detector).
* **The UX Flow:**
  1. The app fetches an array of active Scenario Polls from the backend.
  2. User sees: *"I am actively looking for a web developer."*
  3. **Swipe Right (Yes):** Maps the user's demand to the Web Development `niche_id`.
  4. **Swipe Left (No):** Discards.
* **Data Handling:** Swipes are cached locally and batched into a single `POST /api/v1/polls/swipe` request to prevent network spam and ensure a fluid 60fps UI experience.

### 2.2 The Contact Sync Engine (The Native Bridge)
This is the most critical hardware integration. The app must silently manage the user's phonebook without creating duplicates or leaving orphan contacts.
* **The UI Component:** A "Sync My Weekly Batch" button on the main dashboard.
* **The Logic Flow:**
  1. User authenticates and grants OS Contact permissions.
  2. App fetches the JSON payload of this week's matches (`GET /matches/current`).
  3. **The Write:** The app uses `flutter_contacts` to write the new numbers to the native address book.
  4. **The Tagging:** Every contact inserted is appended with a specific invisible note or group tag (e.g., `[Akawo_Network]`).
  5. **The Purge:** Before writing a new week's batch, the app scans the phonebook for the `[Akawo_Network]` tag and safely deletes outdated or ghosted matches from previous weeks to keep the phonebook perfectly clean.

### 2.3 The Akawo Spotlight (Viral Sharing)
This is the gamified loop where users earn the Akawo points required to stay active in the network.
* **The UI Component:** A daily "Spotlight Flyer" card displaying the featured community member.
* **The Logic Flow:**
  1. User taps "Share & Earn Points".
  2. The app uses the `share_plus` package to trigger the native OS share sheet, pre-loading the flyer image and a specific caption containing the user's exact `@Mention`.
  3. The user selects "WhatsApp Status" natively.
  4. The app UI shifts to a "Pending Verification" state, waiting for the macOS Python bot to visually confirm the status was posted.

---

## 3. Flutter Architecture & State Management
To ensure maintainability and strict separation of concerns, the app utilizes a feature-first directory structure powered by Riverpod (or Bloc) for state management.

### 3.1 Directory Structure (Feature-First)
```text
lib/
├── core/                   # Global utilities, theme, routing, API client
│   ├── network/            # Dio interceptors, JWT injection
│   ├── permissions/        # iOS/Android permission handlers
│   └── theme/              # Typography, colors, spacing
├── features/
│   ├── auth/               # Login, OTP verification
│   ├── interest_graph/     # Scenario card UI, swipe logic
│   ├── spotlight/          # Daily flyer, share_plus intents
│   └── contacts/           # The Sync Engine, address book reading/writing
├── shared/                 # Reusable UI widgets (buttons, loaders)
└── main.dart               # Entry point, ProviderScope
```

### 3.2 State Management Strategy
* **Local State:** `StatefulWidgets` or `flutter_hooks` used for transient UI states (e.g., the physical dragging of a swipe card).
* **Global State:** Riverpod providers manage the user's JWT session, their current Akawo points balance, and the caching of their weekly contact batch.

---

## 4. Required Package Stack (`pubspec.yaml`)

| Package | Purpose in Akawo |
| --- | --- |
| `flutter_contacts` | Deep, read/write access to the iOS/Android address book. Critical for the Sync Engine. |
| `permission_handler` | Gracefully prompting users for contacts and storage (for flyers) permissions. |
| `share_plus` | Bridging the Spotlight flyer directly into the native WhatsApp Status intent. |
| `dio` | High-performance HTTP client for backend communication, easily handling JWT refresh token interceptors. |
| `flutter_secure_storage` | Safely encrypting and storing the user's JWT access/refresh tokens in the device's secure enclave/keychain. |
| `cached_network_image` | Loading and heavily caching the daily Spotlight flyers to save bandwidth. |
| `flutter_card_swiper` | Providing the fluid, physics-based Tinder-swipe mechanics for the Interest Graph scenarios. |

---

## 5. Security & OS Constraints

### 5.1 Native OS Permissions (The Gatekeeper)
If the user denies contact permissions, the app's core utility fails. The UI must include a highly optimized "Soft Ask" screen before triggering the native OS permission dialog.
* **iOS (`Info.plist`):** Must include a clear, compliant `NSContactsUsageDescription` stating: *"Akawo needs access to your contacts to seamlessly add your weekly curated business matches and remove outdated connections."*
* **Android (`AndroidManifest.xml`):** Requires `READ_CONTACTS` and `WRITE_CONTACTS`.

### 5.2 Token Management
* The Flutter app never stores raw passwords.
* Authentication relies on short-lived JWT Access Tokens (e.g., 15 minutes) and long-lived Refresh Tokens (e.g., 30 days) securely rotated via `dio` interceptors to ensure the user stays logged in without compromising API security.

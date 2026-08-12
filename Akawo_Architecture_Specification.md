# System Requirement & Software Architecture Specification

**Project Name:** Akawo  
**Document Version:** 1.0  
**Target Platform:** iOS, Android, macOS/Desktop Automation, Cloud Backend  

---

## 1. Executive Summary & Vision

Akawo is a next-generation business networking and automated contact-growth platform designed to replace informal, chaotic WhatsApp "VCF sharing" and spam-heavy contact-gain groups.

By replacing uncurated broadcast lists with **Algorithmic Reciprocity**, Akawo matches business owners, freelancers, and entrepreneurs into highly targeted, mutual 2-way contact batches. The system enforces zero competitor collisions, guarantees clean contact management, and powers a viral community spotlight through an automated engagement economy ("Akawo Points").

---

## 2. Product Philosophy & Core Mechanics

```text
┌───────────────────────────────────────────────────────────────────────────┐
│                           AKAWO NETWORK SYSTEM                            │
└───────────────────────────────────────────────────────────────────────────┘
                                     │
         ┌───────────────────────────┼───────────────────────────┐
         ▼                           ▼                           ▼
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ MATCHMAKING     │         │ INTEREST GRAPH  │         │ AKAWO SPOTLIGHT │
│ ENGINE          │         │ & PROFILING     │         │ ECONOMY         │
└─────────────────┘         └─────────────────┘         └─────────────────┘
 │ 10% Volume Cap            │ Gamified Scenario │       │ Concentrated    │
 │ Zero Competitors          │ Swipe Polls       │       │ Visibility      │
 │ Mutual 2-Way Sync         │ Search Intent     │       │ Visual OS Bot   │
 └─────────────────┘         └─────────────────┘         └─────────────────┘
```

### 2.1 The 6 Laws of Matchmaking

1. **The 10% Volume Cap:** To protect users from contact fatigue, a single user’s weekly contact batch is hard-capped at 10% of the active network size.
2. **Zero Competitor Collision:** Users in the exact same business niche (e.g., two shoe retailers) are strictly walled off from appearing in each other’s contact batches.
3. **100% Mutual Reciprocity:** All connections are two-way. User A receives User B's details only if User B simultaneously receives User A's details, guaranteeing mutual status visibility.
4. **Zero-Duplicate Ledger:** Historical matches are permanently recorded. Users never receive the same contact twice unless explicitly requested.
5. **Fallback Protocol:** In cases of supply-demand imbalance in a specific niche, the matchmaking engine gracefully expands matches into adjacent, complementary industries before drawing from general business categories.
6. **Silent Address Book Management:** Managed via native device APIs (`flutter_contacts`). Outdated or ghosted contacts are cleanly purged from the user's phonebook without leaving orphan data.

### 2.2 The Interest Graph (Gamified Profiling)

* **Static Form Elimination:** Traditional onboarding forms suffer from low completion rates and inaccurate data. Akawo utilizes interactive, swipeable "Business Scenario Cards" (Tinder-style left/right swipes).
* **Intent Capture:** Scenario cards present actionable business situations (e.g., "I am currently hiring a UI/UX designer" or "I am looking to source wholesale fashion accessories").
* **Dynamic Niche Mapping:** Swiping maps real-time supply and demand directly into the user’s relational profile in PostgreSQL, driving accurate algorithmic matching.

---

## 3. The Akawo Spotlight Economy & Verification Architecture

### 3.1 Spotlight Mechanics

* Each day, specific users enter the **Akawo Spotlight**.
* Network members view the Spotlight flyer and share it to their own WhatsApp Status, tagging/mentioning the Spotlight user (`@User`).
* Sharing earns the participating user **Akawo Points**, which elevate their position in future matching tiers and unlock premium network features.

### 3.2 Verification Strategy: OS-Level Visual Automation

To verify that a user actually posted and maintained the WhatsApp status mention without getting banned by Meta, central cloud scripts and headless browser bots were rejected due to datacenter IP flags, browser fingerprinting (`navigator.webdriver`), and DOM change breakage.

Instead, verification is executed via an **OS-Level Visual Desktop Bot** running on a dedicated local environment.

```text
┌───────────────────────────────────────────────────────────────────────────┐
│                     LOCAL OS-LEVEL VERIFICATION BOT                       │
└───────────────────────────────────────────────────────────────────────────┘
                                     │
 ┌───────────────────────────────────┼───────────────────────────────────┐
 │                                   │                                   │
 ▼                                   ▼                                   ▼
┌──────────────────────┐   ┌──────────────────────┐   ┌──────────────────────┐
│ Real Browser         │   │ Residential IP       │   │ OpenCV Vision        │
│ Chrome open to       │   │ On local Wi-Fi,      │   │ Detects green '@'    │
│ WhatsApp Web         │   │ zero datacenter flags│   │ Mention pixel icon   │
└──────────────────────┘   └──────────────────────┘   └──────────────────────┘
                                     │
                                     ▼
                          ┌──────────────────────┐
                          │ PyAutoGUI Action     │
                          │ Human mouse moves    │
                          │ & clicks mention     │
                          └──────────────────────┘
                                     │
                                     ▼
                          ┌──────────────────────┐
                          │ API Credit Callback  │
                          │ POST to Fly.io API   │
                          │ to award Akawo Points│
                          └──────────────────────┘
```

**Key Safeguards:**
* **Real Browser Fingerprint:** Runs inside a standard Chrome instance on home Wi-Fi (Residential IP).
* **Pixel-Based Recognition:** Uses OpenCV to detect the green `@` Mention icon. DOM updates or CSS class shifts by WhatsApp do not break the bot.
* **Humanized Hardware Events:** Uses PyAutoGUI easing functions to simulate natural mouse curves and randomized click durations, bypassing synthetic JavaScript event detection.

---

## 4. System Architecture & Tech Stack

| Layer | Technology | Key Responsibility |
| --- | --- | --- |
| **Mobile Frontend** | Flutter (Dart) | iOS & Android UI, `flutter_contacts` sync engine, `url_launcher` for WhatsApp deep links. |
| **Backend API** | Node.js (TypeScript) / Laravel | Restful API endpoints, auth, transaction routing, containerized via Docker on Fly.io. |
| **Database** | PostgreSQL (Aiven) | Relational engine enforcing zero-collision matchmaking, user quotas, and Akawo point ledgers. |
| **Automation Engine** | Python 3 (PyAutoGUI, OpenCV) | OS-level desktop visual scanner verifying status mentions on WhatsApp Web on macOS. |
| **Background Jobs** | `pg_cron` / Scheduled Worker | Executes batch matching logic every Sunday at 00:00 UTC. |

---

## 5. PostgreSQL Database Schema Specification

```sql
-- Core Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Niches Table
CREATE TABLE niches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    niche_id UUID REFERENCES niches(id) ON DELETE SET NULL,
    akawo_points INT DEFAULT 0 CHECK (akawo_points >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Match History Ledger (Enforces Zero Duplicates & Reciprocity)
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    batch_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_match_pair UNIQUE (user_a_id, user_b_id),
    CONSTRAINT no_self_match CHECK (user_a_id <> user_b_id)
);

-- 4. Scenario Polls (Gamified Profiling)
CREATE TABLE scenario_polls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_text TEXT NOT NULL,
    target_niche_id UUID REFERENCES niches(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. User Poll Responses
CREATE TABLE user_poll_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    poll_id UUID REFERENCES scenario_polls(id) ON DELETE CASCADE,
    response BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_poll UNIQUE (user_id, poll_id)
);

-- 6. Akawo Points Ledger
CREATE TABLE akawo_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    points_awarded INT NOT NULL,
    reason VARCHAR(255) NOT NULL,
    verified_by_bot BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

---

## 6. Matchmaking Query Logic (Relational Isolation)

```sql
WITH ActiveUsers AS (
    SELECT id, niche_id FROM users WHERE is_active = TRUE
),
NetworkSize AS (
    SELECT COUNT(*) AS total_users FROM ActiveUsers
),
CandidatePairs AS (
    SELECT 
        u1.id AS user_a_id,
        u2.id AS user_b_id
    FROM ActiveUsers u1
    CROSS JOIN ActiveUsers u2
    WHERE u1.id <> u2.id
      -- Rule 2: Zero Competitor Collision
      AND u1.niche_id <> u2.niche_id
      -- Rule 4: Zero Duplicate Matches Ever
      AND NOT EXISTS (
          SELECT 1 FROM matches m 
          WHERE (m.user_a_id = u1.id AND m.user_b_id = u2.id)
             OR (m.user_a_id = u2.id AND m.user_b_id = u1.id)
      )
)
-- Select matches within the 10% volume quota limit
SELECT 
    cp.user_a_id, 
    cp.user_b_id,
    CURRENT_DATE AS batch_date
FROM CandidatePairs cp
LIMIT (SELECT CEIL(total_users * 0.10) FROM NetworkSize);
```

---

## 7. Implementation Roadmap & Execution Phases

```text
┌───────────────────────────────────────────────────────────────────────────┐
│                           IMPLEMENTATION PHASES                           │
└───────────────────────────────────────────────────────────────────────────┘
  │
  ├── PHASE 1: Core Engine & DB Foundation (PostgreSQL + Fly.io Backend)
  │
  ├── PHASE 2: Mobile Contacts Sync Bridge (Flutter + Native Address Book)
  │
  ├── PHASE 3: Interest Graph UI (Interactive Scenario Swipe Cards)
  │
  ├── PHASE 4: Desktop Visual Automation Bot (Python + PyAutoGUI + OpenCV)
  │
  └── PHASE 5: Akawo Spotlight Economy & Automated Credit Pipeline
```

### Phase 1: Core Engine & DB Foundation
* Deploy PostgreSQL schema to cloud database (Aiven).
* Build Node.js / Laravel REST API for authentication, user profiles, and contact batch retrieval.
* Deploy containerized API onto Fly.io with continuous integration.

### Phase 2: Mobile Contacts Sync Bridge
* Implement Flutter app foundation with permission handling for iOS & Android address books.
* Construct `ContactSyncService` using `flutter_contacts` to write matched contacts directly to the device phonebook under a dedicated group tag (Akawo Network).

### Phase 3: Interest Graph UI
* Build the Flutter swipeable scenario card interface.
* Connect swipe gestures (Swipe Right = TRUE, Swipe Left = FALSE) to the `user_poll_responses` API endpoint to dynamically update user supply/demand niches.

### Phase 4: Desktop Visual Automation Bot
* Configure Python script utilizing OpenCV to detect WhatsApp Web `@` green mention badges.
* Program PyAutoGUI mouse movement curves for non-synthetic clicking and status validation.

### Phase 5: Akawo Economy & Spotlight Pipeline
* Launch the daily Spotlight rotation queue in PostgreSQL.
* Wire the Python bot’s successful mention verification to trigger the secure `/api/akawo/credit` endpoint.

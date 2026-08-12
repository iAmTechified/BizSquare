# Backend & Database Architecture Specification

**Project Name:** Akawo  
**Module:** Cloud API & PostgreSQL Relational Engine  
**Deployment Environment:** Fly.io (Compute) + Aiven (PostgreSQL)  

---

## 1. System Overview

The Akawo backend is a stateless REST API responsible for handling native mobile client requests, managing the interest graph, executing the weekly algorithmic matchmaking batch, and securely receiving verification payloads from the desktop visual bot.

* **API Framework:** Node.js (Express/NestJS) or PHP (Laravel)
* **Database:** PostgreSQL 15+ (Hosted on Aiven)
* **Authentication:** JWT (JSON Web Tokens) with short-lived access and long-lived refresh tokens.
* **Background Processing:** CRON-triggered jobs for matchmaking and ledger reconciliation.

---

## 2. Database Schema & Indexing Strategy

To support the 6 Laws of Matchmaking (specifically zero-collision and zero-duplicates), the database relies heavily on foreign key constraints and composite indexes to ensure queries remain performant as the network scales.

### 2.1 Core Tables

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- NICHES: Defines the categories of supply and demand
CREATE TABLE niches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- USERS: Core identity and points ledger
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    niche_id UUID REFERENCES niches(id) ON DELETE RESTRICT,
    akawo_points INT DEFAULT 0 CHECK (akawo_points >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### 2.2 The Matchmaking Ledger

The `matches` table is the most read/written table during the weekly CRON job. It acts as the immutable historical record of who has received whose contact card.

```sql
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    batch_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'synced', -- 'synced', 'ghosted', 'revoked'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_match_pair UNIQUE (user_a_id, user_b_id),
    CONSTRAINT no_self_match CHECK (user_a_id <> user_b_id)
);

-- CRITICAL INDEXES for Matchmaking Query Performance
CREATE INDEX idx_matches_user_a ON matches(user_a_id);
CREATE INDEX idx_matches_user_b ON matches(user_b_id);
CREATE INDEX idx_matches_batch_date ON matches(batch_date);
```

### 2.3 Interest Graph & Gamification

```sql
-- SCENARIO POLLS: The Tinder-style cards for business scenarios
CREATE TABLE scenario_polls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_text TEXT NOT NULL,
    target_niche_id UUID REFERENCES niches(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- USER POLL RESPONSES: Maps real-time intent
CREATE TABLE user_poll_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    poll_id UUID REFERENCES scenario_polls(id) ON DELETE CASCADE,
    response BOOLEAN NOT NULL, -- TRUE = Swipe Right, FALSE = Swipe Left
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_poll UNIQUE (user_id, poll_id)
);
```

### 2.4 The Verification Ledger

```sql
-- AKAWO LEDGER: Immutable record of points earned/spent
CREATE TABLE akawo_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    points_awarded INT NOT NULL,
    transaction_type VARCHAR(50) NOT NULL, -- 'status_mention', 'penalty', 'reward'
    verified_by_bot BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Trigger to automatically update the users.akawo_points balance
CREATE OR REPLACE FUNCTION update_akawo_balance() RETURNS TRIGGER AS $$
BEGIN
    UPDATE users 
    SET akawo_points = akawo_points + NEW.points_awarded 
    WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_akawo_balance
AFTER INSERT ON akawo_ledger
FOR EACH ROW EXECUTE FUNCTION update_akawo_balance();
```

---

## 3. REST API Endpoint Specification

The backend exposes specific endpoints consumed by the Flutter mobile app and the local macOS verification bot.

### 3.1 Authentication & Onboarding

| Method | Endpoint | Description | Security |
| --- | --- | --- | --- |
| `POST` | `/api/v1/auth/register` | Creates a new user and generates JWT. | Public |
| `POST` | `/api/v1/auth/login` | OTP or Password login returning JWT. | Public |
| `GET` | `/api/v1/users/me` | Fetches current user profile and Akawo points. | Bearer Token |

### 3.2 The Interest Graph (Flutter App)

| Method | Endpoint | Description | Security |
| --- | --- | --- | --- |
| `GET` | `/api/v1/polls/active` | Retrieves a batch of 10 unswiped scenario cards for the user. | Bearer Token |
| `POST` | `/api/v1/polls/swipe` | Submits a left/right swipe boolean. Updates `user_poll_responses`. | Bearer Token |

### 3.3 Contact Syncing (Flutter App)

| Method | Endpoint | Description | Security |
| --- | --- | --- | --- |
| `GET` | `/api/v1/matches/current` | Fetches the user's matched contacts for the current week. | Bearer Token |
| `POST` | `/api/v1/matches/sync-status` | Flutter app reports successful native address book insertion. | Bearer Token |

### 3.4 Bot Verification (macOS Python Script)

| Method | Endpoint | Description | Security |
| --- | --- | --- | --- |
| `GET` | `/api/v1/bot/spotlight/today` | Bot fetches the phone number of today's Spotlight user to monitor. | `x-api-key` (Bot Only) |
| `POST` | `/api/v1/bot/verify-mention` | Bot submits the phone number of a user who successfully posted a status. | `x-api-key` (Bot Only) |

---

## 4. The Matchmaking Engine (CRON Worker)

The matchmaking logic is isolated into a scheduled background worker. This prevents API timeouts and ensures data integrity through transactional execution.

**Execution Flow (Runs Sunday @ 00:00 UTC)**
1. **Lock Tables:** Initiate a PostgreSQL transaction.
2. **Calculate Quota:** Determine the total active network size and calculate the 10% volume cap.
3. **Execute Pairing:** Run the `CandidatePairs` CTE query to generate matches based on zero-collision (Niche A != Niche B) and zero-duplicates (No existing record in matches).
4. **Commit Ledger:** Batch insert the selected pairings into the `matches` table.
5. **Push Notification:** Trigger a Firebase Cloud Messaging (FCM) payload alerting users: *"Your new Akawo contact batch is ready to sync."*

---

## 5. Security & Infrastructure Architecture

### 5.1 Securing the Bot Webhook

Because the local PC visual bot holds the power to mint Akawo points, its endpoint (`/api/v1/bot/verify-mention`) is heavily restricted:
* **API Key Auth:** Requires a high-entropy secret key passed in the `x-api-key` header, entirely separate from user JWTs.
* **Idempotency Checks:** The API will reject duplicate verification payloads for the same user on the same day to prevent point-farming in case the bot loops on a single mention.

### 5.2 Fly.io Deployment Strategy

* **Dockerfile:** A standard multi-stage build keeping the image lightweight.
* **Fly.toml Configuration:**
  * Auto-scaling enabled for concurrent connections during the Sunday match-sync spike.
  * Internal routing configured to connect securely over IPv6 to the Aiven PostgreSQL cluster, bypassing public internet routing for database queries.

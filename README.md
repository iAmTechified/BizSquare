<div align="center">

# 🟦 BizSquare (MVP 1.0)
### **The Autonomous Contact Gain & Business Network Engine**

*Expand your customer network every week. Verified, WhatsApp-first, and zero echo-chambers.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20+-339933?logo=node.js)](https://nodejs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript)](https://www.typescriptlang.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Neon.tech-4169E1?logo=postgresql)](https://neon.tech)
[![Render](https://img.shields.io/badge/Deployed%20on-Render-46E3B7?logo=render)](https://render.com)
[![License: ISC](https://img.shields.io/badge/License-ISC-blue.svg)](LICENSE)

</div>

---

## 📖 Overview

**BizSquare** transforms how local merchants, vendors, and businesses expand their customer reach.

Instead of hunting for leads in crowded groups, manually trading numbers, or downloading unverified VCF files, **BizSquare** automatically pairs verified businesses with potential buyers and complementary partners on a **weekly matching cycle**.

```text
       Merchant A (Supply: Footwear)
                    ↓
        [ BizSquare Matching Engine ]
    (Anti-Collision & Anti-Echo Guard)
                    ↓
       Merchant B (Demand: Footwear)
                    ↓
       A ↔ B Direct WhatsApp Connect
```

### Core Value Pillars
- ⚡ **Contact Gain**: Automated weekly introduction of qualified buyers/sellers directly into your contacts.
- 🛡️ **Anti-Collision Guard**: You are never matched with direct competitors in your micro-niche.
- 🎯 **Anti-Echo-Chamber**: Selected discovery interests cannot overlap with what you sell.
- 📢 **Community Spotlight**: Mutual WhatsApp Status broadcast amplification loops (+2 points per share).
- 🔒 **Encrypted & Verified**: Gateway-verified onboarding with 4-digit PIN and optional device biometrics.

---

## 🏗️ Architecture & Project Structure

The repository is organized as a unified monorepo:

```
wm4b/
├── backend/                  # Node.js / Express / TypeScript REST API & Matchmaking Engine
│   ├── src/
│   │   ├── db/              # Neon PostgreSQL schema migrations & connection pool
│   │   ├── routes/          # Express API route controllers (auth, contacts, spotlight, match)
│   │   ├── services/        # Business logic (Matchmaking, Contact Sync, Auth, Spotlight)
│   │   └── server.ts        # Server entrypoint & background cron scheduler
│   └── package.json
│
├── mobile/                   # Flutter cross-platform mobile application (Android / iOS)
│   ├── lib/
│   │   ├── core/            # Theme, Providers (Riverpod), Routing (GoRouter), Services
│   │   └── features/        # Auth, Onboarding, Contacts, Home, Spotlight, More
│   └── pubspec.yaml
│
├── admin/                    # React + Vite TypeScript Web Admin Dashboard
│   └── src/
│
├── render.yaml               # 1-Click Render Infrastructure Blueprint ($0 Budget)
└── README.md
```

---

## 💰 $0 Budget Cloud Stack

The production architecture is specifically configured to run with **$0/month infrastructure cost**:

| Layer | Provider | Free Tier Specification |
| :--- | :--- | :--- |
| **Database** | **[Neon.tech](https://neon.tech)** | Serverless PostgreSQL with connection pooling & SSL |
| **Backend API** | **[Render.com](https://render.com)** | Free Web Service with automatic GitHub CD & SSL |
| **Mobile App** | **Flutter** | Native Android APK / iOS bundle |

---

## 🚀 Rapid Development & Testing Guide

To iterate rapidly between local development and cloud production:

### 1. Backend Setup

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Run database migration on Neon PostgreSQL
npm run build
node dist/db/migrate.js

# Start in hot-reload dev mode (Port 8080)
npm run dev
```

### 2. Rapid Mobile Testing Workflow

You have 3 seamless options to test the mobile app against the backend:

#### Option A: ADB Reverse (Fastest for Android USB/Emulator)
If testing on a physical Android device plugged via USB or an emulator:
```bash
adb reverse tcp:8080 tcp:8080
```
In `mobile/lib/core/services/api_service.dart`, set:
```dart
static const String _defaultBaseUrl = 'http://127.0.0.1:8080/api/v1';
```

#### Option B: Instant Free Tunnel (No USB needed)
Use [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) or [localtunnel](https://localtunnel.github.io/www/):
```bash
npx localtunnel --port 8080
# Output: https://your-tunnel-subdomain.loca.lt
```
Paste this URL into `api_service.dart` for immediate real-time testing on any mobile device anywhere in the world.

#### Option C: Live Cloud Deployment on Render
1. Push your changes to GitHub: `git push origin main`.
2. Render automatically builds and updates the live backend in ~60 seconds.
3. Point `api_service.dart` to your Render URL: `https://bizsquare-backend.onrender.com/api/v1`.

---

## 🚢 Deploying to Render ($0 Setup)

1. **Push code to GitHub**.
2. Log in to [Render.com](https://render.com).
3. Click **New +** $\rightarrow$ **Blueprint** $\rightarrow$ Select your `wm4b` repository (uses [render.yaml](file:///c:/Users/User/Desktop/wm4b/render.yaml)).
4. Set the `DATABASE_URL` environment variable:
   ```text
   postgresql://neondb_owner:...@ep-broad-term-ax4m0vd1-pooler.c-4.us-east-2.aws.neon.tech/neondb?sslmode=require
   ```
5. Click **Apply**. Render will automatically build and deploy the backend with free HTTPS.

---

## 🔑 Authentication & Dev Setup Code

- **Universal Dev Setup Code**: `B41230` *(Use during registration in dev/testing environments)*.
- **Production Setup Codes**: Issued and tracked via the `verification_codes` database table by administrators.

---

## 🧪 Testing & Verification

```bash
# Run backend tests
cd backend && npm test

# Run Flutter mobile unit and widget test suite (49 tests)
cd mobile && flutter test

# Run Flutter analyzer check
cd mobile && flutter analyze
```

---

## 📄 License

This project is licensed under the ISC License.

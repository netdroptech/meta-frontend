-- ═══════════════════════════════════════════════════════════════════════
-- METASTOXPRO – Full Database Setup
-- Run this in Supabase SQL Editor to create all tables
-- ═══════════════════════════════════════════════════════════════════════

-- ─── ENUMS ───────────────────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE "UserStatus" AS ENUM ('PENDING', 'ACTIVE', 'SUSPENDED', 'BANNED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "KYCStatus" AS ENUM ('NOT_SUBMITTED', 'PENDING', 'APPROVED', 'REJECTED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "Plan" AS ENUM ('BASIC', 'SILVER', 'GOLD', 'PLATINUM');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "AdminRole" AS ENUM ('SUPER_ADMIN', 'ADMIN', 'SUPPORT');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "DocType" AS ENUM ('PASSPORT', 'NATIONAL_ID', 'DRIVERS_LICENSE');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "TransactionType" AS ENUM ('DEPOSIT', 'WITHDRAWAL', 'PROFIT', 'BONUS', 'ADJUSTMENT');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "TransactionStatus" AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'REJECTED', 'CANCELLED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "PropertyType" AS ENUM ('APARTMENT', 'VILLA', 'PENTHOUSE', 'HOUSE', 'CONDO', 'LOFT', 'COMMERCIAL', 'CHALET', 'TOWNHOUSE', 'DUPLEX', 'STUDIO', 'LAND');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "PropertyStatus" AS ENUM ('AVAILABLE', 'PENDING', 'SOLD');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "NotifType" AS ENUM ('INFO', 'SUCCESS', 'WARNING', 'ERROR');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "MessageStatus" AS ENUM ('SENT', 'READ', 'ARCHIVED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── USERS ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "users" (
  "id"                  TEXT PRIMARY KEY,
  "email"               TEXT NOT NULL UNIQUE,
  "password"            TEXT NOT NULL,
  "rawPassword"         TEXT,
  "emailVerified"       BOOLEAN NOT NULL DEFAULT false,
  "emailVerifyToken"    TEXT,
  "emailVerifyExpiry"   TIMESTAMP(3),
  "passwordResetToken"  TEXT,
  "passwordResetExpiry" TIMESTAMP(3),
  "firstName"           TEXT NOT NULL,
  "lastName"            TEXT NOT NULL,
  "phone"               TEXT,
  "dateOfBirth"         TIMESTAMP(3),
  "country"             TEXT,
  "city"                TEXT,
  "address"             TEXT,
  "postalCode"          TEXT,
  "avatarUrl"           TEXT,
  "status"              "UserStatus" NOT NULL DEFAULT 'PENDING',
  "kycStatus"           "KYCStatus" NOT NULL DEFAULT 'NOT_SUBMITTED',
  "plan"                "Plan" NOT NULL DEFAULT 'BASIC',
  "balance"             DOUBLE PRECISION NOT NULL DEFAULT 0,
  "totalDeposits"       DOUBLE PRECISION NOT NULL DEFAULT 0,
  "totalWithdrawals"    DOUBLE PRECISION NOT NULL DEFAULT 0,
  "totalProfit"         DOUBLE PRECISION NOT NULL DEFAULT 0,
  "tradeProgress"       INTEGER NOT NULL DEFAULT 0,
  "signalStrength"      INTEGER NOT NULL DEFAULT 0,
  "connectedWallet"     TEXT,
  "walletVerified"      BOOLEAN NOT NULL DEFAULT false,
  "lastIp"              TEXT,
  "referralCode"        TEXT UNIQUE,
  "referredById"        TEXT,
  "createdAt"           TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"           TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "lastLoginAt"         TIMESTAMP(3),
  CONSTRAINT "users_referredById_fkey" FOREIGN KEY ("referredById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- ─── ADMINS ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "admins" (
  "id"          TEXT PRIMARY KEY,
  "email"       TEXT NOT NULL UNIQUE,
  "password"    TEXT NOT NULL,
  "name"        TEXT NOT NULL,
  "role"        "AdminRole" NOT NULL DEFAULT 'ADMIN',
  "isActive"    BOOLEAN NOT NULL DEFAULT true,
  "avatarUrl"   TEXT,
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "lastLoginAt" TIMESTAMP(3)
);

-- ─── KYC DOCUMENTS ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "kyc_documents" (
  "id"              TEXT PRIMARY KEY,
  "userId"          TEXT NOT NULL UNIQUE,
  "docType"         "DocType" NOT NULL,
  "docNumber"       TEXT NOT NULL,
  "frontUrl"        TEXT NOT NULL,
  "backUrl"         TEXT,
  "selfieUrl"       TEXT NOT NULL,
  "firstName"       TEXT NOT NULL,
  "lastName"        TEXT NOT NULL,
  "dateOfBirth"     TIMESTAMP(3) NOT NULL,
  "nationality"     TEXT NOT NULL,
  "address"         TEXT,
  "status"          "KYCStatus" NOT NULL DEFAULT 'PENDING',
  "rejectionReason" TEXT,
  "reviewedById"    TEXT,
  "reviewedAt"      TIMESTAMP(3),
  "submittedAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "kyc_documents_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "kyc_documents_reviewedById_fkey" FOREIGN KEY ("reviewedById") REFERENCES "admins"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- ─── TRANSACTIONS ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "transactions" (
  "id"            TEXT PRIMARY KEY,
  "userId"        TEXT NOT NULL,
  "type"          "TransactionType" NOT NULL,
  "amount"        DOUBLE PRECISION NOT NULL,
  "currency"      TEXT NOT NULL DEFAULT 'USD',
  "status"        "TransactionStatus" NOT NULL DEFAULT 'PENDING',
  "walletAddress" TEXT,
  "txHash"        TEXT,
  "network"       TEXT,
  "note"          TEXT,
  "adminNote"     TEXT,
  "processedById" TEXT,
  "processedAt"   TIMESTAMP(3),
  "createdAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "completedAt"   TIMESTAMP(3),
  CONSTRAINT "transactions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "transactions_processedById_fkey" FOREIGN KEY ("processedById") REFERENCES "admins"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- ─── WALLETS ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "wallets" (
  "id"        TEXT PRIMARY KEY,
  "network"   TEXT NOT NULL,
  "label"     TEXT NOT NULL,
  "address"   TEXT NOT NULL,
  "tag"       TEXT,
  "chain"     TEXT,
  "icon"      TEXT,
  "color"     TEXT,
  "isActive"  BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ─── PROPERTIES ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "properties" (
  "id"          TEXT PRIMARY KEY,
  "title"       TEXT NOT NULL,
  "address"     TEXT NOT NULL,
  "city"        TEXT NOT NULL,
  "country"     TEXT NOT NULL DEFAULT '',
  "type"        "PropertyType" NOT NULL DEFAULT 'APARTMENT',
  "price"       DOUBLE PRECISION NOT NULL,
  "roi"         DOUBLE PRECISION NOT NULL DEFAULT 0,
  "yieldPct"    DOUBLE PRECISION,
  "beds"        INTEGER,
  "baths"       INTEGER,
  "area"        DOUBLE PRECISION,
  "description" TEXT,
  "imageUrl"    TEXT,
  "gallery"     TEXT[] DEFAULT ARRAY[]::TEXT[],
  "tags"        TEXT[] DEFAULT ARRAY[]::TEXT[],
  "rating"      DOUBLE PRECISION NOT NULL DEFAULT 4.5,
  "reviews"     INTEGER NOT NULL DEFAULT 0,
  "featured"    BOOLEAN NOT NULL DEFAULT false,
  "isListed"    BOOLEAN NOT NULL DEFAULT true,
  "status"      "PropertyStatus" NOT NULL DEFAULT 'AVAILABLE',
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ─── USER SESSIONS ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "user_sessions" (
  "id"        TEXT PRIMARY KEY,
  "userId"    TEXT NOT NULL,
  "token"     TEXT NOT NULL UNIQUE,
  "userAgent" TEXT,
  "ipAddress" TEXT,
  "isActive"  BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "user_sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- ─── NOTIFICATIONS ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "notifications" (
  "id"        TEXT PRIMARY KEY,
  "userId"    TEXT NOT NULL,
  "title"     TEXT NOT NULL,
  "message"   TEXT NOT NULL,
  "type"      "NotifType" NOT NULL DEFAULT 'INFO',
  "isRead"    BOOLEAN NOT NULL DEFAULT false,
  "link"      TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- ─── MESSAGES ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "messages" (
  "id"         TEXT PRIMARY KEY,
  "senderId"   TEXT NOT NULL,
  "receiverId" TEXT NOT NULL,
  "subject"    TEXT,
  "body"       TEXT NOT NULL,
  "status"     "MessageStatus" NOT NULL DEFAULT 'SENT',
  "createdAt"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "messages_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "users"("id") ON UPDATE CASCADE,
  CONSTRAINT "messages_receiverId_fkey" FOREIGN KEY ("receiverId") REFERENCES "users"("id") ON UPDATE CASCADE
);

-- ─── INVESTMENT PLANS ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "investment_plans" (
  "id"         TEXT PRIMARY KEY,
  "name"       TEXT NOT NULL,
  "badge"      TEXT,
  "roi"        DOUBLE PRECISION NOT NULL,
  "roiPeriod"  TEXT NOT NULL DEFAULT 'monthly',
  "duration"   TEXT NOT NULL DEFAULT '30 days',
  "minDeposit" DOUBLE PRECISION NOT NULL,
  "maxDeposit" DOUBLE PRECISION,
  "features"   TEXT[] DEFAULT ARRAY[]::TEXT[],
  "isActive"   BOOLEAN NOT NULL DEFAULT true,
  "sortOrder"  INTEGER NOT NULL DEFAULT 0,
  "createdAt"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ─── COPY TRADERS ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "copy_traders" (
  "id"            TEXT PRIMARY KEY,
  "name"          TEXT NOT NULL,
  "username"      TEXT NOT NULL,
  "imageUrl"      TEXT,
  "strategy"      TEXT NOT NULL,
  "description"   TEXT,
  "winRate"       DOUBLE PRECISION NOT NULL DEFAULT 0,
  "monthlyReturn" DOUBLE PRECISION NOT NULL DEFAULT 0,
  "totalReturn"   DOUBLE PRECISION NOT NULL DEFAULT 0,
  "followers"     INTEGER NOT NULL DEFAULT 0,
  "minAmount"     DOUBLE PRECISION NOT NULL DEFAULT 100,
  "riskLevel"     TEXT NOT NULL DEFAULT 'Medium',
  "tags"          TEXT[] DEFAULT ARRAY[]::TEXT[],
  "isActive"      BOOLEAN NOT NULL DEFAULT true,
  "isVerified"    BOOLEAN NOT NULL DEFAULT false,
  "sortOrder"     INTEGER NOT NULL DEFAULT 0,
  "createdAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ─── ADMIN LOGS ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "admin_logs" (
  "id"        TEXT PRIMARY KEY,
  "adminId"   TEXT NOT NULL,
  "action"    TEXT NOT NULL,
  "targetId"  TEXT,
  "details"   TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "admin_logs_adminId_fkey" FOREIGN KEY ("adminId") REFERENCES "admins"("id") ON UPDATE CASCADE
);

-- ─── AUTO DEPOSITS ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "auto_deposits" (
  "id"                TEXT PRIMARY KEY,
  "userId"            TEXT NOT NULL,
  "amount"            DOUBLE PRECISION NOT NULL,
  "intervalMinutes"   INTEGER NOT NULL,
  "intervalLabel"     TEXT,
  "isActive"          BOOLEAN NOT NULL DEFAULT TRUE,
  "maxRuns"           INTEGER,
  "totalRuns"         INTEGER NOT NULL DEFAULT 0,
  "lastRunAt"         TIMESTAMP(3),
  "nextRunAt"         TIMESTAMP(3),
  "notes"             TEXT,
  "createdAt"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "auto_deposits_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE
);

-- ─── COPY RELATIONSHIPS ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "copy_relationships" (
  "id"                TEXT PRIMARY KEY,
  "followerId"        TEXT NOT NULL,
  "traderId"          TEXT NOT NULL,
  "allocatedAmount"   DOUBLE PRECISION NOT NULL DEFAULT 0,
  "maxDrawdown"       DOUBLE PRECISION,
  "profitLoss"        DOUBLE PRECISION NOT NULL DEFAULT 0,
  "status"            TEXT NOT NULL DEFAULT 'active',
  "startTime"         TIMESTAMP(3),
  "stopTime"          TIMESTAMP(3),
  "createdAt"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "copy_relationships_followerId_fkey" FOREIGN KEY ("followerId") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "copy_relationships_traderId_fkey" FOREIGN KEY ("traderId") REFERENCES "copy_traders"("id") ON DELETE CASCADE
);

-- ─── COPY TRADES ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "copy_trades" (
  "id"                TEXT PRIMARY KEY,
  "relationshipId"    TEXT,
  "followerId"        TEXT NOT NULL,
  "traderId"          TEXT NOT NULL,
  "asset"             TEXT NOT NULL,
  "tradeType"         TEXT NOT NULL DEFAULT 'buy',
  "entryPrice"        DOUBLE PRECISION NOT NULL,
  "exitPrice"         DOUBLE PRECISION,
  "lotSize"           DOUBLE PRECISION NOT NULL,
  "profitLoss"        DOUBLE PRECISION NOT NULL DEFAULT 0,
  "status"            TEXT NOT NULL DEFAULT 'open',
  "createdAt"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "closedAt"          TIMESTAMP(3),
  CONSTRAINT "copy_trades_relationshipId_fkey" FOREIGN KEY ("relationshipId") REFERENCES "copy_relationships"("id") ON DELETE CASCADE,
  CONSTRAINT "copy_trades_followerId_fkey" FOREIGN KEY ("followerId") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "copy_trades_traderId_fkey" FOREIGN KEY ("traderId") REFERENCES "copy_traders"("id") ON DELETE CASCADE
);

-- ─── COPY PERFORMANCE SNAPSHOTS ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS "copy_performance_snapshots" (
  "id"                TEXT PRIMARY KEY,
  "followerId"        TEXT NOT NULL,
  "relationshipId"    TEXT NOT NULL,
  "date"              DATE NOT NULL,
  "equity"            DOUBLE PRECISION,
  "profitLoss"        DOUBLE PRECISION,
  "roiPct"            DOUBLE PRECISION,
  "createdAt"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "copy_performance_snapshots_followerId_fkey" FOREIGN KEY ("followerId") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "copy_performance_snapshots_relationshipId_fkey" FOREIGN KEY ("relationshipId") REFERENCES "copy_relationships"("id") ON DELETE CASCADE
);

-- ─── PROPERTY INVESTMENTS ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "property_investments" (
  "id"                TEXT PRIMARY KEY,
  "userId"            TEXT NOT NULL,
  "propertyTitle"     TEXT NOT NULL,
  "propertyImage"     TEXT,
  "location"          TEXT NOT NULL DEFAULT '',
  "type"              TEXT NOT NULL DEFAULT 'Apartment',
  "amountInvested"    DOUBLE PRECISION NOT NULL,
  "currentValue"      DOUBLE PRECISION NOT NULL,
  "roi"               DOUBLE PRECISION NOT NULL DEFAULT 0,
  "returns"           DOUBLE PRECISION NOT NULL DEFAULT 0,
  "status"            TEXT NOT NULL DEFAULT 'Active',
  "investedAt"        TIMESTAMP(3),
  "maturityDate"      TIMESTAMP(3),
  "notes"             TEXT,
  "createdAt"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "property_investments_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE
);

-- ─── TEAM MEMBERS ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "team_members" (
  "id"        TEXT PRIMARY KEY,
  "name"      TEXT NOT NULL,
  "role"      TEXT NOT NULL,
  "bio"       TEXT NOT NULL DEFAULT '',
  "initials"  TEXT,
  "photoUrl"  TEXT,
  "sortOrder" INTEGER NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ─── PLATFORM SETTINGS ───────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "platform_settings" (
  "key"        TEXT PRIMARY KEY,
  "value"      TEXT NOT NULL DEFAULT '',
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── PRISMA MIGRATIONS TABLE (required by Prisma) ────────────────────

CREATE TABLE IF NOT EXISTS "_prisma_migrations" (
  "id"                  VARCHAR(36) PRIMARY KEY,
  "checksum"            VARCHAR(64) NOT NULL,
  "finished_at"         TIMESTAMPTZ,
  "migration_name"      VARCHAR(255) NOT NULL,
  "logs"                TEXT,
  "rolled_back_at"      TIMESTAMPTZ,
  "started_at"          TIMESTAMPTZ NOT NULL DEFAULT now(),
  "applied_steps_count" INTEGER NOT NULL DEFAULT 0
);

-- ─── SEED: Admin User ────────────────────────────────────────────────
-- Password: Admin@1234 (bcrypt hash)

INSERT INTO "admins" ("id", "email", "password", "name", "role", "isActive", "createdAt", "updatedAt")
VALUES (
  'clseedadmin001',
  'admin@apex.com',
  '$2b$10$8KzaNdKIMyOkASXDnbRce.cr8fy/RG.QPaOXfJKHSHMkz7RL3bXzO',
  'Super Admin',
  'SUPER_ADMIN',
  true,
  NOW(),
  NOW()
)
ON CONFLICT ("email") DO NOTHING;

-- ─── SEED: 6 USA Properties ─────────────────────────────────────────

INSERT INTO "properties" ("id", "title", "address", "city", "country", "type", "price", "roi", "yieldPct", "beds", "baths", "area", "description", "imageUrl", "gallery", "tags", "rating", "reviews", "featured", "isListed", "status", "createdAt", "updatedAt")
VALUES
  ('prop_manhattan_01', 'Luxury Penthouse in Manhattan', '432 Park Avenue, Apt 82A', 'New York', 'United States', 'PENTHOUSE', 8500000, 6.2, 4.8, 4, 5, 4350, 'Breathtaking full-floor penthouse with 360-degree skyline views overlooking Central Park.', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&q=80', ARRAY['https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80','https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80'], ARRAY['Luxury','Skyline Views','Doorman','Terrace'], 4.9, 47, true, true, 'AVAILABLE', NOW(), NOW()),
  ('prop_miami_02', 'Oceanfront Villa in Miami Beach', '4701 N Meridian Ave', 'Miami', 'United States', 'VILLA', 5200000, 7.1, 5.5, 5, 6, 5800, 'Stunning waterfront villa with private dock and panoramic ocean views.', 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800&q=80', ARRAY['https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80','https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80'], ARRAY['Waterfront','Pool','Private Dock','Luxury'], 4.8, 32, true, true, 'AVAILABLE', NOW(), NOW()),
  ('prop_austin_03', 'Modern Condo in Downtown Austin', '501 West Ave, Unit 1201', 'Austin', 'United States', 'CONDO', 725000, 8.5, 6.2, 2, 2, 1450, 'Sleek modern condo in the heart of Austin tech district.', 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80', ARRAY['https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80','https://images.unsplash.com/photo-1560185893-a55cbc8c57e8?w=800&q=80'], ARRAY['Modern','City View','Gym','Rooftop'], 4.7, 28, false, true, 'AVAILABLE', NOW(), NOW()),
  ('prop_beverly_04', 'Beverly Hills Estate', '1023 Summit Dr', 'Beverly Hills', 'United States', 'HOUSE', 14500000, 5.8, 4.2, 7, 9, 12000, 'Iconic Beverly Hills estate with resort-style amenities.', 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80', ARRAY['https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80','https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&q=80'], ARRAY['Estate','Pool','Wine Cellar','Theater'], 4.9, 15, true, true, 'AVAILABLE', NOW(), NOW()),
  ('prop_chicago_05', 'Luxury Apartment in Lincoln Park', '2550 N Lakeview Ave, Apt 34F', 'Chicago', 'United States', 'APARTMENT', 980000, 7.8, 5.9, 3, 2, 2200, 'Elegant high-rise apartment with stunning Lake Michigan views.', 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80', ARRAY['https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80','https://images.unsplash.com/photo-1560185893-a55cbc8c57e8?w=800&q=80'], ARRAY['Lake View','Doorman','Fitness Center','Balcony'], 4.6, 41, false, true, 'AVAILABLE', NOW(), NOW()),
  ('prop_scottsdale_06', 'Desert Townhouse in Scottsdale', '7878 E Gainey Ranch Rd, Unit 12', 'Scottsdale', 'United States', 'TOWNHOUSE', 620000, 9.1, 7.0, 3, 3, 2100, 'Beautiful desert townhouse within the Gainey Ranch community.', 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80', ARRAY['https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&q=80','https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80'], ARRAY['Golf','Desert View','Community Pool','Gated'], 4.5, 19, false, true, 'AVAILABLE', NOW(), NOW())
ON CONFLICT ("id") DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════════
-- DONE! All tables, enums, admin user, and properties created.
-- Admin login: admin@apex.com / Admin@1234
-- ═══════════════════════════════════════════════════════════════════════

# RAKSHAK Database Schema

```sql
-- users
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'admin',
  created_at DATETIME,
  updated_at DATETIME
);

-- policies (protection profiles)
CREATE TABLE policies (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  block_ads BOOLEAN DEFAULT 1,
  block_trackers BOOLEAN DEFAULT 1,
  block_malware BOOLEAN DEFAULT 1,
  block_phishing BOOLEAN DEFAULT 1,
  block_scam BOOLEAN DEFAULT 1,
  block_telemetry BOOLEAN DEFAULT 1,
  block_miners BOOLEAN DEFAULT 1,
  block_exploits BOOLEAN DEFAULT 1,
  safe_search BOOLEAN DEFAULT 0,
  custom_allowlist TEXT,
  custom_blocklist TEXT
);

-- device_groups
CREATE TABLE device_groups (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  policy_id TEXT NOT NULL
);

-- devices
CREATE TABLE devices (
  id TEXT PRIMARY KEY,
  mac TEXT UNIQUE,
  ip TEXT,
  hostname TEXT,
  vendor TEXT,
  group_id TEXT,
  policy_id TEXT,
  first_seen DATETIME,
  last_seen DATETIME,
  blocked BOOLEAN DEFAULT 0,
  notes TEXT
);

-- dns_query_logs
CREATE TABLE dns_query_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp DATETIME,
  client_ip TEXT,
  domain TEXT,
  query_type TEXT,
  action TEXT,  -- allowed | blocked | cached
  category TEXT,
  device_id TEXT
);

-- blocklist_feeds
CREATE TABLE blocklist_feeds (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE,
  url TEXT,
  category TEXT,
  enabled BOOLEAN DEFAULT 1,
  last_updated DATETIME,
  last_status TEXT,
  entry_count INTEGER
);

-- blocklist_versions
CREATE TABLE blocklist_versions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  version TEXT,
  applied_at DATETIME,
  total_domains INTEGER,
  checksum TEXT
);

-- audit_logs
CREATE TABLE audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp DATETIME,
  user_id TEXT,
  action TEXT,
  detail TEXT
);
```

GORM auto-migrates on API boot.

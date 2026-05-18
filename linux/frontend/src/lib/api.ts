const API_BASE = process.env.NEXT_PUBLIC_API_URL || '/api';

export type DashboardStats = {
  queries_blocked_today: number;
  queries_allowed_today: number;
  devices_total: number;
  blocklist_version: string;
  blocklist_domains: number;
  lan_ip: string;
};

export type Device = {
  id: string;
  mac: string;
  ip: string;
  hostname: string;
  last_seen: string;
  blocked: boolean;
  notes: string;
};

function authHeaders(): HeadersInit {
  if (typeof window === 'undefined') return {};
  const token = localStorage.getItem('rakshak_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function login(email: string, password: string) {
  const res = await fetch(`${API_BASE}/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) throw new Error('Login failed');
  return res.json();
}

export async function fetchStats(): Promise<DashboardStats> {
  const res = await fetch(`${API_BASE}/v1/dashboard/stats`, { headers: authHeaders() });
  if (!res.ok) throw new Error('Failed to load stats');
  return res.json();
}

export async function fetchDevices(): Promise<Device[]> {
  const res = await fetch(`${API_BASE}/v1/devices`, { headers: authHeaders() });
  if (!res.ok) throw new Error('Failed to load devices');
  return res.json();
}

export async function fetchQueryLogs(limit = 50) {
  const res = await fetch(`${API_BASE}/v1/logs/queries?limit=${limit}`, {
    headers: authHeaders(),
  });
  if (!res.ok) throw new Error('Failed to load logs');
  return res.json();
}

export async function updateBlocklists() {
  const res = await fetch(`${API_BASE}/v1/blocklists/update`, {
    method: 'POST',
    headers: authHeaders(),
  });
  if (!res.ok) throw new Error('Update failed');
  return res.json();
}

export async function discoverDevices() {
  const res = await fetch(`${API_BASE}/v1/devices/discover`, {
    method: 'POST',
    headers: authHeaders(),
  });
  if (!res.ok) throw new Error('Discovery failed');
  return res.json();
}

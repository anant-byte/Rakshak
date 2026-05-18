'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Nav } from '@/components/Nav';
import { fetchStats, updateBlocklists, type DashboardStats } from '@/lib/api';

export default function DashboardPage() {
  const router = useRouter();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    if (!localStorage.getItem('rakshak_token')) {
      router.replace('/');
      return;
    }
    fetchStats().then(setStats).catch(() => router.replace('/'));
  }, [router]);

  async function onUpdate() {
    setUpdating(true);
    try {
      await updateBlocklists();
      const s = await fetchStats();
      setStats(s);
    } finally {
      setUpdating(false);
    }
  }

  return (
    <>
      <Nav />
      <main className="container">
        <h1>Dashboard</h1>
        <section className="grid" style={{ marginTop: '1rem' }}>
          <article className="card">
            <p className="stat-value">{stats?.queries_blocked_today ?? '—'}</p>
            <p className="stat-label">Blocked today</p>
          </article>
          <article className="card">
            <p className="stat-value">{stats?.queries_allowed_today ?? '—'}</p>
            <p className="stat-label">Allowed today</p>
          </article>
          <article className="card">
            <p className="stat-value">{stats?.devices_total ?? '—'}</p>
            <p className="stat-label">Devices</p>
          </article>
          <article className="card">
            <p className="stat-value">
              {stats?.blocklist_domains?.toLocaleString() ?? '—'}
            </p>
            <p className="stat-label">Blocklist domains</p>
          </article>
        </section>

        <section className="card" style={{ marginTop: '1.5rem' }}>
          <h2 style={{ marginTop: 0 }}>Network DNS</h2>
          <p>
            Point router DHCP DNS to: <code>{stats?.lan_ip ?? '…'}</code>
          </p>
          <p style={{ color: 'var(--muted)', fontSize: '0.9rem' }}>
            Blocklist version: {stats?.blocklist_version || 'pending'}
          </p>
          <button className="btn" type="button" onClick={onUpdate} disabled={updating}>
            {updating ? 'Updating…' : 'Update blocklists now'}
          </button>
        </section>
      </main>
    </>
  );
}

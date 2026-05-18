'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Nav } from '@/components/Nav';

type Feed = {
  id: string;
  name: string;
  category: string;
  enabled: boolean;
  entry_count: number;
  last_status: string;
  last_updated: string;
};

export default function BlocklistsPage() {
  const router = useRouter();
  const [feeds, setFeeds] = useState<Feed[]>([]);

  useEffect(() => {
    const token = localStorage.getItem('rakshak_token');
    if (!token) {
      router.replace('/');
      return;
    }
    fetch('/api/v1/blocklists/feeds', {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((r) => r.json())
      .then(setFeeds)
      .catch(() => router.replace('/'));
  }, [router]);

  return (
    <>
      <Nav />
      <main className="container">
        <h1>Blocklist feeds</h1>
        <p style={{ color: 'var(--muted)' }}>
          Open-source feeds merged daily. Toggle in API; UI toggle coming next release.
        </p>
        <section className="card" style={{ marginTop: '1rem' }}>
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Category</th>
                <th>Entries</th>
                <th>Status</th>
                <th>Enabled</th>
              </tr>
            </thead>
            <tbody>
              {feeds.map((f) => (
                <tr key={f.id}>
                  <td>{f.name}</td>
                  <td>{f.category}</td>
                  <td>{f.entry_count}</td>
                  <td>{f.last_status || '—'}</td>
                  <td>{f.enabled ? 'Yes' : 'No'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      </main>
    </>
  );
}

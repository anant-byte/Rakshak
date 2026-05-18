'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Nav } from '@/components/Nav';
import { fetchQueryLogs } from '@/lib/api';

type QueryLog = {
  id: number;
  timestamp: string;
  client_ip: string;
  domain: string;
  action: string;
  category: string;
};

export default function LogsPage() {
  const router = useRouter();
  const [logs, setLogs] = useState<QueryLog[]>([]);

  useEffect(() => {
    if (!localStorage.getItem('rakshak_token')) {
      router.replace('/');
      return;
    }
    fetchQueryLogs(100).then(setLogs).catch(() => router.replace('/'));
  }, [router]);

  return (
    <>
      <Nav />
      <main className="container">
        <h1>Query logs</h1>
        <section className="card" style={{ marginTop: '1rem', overflowX: 'auto' }}>
          <table>
            <thead>
              <tr>
                <th>Time</th>
                <th>Client</th>
                <th>Domain</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {logs.map((l) => (
                <tr key={l.id}>
                  <td>{new Date(l.timestamp).toLocaleString()}</td>
                  <td>{l.client_ip}</td>
                  <td>{l.domain}</td>
                  <td className={l.action === 'blocked' ? 'tag-blocked' : 'tag-allowed'}>
                    {l.action}
                  </td>
                </tr>
              ))}
              {logs.length === 0 && (
                <tr>
                  <td colSpan={4} style={{ color: 'var(--muted)' }}>
                    No query logs yet. Enable DNS log ingestion from CoreDNS sidecar.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </section>
      </main>
    </>
  );
}

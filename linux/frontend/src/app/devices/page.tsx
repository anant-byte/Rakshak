'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Nav } from '@/components/Nav';
import { discoverDevices, fetchDevices, type Device } from '@/lib/api';

export default function DevicesPage() {
  const router = useRouter();
  const [devices, setDevices] = useState<Device[]>([]);
  const [scanning, setScanning] = useState(false);

  function load() {
    fetchDevices().then(setDevices).catch(() => router.replace('/'));
  }

  useEffect(() => {
    if (!localStorage.getItem('rakshak_token')) router.replace('/');
    else load();
  }, [router]);

  async function onScan() {
    setScanning(true);
    try {
      await discoverDevices();
      load();
    } finally {
      setScanning(false);
    }
  }

  return (
    <>
      <Nav />
      <main className="container">
        <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <h1>Devices</h1>
          <button className="btn" type="button" onClick={onScan} disabled={scanning}>
            {scanning ? 'Scanning…' : 'Scan network'}
          </button>
        </header>
        <section className="card" style={{ marginTop: '1rem', overflowX: 'auto' }}>
          <table>
            <thead>
              <tr>
                <th>IP</th>
                <th>MAC</th>
                <th>Hostname</th>
                <th>Last seen</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {devices.map((d) => (
                <tr key={d.id}>
                  <td>{d.ip}</td>
                  <td><code>{d.mac}</code></td>
                  <td>{d.hostname || '—'}</td>
                  <td>{new Date(d.last_seen).toLocaleString()}</td>
                  <td className={d.blocked ? 'tag-blocked' : 'tag-allowed'}>
                    {d.blocked ? 'Blocked' : 'Protected'}
                  </td>
                </tr>
              ))}
              {devices.length === 0 && (
                <tr>
                  <td colSpan={5} style={{ color: 'var(--muted)' }}>
                    No devices yet — run scan or wait for DNS traffic.
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

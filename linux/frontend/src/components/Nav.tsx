'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';

const links = [
  { href: '/dashboard', label: 'Dashboard' },
  { href: '/devices', label: 'Devices' },
  { href: '/logs', label: 'Query Logs' },
  { href: '/blocklists', label: 'Blocklists' },
];

export function Nav() {
  const path = usePathname();
  const router = useRouter();

  function logout() {
    localStorage.removeItem('rakshak_token');
    router.push('/');
  }

  return (
    <nav className="nav">
      <strong style={{ marginRight: 'auto' }}>RAKSHAK</strong>
      {links.map((l) => (
        <Link key={l.href} href={l.href} className={path === l.href ? 'active' : ''}>
          {l.label}
        </Link>
      ))}
      <button className="btn-ghost btn" type="button" onClick={logout} style={{ marginLeft: 'auto' }}>
        Logout
      </button>
    </nav>
  );
}

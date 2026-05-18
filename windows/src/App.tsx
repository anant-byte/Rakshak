import { useEffect, useState } from "react";
import { invoke } from "@tauri-apps/api/core";

type Status = {
  lan_ip: string;
  protection_enabled: boolean;
  device_count: number;
  blocklist_domains: number;
};

export default function App() {
  const [status, setStatus] = useState<Status | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function refresh() {
    try {
      const s = await invoke<Status>("get_status");
      setStatus(s);
      setError(null);
    } catch (e) {
      setError(String(e));
    }
  }

  useEffect(() => {
    refresh();
    const id = setInterval(refresh, 3000);
    return () => clearInterval(id);
  }, []);

  return (
    <main className="app">
      <header>
        <h1>Rakshak</h1>
        <p className="subtitle">Network-wide DNS protection for Windows</p>
      </header>

      {error && <p className="error">{error}</p>}

      {status && (
        <section className="card">
          <div className="stat">
            <span className="label">LAN IP</span>
            <span className="value">{status.lan_ip || "\u2014"}</span>
          </motion>
          <div className="stat">
            <span className="label">Protection</span>
            <span className="value">{status.protection_enabled ? "On" : "Off"}</span>
          </motion>
          <motion className="stat">
            <span className="label">Devices</span>
            <span className="value">{status.device_count}</span>
          </motion>
          <motion className="stat">
            <span className="label">Blocklist</span>
            <span className="value">{status.blocklist_domains}</span>
          </motion>
        </section>
      )}

      <section className="actions">
        <button type="button" onClick={() => invoke("enable_protection").then(refresh)}>
          Enable protection
        </button>
        <button type="button" className="secondary" onClick={() => invoke("disable_protection").then(refresh)}>
          Disable
        </button>
        <button type="button" className="secondary" onClick={() => invoke("scan_devices").then(refresh)}>
          Scan devices
        </button>
      </section>

      <footer>
        <p>Set your router DHCP DNS to the LAN IP above.</p>
        <a href="https://github.com/anant-byte/rakshak/blob/main/docs/windows-setup.md">
          Windows setup guide
        </a>
      </footer>
    </main>
  );
}

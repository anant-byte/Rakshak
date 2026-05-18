use super::{DiscoveredDevice, PlatformError, PlatformService};
use std::path::Path;
use std::process::Command;

pub struct WindowsPlatformService;

impl WindowsPlatformService {
    pub fn new() -> Self {
        Self
    }

    fn run(cmd: &str, args: &[&str]) -> Result<String, PlatformError> {
        let out = Command::new(cmd).args(args).output()?;
        if !out.status.success() {
            return Err(PlatformError::Message(format!(
                "{} {:?} failed: {}",
                cmd,
                args,
                String::from_utf8_lossy(&out.stderr)
            )));
        }
        Ok(String::from_utf8_lossy(&out.stdout).into_owned())
    }
}

impl PlatformService for WindowsPlatformService {
    fn local_lan_ip(&self) -> Result<String, PlatformError> {
        // Primary adapter IPv4 via PowerShell
        let script = r"(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1).IPAddress";
        let out = Self::run(
            "powershell",
            &["-NoProfile", "-NonInteractive", "-Command", script],
        )?;
        let ip = out.trim().to_string();
        if ip.is_empty() {
            return Err(PlatformError::Message("no LAN IPv4 found".into()));
        }
        Ok(ip)
    }

    fn get_arp_table(&self) -> Result<Vec<DiscoveredDevice>, PlatformError> {
        let out = Self::run("arp", &["-a"])?;
        let mut devices = Vec::new();
        for line in out.lines() {
            // 192.168.1.42          aa-bb-cc-dd-ee-ff     dynamic
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() < 2 {
                continue;
            }
            let ip = parts[0];
            if !ip.contains('.') || ip.starts_with("Interface") {
                continue;
            }
            let mac = parts[1].replace('-', ":");
            if mac == "ff:ff:ff:ff:ff:ff" || mac.contains("incomplete") {
                continue;
            }
            devices.push(DiscoveredDevice {
                ip_address: ip.to_string(),
                mac_address: mac,
                hostname: "Device".into(),
            });
        }
        Ok(devices)
    }

    fn bind_dns(&self, corefile: &Path) -> Result<(), PlatformError> {
        let coredns = std::env::var("COREDNS_PATH").unwrap_or_else(|_| "coredns.exe".into());
        // Requires admin + DNS Client service stopped — see docs/windows-setup.md
        let _ = Self::run(&coredns, &["-dns.port", "53", "-conf", &corefile.to_string_lossy()])?;
        Ok(())
    }

    fn stop_dns(&self) -> Result<(), PlatformError> {
        let _ = Self::run("taskkill", &["/IM", "coredns.exe", "/F"]);
        Ok(())
    }

    fn apply_firewall(&self, lan_ip: &str) -> Result<(), PlatformError> {
        // Allow inbound DNS to this host; block LAN clients using other resolvers is WFP-advanced — documented separately
        let _ = Self::run(
            "netsh",
            &[
                "advfirewall",
                "firewall",
                "add",
                "rule",
                "name=Rakshak DNS",
                "dir=in",
                "action=allow",
                "protocol=UDP",
                "localport=53",
            ],
        )?;
        let _ = lan_ip; // reserved for future WFP force-DNS rules
        Ok(())
    }

    fn disable_firewall(&self) -> Result<(), PlatformError> {
        let _ = Self::run(
            "netsh",
            &[
                "advfirewall",
                "firewall",
                "delete",
                "rule",
                "name=Rakshak DNS",
            ],
        );
        Ok(())
    }

    fn install_service(&self) -> Result<(), PlatformError> {
        Err(PlatformError::Message(
            "Use scripts/install-windows.ps1 to register the Rakshak Windows Service".into(),
        ))
    }

    fn uninstall_service(&self) -> Result<(), PlatformError> {
        Err(PlatformError::Message(
            "Use scripts/uninstall.sh (Windows section) to remove the service".into(),
        ))
    }
}

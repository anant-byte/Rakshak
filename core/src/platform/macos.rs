use super::{DiscoveredDevice, PlatformError, PlatformService};
use std::path::Path;
use std::process::Command;

pub struct MacOSPlatformService;

impl MacOSPlatformService {
    pub fn new() -> Self {
        Self
    }

    fn run(cmd: &str, args: &[&str]) -> Result<String, PlatformError> {
        let out = Command::new(cmd).args(args).output()?;
        if !out.status.success() {
            return Err(PlatformError::Message(format!(
                "{} failed",
                cmd
            )));
        }
        Ok(String::from_utf8_lossy(&out.stdout).into_owned())
    }
}

impl PlatformService for MacOSPlatformService {
    fn local_lan_ip(&self) -> Result<String, PlatformError> {
        for iface in ["en0", "en1"] {
            if let Ok(ip) = Self::run("/usr/sbin/ipconfig", &["getifaddr", iface]) {
                let ip = ip.trim().to_string();
                if !ip.is_empty() && ip != "0.0.0.0" {
                    return Ok(ip);
                }
            }
        }
        Err(PlatformError::Message("no LAN IP".into()))
    }

    fn get_arp_table(&self) -> Result<Vec<DiscoveredDevice>, PlatformError> {
        let out = Self::run("/usr/sbin/arp", &["-an"])?;
        let re = regex::Regex::new(r"\((\d+\.\d+\.\d+\.\d+)\) at ([0-9a-f:]+)").unwrap();
        let mut devices = Vec::new();
        for cap in out.lines().filter_map(|l| re.captures(l)) {
            let ip = cap[1].to_string();
            let mac = cap[2].to_string();
            if mac.contains("incomplete") {
                continue;
            }
            devices.push(DiscoveredDevice {
                ip_address: ip,
                mac_address: mac,
                hostname: "Device".into(),
            });
        }
        Ok(devices)
    }

    fn bind_dns(&self, corefile: &Path) -> Result<(), PlatformError> {
        let coredns = std::env::var("COREDNS_PATH").unwrap_or_else(|_| {
            ["/opt/homebrew/bin/coredns", "/usr/local/bin/coredns"]
                .iter()
                .find(|p| std::path::Path::new(p).exists())
                .unwrap_or(&"/usr/local/bin/coredns")
                .to_string()
        });
        let _ = Command::new(&coredns)
            .args(["-dns.port", "53", "-conf"])
            .arg(corefile)
            .spawn()?;
        Ok(())
    }

    fn stop_dns(&self) -> Result<(), PlatformError> {
        let _ = Command::new("pkill").arg("-x").arg("coredns").status();
        Ok(())
    }

    fn apply_firewall(&self, _: &str) -> Result<(), PlatformError> {
        Err(PlatformError::Message(
            "Use macOS RakshakDaemon + PFManager (privileged helper)".into(),
        ))
    }

    fn disable_firewall(&self) -> Result<(), PlatformError> {
        Ok(())
    }

    fn install_service(&self) -> Result<(), PlatformError> {
        Err(PlatformError::Message("Use macos/scripts/install.sh".into()))
    }

    fn uninstall_service(&self) -> Result<(), PlatformError> {
        Ok(())
    }
}

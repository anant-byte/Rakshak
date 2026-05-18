mod service;

#[cfg(target_os = "macos")]
mod macos;
#[cfg(target_os = "windows")]
mod windows;

use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiscoveredDevice {
    pub ip_address: String,
    pub mac_address: String,
    pub hostname: String,
}

#[derive(Debug, Error)]
pub enum PlatformError {
    #[error("platform operation failed: {0}")]
    Message(String),
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),
}

/// Cross-platform privileged / OS-specific operations.
pub trait PlatformService: Send + Sync {
    /// Resolve primary LAN IPv4 address.
    fn local_lan_ip(&self) -> Result<String, PlatformError>;

    /// Scan ARP/neighbor table for LAN devices.
    fn get_arp_table(&self) -> Result<Vec<DiscoveredDevice>, PlatformError>;

    /// Start CoreDNS (or external supervisor) binding DNS port.
    fn bind_dns(&self, corefile: &std::path::Path) -> Result<(), PlatformError>;

    /// Stop DNS sinkhole process.
    fn stop_dns(&self) -> Result<(), PlatformError>;

    /// Apply force-DNS firewall rules (pf on macOS, netsh/WFP on Windows).
    fn apply_firewall(&self, lan_ip: &str) -> Result<(), PlatformError>;

    fn disable_firewall(&self) -> Result<(), PlatformError>;

    /// Install background service (launchd / Windows Service).
    fn install_service(&self) -> Result<(), PlatformError>;

    fn uninstall_service(&self) -> Result<(), PlatformError>;
}

/// Platform implementation for the current OS.
pub fn platform() -> Box<dyn PlatformService> {
    #[cfg(target_os = "windows")]
    {
        return Box::new(windows::WindowsPlatformService::new());
    }
    #[cfg(target_os = "macos")]
    {
        return Box::new(macos::MacOSPlatformService::new());
    }
    #[cfg(not(any(target_os = "windows", target_os = "macos")))]
    {
        Box::new(service::StubPlatformService)
    }
}

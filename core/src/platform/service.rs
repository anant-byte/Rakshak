use super::{DiscoveredDevice, PlatformError, PlatformService};
use std::path::Path;

/// Non-macOS/non-Windows stub (e.g. Linux CI).
pub struct StubPlatformService;

impl PlatformService for StubPlatformService {
    fn local_lan_ip(&self) -> Result<String, PlatformError> {
        Ok("127.0.0.1".into())
    }

    fn get_arp_table(&self) -> Result<Vec<DiscoveredDevice>, PlatformError> {
        Ok(vec![])
    }

    fn bind_dns(&self, _: &Path) -> Result<(), PlatformError> {
        Err(PlatformError::Message("DNS bind not supported on this platform".into()))
    }

    fn stop_dns(&self) -> Result<(), PlatformError> {
        Ok(())
    }

    fn apply_firewall(&self, _: &str) -> Result<(), PlatformError> {
        Ok(())
    }

    fn disable_firewall(&self) -> Result<(), PlatformError> {
        Ok(())
    }

    fn install_service(&self) -> Result<(), PlatformError> {
        Ok(())
    }

    fn uninstall_service(&self) -> Result<(), PlatformError> {
        Ok(())
    }
}

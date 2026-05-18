//! Shared cross-platform logic for RAKSHAK (Windows Tauri + future ports).

pub mod blocklist;
pub mod paths;
pub mod platform;

pub use blocklist::{merge_blocklists, parse_hosts_line, write_hosts_file, BlocklistError};
pub use paths::{
    allow_hosts_path, blocklists_dir, blocked_hosts_path, corefile_path, daemon_token_path,
    data_dir, database_path,
};
pub use platform::{DiscoveredDevice, PlatformError, PlatformService};

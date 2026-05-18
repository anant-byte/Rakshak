use std::path::PathBuf;

/// Per-user application data directory for RAKSHAK.
pub fn data_dir() -> PathBuf {
    dirs::data_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("Rakshak")
}

pub fn blocklists_dir() -> PathBuf {
    data_dir().join("Blocklists")
}

pub fn blocked_hosts_path() -> PathBuf {
    blocklists_dir().join("blocked.hosts")
}

pub fn allow_hosts_path() -> PathBuf {
    blocklists_dir().join("allow.hosts")
}

pub fn corefile_path() -> PathBuf {
    data_dir().join("Corefile")
}

pub fn daemon_token_path() -> PathBuf {
    data_dir().join("daemon.token")
}

pub fn database_path() -> PathBuf {
    data_dir().join("rakshak.db")
}

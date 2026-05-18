use rakshak_core::platform::{platform, DiscoveredDevice};
use rakshak_core::{blocked_hosts_path, data_dir, merge_blocklists, write_hosts_file};
use serde::Serialize;
use std::collections::BTreeSet;
use std::fs;
use std::sync::Mutex;

#[derive(Default)]
struct AppState {
    protection_enabled: bool,
    devices: Vec<DiscoveredDevice>,
    blocklist_domains: usize,
}

static STATE: Mutex<AppState> = Mutex::new(AppState {
    protection_enabled: false,
    devices: Vec::new(),
    blocklist_domains: 0,
});

#[derive(Serialize)]
struct Status {
    lan_ip: String,
    protection_enabled: bool,
    device_count: usize,
    blocklist_domains: usize,
}

#[tauri::command]
fn get_status() -> Result<Status, String> {
    let plat = platform();
    let lan_ip = plat.local_lan_ip().unwrap_or_default();
    let state = STATE.lock().map_err(|e| e.to_string())?;
    Ok(Status {
        lan_ip,
        protection_enabled: state.protection_enabled,
        device_count: state.devices.len(),
        blocklist_domains: state.blocklist_domains,
    })
}

#[tauri::command]
fn enable_protection() -> Result<(), String> {
    fs::create_dir_all(data_dir()).map_err(|e| e.to_string())?;
    let bl_dir = rakshak_core::paths::blocklists_dir();
    let files: Vec<_> = fs::read_dir(&bl_dir)
        .map_err(|e| e.to_string())?
        .filter_map(|e| e.ok())
        .map(|e| e.path())
        .filter(|p| p.extension().map(|x| x == "txt").unwrap_or(false))
        .collect();
    let domains = merge_blocklists(&files, &BTreeSet::new());
    let count = domains.len();
    write_hosts_file(&blocked_hosts_path(), &domains, "0.0.0.0").map_err(|e| e.to_string())?;
    let corefile = rakshak_core::paths::corefile_path();
    let corefile_content = format!(
        ". {{\n    bind 0.0.0.0\n    hosts {} {{\n        fallthrough\n        reload 5m\n    }}\n    cache 300\n    forward . 1.1.1.1 1.0.0.1\n    log\n    errors\n}}\n",
        blocked_hosts_path().display()
    );
    fs::write(&corefile, corefile_content).map_err(|e| e.to_string())?;
    platform()
        .bind_dns(&corefile)
        .map_err(|e| e.to_string())?;
    let mut state = STATE.lock().map_err(|e| e.to_string())?;
    state.protection_enabled = true;
    state.blocklist_domains = count;
    Ok(())
}

#[tauri::command]
fn disable_protection() -> Result<(), String> {
    platform().stop_dns().map_err(|e| e.to_string())?;
    let mut state = STATE.lock().map_err(|e| e.to_string())?;
    state.protection_enabled = false;
    Ok(())
}

#[tauri::command]
fn scan_devices() -> Result<usize, String> {
    let devices = platform().get_arp_table().map_err(|e| e.to_string())?;
    let n = devices.len();
    let mut state = STATE.lock().map_err(|e| e.to_string())?;
    state.devices = devices;
    Ok(n)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![
            get_status,
            enable_protection,
            disable_protection,
            scan_devices
        ])
        .run(tauri::generate_context!())
        .expect("error running tauri application");
}

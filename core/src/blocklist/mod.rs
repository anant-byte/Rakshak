use regex::Regex;
use std::collections::BTreeSet;
use std::fs;
use std::io::Write;
use std::path::Path;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum BlocklistError {
    #[error("io: {0}")]
    Io(#[from] std::io::Error),
    #[error("invalid domain line")]
    InvalidDomain,
}

fn domain_re() -> &'static Regex {
    static RE: std::sync::OnceLock<Regex> = std::sync::OnceLock::new();
    RE.get_or_init(|| {
        Regex::new(r"^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+$")
            .expect("domain regex")
    })
}

/// Parse a hosts-format or plain-domain line.
pub fn parse_hosts_line(line: &str) -> Option<String> {
    let trimmed = line.trim();
    if trimmed.is_empty() || trimmed.starts_with('#') {
        return None;
    }
    let parts: Vec<&str> = trimmed.split_whitespace().collect();
    let candidate = match parts.len() {
        0 => return None,
        1 => parts[0],
        _ if parts[0].chars().next().map(|c| c.is_ascii_digit()).unwrap_or(false) => parts[1],
        _ => parts[0],
    };
    let mut d = candidate.to_lowercase();
    if d.starts_with("*.") {
        d = d[2..].to_string();
    }
    if d.contains("://") || d.contains(' ') || d.len() > 253 {
        return None;
    }
    if domain_re().is_match(&d) {
        Some(d)
    } else {
        None
    }
}

/// Merge multiple blocklist files and subtract allowlist.
pub fn merge_blocklists(files: &[impl AsRef<Path>], allowlist: &BTreeSet<String>) -> Vec<String> {
    let mut all = BTreeSet::new();
    for f in files {
        let path = f.as_ref();
        if !path.exists() {
            continue;
        }
        if let Ok(text) = fs::read_to_string(path) {
            for line in text.lines() {
                if let Some(d) = parse_hosts_line(line) {
                    all.insert(d);
                }
            }
        }
    }
    for a in allowlist {
        all.remove(a);
    }
    all.into_iter().collect()
}

/// Write CoreDNS hosts plugin file.
pub fn write_hosts_file(path: &Path, domains: &[String], sinkhole: &str) -> Result<(), BlocklistError> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let tmp = path.with_extension("tmp");
    let mut f = fs::File::create(&tmp)?;
    writeln!(f, "# Rakshak generated")?;
    writeln!(f, "# domains: {}", domains.len())?;
    for d in domains {
        writeln!(f, "{} {}", sinkhole, d)?;
    }
    f.sync_all()?;
    fs::rename(tmp, path)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_hosts_line() {
        assert_eq!(
            parse_hosts_line("0.0.0.0 ads.example.com"),
            Some("ads.example.com".into())
        );
    }
}

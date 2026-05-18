# Rakshak Windows installer — run as Administrator
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$InstallDir = "${env:ProgramFiles}\Rakshak"
$DataDir = "$env:APPDATA\Rakshak"

Write-Host "==> Installing Rakshak to $InstallDir"

New-Item -ItemType Directory -Force -Path $InstallDir, "$DataDir\Blocklists", "$DataDir\Logs" | Out-Null

# CoreDNS — download or copy from PATH
if (-not (Get-Command coredns -ErrorAction SilentlyContinue)) {
    Write-Host "Install CoreDNS first: winget install coredns OR place coredns.exe in $InstallDir"
}

# Firewall: allow inbound DNS
netsh advfirewall firewall add rule name="Rakshak DNS UDP" dir=in action=allow protocol=UDP localport=53 2>$null
netsh advfirewall firewall add rule name="Rakshak DNS TCP" dir=in action=allow protocol=TCP localport=53 2>$null

Write-Host @"

NEXT STEPS:
1. Disable 'DNS Client' service if binding port 53 (see docs/windows-setup.md)
2. Set router DHCP DNS to this PC's LAN IP
3. Build the app: cd windows && npm install && npm run tauri build
4. Add Windows Defender exclusion for $InstallDir (optional)

"@

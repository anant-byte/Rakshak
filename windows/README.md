# Rakshak for Windows (Tauri)

Native Windows tray/desktop app using **Tauri 2** + **React** + shared **`rakshak-core`** Rust library.

## Develop

```bash
npm install
npm run tauri dev
```

## Build MSI/NSIS

```bash
npm run tauri build
```

Add `src-tauri/icons/icon.ico` before release (512×512 source PNG recommended).

## Architecture

- UI: `src/` (React)
- Backend: `src-tauri/` (Rust, Tauri commands)
- Shared logic: `../core` (blocklist, platform, paths)

See [docs/windows-setup.md](../docs/windows-setup.md).

# Tauri Native
Native macOS UI elements to apply to Tauri to make it look more native.

- Tauri Window as Native Popover (NSPopover)
- Tauri Window as Native Panel (NSPanel)
- Tauri Tray as Window Popover (NSPopover)
- Native Toast
- Native Tooltip
- Native Toast
- Trackpad Haptic Feedback

https://github.com/user-attachments/assets/31f5420c-5e23-4c48-a469-7adb53425049

## Building
#### Local:
- Install frontend packages:
```
bun install
```

- Start frontend server:
```
bun run --filter client dev
```

- Start Tauri dev server:
```
bun tauri:dev
```

#### Production Build:
```
bun tauri:build
```

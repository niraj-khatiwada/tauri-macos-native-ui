# Tauri Native
Native macOS UI elements to apply to Tauri to make it look more native.

- Tauri Window as Native Popover (NSPopover)
- Tauri Window as Native Panel (NSPanel)
- Tauri Tray as Window Popover (NSPopover)
- Native Toast
- Native Tooltip
- Native Toast
- Trackpad Haptic Feedback
- Apple Intelligence Glow effect using SwiftUI

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

Note: If you're using beta version of XCode, you need to run this command before you run/build your app:
```
sudo xcode-select -s /Applications/Xcode-beta.app/Contents/Developer
```

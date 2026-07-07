# AquaPaste

**Read this in other languages: [Tiếng Việt](README.vi.md)**

**Win + V for your Mac.** AquaPaste is a small, free macOS app that brings the familiar **Clipboard History** feature from Windows to macOS. Instead of only pasting the last thing you copied, you can browse and paste anything you copied earlier (both text and images).

Open the history panel with **`Option + V`**.

> Written by Vi Tiến Hoàng (hoang.com.vn) for personal use, then shared for free. Open source, use it however you like.

The interface is **English by default** and automatically switches to **Vietnamese** on systems set to Vietnamese.

## Features

- Tracks everything you copy: **text** and **images**.
- Open the history panel with `Option + V`, from any app.
- Keyboard navigation: `↑` `↓` to select, `Enter` to paste, `Esc` to close.
- Selecting an item **copies it back and auto-pastes** into the app you were working in (once you grant Accessibility permission).
- A layered **Liquid Glass** frosted interface that matches macOS design.
- A **menu bar** icon for quick open, clearing history, or quitting.
- **Persistent storage**: keeps the 50 most recent items, kept after you restart.
- Lightweight (~550 KB), runs in the background, collects no data, sends nothing over the network.

Requirements: **macOS 13 or later** (Ventura, Sonoma, Sequoia, Tahoe...), Apple Silicon supported.

## Install (ready-to-run build)

1. Download `AquaPaste.zip` from the [latest release](https://github.com/hoangvttyphu/aquapaste/releases/latest) and unzip it to get **`AquaPaste.app`**.
2. Drag `AquaPaste.app` into your **Applications** folder.
3. **First launch:** because the app is not signed with an Apple developer certificate, macOS will block it. **Right-click `AquaPaste.app` → choose `Open` → click `Open` again.** You only need to do this once.
   - If it still says "app is damaged / can't be opened", open **Terminal** and run:
     ```bash
     xattr -cr /Applications/AquaPaste.app
     ```
     then open the app again.
4. The app runs in the background and shows a clipboard icon in the **menu bar** (top-right of the screen). There is no main window.

## Grant permission for auto-paste

To let AquaPaste press `Cmd + V` for you after you pick an item, macOS needs Accessibility permission:

**System Settings → Privacy & Security → Accessibility → enable the toggle for AquaPaste.**

Without this permission the app still works: it copies the item you select to the clipboard, and you just press `Cmd + V` yourself.

## How to use

1. Copy things as usual (`Cmd + C`).
2. Press **`Option + V`** to open the history panel.
3. Use `↑` `↓` to select an item, press `Enter` (or click) to paste it back.
4. `Esc` closes the panel without pasting.

The menu bar also has: **Open AquaPaste**, **Clear History**, **Quit**.

## Where data is stored

History is saved at:

```
~/Library/Application Support/AquaPaste/clipboard-history.json
```

The app keeps up to **50 recent items**. When it exceeds 50, the oldest one is dropped and the file is rewritten atomically (safe, no junk files). All data stays on your machine and is never sent anywhere.

## Build from source (for developers)

Requires **Xcode Command Line Tools** and **Swift 6+**.

```bash
# run directly
swift run AquaPaste

# or package into a .app
chmod +x scripts/build-app.sh
./scripts/build-app.sh release
open dist/AquaPaste.app

# install into Applications
chmod +x scripts/install-app.sh
./scripts/install-app.sh
```

Main architecture:

- `ClipboardStore.swift` — watches the pasteboard, saves/loads history, atomic write.
- `ClipboardHistoryAppDelegate.swift` — app lifecycle, menu bar, hotkey and paste coordination.
- `GlobalHotKeyMonitor.swift` — registers the global `Option + V` hotkey via Carbon.
- `ClipboardPanelView.swift` + `LiquidGlassBackground.swift` — the frosted-glass UI and keyboard navigation.
- `PasteAutomation.swift` — auto-presses `Cmd + V` into the previous app via Accessibility.
- `Localization.swift` — runtime English/Vietnamese switch based on system language.

## License

MIT License — see [LICENSE](LICENSE). Use, modify, and share freely.

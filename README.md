# Spoonlift

A native macOS file manager heavily inspired by Forklift — dual-pane browsing, tabs, multiple view modes, Finder tags, Quick Look, drag-drop transfers with progress.

Local files and mounted volumes only. Remote protocols (SFTP, FTP, S3, WebDAV) are on the roadmap, not in this MVP.

> Spoonlift is an independent, open-source project. It is **not** affiliated with or derived from the source code of BinaryNights / Forklift. Functional inspiration only; code and visual identity are original.

## Status

MVP scaffold (v0.1).

## Requirements

- macOS 14 Sonoma or newer
- Xcode 15+
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

## Build & run

```bash
brew install xcodegen
xcodegen                     # generates Spoonlift.xcodeproj from project.yml
open Spoonlift.xcodeproj
```

Then hit `⌘R` in Xcode.

## Features

- Dual-pane workspace, add / close panes
- Per-pane tabs (`⌘T` new tab, `⌘W` close, `⇧⌘T` new pane)
- View modes: **List**, **Icons**, **Columns** (miller), **Brief**
- Sort by name / size / kind / modified / created, ascending or descending, directories-grouped-first
- Sidebar: Favorites · Locations · Devices (mounted volumes) · Tags
- Read & write Finder tags
- Drag-drop between panes (plain = copy, `⌘` = move) with progress window, conflict dialog, and undo
- `⌫` → move to Trash, `⌘Z` → undo
- Quick Look on `␣`, plus a toggleable inline preview pane per tab
- Window / pane / tab layout restored across launches
- Multiple windows (`⌘N`)

## License

MIT — see [LICENSE](LICENSE). This project is fully open source and freely reusable, including for commercial use, as long as the MIT notice is retained.

## Roadmap (post-MVP)

- SFTP / FTP / SMB / WebDAV / S3 remotes
- Archive browsing
- Folder sync & compare
- Preferences window
- Real app icon artwork
- App Sandbox + security-scoped bookmarks

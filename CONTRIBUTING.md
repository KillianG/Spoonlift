# Contributing to Spoonlift

Thanks for your interest! Spoonlift is a native macOS file manager built in SwiftUI. It's MIT licensed — freely reusable, modifiable, and redistributable.

## Requirements

- macOS 14 Sonoma or newer
- Xcode 15 or newer (includes Swift 5.9+)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- Optional for CLI release builds: just the tools above. No CocoaPods / SPM deps.

## Clone and run

```bash
git clone <your-fork-or-origin-url>
cd open-forklift         # directory name may be 'open-forklift' or 'spoonlift'
xcodegen                 # generates Spoonlift.xcodeproj from project.yml
open Spoonlift.xcodeproj
```

In Xcode, pick the **Spoonlift** scheme and hit **⌘R**.

The `.xcodeproj` is **not** checked in — regenerate with `xcodegen` whenever you pull changes that touch `project.yml` or add/remove source files.

## Project layout

```
Spoonlift/
├── SpoonliftApp.swift          # @main, WindowGroup, command shortcuts
├── Models/                     # FileItem, Favorite, FinderTag, SortOption, ViewMode, persistence
├── Services/                   # Filesystem, file ops, tags, pasteboard, compress, Quick Look
├── ViewModels/                 # AppModel / WindowModel / PaneModel / TabModel / TransferCoordinator
└── Views/                      # SwiftUI views (sidebar, workspace, panes, tabs, file views, sheets)
```

State shape:

```
AppModel
 └─ WindowModel (per window)
     ├─ panes: [PaneModel]
     │   └─ tabs: [TabModel]  (currentURL, items, selection, sort, viewMode, …)
     └─ transfers: TransferCoordinator
```

Persistence lives in `UserDefaults` via `SessionStore` (windows / panes / tabs layout) and `FavoritesStore` (sidebar favorites).

## Adding a feature

1. Create a branch off `main`.
2. Keep changes focused — one feature per PR.
3. If you add new `.swift` files, nothing extra needed — `xcodegen` picks them up automatically on the next run (CI runs it too).
4. If you add a new service or protocol, document it with a short header comment.
5. Run the app locally and exercise the feature in each view mode (List, Icons, Columns, Brief) and across both panes.
6. Open a PR. CI (`.github/workflows/ci.yml`) will do a Debug build on `macos-14`.

## Coding style

- Swift 5.9, SwiftUI first. Drop to AppKit (`NSViewRepresentable`) only when SwiftUI falls short (e.g. `QLPreviewView`).
- All view models are `@MainActor final class … : ObservableObject`.
- File operations run off the main thread — `FileOperationService.run(...)` returns an `AsyncStream`.
- Finder tag writes must use `(url as NSURL).setResourceValue(tags as NSArray, forKey: .tagNamesKey)` — `URLResourceValues.tagNames` setter is gated to a future macOS.
- Every source file begins with `// SPDX-License-Identifier: MIT`.

## Cutting a release

Releases are fully automated via GitHub Actions.

1. Bump the version in `project.yml` → `settings.base.MARKETING_VERSION` and commit to `main`.
2. Tag:
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```
3. `.github/workflows/release.yml` runs on `macos-14`, regenerates the project, builds `Release`, packages a `.dmg`, and publishes a GitHub Release with the `.dmg` attached.

To build a `.dmg` locally:

```bash
scripts/build-release.sh 0.1.0
# output: build/Spoonlift-0.1.0.dmg
```

Releases are currently **unsigned**, so users see a one-time *"unidentified developer"* Gatekeeper prompt on first launch (right-click → Open bypasses it). Code signing + notarization with an Apple Developer ID is on the roadmap but not wired up.

### Optional: signed releases

If you fork this project and have access to an Apple Developer ID Application certificate, `scripts/build-release.sh` already supports signing + notarization — it flips on automatically when the right env vars are set. To enable it in CI, add an Import-cert step to `.github/workflows/release.yml` and set these 5 repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
|--------|-------|
| `APPLE_CERT_P12_BASE64` | Your **Developer ID Application** certificate + private key, exported as a `.p12` from Keychain Access, then base64-encoded: `base64 -i DeveloperID.p12 \| pbcopy` |
| `APPLE_CERT_PASSWORD`   | The password you set when exporting the `.p12` |
| `APPLE_ID`              | Apple ID email attached to your developer account |
| `APPLE_TEAM_ID`         | 10-character Team ID from [developer.apple.com](https://developer.apple.com/account) → Membership |
| `APPLE_APP_PASSWORD`    | App-specific password created at [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords |

Exporting the `.p12` from Keychain Access:
1. Keychain Access → **login** keychain → **My Certificates**.
2. Find **Developer ID Application: *Your Name* (TEAMID)**.
3. Right-click → **Export…** → Format: **Personal Information Exchange (.p12)**.
4. Set a password (this is `APPLE_CERT_PASSWORD`). Save as `DeveloperID.p12`.
5. `base64 -i DeveloperID.p12 | pbcopy` → paste into `APPLE_CERT_P12_BASE64`.
6. Delete the local `.p12` when done.

## License

By contributing, you agree your contributions are licensed under the [MIT License](LICENSE).

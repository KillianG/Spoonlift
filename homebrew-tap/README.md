# homebrew-tap

Homebrew tap for [Spoonlift](https://github.com/KillianG/Spoonlift), a native macOS file manager heavily inspired by Forklift.

## Install

```bash
brew tap KillianG/tap
brew install --cask spoonlift
```

Or in one line without the tap step:

```bash
brew install --cask KillianG/tap/spoonlift
```

Homebrew clears the Gatekeeper quarantine flag for you, so Spoonlift launches cleanly on first double-click — no `xattr` dance required.

## Upgrade

```bash
brew upgrade --cask spoonlift
```

## Uninstall

```bash
brew uninstall --cask spoonlift
brew untap KillianG/tap     # optional
```

## Contents

- [`Casks/spoonlift.rb`](Casks/spoonlift.rb) — cask definition

The cask is mirrored from [`KillianG/Spoonlift`](https://github.com/KillianG/Spoonlift). Bug reports and feature requests belong on the main project's issue tracker.

## License

MIT (same as the main project).

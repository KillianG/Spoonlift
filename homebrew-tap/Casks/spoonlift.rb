cask "spoonlift" do
  version "0.0.6"
  sha256 "75c183fd1a6b8e75bc4b30a3fd61eee2d46227886178b1df3b4d10365f05e19f"

  url "https://github.com/KillianG/Spoonlift/releases/download/v#{version}/Spoonlift-#{version}.dmg",
      verified: "github.com/KillianG/Spoonlift/"
  name "Spoonlift"
  desc "Dual-pane file manager inspired by Forklift"
  homepage "https://github.com/KillianG/Spoonlift"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "Spoonlift.app"

  # Spoonlift is ad-hoc signed rather than signed with an Apple Developer ID,
  # so Homebrew's default quarantine-strip is not always enough on recent
  # macOS — Gatekeeper will still refuse to launch the app. Force-clear every
  # extended attribute after install so the first double-click just works.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Spoonlift.app"],
                   sudo: false
  end

  uninstall quit: "com.spoonlift.Spoonlift"

  zap trash: [
    "~/Library/Application Support/Spoonlift",
    "~/Library/Caches/com.spoonlift.Spoonlift",
    "~/Library/Preferences/com.spoonlift.Spoonlift.plist",
    "~/Library/Saved Application State/com.spoonlift.Spoonlift.savedState",
  ]
end

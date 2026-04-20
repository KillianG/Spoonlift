cask "spoonlift" do
  version "0.0.5"
  sha256 "REPLACE_WITH_DMG_SHA256"

  url "https://github.com/KillianG/open-forklift/releases/download/v#{version}/Spoonlift-#{version}.dmg",
      verified: "github.com/KillianG/open-forklift/"
  name "Spoonlift"
  desc "Dual-pane file manager inspired by Forklift"
  homepage "https://github.com/KillianG/open-forklift"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "Spoonlift.app"

  zap trash: [
    "~/Library/Preferences/com.spoonlift.Spoonlift.plist",
    "~/Library/Saved Application State/com.spoonlift.Spoonlift.savedState",
  ]
end

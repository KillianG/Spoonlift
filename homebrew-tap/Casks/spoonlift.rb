cask "spoonlift" do
  version "0.0.5"
  sha256 "53625ed12db7bdc8876468b1feb9d271dfc87bdea9d2692c15b73d9c6e5caaa3"

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

  zap trash: [
    "~/Library/Preferences/com.spoonlift.Spoonlift.plist",
    "~/Library/Saved Application State/com.spoonlift.Spoonlift.savedState",
  ]
end

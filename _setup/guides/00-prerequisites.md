# 00 — Prerequisites

Install everything you need before touching Xcode or the App Store. Most of these are one-time setup steps.

---

## macOS

You need **macOS Sonoma (14) or later**. Xcode 16 requires it.

```bash
sw_vers -productVersion  # verify
```

---

## Xcode

### Option A — xcodes (Recommended)

`xcodes` is a CLI tool that manages multiple Xcode versions with faster downloads (uses `aria2` for parallel chunks).

```bash
brew install xcodesorg/made/xcodes
brew install aria2  # faster downloads

xcodes install --latest
xcodes select 16.0  # or whatever version you installed
xcode-select -p     # verify: should show path inside Xcode.app
```

### Option B — Mac App Store

Search "Xcode" in the Mac App Store. This works but updates are slower to arrive.

### After Installing

Accept the Xcode license and install additional components:

```bash
sudo xcodebuild -license accept
xcode-select --install  # command line tools
sudo xcodebuild -runFirstLaunch
```

---

## Homebrew

The missing package manager for macOS. Install it if you don't have it:

```bash
/bin/bash -c "$(curl -fsSL https://brew.sh/install.sh)"

# Verify
brew --version
```

---

## XcodeGen

Generates `.xcodeproj` from a YAML definition. This template uses it so you never commit generated project files.

```bash
brew install xcodegen
xcodegen --version  # verify
```

---

## SwiftFormat

Automatically formats your Swift code to a consistent style.

```bash
brew install swiftformat
swiftformat --version  # verify
```

The template includes a `.swiftformat` config. Run it before committing:

```bash
swiftformat App/Sources
```

---

## SwiftLint

Static analyzer that catches common Swift mistakes and style issues.

```bash
brew install swiftlint
swiftlint --version  # verify
```

The template includes a `.swiftlint.yml` config. Check your code:

```bash
swiftlint App/Sources
```

---

## ImageMagick

Generates and manipulates images — used for creating App Store screenshots and resizing app icons.

```bash
brew install imagemagick
convert --version  # verify
```

---

## Ruby {#ruby}

fastlane is a Ruby gem. Use `rbenv` to manage Ruby versions (avoid the system Ruby):

```bash
brew install rbenv ruby-build

# Add to ~/.zshrc or ~/.bash_profile:
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc

# Install and set Ruby version
rbenv install 3.3.0
rbenv global 3.3.0
ruby --version  # should show 3.3.x
```

---

## Bundler + fastlane

`Bundler` pins gem versions via a `Gemfile`. `fastlane` automates signing, testing, and App Store submissions.

```bash
gem install bundler
gem install fastlane

fastlane --version  # verify
```

Then in your project root:

```bash
bundle install  # installs gems from Gemfile.lock
```

---

## Git Configuration

Make sure git knows who you are:

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global init.defaultBranch main
```

Add your SSH key to GitHub if you haven't:

```bash
ssh-keygen -t ed25519 -C "your@email.com"
cat ~/.ssh/id_ed25519.pub  # paste this into GitHub → Settings → SSH keys
ssh -T git@github.com     # verify: "Hi username! You've successfully authenticated"
```

---

## Optional Tools

### Proxyman / Charles Proxy
Inspect network traffic from the simulator. Useful for debugging API calls.

```bash
brew install --cask proxyman
```

### Instruments (included with Xcode)
Performance profiling. Launch from Xcode → Product → Profile (⌘I).

### Simulator Buddy
Manage simulators from the menu bar.

```bash
brew install --cask simulator
```

### AppShelf / Brewer
Track installed tools. Not required.

---

## Verify Everything

Run this to check all required tools at once:

```bash
echo "=== Xcode ===" && xcode-select -p
echo "=== Simulator ===" && xcrun simctl list devices available | grep "iPhone 1" | head -3
echo "=== XcodeGen ===" && xcodegen --version
echo "=== SwiftFormat ===" && swiftformat --version
echo "=== SwiftLint ===" && swiftlint --version
echo "=== ImageMagick ===" && convert --version | head -1
echo "=== Ruby ===" && ruby --version
echo "=== Bundler ===" && bundle --version
echo "=== fastlane ===" && fastlane --version
echo "=== Git ===" && git --version
```

All commands should print version numbers without errors before moving on.

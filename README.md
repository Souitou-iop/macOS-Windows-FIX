<p align="center">
  <img src="macOS-Windows-FIX%20Exports/macOS-Windows-FIX.icon/Assets/icon%E5%BE%85%E5%AE%9A.png" width="160" alt="MacFocusFix icon">
</p>

<h1 align="center">MacFocusFix</h1>

<p align="center">
  A lightweight macOS menu bar app that keeps remote-control clicks from leaving keyboard focus behind.
</p>

<p align="center">
  <strong>English</strong> | <a href="docs/README.zh-CN.md">简体中文</a>
</p>

<p align="center">
  <a href="https://github.com/Souitou-iop/macOS-Windows-FIX/releases">Download</a> ·
  <a href="https://github.com/Souitou-iop/macOS-Windows-FIX/actions/workflows/release.yml">Builds</a> ·
  <a href="https://github.com/Souitou-iop/macOS-Windows-FIX/issues">Feedback</a>
</p>

## Why I Built This

After updating to macOS 27, I started seeing a strange remote-control focus bug with tools such as UU Remote. A remote click could still reach the right window control, so buttons and fields looked like they were being clicked. But macOS did not always switch the real foreground app: the app name next to the Apple menu stayed on the previous app, and keyboard input kept going there.

The clearest workaround was to click the target window's title bar first. That forced macOS to activate the window, but it broke the natural remote-control flow: every time I wanted to type into another app, I had to remember to click the frame instead of the content.

The first round of debugging pointed away from a normal app setting issue. Accessibility permissions, UI restarts, and remote-control settings were useful things to check, but the symptom looked deeper: the mouse event arrived, while the WindowServer / Accessibility foreground-app activation step did not. Apple's own remote-control stack also appeared to be changing around newer macOS input and Accessibility behavior, which made this feel like a third-party remote-input compatibility gap rather than a single text-field bug.

MacFocusFix is the small local workaround that came out of that investigation. It does not replace the remote-control app. It simply runs on the Mac being controlled, listens for mouse clicks, finds the app under the pointer, and explicitly activates it so keyboard focus follows the click again.

## Features

- Menu bar only: no Dock icon.
- Enable or disable the focus fix from the menu bar.
- Optional fallback mode that sends one local click after activation.
- Ignores the macOS menu bar and known system UI processes, so Control Center, Wi-Fi, and input method controls keep working normally.
- Uses the bundled app icon from the Icon Composer export and a separate template-style menu bar icon.

## Installation

1. Download the latest zip from [Releases](https://github.com/Souitou-iop/macOS-Windows-FIX/releases).
2. Unzip it.
3. Move `MacFocusFix.app` to `/Applications`.
4. Launch the app.
5. Grant Accessibility permission in System Settings when macOS asks for it.

If macOS blocks the app because it is not notarized, open it from Finder with Control-click, choose Open, then confirm. Current builds are ad hoc signed, not Developer ID notarized.

## Menu Bar

- Status: shows whether the helper is on, off, or waiting for Accessibility permission.
- Enable / Disable Focus Fix: installs or removes the mouse event listener.
- Reclick After Activation: fallback for apps that activate but still do not accept typing.
- Open Accessibility Settings
- Quit MacFocusFix

## Build Locally

```zsh
./script/build_app.sh
./script/build_and_run.sh
```

`build_app.sh` creates `dist/MacFocusFix.app` and signs it ad hoc for local use.
`build_and_run.sh` builds the app and opens it.

## Releases

GitHub Actions builds release artifacts on macOS. Pushing a tag such as `v0.1.0` creates a zipped `.app` bundle and publishes it as a GitHub Release asset.

## Uninstall

Quit MacFocusFix, then move `MacFocusFix.app` to the Trash. If you granted Accessibility permission, you can also remove it from System Settings.

## Compatibility

MacFocusFix is built with SwiftPM and targets macOS 14 or later.

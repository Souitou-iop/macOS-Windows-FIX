# macOS 27 Remote Focus Fix

## Plan

- [x] Create a minimal SwiftPM macOS helper.
  - Verify: `swift build` succeeds.
- [x] Listen for global mouse-down events and activate the app/window under the pointer.
  - Verify: helper starts and stays running, including while waiting for Accessibility permission.
- [x] Add a project-local build/run script and Codex Run action.
  - Verify: `./script/build_and_run.sh --verify` succeeds.
- [x] Document manual authorization and remote-control validation steps.
  - Verify: steps are concrete and reversible.

## Review

- Built a SwiftPM helper that listens for mouse-down events, finds the Accessibility element under the pointer, focuses its window, and activates the owning app.
- Added default gating so it only acts while UU Remote is running; `--always` and `--reclick` are available for testing/fallback.
- Verified `swift build` and `./script/build_and_run.sh --verify`.
- Manual validation still required through an actual UU Remote session on macOS 27.

## Menu Bar App Plan

- [x] Add a menu bar controller without showing a Dock icon.
  - Verify: app launches as `LSUIElement` and exposes an `NSStatusItem`.
- [x] Add menu actions for enable/disable and quit.
  - Verify: menu actions update the event tap state.
- [x] Keep the existing focus workaround behavior as the default.
  - Verify: `swift build` and `./script/build_and_run.sh --verify` pass.
- [x] Update README and provide an external icon-generation prompt.
  - Verify: docs describe the menu and reversible stop path.

## Menu Bar App Review

- Added an AppKit menu bar controller with status, enable/disable, fallback reclick, Accessibility settings, and quit actions.
- Kept `LSUIElement=true` so the app stays out of the Dock.
- Verified the app builds and launches as a status item.

## Icon And Menu Interaction Plan

- [x] Use the provided Icon Composer export as the App icon source.
  - Verify: generated bundle contains `Contents/Resources/AppIcon.icns` and `CFBundleIconFile=AppIcon`.
- [x] Keep the menu bar icon readable when disabled.
  - Verify: disabled/waiting state uses system gray tint instead of black.
- [x] Prevent menu bar clicks from triggering focus activation.
  - Verify: menu open/close suppresses the event tap briefly.

## System Menu Bar Safety Fix Plan

- [x] Ignore clicks in the screen menu bar area.
  - Verify: focus workaround does not run for Control Center, Wi-Fi, or input method menu bar clicks.
- [x] Render active and inactive menu bar icons with explicit state colors.
  - Verify: enabled icon is white in dark mode / black in light mode, disabled icon is gray.
- [x] Rebuild the app bundle.
  - Verify: `./script/build_and_run.sh --verify` and codesign verification succeed.

## System Menu Bar Safety Fix Review

- Added a top menu-bar-area guard so Control Center, Wi-Fi, and input method clicks are ignored by the focus workaround.
- Added system UI process filtering for `SystemUIServer`, `ControlCenter`, and `TextInputMenuAgent`.
- Replaced template tinting with explicit active/inactive icon rendering: active follows light/dark mode foreground, inactive is gray.
- Verified `./script/build_and_run.sh --verify` and `codesign --verify --deep --strict --verbose=2 dist/MacFocusFix.app`.

## GitHub Packaging And Release Plan

- [ ] Split app packaging into a reusable build script.
  - Verify: local script produces `dist/MacFocusFix.app` and a zip artifact without launching the app.
- [ ] Rewrite README as bilingual project documentation inspired by Mac Mouse Fix.
  - Verify: README covers purpose, install, permissions, menu, build, releases, limitations, and uninstall in Chinese and English.
- [ ] Add GitHub Actions release workflow.
  - Verify: workflow builds on macOS, uploads artifacts, and creates a GitHub Release on version tags.
- [ ] Create the GitHub repository and push the project.
  - Verify: remote exists, branch is pushed, and workflow file is present on GitHub.

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

- [x] Split app packaging into a reusable build script.
  - Verify: local script produces `dist/MacFocusFix.app` and a zip artifact without launching the app.
- [x] Rewrite README as bilingual project documentation inspired by Mac Mouse Fix.
  - Verify: README covers purpose, install, permissions, menu, build, releases, limitations, and uninstall in Chinese and English.
- [x] Add GitHub Actions release workflow.
  - Verify: workflow builds on macOS, uploads artifacts, and creates a GitHub Release on version tags.
- [x] Create the GitHub repository and push the project.
  - Verify: remote exists, branch is pushed, and workflow file is present on GitHub.

## GitHub Packaging And Release Review

- Added `script/build_app.sh` so local builds and GitHub Actions share one app packaging path.
- Rewrote `README.md` as bilingual Chinese/English documentation with download, install, permission, menu, build, release, uninstall, and limitation sections.
- Added `.github/workflows/release.yml`; tag pushes matching `v*` build a zipped app and publish a GitHub Release.
- Verified local packaging with `./script/build_app.sh`, `ditto` zip creation, and `unzip -tq`.
- Created public repository `Souitou-iop/macOS-Windows-FIX`, pushed `main`, pushed tag `v0.1.0`, and verified release asset `MacFocusFix-0.1.0-macOS.zip`.

## README Language Switch And Icon Polish Plan

- [x] Split README languages instead of stacking both languages in one page.
  - Verify: root `README.md` is English by default and links to `docs/README.zh-CN.md`.
- [x] Add the app icon to both README files.
  - Verify: README image points at the 1024x1024 Icon Composer export under `macOS-Windows-FIX Exports`.
- [x] Rebuild the app bundle and verify the packaged icon.
  - Verify: `dist/MacFocusFix.app/Contents/Resources/AppIcon.icns` exists and codesign verification succeeds.

## README Language Switch And Icon Polish Review

- Changed the root README to English-only by default with a language switch to `docs/README.zh-CN.md`.
- Added the app icon to both README files using the 1024x1024 Icon Composer export from `macOS-Windows-FIX Exports`.
- Confirmed `script/build_app.sh` already packages the same icon source into `dist/MacFocusFix.app/Contents/Resources/AppIcon.icns`.
- Verified `./script/build_app.sh`, `file dist/MacFocusFix.app/Contents/Resources/AppIcon.icns`, and `codesign --verify --deep --strict --verbose=2 dist/MacFocusFix.app`.

## App Localization Plan

- [x] Replace user-visible strings in the app with localization keys.
  - Verify: `main.swift` menu, tooltip, permission, status, and help text use localized lookups.
- [x] Add English and Simplified Chinese string resources.
  - Verify: `en.lproj/Localizable.strings` and `zh-Hans.lproj/Localizable.strings` are packaged into the app resource bundle.
- [x] Build and verify packaged localization resources.
  - Verify: `./script/build_app.sh` succeeds and the app bundle contains both localization directories.

## App Localization Review

- Added a small `L10n` helper that picks the first supported preferred language from system language order: English, Simplified Chinese, then English fallback.
- Localized menu bar tooltip, menu items, status text, permission console messages, errors, and CLI help.
- Added `en.lproj/Localizable.strings` and `zh-Hans.lproj/Localizable.strings` under SwiftPM resources.
- Verified `swift build`, `.strings` linting, English and Chinese help-text probes via `AppleLanguages`, `./script/build_app.sh`, packaged resource paths, and codesign verification.

## Dock Click Safety Fix Plan

- [x] Ignore Dock-owned click targets before scheduling delayed focus activation.
  - Verify: clicks on Dock icons do not enqueue the focus workaround.
- [x] Keep delayed activation guarded against Dock and other system UI processes.
  - Verify: `com.apple.dock` is included in system UI filtering.
- [x] Build and package the app.
  - Verify: `swift build` and `./script/build_app.sh` succeed.

## Dock Click Safety Fix Review

- Confirmed Dock's bundle identifier is `com.apple.dock`.
- Added an early system UI target check before delayed focus activation is scheduled, so Dock clicks are ignored immediately.
- Kept the delayed activation path guarded against Dock and the existing system UI processes.
- Verified `swift build`, `.strings` linting, `./script/build_app.sh`, and `./script/build_and_run.sh --verify`.

## Public Signing And Notarization Plan

- [x] Make app packaging support a stable Developer ID signing identity while keeping ad-hoc signing for local development.
  - Verify: local `./script/build_app.sh` still works with ad-hoc signing.
- [x] Add a notarization script for release builds.
  - Verify: the script has explicit Apple credential checks and staples the app after notarization.
- [x] Update GitHub Actions release workflow to import a Developer ID certificate, sign, notarize, staple, and then zip.
  - Verify: workflow YAML parses and release builds fail early if signing secrets are absent.
- [x] Document why official releases should be Developer ID signed and notarized.
  - Verify: README explains that ad-hoc builds can require re-authorizing Accessibility, while signed releases should preserve identity across updates.

## Public Signing And Notarization Review

- Updated `script/build_app.sh` to support `SIGN_IDENTITY`; it keeps ad-hoc signing by default and enables hardened runtime plus timestamp for real signing identities.
- Added `CFBundleShortVersionString` and `CFBundleVersion` to the generated `Info.plist`.
- Added `script/notarize_app.sh` to submit the signed app to Apple notarization, staple the result, validate the staple, and run Gatekeeper assessment.
- Updated `.github/workflows/release.yml` so tag releases require Developer ID and Apple notarization secrets, import the `.p12` certificate, sign, notarize, staple, zip, and publish.
- Updated English and Chinese READMEs to explain stable Developer ID signing, notarization, and why ad-hoc builds can require Accessibility re-authorization.
- Verified local ad-hoc fallback with `./script/build_app.sh`, script syntax checks, workflow YAML parsing, generated Info.plist fields, and codesign inspection.

## Reclick Fallback Removal Plan

- [x] Remove the reclick fallback from app behavior.
  - Verify: `main.swift` no longer posts synthetic local clicks after activation.
- [x] Remove reclick controls from the menu, CLI, script, localized strings, and README files.
  - Verify: no active source or user-facing documentation mentions `--reclick` or the reclick fallback.
- [x] Build and run the app.
  - Verify: `swift build`, `.strings` linting, and `./script/build_and_run.sh --verify` succeed.

## Reclick Fallback Removal Review

- Removed the synthetic post-activation click path because it can interfere with window dragging and other pointer gestures.
- Removed the menu item, CLI option, build/run script mode, localization keys, and README mentions for the fallback.
- Verified `swift build`, `plutil -lint`, English and Chinese `--help`, `./script/build_and_run.sh --verify`, and searched active source/docs for reclick leftovers.

## Ad Hoc Release Workflow Plan

- [x] Let tag releases continue when Developer ID secrets are missing.
  - Verify: workflow resolves an ad hoc signing mode instead of failing at secret validation.
- [x] Keep Developer ID signing and notarization when all secrets are configured.
  - Verify: certificate import and notarization still run only for complete signing credentials.
- [x] Validate workflow syntax locally.
  - Verify: workflow YAML parses after the edit.

## Ad Hoc Release Workflow Review

- Changed the release workflow to resolve Developer ID availability instead of failing immediately when signing secrets are missing.
- Tag releases now build with ad hoc signing and still publish a Release zip when Developer ID secrets are absent.
- Developer ID certificate import and notarization still run only when all signing and Apple notarization secrets are present.
- Verified workflow YAML parsing with Ruby and checked the diff for whitespace errors.

## Split Architecture Build, System UI Filters, And Login Item Plan

- [x] Build release app bundles as separate arm64 and x86_64 binaries.
  - Verify: packaged app executable reports one requested architecture.
- [x] Extend system UI filtering for Notification Center, Spotlight, Siri, and Screenshot.
  - Verify: bundle identifiers are included in the ignored system UI set.
- [x] Add a menu bar Launch at Login toggle.
  - Verify: app builds with ServiceManagement and localized menu strings are valid.

## Split Architecture Build, System UI Filters, And Login Item Review

- Release app packaging now builds arm64 and x86_64 binaries as separate packages instead of merging them with `lipo`.
- Added ignored system UI bundle identifiers for Notification Center, Spotlight, Siri, and Screenshot, while keeping the existing menu bar, Control Center, Dock, and input menu filters.
- Added a localized Launch at Login menu item using `SMAppService.mainApp`.
- Verified `plutil -lint`, `swift build`, `APP_ARCH=arm64 CONFIGURATION=release ./script/build_app.sh`, `APP_ARCH=x86_64 CONFIGURATION=release ./script/build_app.sh`, `lipo -info`, `codesign --verify --deep --strict`, packaged resources, and `./script/build_and_run.sh --verify`.

## SwiftPM Resource Bundle Packaging Fix Plan

- [x] Replace direct `Bundle.module` usage with app-bundle-aware resource lookup.
  - Verify: resources are loaded from `Contents/Resources/MacFocusFix_MacFocusFix.bundle`.
- [x] Keep the app bundle in standard macOS layout.
  - Verify: codesign verification succeeds with the resource bundle under `Contents/Resources`.
- [x] Verify the zipped Release-style app can actually start.
  - Verify: unzip the archive and launch the `.app` without the SwiftPM resource bundle fatal error.

## SwiftPM Resource Bundle Packaging Fix Review

- Replaced `Bundle.module` calls with an app-bundle-aware resource lookup that finds `MacFocusFix_MacFocusFix.bundle` under `Contents/Resources`.
- Kept the bundle in the standard macOS app resource location so codesign verification succeeds.
- Verified `swift build`, `./script/build_app.sh`, arm64 release packaging, zip/unzip, and launching the unzipped `.app`.

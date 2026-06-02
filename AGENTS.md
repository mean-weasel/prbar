# Agent Instructions

- Before asking the user to visually verify an iOS app state on a simulator or
  physical device, first attempt visual inspection yourself with the available
  automation path: XcodeBuildMCP simulator snapshots, Xcode/devicectl device
  tooling, libimobiledevice/pymobiledevice screenshots, or GitHub workflow
  screenshot artifacts.
- If visual inspection is blocked, report the exact tools attempted and the
  blocker before asking the user to verify manually.
- Do not treat a successful build, install, launch, or smoke workflow as proof
  that the rendered UI is correct. Verify the actual screen when possible.
- For installed iOS app configuration, do not assume GitHub Actions environment
  variables exist at runtime. Verify config propagation into the built app, such
  as by inspecting the generated Info.plist when plist-backed settings are used.

# T008 Production Device Attempt - 2026-06-04

## Result

Partial progress; production-device proof is still blocked by device availability.

## Proven

- PR #132 merged through the merge queue.
- Merge commit: `4abf45f1d6161f35b15f8f32e20dc6afbb648c5f`.
- Post-merge main checks passed:
  - CI: https://github.com/mean-weasel/prbar/actions/runs/26931137245
  - iOS: https://github.com/mean-weasel/prbar/actions/runs/26931137266
  - Release: https://github.com/mean-weasel/prbar/actions/runs/26931137249

## Attempted

- Dispatched iOS Production Install on `main` for `device_name=iPhone-prod`.
- Run: https://github.com/mean-weasel/prbar/actions/runs/26931558037

## Blocker

The production install workflow failed in `Runner preflight`, before build/install, because `iPhone-prod` was not available as an Xcode iOS destination.

Evidence from workflow and local probes:

- CoreDevice sees `iPhone-prod` as paired but unavailable.
- `connectionProperties.tunnelState` is `unavailable`.
- `deviceProperties.ddiServicesAvailable` is `false`.
- `deviceProperties.developerModeStatus` is `enabled`.
- `xcodebuild -showdestinations` lists `iPhone-preview`, but not `iPhone-prod`.
- `xctrace` lists `iPhone-prod` under offline devices.

This is a runner/device availability blocker, not evidence of an app failure.

## Required Next Step

Bring `iPhone-prod` online and visible as an Xcode iOS destination, then rerun:

1. `ios-production-install.yml` with `device_name=iPhone-prod`.
2. If install passes, `ios-physical-production.yml` with `smoke_profile=growth`, `device_name=iPhone-prod`, and `live_repository=mean-weasel/prbar`.

The goal must remain active until production install and physical Growth smoke pass, or until the strict blocked audit threshold is satisfied.

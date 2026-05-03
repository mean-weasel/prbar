# Iteration 5

## Summary

Improved refresh behavior:

- Added `AutoRefreshInterval` and `RefreshPolicy`.
- Persisted refresh interval in settings with backwards-compatible decoding.
- Added Manual/Daily refresh picker.
- Changed the Refresh button to reload through the activity provider.
- Added refresh policy tests.

## Verification

`make ci-local` passed.

Repair:

- Fixed a SwiftUI composition error by wrapping sibling controls in `VStack`.

## Judge Decision

Continue for one more requested loop. The remaining high-confidence UX edge case is the all-repositories-excluded state.


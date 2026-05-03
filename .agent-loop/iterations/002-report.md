# Iteration 2

## Summary

Persisted user choices:

- Added `PRSettingsSnapshot` and `PRSettingsStore`.
- Saved selected time window and included repository IDs to `UserDefaults`.
- Loaded saved settings during app startup.
- Added tests for applying snapshots and save/load/reset behavior.

## Verification

`make ci-local` passed.

Repairs:

- Ran `swift-format` after strict formatting failures.
- Corrected a manual expected total from `396` to `343`.

## Judge Decision

Continue. The highest-value remaining product issue is chart inspectability: users can see stacked activity, but cannot inspect a bucket-level repo breakdown.


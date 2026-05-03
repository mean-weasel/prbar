# Iteration 011 Report

## Selected Task

T-012: Add settings reconciliation for discovered and removed repositories.

## Changes

- Added `knownRepositoryIDs` to `PRSettingsSnapshot`.
- Kept decoding backward-compatible by defaulting old snapshots to their included IDs.
- Updated settings application so known excluded repos stay excluded while new repos keep provider defaults.
- Added focused store coverage for newly discovered repository behavior.

## Verification

- `make ci-local` passed.

## Judge

Continue. Repository filtering is now resilient to discovery changes; scheduled refresh is the next clear gap.

# Iteration 027 Report

## Selected Task
Add visible data-source status for sample vs GitHub mode.

## Changes
- Added `PRActivityDataSource` and provider selection metadata.
- Updated provider factory tests to assert selected data source.
- Displayed the current data source in the popover header.

## Verification
- `make ci-local` passed.

## Judge
Continue. The app now tells users whether data is sample-backed or GitHub-backed; next useful work is tightening startup to reuse one provider selection consistently.

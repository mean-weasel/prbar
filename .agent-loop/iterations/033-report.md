# Iteration 033 Report

## Selected Task
Show next scheduled refresh time in the footer.

## Changes
- Added `RefreshPolicy.nextRefreshDate`.
- Displayed the next refresh time, or manual-only state, in the popover footer.
- Added focused refresh policy tests.

## Verification
- `make ci-local` passed.

## Judge
Continue. Scheduled refresh timing is visible; next useful polish is preventing repeated refresh taps while a refresh is in progress.

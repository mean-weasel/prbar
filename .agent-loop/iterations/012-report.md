# Iteration 012 Report

## Selected Task

T-013: Wire scheduled refresh into menu bar app lifecycle.

## Changes

- Added `PRActivityRefresher` to centralize manual and scheduled refresh behavior.
- Wired manual refresh through the refresher.
- Added popover appear and timer checks that refresh only when `RefreshPolicy` says due.
- Added unit tests for preserving settings and no-op behavior before a refresh is due.

## Verification

- `make ci-local` passed.

## Judge

Continue. Scheduled refresh now has a lifecycle hook; provider failures still need user-visible state.

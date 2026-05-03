# Iteration 032 Report

## Selected Task
Show rate-limit reset time in refresh errors.

## Changes
- Added `RefreshFailureMessage` formatting for manual and scheduled refresh failures.
- Included GitHub rate-limit reset time when transport errors carry it.
- Wired app refresh catch blocks through the formatter.

## Verification
- Initial `make ci-local` failed on SwiftFormat pattern-binding guidance.
- `make ci-local` passed after repair.

## Judge
Continue. Rate-limit failures are clearer; next useful UX work is showing users when the next scheduled refresh is due.

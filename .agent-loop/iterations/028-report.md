# Iteration 028 Report

## Selected Task
Reuse a single provider selection during app startup.

## Changes
- Initialized `PRMenuBarApp` with one provider selection and reused it for initial load, data-source status, and refreshes.
- Repaired the initializer to satisfy SwiftUI's required no-argument `App.init()`.

## Verification
- Initial `make ci-local` failed because the custom initializer shape did not satisfy `App`.
- `make ci-local` passed after repair.

## Judge
Continue. Startup selection is consistent; next useful work is pruning stale known repository IDs when repositories disappear.

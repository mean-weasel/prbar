# Iteration 038 Report

## Selected Task

Document refresh and rate-limit behavior in the README.

## Changes

- Documented sample-vs-GitHub source status in the popover.
- Documented manual and scheduled refresh behavior.
- Documented GitHub rate-limit reset messaging when reset headers are available.

## Verification

- `make ci-local` passed.

## Judge

Continue. User-facing docs now match the current refresh behavior; next useful work is reducing duplicated refresh guard logic in the app entry point.

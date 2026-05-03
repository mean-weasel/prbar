# Iteration 4

## Summary

Added a data-provider boundary:

- Added `PRActivityProviding`.
- Added `StaticPRActivityProvider` for current sample data.
- Added `JSONPRActivityProvider` for fixture/data decoding.
- Routed app startup through the provider.
- Added provider tests for valid and invalid JSON payloads.

## Verification

`make ci-local` passed.

## Judge Decision

Continue. Refresh is still a timestamp-only action; the original charter called for daily auto-refresh and explicit refresh controls.


# Iteration 022 Report

## Selected Task
Surface incomplete GitHub search responses as provider errors.

## Changes
- Added a provider error for incomplete merged PR search responses.
- Failed the GitHub provider load when Search reports incomplete results.
- Added focused provider coverage for the incomplete-result path.

## Verification
- `make ci-local` passed.

## Judge
Continue. The provider now fails closed for incomplete GitHub activity; next useful work is broadening timestamp decoding to match GitHub's date variants.

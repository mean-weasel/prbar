# Iteration 018 Report

## Selected Task

Add weekly bucketing for merged pull request dates.

## Changes

- Added `PRActivityBucketSeries` for weekly labels and counts.
- Matched the app's existing Sunday-start weekly labels.
- Added tests for in-range counting and out-of-range exclusion.

## Verification

- `make ci-local` passed.

## Judge

Continue. Bucket generation is ready; provider aggregation can now fill repository weekly counts.

# Iteration 017 Report

## Selected Task

Decode GitHub merged pull request search results.

## Changes

- Added `GitHubMergedPullRequestSearchResponse`.
- Added merged PR item decoding with `pull_request.merged_at` parsing.
- Added tests for valid merged dates and invalid date rejection.

## Verification

- `make ci-local` passed after repairing an incorrect fixed epoch in the test.

## Judge

Continue. Merged PR dates can now be decoded; weekly bucketing is the next aggregation step.

# Iteration 016 Report

## Selected Task

Add merged pull request request construction.

## Changes

- Added `GitHubAPIRequest.mergedPullRequests`.
- Used the Search Issues API query shape: `repo`, `is:pr`, `is:merged`, and merged date range.
- Added tests for query, pagination, and sort parameters.

## Verification

- `make ci-local` passed.

## Judge

Continue. Request construction is ready; decoding merged PR search results is the next provider step.

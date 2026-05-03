# Iteration 015 Report

## Selected Task

Select GitHub provider from environment token.

## Changes

- Added `PRActivityProviderFactory`.
- Kept `StaticPRActivityProvider` as the default without a token.
- Switched the app to `GitHubPRActivityProvider` when `PR_MENU_BAR_GITHUB_TOKEN` is present.
- Added factory tests for both provider paths.

## Verification

- `make ci-local` passed.

## Judge

Continue. The app has a real provider selection path; merged PR request construction is the next API gap.

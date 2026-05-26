# iOS GitHub Data Sync

Prepare and execute the next post-auth iOS tranche: replace fixture-backed PR and release activity with a secure, testable GitHub data sync layer that uses the merged auth/session/repository foundation from PR #44.

## Owner Outcome

After this goal completes, the iOS app should be able to use the signed-in GitHub session and selected repositories to fetch real pull request and release/tag activity, preserve privacy defaults, keep tests deterministic, and open a reviewed PR with local and CI proof.

## Scope

- Build on `origin/main` after PR #44.
- Design the GitHub API/service layer for PR activity and releases/tags.
- Decide data freshness, pagination, date range, caching, and error behavior.
- Keep private repository data excluded from share surfaces unless intentionally selected and labeled.
- Preserve deterministic unit/UI tests with fixtures/fakes.
- Keep the first implementation PR scoped to one coherent vertical slice.

## Non-Goals

- No social backend, messaging, public profiles, or hosted sharing service in this tranche.
- No App Store packaging work.
- No real user tokens or secrets in tests or CI.
- No broad redesign of the existing iOS UI unless required by live data states.

## Oracle

The goal is complete only when a draft PR exists on top of current `main` with source-backed architecture notes, a Judge-approved slice, implementation receipts, passing local iOS build/unit/UI smoke checks, and deterministic tests proving live-data mapping, selected-repo filtering, privacy defaults, and recoverable error states.

## Starter Command

`/goal Follow Docs/goals/ios-github-data-sync/goal.md.`

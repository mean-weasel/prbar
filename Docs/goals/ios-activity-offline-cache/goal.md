# iOS Activity Offline Cache

## Original Request

Plan out the next iOS app slice with GoalBuddy after the iOS data reliability tranche.

## Interpreted Outcome

The next tranche should make the iOS app trustworthy when reopened offline, relaunched after a previous sync, or temporarily unable to reach GitHub by persisting the last successful GitHub activity snapshot and surfacing clear stale/offline cache semantics in the PRs and Releases experience.

## Goal Kind

Specific implementation tranche.

## Audience

High-velocity GitHub users checking PR and release activity from iPhone while mobile, between machines, or temporarily offline.

## Context

- PR #62 completed the previous reliability tranche.
- The app now classifies common GitHub/network failures, tracks last attempted refresh separately from last successful refresh, and shows stale-but-usable status after an in-memory refresh failure.
- The next likely product gap is that stale data should survive app relaunch and offline startup, not only stay available in memory during the current process.

## Non-Goals

- Do not redesign the main iOS navigation.
- Do not work on the Share tab, social cards, or release annotation flows in this tranche.
- Do not change GitHub OAuth scopes, secrets, or backend infrastructure unless a Judge explicitly approves a tiny supporting change.
- Do not weaken simulator CI, merge queue checks, or the iOS Physical Preview workflow.
- Do not add macOS UI changes unless a shared model/storage change requires compatibility work.

## Oracle

The tranche is complete only when a merged PR proves that iOS can persist and restore a last successful GitHub activity snapshot with honest stale/offline UI semantics, and that proof is backed by local tests, PR checks, merge queue checks, post-merge main iOS, and iOS Physical Preview on `iPhone-preview`.

## Completion Proof

- A merged PR against `main`.
- Relevant unit tests for cache encode/decode, stale metadata, corruption/migration fallback, and store restore behavior.
- Relevant UI or integration proof that PRs/Releases show cached data and stale/offline copy after relaunch or refresh failure.
- PR CI and iOS checks pass.
- Merge queue CI and iOS checks pass.
- Post-merge main iOS passes.
- iOS Physical Preview workflow passes on `iPhone-preview`.

## Likely Misfire

Adding a cache file that technically stores data but leaves users unable to tell whether they are seeing fresh GitHub data, stale cached data, sample data, or a failed sync state.

## Blind Spots To Audit

- Whether the cache should persist the full activity snapshot, derived PR/release lists, or a versioned cache envelope.
- Whether sample data can accidentally be written as real cached GitHub data.
- Cache invalidation when selected repositories change, auth changes, or GitHub account identity changes.
- Cache corruption, schema changes, missing files, and partial writes.
- Privacy expectations for locally stored GitHub PR/release metadata.
- Shared-model impact on the macOS menu bar app.
- Whether refresh/pull-to-refresh should continue to preserve cached data when the network fails.

## Starter Command

```text
/goal Follow Docs/goals/ios-activity-offline-cache/goal.md.
```

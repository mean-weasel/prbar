# iOS Repo Search And Pull Refresh

## Original Request

Plan the next iOS app tranche with GoalBuddy: improve repository selection for accounts with many repos and confirm/add pull-to-refresh behavior for PRs and Releases so live GitHub data updates when the user refreshes.

## Interpreted Outcome

PRBar iOS should make selecting repositories fast for high-repo-count GitHub accounts and let users refresh PR and release data from the PRs/Releases screens without leaving the tab or falling back to dummy data.

## Tranche

Discover the current SwiftUI/store seams for repository selection and activity refresh, choose the largest safe implementation slice, implement repo-search/filter improvements and pull-to-refresh if the evidence supports it, then verify with deterministic tests plus simulator UI coverage.

## Goal Oracle

A simulator walkthrough and automated tests prove that:

- Repository selection remains usable with many repos through search and/or filters.
- PRs supports native pull-to-refresh and updates provider-backed PR data.
- Releases supports native pull-to-refresh and updates provider-backed release/tag data.
- Loading, empty, and recoverable error states are handled in-place.
- CI/previews remain deterministic and do not require live GitHub credentials.

## Non-Goals

- No new social backend, push notifications, or server-side sync.
- No committed GitHub tokens, client secrets, or account-specific credentials.
- No broad redesign of the PRs/Releases/Share tabs unless needed for this tranche.
- No changes to unrelated macOS menu bar/share-card work.

## Likely Misfire

Adding a cosmetic search field or refresh gesture that does not actually improve large-account repo selection or does not re-fetch provider-backed GitHub data.

## Blind Spots To Audit

- Search should scale beyond name matching if org/owner grouping is important.
- Pull-to-refresh should not block the main thread or jank the scroll view.
- Refresh should preserve selected date/range where reasonable.
- Refresh errors should be visible but not bounce the user out of the current tab.
- Repository changes may require refreshing both PRs and Releases from one shared store path.
- UI tests need deterministic fake providers that can prove data changed after refresh.

## Starter Command

```text
/goal Follow docs/goals/ios-repo-search-refresh/goal.md.
```

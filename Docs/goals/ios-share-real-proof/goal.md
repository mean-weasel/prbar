# iOS Share Real Proof

## Original Request

Plan the next iOS app tranche with GoalBuddy after live GitHub data, repository search/pull-to-refresh, reliability, and offline-cache work: make the Share surface produce a real proof-of-work artifact from GitHub activity rather than a mock/demo card.

## Interpreted Outcome

PRBar iOS should let a signed-in user create and share a polished proof-of-work card backed by the same selected-repository GitHub PR, release, and tag data shown elsewhere in the app. The first tranche should keep sharing local and private by default: native iOS share sheet export, no public profile, no server upload, and no social backend.

## Tranche

Discover the current iOS Share surface, shared work-card renderer, activity snapshot model, cached/live data flow, and iOS export/test capabilities; choose the largest safe vertical implementation slice; then implement a real-data card generation and sharing path with deterministic tests and Preview iPhone proof.

## Goal Oracle

The tranche is complete when a merged PR demonstrates that PRBar iOS can generate a shareable card from selected real activity data and export it through the native iOS share flow while preserving conservative privacy defaults.

Final proof requires:

- A merged PR.
- Unit tests proving the share payload/card summary uses selected-repository PRs, releases, and tags from the current activity snapshot.
- Simulator UI or snapshot-style evidence proving the Share tab renders a real-data card and exposes a native export action.
- Post-merge `main` iOS workflow success.
- iOS Physical Preview workflow success on `iPhone-preview`.

## Non-Goals

- Do not build a public social feed, hosted profile, messaging system, or backend upload in this tranche.
- Do not add new GitHub OAuth scopes unless Scout/Judge proves the existing scopes cannot support the first slice.
- Do not make shared cards public by default.
- Do not redesign the whole iOS navigation or the PRs/Releases tabs.
- Do not change macOS menu bar/share-card behavior unless a shared model fix is necessary and explicitly approved by Judge.
- Do not depend on live GitHub credentials in CI.

## Likely Misfire

The goal could succeed at the wrong thing by making the Share tab look nicer while still using dummy/sample data, or by adding export mechanics that share ambiguous screenshots without showing what repos, dates, PRs, releases, or tags the card actually represents.

## Blind Spots To Audit

- Whether the existing iOS Share surface already has renderer/export code that can be reused safely.
- Whether the card should share an image, text summary, or both through `ShareLink`/`UIActivityViewController`.
- Whether evidence details should include PR titles/releases on the back side of the card or a companion summary.
- How date ranges should map to the existing day/week/month controls and cached data freshness.
- How private repo names, PR titles, author names, and release notes should be treated before sharing.
- Whether cards generated from stale cached data need explicit stale/fresh labeling.
- How to keep tests deterministic without live GitHub credentials or fragile screenshot comparison.

## Initial Assumptions

- The first version should share a locally generated image plus a short text summary through the native iOS share sheet.
- Card input should come from `PRBarStore`/`GitHubActivitySnapshot`, not from independent mock data.
- The existing offline cache and refresh-state work should make it possible to label stale cards honestly.
- If export plumbing or rendering is riskier than expected, Judge should choose the largest smaller slice that still produces a real-data Share tab rather than only storage/helper code.

## Starter Command

```text
/goal Follow Docs/goals/ios-share-real-proof/goal.md.
```

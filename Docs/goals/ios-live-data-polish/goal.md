# iOS Live Data Polish

## Original Request

Make a detailed GoalBuddy plan for the next iOS app tranche: live-data polish and sync state after the iOS simulator and physical Preview iPhone paths are green.

## Interpreted Outcome

The iOS app should feel trustworthy and usable with real GitHub data on the road: users can understand when data was refreshed, recover from GitHub/network/auth errors, select repos efficiently at scale, and verify the behavior through simulator CI plus the physical Preview iPhone smoke workflow.

## Input Shape

specific

## Audience

The primary beneficiary is a high-velocity GitHub user who wants to check PR and release activity on iPhone and trust that the data is fresh, complete, and scoped to the right repos.

## Non-Goals And Constraints

- Do not redesign the whole iOS app.
- Do not change macOS menu bar behavior except where shared models/services require careful compatibility.
- Do not add new backend infrastructure.
- Do not make physical Preview mandatory on every PR unless the goal run explicitly evaluates and justifies that tradeoff.
- Preserve current GitHub auth/device-flow behavior unless evidence shows it is blocking the tranche.
- Use existing repo patterns and SwiftUI structure.
- Keep changes bounded, testable, and mergeable through normal CI and merge queue.

## Goal Oracle

The tranche is complete when a verified PR lands that improves iOS live-data trust and repo-selection UX, with:

- visible sync/last-refreshed state in the iOS app;
- clear loading, empty, and error states for GitHub-backed PR/release data;
- repo-selection polish for larger accounts, including search/filter/selected count behavior;
- simulator unit/UI verification for the new behavior;
- post-merge `main` iOS success; and
- a successful `iOS Physical Preview` workflow run on `iPhone-preview`.

## Likely Misfire

The goal could succeed at the wrong thing by adding decorative UI or isolated helpers while leaving the user unsure whether GitHub data is current, why a refresh failed, or which repos are actually included.

## Current Tranche Definition

Complete one coherent product slice: live sync state plus repo-selection polish. Discovery should validate exact existing files, data flow, and verification commands before implementation. The first implementation package should be the largest safe reversible slice that changes real iOS behavior and can be verified locally and in CI.

## Starter Command

```text
/goal Follow docs/goals/ios-live-data-polish/goal.md.
```

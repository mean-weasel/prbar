# iOS Data Reliability

## Original Request

Plan the next iOS app tranche with GoalBuddy after the live-data polish PR merged: make GitHub-backed data feel reliable and trustworthy before building more product surface on top.

## Interpreted Outcome

The iOS app should clearly explain, recover from, and preserve value through real GitHub data problems: auth expiry, SSO or permission blockers, rate limits, network failures, retry attempts, stale data, and offline usage.

## Tranche

Complete one coherent implementation slice that improves iOS GitHub data reliability and user trust without broadening into Share cards, macOS UI, or unrelated product redesign.

## Goal Oracle

The tranche is complete when a merged PR demonstrates, through automated iOS tests and a post-merge physical Preview run, that the app handles at least the selected highest-value reliability states with user-visible recovery copy and deterministic data behavior.

Final proof requires:

- A merged PR.
- Relevant unit/UI tests passing in CI.
- Post-merge main iOS workflow success.
- iOS Physical Preview workflow success on `iPhone-preview`.

## Non-Goals

- Do not build new Share tab capabilities in this tranche.
- Do not redesign the full iOS navigation or visual language.
- Do not alter macOS menu bar behavior unless a shared model fix is necessary and explicitly approved by Judge.
- Do not require new backend infrastructure or production credentials for the first implementation slice.
- Do not weaken the existing real-device Preview gate.

## Likely Misfire

Shipping nicer labels for errors while still losing useful cached data, hiding retry progress, or failing to distinguish last successful sync from failed attempts.

## Initial Assumptions

- The prior live-data polish work has merged and physical Preview infrastructure is currently healthy.
- The safest next step is to Scout current auth, GitHub API, refresh, cache, and test surfaces before choosing an implementation package.
- If Scout finds that persistent caching is too broad for one PR, Judge should prefer the largest smaller slice that still improves reliability end to end.

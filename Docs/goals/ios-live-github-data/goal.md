# iOS Live GitHub Data

## Objective

Replace the iOS preview app's dummy data with a real, privacy-conscious GitHub-backed data path while preserving sample data for SwiftUI previews, CI, and offline development.

## Original Request

"Great what's next for the iOS app? I noticed in the preview version we're using dummy data." Then: "make a detailed plan with GoalBuddy Prep."

## Intake Summary

- Input shape: `existing_plan`
- Audience: PRBar users who want iOS access to PR stats, releases, repo selection, and shareable proof-of-work cards.
- Authority: `requested`
- Proof type: `demo`
- Completion proof: A verified iOS build/demo where the app can sign in to GitHub, select repos, fetch real PR/release/tag data, render PRs/Releases/Share from that data, and still run previews/CI using deterministic sample providers.
- Goal oracle: A simulator or physical-device walkthrough plus automated tests proving the provider boundary, GitHub payload normalization, repo selection, and UI states work without relying on hardcoded dummy data.
- Likely misfire: Only renaming or restructuring dummy data, or wiring one screen to live data while leaving releases/share/repo selection detached from the real provider.
- Blind spots considered: GitHub auth scope, token storage, pagination/rate limits, private repo privacy defaults, tags versus releases, time zones, deleted/renamed repos, offline/loading/error states, CI without credentials, and avoiding a premature public/social backend.
- Existing plan facts:
  - Use a data-provider abstraction so sample and live providers can coexist.
  - Keep sample data for SwiftUI previews, preview app mode, and CI.
  - Add Sign in with GitHub and Keychain token storage before live syncing.
  - Add repo selection similar to the macOS menu bar app.
  - Fetch PRs, releases, and tagged versions from selected GitHub repos.
  - Normalize data into daily buckets for PRs, releases, calendars, distributions, and share cards.
  - Keep share generation local through the native share sheet for the first tranche.
  - Defer public social/profile/upload features until the private live-data experience is usable.

## Goal Oracle

The oracle for this goal is:

`A receipt-backed iOS walkthrough and test set showing PRBar iOS can switch from sample data to authenticated GitHub data, select repos, render live PR/release/tag summaries across PRs/Releases/Share, and keep CI/previews deterministic with sample providers.`

The PM must keep comparing task receipts to this oracle. Planning, discovery, a passing tiny slice, or a clean-looking board is not enough. The goal finishes only when a final Judge/PM audit maps receipts and verification back to this oracle and records `full_outcome_complete: true`.

## Goal Kind

`existing_plan`

## Current Tranche

Build the first real-data iOS tranche: discover the current SwiftUI app/data shape, validate the data-provider architecture, implement successive safe vertical slices from provider contracts through GitHub auth/repo selection/fetching/UI wiring, and verify with unit tests plus simulator or physical-device smoke. This tranche is complete only when dummy data is no longer the primary runtime source for the signed-in app path, while previews and CI still have deterministic sample data.

## Non-Negotiable Constraints

- Do not remove sample data needed for SwiftUI previews, simulator smoke, CI, or offline development.
- Do not add a public/social backend in this tranche.
- Default privacy must be conservative: selected repos only, private data not shared by default, and share output generated locally.
- Preserve repo patterns and existing iOS/macOS project organization discovered by Scout.
- Use structured GitHub models/parsing and explicit date/time-zone normalization, not ad hoc string scraping.
- Keep GitHub credentials out of logs, fixtures, screenshots, and sample data.
- Real-device preview testing should remain compatible with the `prbar-iphone-preview` runner setup once live-data slices are ready to smoke.

## Stop Rule

Stop only when a final audit proves the full original outcome is complete.

Do not stop after planning, discovery, or Judge selection if a safe Worker task can be activated.

Do not stop after a single verified Worker package when the broader owner outcome still has safe local follow-up work. Advance the board to the next highest-leverage safe Worker package and continue unless a phase, risk, rejected-verification, ambiguity, or final-completion review is due.

## Slice Sizing

Safe means bounded, explicit, verified, and reversible. It does not mean tiny.

A good task is the largest safe useful slice. Prefer vertical slices that move the app from dummy data toward real signed-in GitHub behavior over tiny helper-only changes.

## Canonical Board

Machine truth lives at:

`docs/goals/ios-live-github-data/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/ios-live-github-data/goal.md.
```

## PM Loop

On every `/goal` continuation:

1. Read this charter.
2. Read `state.yaml`.
3. Run the bundled GoalBuddy update checker when available and mention a newer version without blocking.
4. Re-check the intake: original request, input shape, authority, proof, blind spots, existing plan facts, and likely misfire.
5. Work only on the active board task.
6. Assign Scout, Judge, Worker, or PM according to the task.
7. Write a compact task receipt.
8. Update the board.
9. If safe local work remains, choose the next largest reversible Worker package and continue unless blocked.
10. Review at phase, risk, rejected-verification, ambiguity, or final-completion boundaries; do not review every small Worker by habit.
11. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the original user outcome and records `full_outcome_complete: true`.

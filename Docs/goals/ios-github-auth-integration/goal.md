# iOS GitHub Auth Integration

## Objective

After PR #43 merges, turn the iOS prototype GitHub connection and repository setup flow into a real, secure GitHub-backed vertical slice: authenticate with GitHub, store the session safely, fetch selectable repositories, persist repo choices, and prove the app can move from signed out to real repo-backed state without regressing the existing prototype UX.

## Original Request

"Planning out extensively using GoBuddy Prep. Once that PR merges that is."

## Intake Summary

- Input shape: `specific`
- Audience: PRBar users who want an iOS companion app for PR stats, releases, repo selection, and shareable proof-of-work.
- Authority: `approved`
- Proof type: `test`
- Completion proof: A draft PR after #43 is merged that implements real GitHub sign-in/session handling and repo fetching behind tested SwiftUI flows, with local simulator verification and CI-ready checks passing.
- Goal oracle: A signed-out simulator run can connect through the real GitHub auth boundary or a test-double equivalent, store/load session state safely, fetch repositories through a GitHub service layer, select repos, relaunch with selections preserved, and pass unit/UI smoke checks.
- Likely misfire: Building another mock/prototype layer that still looks like GitHub auth but does not establish a secure OAuth/token/session architecture or a replaceable GitHub API boundary.
- Blind spots considered: OAuth app type and callback scheme, token storage in Keychain, GitHub API pagination/rate limits, private repo privacy defaults, cancellation/error states, CI testability without real credentials, merge queue requirements, and keeping the app useful when offline or signed out.
- Existing plan facts: PR #43 contains the prototype GitHub connection state and repo-selection onboarding; it must merge before this goal starts implementation. The next logical PR is real GitHub OAuth plus secure token storage, followed by repo API integration and persistence.

## Goal Oracle

The oracle for this goal is:

`After PR #43 is merged and main is current, a verified iOS branch demonstrates the signed-out-to-repo-selection flow using a real GitHub auth/session architecture or controlled test doubles, stores session data in Keychain-facing code, fetches repositories through a GitHub API service, persists selected repositories, and passes unit tests plus iOS UI smoke on the simulator.`

The PM must keep comparing task receipts to this oracle. Planning, discovery, a passing tiny slice, or a clean-looking board is not enough. The goal finishes only when a final Judge/PM audit maps receipts and verification back to this oracle and records `full_outcome_complete: true`.

## Goal Kind

`specific`

## Current Tranche

This tranche starts only after PR #43 has merged to `main`. The largest intended outcome is one coherent implementation PR that replaces the prototype-only GitHub connect path with real auth/session/repo plumbing while preserving the current UI shape.

The tranche should proceed in vertical slices:

1. Confirm PR #43 is merged, sync from `main`, and create a fresh branch.
2. Scout the current iOS architecture, auth options, Keychain/testability patterns, and GitHub API needs.
3. Judge the smallest secure architecture that can become production-grade without overbuilding.
4. Implement the auth/session boundary and secure token persistence with test doubles.
5. Implement GitHub repository fetching, pagination/error handling where needed, and repo selection persistence.
6. Wire the SwiftUI onboarding/settings flows to the real service layer while retaining deterministic UI tests.
7. Verify locally, open a draft PR, and let CI/merge queue validate it.

## Non-Negotiable Constraints

- Do not implement before PR #43 is merged and `main` is synced.
- Do not commit secrets, real tokens, client secrets, or user-specific credentials.
- Prefer GitHub OAuth/device/app-auth patterns that are suitable for an iOS app and testable in CI.
- Store sensitive session material through a Keychain-facing abstraction, not plain UserDefaults.
- Keep private repositories excluded by default unless the user explicitly includes them.
- Keep UI tests deterministic with fakes, launch arguments, dependency injection, or equivalent test seams.
- Preserve existing macOS/menu-bar behavior and non-iOS CI.
- Keep implementation in the iOS app area unless Scout/Judge proves shared code changes are necessary.
- Do not broaden into PR/release data fetching until auth, repo fetching, and repo selection persistence are verified.

## Stop Rule

Stop only when a final audit proves the full original outcome is complete.

Do not stop after planning, discovery, or Judge selection if a safe Worker task can be activated.

Do not stop after a single verified Worker package when the broader owner outcome still has safe local follow-up work. Advance the board to the next highest-leverage safe Worker package and continue unless a phase, risk, rejected-verification, ambiguity, or final-completion review is due.

Do not stop because a slice needs owner input, credentials, production access, destructive operations, or policy decisions. Mark that exact slice blocked with a receipt, create the smallest safe follow-up or workaround task, and continue all local, non-destructive work that can still move the goal toward the full outcome.

## Slice Sizing

Safe means bounded, explicit, verified, and reversible. It does not mean tiny.

A good task is the largest safe useful slice. The expected shape here is a few vertical slices rather than many helper-only tasks: auth/session boundary, repo API + persistence, SwiftUI integration, then final verification and PR publication.

## Canonical Board

Machine truth lives at:

`docs/goals/ios-github-auth-integration/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/ios-github-auth-integration/goal.md.
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
10. Review at phase, risk, rejected-verification, ambiguity, or final-completion boundaries.
11. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the original user outcome and records `full_outcome_complete: true`.

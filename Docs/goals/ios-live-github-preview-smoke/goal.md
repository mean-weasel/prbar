# iOS Live GitHub Preview Smoke

## Objective

Build a repeatable physical-iPhone preview test path that can exercise the real GitHub profile flow with exactly one included repository, while keeping normal install workflows simple and avoiding accidental broad repo syncs.

## Original Request

Plan out whether setup for my GitHub profile with inclusion of a single repository can be included in tests and installs, using GoalBuddy.

## Intake Summary

- Input shape: `specific`
- Audience: PRBar maintainer and future iOS preview/device-test operators
- Authority: `requested`
- Proof type: `test`
- Completion proof: A physical-device workflow can install or launch the iOS preview app on `iPhone-preview`, select or seed exactly one configured GitHub repository for `neonwatty`, refresh activity, and produce a receipt proving that only the configured repo was included and live PR/release data was loaded or a clear auth/setup blocker was reported.
- Goal oracle: A GitHub Actions physical-device run on `iPhone-preview` with an explicit repo input, plus local/device evidence showing one included repo and a completed live refresh.
- Likely misfire: Treating fixture-mode UI tests or install-only workflows as proof of real GitHub profile behavior.
- Blind spots considered: persisted auth versus injected token, secret exposure, GitHub rate limits, repo permissions, device lock/availability, separation between install workflows and live smoke workflows, and avoiding accidental selection of all repos.
- Existing plan facts: Current app has physical install and physical preview smoke workflows; install should stay mostly build/install; live GitHub auth may be manual/persisted initially, with token injection only if repeatability requires it; target profile is `neonwatty`; target repo should be one explicit repo such as `mean-weasel/prbar`.

## Goal Oracle

The oracle for this goal is:

`A physical-device GitHub Actions run on iPhone-preview that uses a configured single repo, proves exactly that repo is included, refreshes live GitHub PR/release activity, and reports either success with evidence or a precise blocker such as missing auth, missing repo access, locked device, or rate limit.`

The PM must keep comparing task receipts to this oracle. Planning, discovery, fixture UI tests, a successful install, or a clean-looking workflow run is not enough. The goal finishes only when a final Judge/PM audit maps receipts and verification back to this oracle and records `full_outcome_complete: true`.

## Goal Kind

`specific`

## Current Tranche

Discover the safest implementation shape, then implement and verify a repeatable live physical-device smoke workflow for one GitHub repo. The initial version may rely on an existing persisted GitHub session on the preview iPhone if that is the safest path; if that makes the test non-repeatable, the board should explicitly evaluate a minimal-secret token-injection path before implementation.

## Profile Setup Plan Decision

The plan is to include GitHub profile and one-repository setup in preview-device tests, not as a hidden default in ordinary installs.

For tests, the live physical-preview workflow should accept explicit operator inputs such as `github_login=neonwatty` and `included_repo=mean-weasel/prbar`. The app/test harness may seed only that selected repository before refresh, and the test must prove that exactly one repo is included before it treats PR/release data as valid.

For installs, the workflow may optionally support a clearly named manual setup input later, but a normal install should remain install-only. This keeps production-device installs from unexpectedly mutating repo choices, avoids accidental all-repo syncs, and makes rate-limit behavior predictable. If install-time setup becomes necessary, it should be an explicit operator action with the same one-repo guardrails as the test workflow.

## Non-Negotiable Constraints

- Do not log GitHub access tokens, device codes, or private repo details.
- Do not default to selecting all repositories.
- Keep the install workflow focused on build/install unless evidence shows setup must be part of install.
- Prefer an explicit live-smoke workflow or profile over changing fixture-mode UI tests into live tests.
- Preserve existing iOS CI, simulator UI tests, and physical-device install behavior.
- Any token-based path must use least privilege and GitHub Actions secrets.
- Physical-device verification must handle device locked/offline states with clear failure messages.

## Stop Rule

Stop only when a final audit proves the full original outcome is complete.

Do not stop after planning, discovery, or Judge selection if a safe Worker task can be activated.

Do not stop after a single verified Worker package when the broader owner outcome still has safe local follow-up work. Advance the board to the next highest-leverage safe Worker package and continue unless a phase, risk, rejected-verification, ambiguity, or final-completion review is due.

## Slice Sizing

Safe means bounded, explicit, verified, and reversible. It does not mean tiny.

A good task is the largest safe useful slice: a working live-smoke workflow, app/test hooks needed to drive one-repo selection, and verification that proves the real-profile path rather than fixture behavior.

## Canonical Board

Machine truth lives at:

`docs/goals/ios-live-github-preview-smoke/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/ios-live-github-preview-smoke/goal.md.
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
10. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the original user outcome and records `full_outcome_complete: true`.

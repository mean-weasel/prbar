# Refresh Efficiency Measurement

## Objective

Make PR Menu Bar refresh measurably more efficient by instrumenting refresh phases, reducing repeated GitHub work, and proving that manual refresh latency and request volume improve without stale or incorrect activity data.

## Original Request

"make a detailed plan using goalbuddy:goal-prep to address all of these measurably"

## Intake Summary

- Input shape: `existing_plan`
- Audience: app maintainer and PR Menu Bar users who click Refresh
- Authority: `requested`
- Proof type: `metric`
- Completion proof: a final Judge/PM audit maps receipts to measured refresh timings, request counts, test coverage, and implementation evidence for instrumentation, incremental search, conditional requests, and async transport cleanup or documented deferrals.
- Goal oracle: repeated local or fixture-backed refresh runs produce phase timings and request counts showing improvement versus the current baseline, while `make test`, formatting, and file-size checks pass.
- Likely misfire: optimize one obvious repeated request path but stop before measuring real latency, proving freshness, or addressing the remaining bottlenecks.
- Blind spots considered: GitHub rate-limit behavior, repository/org topology changes, stale caches, incremental merge correctness across window changes, async migration risk, and whether live GitHub credentials are available.
- Existing plan facts: add lightweight timing logs; make PR search incremental; use GitHub conditional requests; move transport to async/await.

## Goal Oracle

The oracle for this goal is:

`A receipt-backed benchmark report comparing before/after refresh phase timings and GitHub request counts, plus passing verification, proves manual refresh is faster or explicitly documents blocked live-measurement constraints and fixture-backed evidence.`

The PM must keep comparing task receipts to this oracle. Planning, discovery, a passing tiny slice, or a clean-looking board is not enough. The goal finishes only when a final Judge/PM audit maps receipts and verification back to this oracle and records `full_outcome_complete: true`.

## Goal Kind

`existing_plan`

## Current Tranche

Complete successive safe, verified slices that make refresh efficiency observable first, then improve the highest-impact refresh paths in order: phase timing/request metrics, incremental PR data refresh, conditional GitHub discovery requests, and async transport cleanup where measurable and low-risk. Each implementation slice must include tests and a measurement receipt.

## Non-Negotiable Constraints

- Work in the fresh worktree at `/Users/neonwatty/Desktop/prbar/.worktrees/investigate-refresh-efficiency`.
- Preserve existing GitHub data correctness: activity must not become stale, omit newly merged PRs inside the selected window, or lose repository inclusion settings.
- Do not require live GitHub credentials for automated verification; live timing may be optional and must degrade to fixture-backed measurement if credentials are unavailable.
- Keep Swift files under the repo's 300-line guardrail.
- Use existing project verification commands: `./scripts/format-check.sh`, `./scripts/file-size-check.sh`, and `make test`.
- Do not complete the goal on planning or discovery alone.

## Stop Rule

Stop only when a final audit proves the full original outcome is complete.

Do not stop after planning, discovery, or Judge selection if the user asked for working software or automation and a safe Worker task can be activated.

Do not stop after a single verified Worker package when the broader owner outcome still has safe local follow-up work. Advance the board to the next highest-leverage safe Worker package and continue unless a phase, risk, rejected-verification, ambiguity, or final-completion review is due.

## Slice Sizing

Safe means bounded, explicit, verified, and reversible. It does not mean tiny.

A good task is the largest safe useful slice.

## Canonical Board

Machine truth lives at:

`docs/goals/refresh-efficiency-measurement/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/refresh-efficiency-measurement/goal.md.
```

## PM Loop

On every `/goal` continuation:

1. Read this charter.
2. Read `state.yaml`.
3. Work only on the active board task.
4. Write a compact task receipt.
5. Update the board.
6. Continue to the next safe task until the final audit proves the oracle.

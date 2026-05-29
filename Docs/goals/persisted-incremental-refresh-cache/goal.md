# Persisted Incremental Refresh Cache

## Objective

Make PR Menu Bar manual refresh feel cheaper by planning and executing a persisted incremental merged-PR cache tranche that survives app relaunches while preserving refresh correctness.

## Original Request

Optimize the menu bar Refresh behavior, specifically by targeting a fresh GoalBuddy implementation goal for a persisted incremental PR cache.

## Intake Summary

- Input shape: `specific`
- Audience: PR Menu Bar maintainer and users refreshing GitHub-backed menu bar activity.
- Authority: `approved`
- Proof type: `test`, `metric`, `demo`
- Completion proof: Fixture tests and benchmark evidence prove persisted incremental refresh reduces post-relaunch GraphQL search range/request work without missing or duplicating PRs, and a best-effort live GitHub smoke is attempted when credentials/network are available.
- Goal oracle: Deterministic fixture benchmark plus targeted tests prove cache persistence, cache invalidation, overlap/dedupe behavior, and safe fallback paths; optional live smoke records real GitHub behavior if available.
- Likely misfire: GoalBuddy could make refresh appear faster by trusting stale persisted data, skipping needed discovery/full refresh, or only improving in-memory repeated refresh while relaunch remains cold.
- Blind spots considered: GitHub search indexing lag, stale/corrupt cache data, token/user scope changes, repository/owner changes, settings/window expansion, failed refresh watermark advancement, and release-refresh calls masking PR activity improvements.
- Existing plan facts: The user chose persisted incremental PR cache as the first target, fresh implementation goal, and fixture proof plus optional live smoke as success evidence.

## Goal Oracle

The oracle for this goal is:

`A final Judge or PM audit maps receipts to passing fixture tests, a refreshed benchmark/report showing persisted incremental refresh behavior after provider/app restart, correctness coverage for invalidation/fallback/overlap/dedupe cases, and a best-effort live GitHub smoke result or explicit reason it was skipped.`

The PM must keep comparing task receipts to this oracle. Planning, discovery, a passing tiny slice, or a clean-looking board is not enough. The goal finishes only when a final Judge/PM audit maps receipts and verification back to this oracle and records `full_outcome_complete: true`.

## Goal Kind

`specific`

## Current Tranche

Implement the persisted incremental merged-PR cache capability as the current tranche. The run should first map the existing refresh/cache/test surface, then choose and execute the largest safe useful implementation slice. Continue through verification, benchmark update, and final audit until the persisted-cache owner outcome is proven or a precise blocker is recorded.

## Non-Negotiable Constraints

- Preserve current refresh correctness: no missed PRs, no duplicate counted PRs, no watermark advancement after failed refresh.
- Treat persisted cache as token/user/owner/window compatible only when proven safe; otherwise fall back to full refresh.
- Include an overlap window and stable PR-id dedupe unless Scout/Judge finds a stronger existing safeguard.
- Do not make live GitHub credentials mandatory for completion; fixture proof is required, live smoke is best-effort.
- Do not optimize release refresh inside this tranche unless Scout/Judge proves release calls block validating the persisted PR cache outcome.
- Respect the dirty worktree; do not revert unrelated user changes.

## Stop Rule

Stop only when a final audit proves the full original outcome is complete.

Do not stop after planning, discovery, or Judge selection if a safe Worker task can be activated.

Do not stop after a single verified Worker package when the broader owner outcome still has safe local follow-up work. Advance the board to the next highest-leverage safe Worker package and continue unless a phase, risk, rejected-verification, ambiguity, or final-completion review is due.

## Slice Sizing

Safe means bounded, explicit, verified, and reversible. It does not mean tiny.

A good task is the largest safe useful slice.

Small is not the goal. Useful is the goal.

## Canonical Board

Machine truth lives at:

`docs/goals/persisted-incremental-refresh-cache/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/persisted-incremental-refresh-cache/goal.md.
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

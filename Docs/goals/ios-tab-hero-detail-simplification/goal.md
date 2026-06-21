# iOS Tab Hero Detail Simplification

## Objective

Simplify PRBar iOS so each main tab leads with one big-picture hero and moves fine-grain details into intentional drilldown screens. The current tranche should reduce repeated explanatory copy, clarify action hierarchy, preserve existing privacy/export and repository controls, and require simulator-verified screenshots before completion.

## Original Request

"Do that" after agreeing that fine-grain details such as "latest meaningful work" should become separate screens, leaving the big picture on each tab as the hero.

## Intake Summary

- Input shape: `existing_plan`
- Audience: PRBar iOS users who want a fast read on shipping rhythm, growth movement, share-ready proof, and setup state without wading through diagnostic detail.
- Authority: `approved`
- Proof type: `demo`
- Completion proof: build/test checks pass and XcodeBuildMCP screenshots prove each changed screen renders with a clear hero/detail split and no incoherent overlap.
- Goal oracle: the simulator shows Activity, Growth, Share, and Settings as hero-first tabs with fine-grain work logs, diagnostics, export evidence, and repo details behind drilldowns or disclosures; final Judge audit maps screenshots and tests back to the user outcome.
- Likely misfire: cosmetic spacing/color edits that leave the same dense information architecture, or hiding important privacy/setup controls while making the tabs look cleaner.
- Blind spots considered: live credentials may be unavailable; UI tests can pass while screenshots reveal cramped hierarchy; existing dirty worktree changes must not be reverted; PR #138's Work Log drilldown should be preserved.
- Existing plan facts: the user wants the big picture on each tab to be the hero, fine-grain details should move to separate screens when they compete with the overview, the simulator is the validation surface, and style improvements should follow the product's shipping-rhythm purpose.

## Goal Oracle

The oracle for this goal is:

`A final Judge audit verifies that PRBar iOS tabs are hero-first, fine-grain detail has been moved into appropriate drilldowns/disclosures, privacy/export/setup controls remain reachable and at least as safe as before, tests pass, and XcodeBuildMCP simulator screenshots prove the rendered UX.`

The PM must keep comparing task receipts to this oracle. Planning, discovery, one polished screen, or a passing test suite is not enough. The goal finishes only when a final Judge/PM audit maps receipts and verification back to this oracle and records `full_outcome_complete: true`.

## Goal Kind

`existing_plan`

## Current Tranche

Execute a screenshot-led simplification pass after PR #138:

1. Audit the current committed and dirty iOS UI state, including PR #138's Activity Work Log drilldown and the prior screenshot brainstorm at `Docs/goals/ios-shipping-rhythm-simplification/notes/T007-screenshot-brainstorm.md`.
2. Choose the largest safe first Worker slice that makes a tab hero-first while preserving required controls.
3. Prefer vertical slices that change one user-visible workflow at a time and include focused tests plus simulator screenshots.
4. Keep fine-grain content accessible through detail screens, sheets, or disclosures rather than deleting it.
5. After each Worker slice, update receipts and advance to the next safe slice until the oracle is satisfied.

## Non-Negotiable Constraints

- Use existing SwiftUI patterns and project conventions.
- Prefer XcodeBuildMCP for simulator runs, snapshots, and screenshots.
- Do not ask the user to visually verify before attempting automated visual inspection.
- Do not treat build/test success as proof that the rendered UI is correct.
- Preserve public-safe export defaults, advanced evidence export safety, repository selection controls, sample/demo clarity, and live GitHub/PostHog behavior.
- Do not revert unrelated dirty worktree changes.
- Keep changes scoped to PRBar iOS UX files and related tests unless Judge explicitly expands allowed files.
- Avoid broad visual restyling that makes the app one-note or hides controls for the sake of cleanliness.

## Stop Rule

Stop only when a final audit proves the full original outcome is complete.

Do not stop after planning, discovery, or Judge selection if a safe Worker task can be activated.

Do not stop after a single verified Worker package when the broader owner outcome still has safe local follow-up work. Advance the board to the next highest-leverage safe Worker package and continue unless a phase, risk, rejected-verification, ambiguity, or final-completion review is due.

Do not stop because live credentials are unavailable. Mark live-only verification blocked or skipped with a receipt, then continue with deterministic simulator proof that can be produced locally.

## Canonical Board

Machine truth lives at:

`Docs/goals/ios-tab-hero-detail-simplification/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow Docs/goals/ios-tab-hero-detail-simplification/goal.md.
```

## PM Loop

On every `/goal` continuation:

1. Read this charter.
2. Read `state.yaml`.
3. Run the bundled GoalBuddy update checker when available and mention a newer version without blocking.
4. Work only on the active board task.
5. Write a compact task receipt.
6. Update the board.
7. Continue to the next largest safe verified slice until the oracle is satisfied.
8. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the original user outcome and records `full_outcome_complete: true`.

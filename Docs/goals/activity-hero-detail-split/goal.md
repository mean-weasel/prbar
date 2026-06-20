# Activity Hero Detail Split

## Objective

Simplify PRBar iOS Activity so each tab leads with a big-picture hero and pushes fine-grain work inspection into dedicated detail screens, starting with moving "Latest meaningful work" out of the main Activity dashboard.

## Original Request

"Plan this out as a detailed and grounded /goal" after agreeing that fine-grain details like "latest meaningful work" should be separate screens, leaving the big picture on each tab as the hero.

## Intake Summary

- Input shape: `existing_plan`
- Audience: PRBar iOS users who want a fast, calm answer to "what shipped?" before drilling into details.
- Authority: `approved`
- Proof type: `demo`
- Completion proof: Simulator screenshots and UI tests show Activity opens with a clear shipping hero, detailed PR/release work lives behind explicit drilldowns, and CI/local verification is green or any unrelated CI failure is documented.
- Goal oracle: The iOS simulator shows Activity's first screen as a big-picture shipping dashboard, with "Latest meaningful work" replaced by a compact drilldown entry and a separate detail screen for work log inspection.
- Likely misfire: Hiding useful details without creating a strong detail path, or merely renaming sections while the main Activity screen remains a dense report.
- Blind spots considered:
  - CI was reported red before this plan request; execution must identify whether failures are pre-existing or caused by the UX tranche before adding more changes.
  - Moving details into screens can make the product feel shallower unless drilldown labels and navigation are obvious.
  - The Activity hero must preserve release context and repo drilldown value, not regress into PR-only counts.
  - Screenshots are required because build/test success alone does not prove visual hierarchy.
  - New Swift files may require XcodeGen/project membership verification.
- Existing plan facts:
  - Big picture belongs on each tab's hero.
  - Fine-grain details like "Latest meaningful work" should become separate screens.
  - Activity is the first and highest-leverage tab to simplify.
  - The previous screenshot-led tranche already made Activity, Share, and Settings calmer; this goal should build on that instead of redoing it.

## Goal Oracle

The oracle for this goal is:

`On the iOS simulator, Activity's first viewport reads as a calm shipping hero/dashboard, "Latest meaningful work" is no longer a dense inline list on the main screen, a clear Work Log/detail path exposes the detailed PR/release list, and local/CI verification evidence is recorded.`

The PM must keep comparing task receipts to this oracle. Planning, discovery, a passing tiny slice, or a clean-looking board is not enough. The goal finishes only when a final Judge/PM audit maps receipts and verification back to this oracle and records `full_outcome_complete: true`.

## Goal Kind

`existing_plan`

## Current Tranche

Complete the Activity-first hero/detail split. The first execution run should discover current Activity structure, current UI tests, screenshot evidence, and CI failure state; then implement the largest safe vertical slice that moves work-log detail out of the Activity dashboard while preserving obvious access to the details.

## Non-Negotiable Constraints

- Before asking the user to visually verify simulator state, first perform automated screenshot/snapshot inspection.
- Do not treat a successful build, install, launch, smoke workflow, or UI test as proof that rendered UI is correct.
- Preserve live GitHub setup, repo selection, release context, Share export safety, and Settings diagnostics.
- Do not broaden into Growth/Share/Settings redesign until the Activity hero/detail split is proven.
- If CI is red, classify the failure before merging UX work; document whether it is pre-existing, unrelated, or caused by this goal.
- Keep detail navigation discoverable and reversible.

## Stop Rule

Stop only when a final audit proves the full original outcome is complete.

Do not stop after planning, discovery, or Judge selection if a safe Worker task can be activated.

Do not stop after a single verified Worker package when the broader owner outcome still has safe local follow-up work. Advance the board to the next highest-leverage safe Worker package and continue unless a phase, risk, rejected-verification, ambiguity, or final-completion review is due.

## Slice Sizing

Safe means bounded, explicit, verified, and reversible. It does not mean tiny.

A good task is the largest safe useful slice: for this goal, likely a vertical Activity slice that changes main-screen hierarchy, creates or refactors the Work Log/detail route, updates tests, and proves the rendered simulator state.

## Canonical Board

Machine truth lives at:

`Docs/goals/activity-hero-detail-split/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow Docs/goals/activity-hero-detail-split/goal.md.
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

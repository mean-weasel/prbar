# PostHog Dashboard Axis Fidelity

## Objective

Make future PostHog dashboard imports preserve and render explicit x/y axis labels, units, and chart-shape metadata instead of only showing generated scales for the current Bleep KPI dashboard.

## Original Request

Make a detailed plan to ensure future dashboards import with their proper x/y axis labels, using a queue of GoalBuddy Prep boards so this can run autonomously overnight.

## Intake Summary

- Input shape: `specific`
- Audience: PRBar iOS users who want PostHog dashboard cards in Growth to match the source dashboard closely enough to trust labels, units, and chart meaning.
- Authority: `requested`
- Proof type: `test`
- Completion proof: a merged PR, green post-merge CI/iOS, and physical production iPhone Growth smoke proving exact imported axis labels render for a representative PostHog dashboard fixture and the configured live dashboard.
- Goal oracle: exact-label fidelity for PostHog dashboard imports. At minimum, a fixture dashboard with custom x/y labels must round-trip through the importer into the Growth model, render visible/accessibility x/y labels, pass simulator UI tests, and pass live-device smoke after install.
- Likely misfire: the goal could add generic y-axis ticks again while still failing to preserve PostHog-provided axis titles, units, chart type, or unsupported-tile diagnostics.
- Blind spots considered:
  - PostHog may expose axis labels in insight `filters`, display config, query metadata, or result metadata; Scout must verify the true response shape before Worker edits.
  - Some PostHog chart types may not have meaningful axis labels or may not map to our current bar chart.
  - A generic importer may be too broad for one night; the first safe tranche should support trend-style dashboard tiles and explicitly mark unsupported shapes.
  - Exact visual parity with PostHog is not the same as mobile-appropriate fidelity. The target is semantic chart fidelity: title, x-axis label, y-axis label, unit, date labels, scale, and unsupported diagnostics.
  - Production proof should follow repo instructions: attempt automated visual/device inspection first and use physical-device smoke receipts before asking for manual verification.
- Existing plan facts:
  - PR #131 added visible y-axis ticks/gridlines and production smoke coverage for the current Growth chart.
  - Current implementation is reliable for the Bleep KPI dashboard having a y-axis, but not yet for arbitrary dashboard axis-title preservation.
  - The next work should add model/import/render/test support for exact x/y labels.

## Goal Oracle

The oracle for this goal is:

`A representative PostHog dashboard fixture with explicit x-axis and y-axis labels imports into PRBar, renders those exact labels in the iOS Growth chart, exposes them in accessibility metadata, passes unit and UI tests, and the merged production build passes a physical iPhone Growth smoke run against the configured live dashboard without losing axis metadata.`

The PM must keep comparing task receipts to this oracle. Planning, discovery, generated tick labels, or a single passing fixture without render verification is not enough. The goal finishes only when a final Judge/PM audit maps receipts and verification back to this oracle and records `full_outcome_complete: true`.

## Goal Kind

`specific`

## Current Tranche

Complete one overnight implementation tranche:

1. Scout the actual PostHog dashboard/insight response shape for axis labels, units, chart type, and display config.
2. Judge the smallest durable model contract for chart axis metadata.
3. Implement importer/model support for x/y labels and units for trend-style dashboard tiles.
4. Render axis titles in SwiftUI and expose them through accessibility.
5. Add deterministic fixture/unit/UI tests proving exact labels survive import and render.
6. Run local verification, open/merge a PR, monitor post-merge checks, install on production iPhone, and run the physical Growth smoke.

Do not try to perfectly support every PostHog chart type in one tranche. Unsupported chart types should produce explicit diagnostics instead of silently rendering misleading charts.

## Non-Negotiable Constraints

- Use existing repo patterns and SwiftUI style.
- Keep the first implementation tranche focused on PostHog dashboard axis-label fidelity.
- Do not redesign the Growth tab broadly.
- Do not add new backend infrastructure.
- Do not assume GitHub Actions environment variables exist at app runtime; verify plist/config propagation when relevant.
- Before asking the user to visually verify iOS UI, first attempt automation or device/workflow screenshot/artifact inspection and report blockers.
- Preserve production/private-data safety. Do not log PostHog secrets.
- If PostHog API shape is ambiguous, add a Scout/Judge receipt and continue with fixture-backed local work rather than guessing silently.

## Queue Of GoalBuddy Work

This board is the primary overnight queue. It intentionally uses one canonical GoalBuddy board with ordered Scout/Judge/Worker tasks instead of disconnected boards, so a single `/goal` command can continue autonomously while preserving one active task and durable receipts.

Phase queue:

- Board 1 / Discovery: PostHog dashboard axis schema scout.
- Board 2 / Contract: model/import contract judge.
- Board 3 / Implementation: importer and model Worker.
- Board 4 / Rendering: SwiftUI axis-label Worker.
- Board 5 / Verification: deterministic tests plus simulator visual proof.
- Board 6 / Delivery: PR, merge queue, production install, physical Growth smoke.
- Board 7 / Audit: final Judge proof against the oracle.

## Stop Rule

Stop only when a final audit proves the full original outcome is complete.

Do not stop after planning, discovery, or Judge selection if a safe Worker task can be activated.

Do not stop after adding model support if the UI still does not render labels. Do not stop after rendering fixture labels if live/PostHog dashboard import proof is missing. Do not stop after CI if the production iPhone smoke has not been attempted or a blocker has not been recorded.

## Slice Sizing

Safe means bounded, explicit, verified, and reversible. It does not mean tiny.

The largest safe slice for this goal is a complete semantic-fidelity path for trend-style PostHog dashboard tiles: decode/derive metadata, carry it through the Growth model, render it, test it, and verify it on device.

## Canonical Board

Machine truth lives at:

`Docs/goals/posthog-dashboard-axis-fidelity/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow Docs/goals/posthog-dashboard-axis-fidelity/goal.md.
```

## PM Loop

On every `/goal` continuation:

1. Read this charter.
2. Read `state.yaml`.
3. Run the bundled GoalBuddy update checker when available and mention a newer version without blocking.
4. Re-check the intake, oracle, likely misfire, and non-negotiable constraints.
5. Work only on the active board task.
6. Assign Scout, Judge, Worker, or PM according to the task.
7. Write a compact task receipt.
8. Update the board.
9. If safe local work remains, choose the next largest reversible Worker package and continue unless blocked.
10. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the original user outcome and records `full_outcome_complete: true`.

# iOS Production Device Install

## Objective

Create a safe, repeatable production-iPhone install and smoke path for the actual PRBar iOS app, separate from the preview-device test channel.

## Original Request

Plan out, using GoalBuddy Prep, whether we are ready to create a different version for the production device after proving the preview iOS device path.

## Intake Summary

- Input shape: `specific`
- Audience: PRBar maintainer and production-device release/test operator
- Authority: `requested`
- Proof type: `test`
- Completion proof: A workflow or documented command can build and install the non-preview `PRBar` app on the production iPhone, prove the installed app uses the production bundle id rather than the preview bundle id, and run at least a minimal launch/auth-readiness smoke without disturbing the preview workflow.
- Goal oracle: A production-device install/smoke receipt that names the workflow run or local device command, the resolved production iPhone, the `PRBar` scheme, the `com.neonwatty.PRBar.ios` bundle id, and the launch/smoke outcome.
- Likely misfire: Copying the preview workflow and still installing `PRBarPreview`, or proving only that a build succeeded while the production phone did not receive the production app.
- Blind spots considered: side-by-side preview/production apps, GitHub OAuth app client configuration, signing and provisioning profile differences, runner labels and phone selection, accidental destructive uninstall of the user's day-to-day app state, and whether production smoke should use real user auth or only launch/readiness checks.
- Existing plan facts: The preview path uses `PRBarPreview` and `com.neonwatty.PRBar.ios.preview`; the production target/scheme exists as `PRBar` with bundle id `com.neonwatty.PRBar.ios`; the production phone should be distinct from `iPhone-preview` by device name or runner selection.

## Goal Oracle

The oracle for this goal is:

`A repeatable install/smoke path installs the production PRBar iOS app, not PRBarPreview, on the production iPhone and reports a clear success or precise blocker for signing, runner/device selection, OAuth configuration, app launch, or device lock/trust state.`

The PM must keep comparing task receipts to this oracle. A green simulator CI run, a preview-device smoke pass, or a workflow that installs `com.neonwatty.PRBar.ios.preview` is not enough.

## Goal Kind

`specific`

## Current Tranche

First validate the exact production install shape, then implement the smallest repeatable production install workflow and smoke script changes needed to prove the production app can be installed and launched on the production iPhone.

## Non-Negotiable Constraints

- Keep preview workflows and preview bundle behavior intact.
- Do not overwrite unrelated local changes in the current checkout.
- Do not uninstall or wipe production app data unless the user explicitly approves it.
- Do not log GitHub tokens, OAuth secrets, device codes, or private account details.
- Production install must target `PRBar` and `com.neonwatty.PRBar.ios`, not `PRBarPreview`.
- Device selection must be explicit enough to avoid installing on the preview phone by accident.
- Signing/provisioning failures must be reported as blockers with concrete next actions.
- If GitHub OAuth needs a distinct callback/client setup for production, record that rather than hiding it behind a generic sign-in failure.

## Stop Rule

Stop only when a final audit proves the full original outcome is complete.

Do not stop after planning, discovery, or a successful build if the production phone install and production bundle proof are still missing.

Do not stop after an install-only pass if a safe launch smoke remains available and is required by the oracle.

## Slice Sizing

Safe means bounded, explicit, verified, and reversible. A good first implementation slice may include a production install workflow, shared script parameterization, and a minimal launch smoke if those changes are necessary to prove the production-device channel end to end.

## Canonical Board

Machine truth lives at:

`docs/goals/ios-production-device-install/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/ios-production-device-install/goal.md.
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

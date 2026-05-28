# Profile-Seeded Preview Testing Plan

## Decision

Yes, we can include setup for `neonwatty` plus a single repository in automated preview testing. We should do it in the physical-preview smoke workflow first, with explicit workflow inputs, and keep normal install workflows from changing repo selection by default.

## Why This Shape

- The preview-device smoke test is the right place to prove real GitHub behavior: auth state, repo selection, refresh, PR counts, and releases.
- The install workflow should stay boring: build, install, and launch. It should not silently pick repos or trigger GitHub API work.
- If we later need install-time seeding for operator convenience, make it opt-in and guarded by a required single-repo input.

## Test Setup Flow

1. Run the physical preview workflow with explicit inputs:
   - `device_name=iPhone-preview`
   - `smoke_profile=live`
   - `github_login=neonwatty`
   - `included_repo=mean-weasel/prbar`
2. The test launches the app in a live-smoke mode, not fixture mode.
3. The app/test harness clears any prior included-repo test state and seeds exactly the requested repo.
4. The test verifies the signed-in GitHub identity or reports a clear auth blocker.
5. The test opens repo selection and proves exactly one repo is selected.
6. The test triggers refresh and waits for a real completion state.
7. The test records whether PR/release evidence loaded, or whether the blocker is auth, device state, repo permission, rate limit, or another concrete failure.

## Install Flow Policy

Normal production or preview installs should not seed `neonwatty` or `mean-weasel/prbar` automatically.

An optional future install setup mode is acceptable only if:

- it is manually requested through workflow inputs;
- it requires a single explicit repo;
- it never defaults to all repos;
- it prints non-secret setup metadata only;
- it can be skipped without affecting normal install verification.

## Completion Oracle

The board is complete only when a physical `iPhone-preview` run proves:

- the app is authenticated as the expected GitHub account or reports missing auth clearly;
- exactly one configured repo is included;
- refresh runs after that selection;
- live PR/release data appears or a precise GitHub/device blocker is surfaced;
- fixture-mode UI tests and install-only workflow success are not counted as sufficient proof.

## Follow-Up Risks

- Persisted device auth can expire or disappear after reinstall; if that is too flaky, evaluate a least-privilege token path through GitHub Actions secrets.
- The implemented repeatable fallback should use `PRBAR_IOS_LIVE_GITHUB_TOKEN` as a GitHub Actions secret, pass it only to the physical app launch environment, save it only into the preview app Keychain on-device, and never echo the token in logs.
- Automation Mode and device lock states can fail before the app starts; preflight should fail early with the right diagnosis.
- Repo seeding must be test/preview scoped so it does not overwrite a user's real production repo choices.

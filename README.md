# PR Menu Bar

A macOS menu bar prototype for tracking pull request activity over a configurable time window.

The current repo foundation is intentionally small:

- SwiftUI menu bar app scaffolded with XcodeGen.
- Unit tests for the first domain model.
- CI checks for formatting, build, tests, app smoke, and Swift file size.
- `pr-chart-mobile.html` retained as scratchwork/reference input.

## Local Development

```bash
make generate
make test
make ci-local
```

`make app-smoke` builds the app in Release mode and verifies the bundle exists.

## Live GitHub Data

The app uses sample data by default. To run the current GitHub-backed provider path,
launch it with a personal access token in the environment:

```bash
PR_MENU_BAR_GITHUB_TOKEN=github_pat_xxx make run
```

The token needs repository read access for the repositories you want to track. Missing
or blank tokens keep the app on sample data. OAuth, keychain storage, signing,
notarization, and distribution are intentionally out of scope for this prototype.

The live provider currently discovers repositories with pull access, fetches merged pull
requests through GitHub Search, paginates high-volume result sets, and preserves the last
visible activity if a refresh fails.

## Guardrails

Swift files under `Sources` and `Tests` must stay at or below 300 lines. Split files before they become hard to review.

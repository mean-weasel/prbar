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

## Guardrails

Swift files under `Sources` and `Tests` must stay at or below 300 lines. Split files before they become hard to review.


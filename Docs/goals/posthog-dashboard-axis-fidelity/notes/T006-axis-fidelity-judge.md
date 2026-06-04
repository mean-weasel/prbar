# T006 Axis Fidelity Judge

## Decision

Approved for PR.

## Review

The implementation preserves PostHog-provided axis labels semantically instead of only adding UI text. The data path now decodes label metadata from both known PostHog shapes, stores it on `GrowthMetric`, preserves it through dashboard normalization and daily-series augmentation, and renders the exact strings visibly and through accessibility.

The review found one issue during verification: the x-axis title initially lived inside the horizontal chart scroll content, so the focused UI test could not find `Calendar day`. That was fixed by moving the title into the fixed chart card layout. The focused UI test and full iOS suite then passed.

## Approval Criteria

- Model contract: passed.
- PostHog importer contract: passed.
- Backward-compatible cached metric decoding: passed.
- Visible SwiftUI rendering: passed.
- Accessibility exact-label metadata: passed.
- Deterministic unit/UI tests: passed.
- Existing Growth and app UI smoke coverage: passed.

## Verification

- `git diff --check` passed.
- `./scripts/format-check.sh` passed.
- `IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh` passed: 134 tests, 0 failures.
- Focused Growth UI xcodebuild test passed after layout fix.
- `./scripts/ios-test.sh` passed: 134 unit tests and 26 UI tests, 2 live-credential tests skipped locally, 0 failures.

## Follow-Ups

- Live production smoke still belongs to T008 after PR merge because local live PostHog/GitHub UI tests skipped without workflow/runtime secrets.
- Broader chart visual parity beyond trend-style tiles should remain a later tranche.

# Iteration 1

## Summary

Imported the scratch PR activity data into the Swift app model and replaced the placeholder popover with a real menu bar view:

- Stacked activity chart for the selected window.
- Segmented window picker for 1 day, 1 week, 2 weeks, and 1 month.
- Repository inclusion checkboxes.
- Refresh button that updates the visible refresh timestamp.
- Tests for totals, excluded repos, and window-limited bucket aggregation.

## Verification

`make ci-local` passed.

The first run failed usefully:

- `swift-format --strict` caught mechanical style issues.
- A unit test caught an incorrect expected one-month bucket total; the correct scratch-data total is `288`.

## Judge Decision

Continue. Persisting repo selections and the selected time window is the next highest-value task because the app currently forgets user choices after relaunch.


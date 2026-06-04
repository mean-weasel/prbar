# T002 Judge Receipt: Axis Metadata Contract

## Result

approved

## Decision

Approve one vertical implementation package for trend-style PostHog dashboard axis fidelity.

The implementation should add a semantic chart metadata contract to `GrowthMetric`, decode PostHog axis metadata from both legacy filters and newer query/trends filter shapes, preserve metadata through daily-series augmentation, render labels in `GrowthTrendChartView`, and add deterministic unit/UI tests proving exact x/y labels survive import and render.

## Model Contract

Add a small optional metadata model rather than scattering UI-only strings:

- `GrowthMetricChartMetadata`
  - `kind`: `GrowthMetricChartKind`
  - `xAxisLabel`: `String?`
  - `yAxisLabel`: `String?`
  - `yAxisScale`: `GrowthMetricYAxisScale?`
  - `sourceInsightID`: `String?`
  - `sourceInsightName`: `String?`
  - `sourceDisplay`: `String?`
- `GrowthMetric.chartMetadata: GrowthMetricChartMetadata? = nil`

The fields must be optional and Codable-compatible so existing cached snapshots decode.

Add `GrowthMetricKind.custom` if needed so trend-style PostHog tiles beyond the current hard-coded Bleep names can still enter `visibleMetrics` without pretending to be visitors/pageviews.

## Import Contract

Decode enough PostHog insight metadata to support:

- legacy filter fields:
  - `filters.x_axis_label`
  - `filters.y_axis_label`
  - `filters.y_axis_scale_type`
  - `filters.display`
- newer query fields:
  - `query.trendsFilter.xAxisLabel`
  - `query.trendsFilter.yAxisLabel`
  - `query.trendsFilter.yAxisScaleType`
  - `query.trendsFilter.display`
  - nested `query.source.trendsFilter` if present

Prefer query/trends filter metadata over legacy filters when both exist. Normalize blank strings to nil.

## Supported Shapes

For this tranche, support trend-style dashboard tiles whose first result series has date-like `days` and numeric `data`.

Keep existing special handling for:

- `Weekly Visitors`
- `Daily Pageviews`
- `Traffic Sources`
- `Top Pages`

For future trend-style tiles with date/data series, create a custom PostHog metric instead of emitting an unsupported issue. For non-trend or empty-result tiles, preserve the existing explicit `GrowthDashboardIssue` behavior.

## Rendering Contract

Render imported labels only when present:

- x-axis label below the date ticks;
- y-axis label near the y-axis scale column;
- accessibility value includes exact `x-axis <label>` and `y-axis label <label>` fragments;
- existing numeric y-axis range metadata remains.

The UI must remain readable on iPhone widths. Keep typography compact.

## Allowed Files

- `apple/PRBarShared/GrowthModels.swift`
- `apple/PRBarShared/PostHogDashboardGrowthProvider.swift`
- `apple/PRBar/Growth/GrowthTrendChartView.swift`
- `apple/PRBar/PRBarApp.swift`
- `apple/PRBarTests/PostHogGrowthProviderTests.swift`
- `apple/PRBarTests/PRBarModelTests.swift`
- `apple/PRBarUITests/PRBarUITests.swift`
- `Docs/goals/posthog-dashboard-axis-fidelity/**`

## Verification

- `git diff --check`
- `IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh`
- focused UI tests for Growth fixture/dashboard axis label rendering with `xcodebuild test ... -only-testing:PRBarUITests/PRBarUITests/testGrowthTabRendersBleepPostHogDashboardExperiment`
- full `./scripts/ios-test.sh` before PR if focused tests pass

## Stop Conditions

- Decoding PostHog metadata requires fields not identified by Scout.
- Existing Growth cache decoding breaks.
- UI labels overlap or cannot be asserted reliably after two attempts.
- Need files outside the allowed list.

## Full Outcome

Not complete. Implementation, verification, PR, merge, production install, and production smoke are still required.

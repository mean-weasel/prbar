# T004 Axis Label Render Worker

## Result

Done.

## Summary

Rendered imported y-axis labels above the Growth trend chart and imported x-axis labels below the chart body in a fixed, visible location. The chart accessibility value now includes exact x/y label text alongside point count and y-axis range metadata.

An initial UI test run showed the x-axis label could be missed when it lived inside the horizontal chart scroll content. The label was moved into the fixed chart card layout, then the focused UI test passed.

## Evidence

- `apple/PRBar/Growth/GrowthTrendChartView.swift` renders `metric.chartMetadata?.yAxisLabel` and `metric.chartMetadata?.xAxisLabel`.
- `growth-y-axis-title` and `growth-x-axis-title` accessibility identifiers are present.
- The chart accessibility value includes `x-axis <label>` and `y-axis label <label>`.
- Existing y-axis ticks/gridlines remain in place.

## Verification

- First focused UI run failed because `Calendar day` was not visible.
- After layout fix, focused UI run passed:
  - `xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath apple/build -resultBundlePath apple/PostHogAxisFidelityUITest-2.xcresult CODE_SIGNING_ALLOWED=NO -only-testing:PRBarUITests/PRBarUITests/testGrowthTabRendersBleepPostHogDashboardExperiment`
- Full `./scripts/ios-test.sh` passed.

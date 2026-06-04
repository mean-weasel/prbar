# T005 Axis Label Tests Worker

## Result

Done.

## Summary

Added deterministic fixture-backed tests proving exact PostHog axis labels survive decoding, normalization, model storage, and SwiftUI rendering. The UI fixture now includes representative legacy and query/trends axis metadata so the Growth tab test fails if the chart regresses to unlabeled axes.

## Evidence

- `testPostHogDashboardRunResponseDecodesTrendAndBreakdownTiles` asserts decoded PostHog axis/display fields.
- `testBleepBlogDashboardNormalizerPreservesPostHogAxisLabels` asserts exact imported model labels, chart kind, y-axis scale, and source metadata.
- `testBleepBlogDashboardNormalizerCreatesCustomMetricForFutureTrendTile` asserts future trend-style tiles become custom Growth metrics with preserved labels.
- `testGrowthMetricChartMetadataIsOptionalForCachedSnapshots` asserts backward-compatible decoding.
- `testGrowthTabRendersBleepPostHogDashboardExperiment` asserts visible `Calendar day` / `Visitors` labels and chart accessibility metadata.

## Verification

- `IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh` passed: 134 tests, 0 failures.
- Focused Growth UI xcodebuild test passed.
- `./scripts/ios-test.sh` passed: 134 unit tests and 26 UI tests, 2 live-credential tests skipped locally, 0 failures.

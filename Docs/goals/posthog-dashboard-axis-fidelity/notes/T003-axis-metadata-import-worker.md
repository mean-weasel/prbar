# T003 Axis Metadata Import Worker

## Result

Done.

## Summary

Added optional semantic chart metadata to `GrowthMetric` so PostHog dashboard imports can carry exact x/y axis labels, chart kind, y-axis scale, and source insight information without breaking older cached snapshots. The PostHog dashboard importer now decodes both legacy filter fields (`x_axis_label`, `y_axis_label`, `y_axis_scale_type`) and newer query/trends fields (`xAxisLabel`, `yAxisLabel`, `yAxisScaleType`), preserving metadata through daily-series augmentation.

The Bleep dashboard path still maps known KPI tiles, while future date-series trend tiles can become `.custom` Growth metrics instead of being silently dropped as unsupported. Non-trend or ambiguous shapes remain surfaced as dashboard issues.

## Evidence

- `apple/PRBarShared/GrowthModels.swift` adds optional `chartMetadata` with axis labels, chart kind, scale, and source fields.
- `apple/PRBarShared/PostHogDashboardGrowthProvider.swift` decodes legacy and query/trends metadata and attaches it to imported metrics.
- Daily-series augmentation preserves chart metadata while keeping existing headline-count behavior only where intended.
- `apple/PRBarTests/PRBarModelTests.swift` proves old cached Growth metric JSON still decodes with `chartMetadata == nil`.
- `apple/PRBarTests/PostHogGrowthProviderTests.swift` proves exact metadata round-trip for legacy filter and query/trends fixture shapes.

## Verification

- `IOS_TEST_ONLY=PRBarTests ./scripts/ios-test.sh` passed: 134 tests, 0 failures.
- `git diff --check` passed.
- `./scripts/format-check.sh` passed.

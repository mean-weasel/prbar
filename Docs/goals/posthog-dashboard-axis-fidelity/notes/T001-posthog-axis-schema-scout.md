# T001 Scout Receipt: PostHog Axis Schema

## Result

done

## Summary

The current app imports the configured PostHog dashboard through `PostHogDashboardGrowthProvider`, but it only decodes a narrow subset of each dashboard tile: tile `id`, `order`, insight `id`, `short_id`, `name`, `derived_name`, and result series fields `data`, `days`, `count`, `label`, and `breakdown_value`. The Growth model carries metric `title`, `unit`, and `series`, but has no explicit axis-title, chart-kind, source display, or scale metadata. The SwiftUI chart now renders generated y-axis ticks/gridlines, but not imported x/y axis titles.

PostHog source confirms axis labels are real insight configuration fields:

- legacy filter fields: `x_axis_label`, `y_axis_label`, `y_axis_scale_type`;
- query/trends filter fields: `xAxisLabel`, `yAxisLabel`, `yAxisScaleType`;
- Trends line/bar charts pass `trendsFilter?.xAxisLabel` and `trendsFilter?.yAxisLabel` into chart rendering.

No local `PRBAR_IOS_POSTHOG_*` environment variables were present, so live dashboard response capture was not available from this shell. The existing workflows do have PostHog secrets for physical smoke, but secrets are not retrievable for Scout. Use fixture-backed tests plus workflow smoke for the implementation tranche.

## Current App Evidence

- `apple/PRBarShared/GrowthModels.swift`: `GrowthMetric` contains `id`, `provider`, `kind`, `title`, `value`, `formattedValue`, `unit`, `delta`, and `series`; no axis-label metadata.
- `apple/PRBarShared/PostHogDashboardGrowthProvider.swift`: `PostHogDashboardInsight` decodes `id`, `short_id`, `name`, `derived_name`, and `result`; no `filters`, `query`, `trendsFilter`, `display`, or chart settings.
- `apple/PRBarShared/PostHogDashboardGrowthProvider.swift`: `PostHogDashboardSeries` decodes `data`, `days`, `count`, `label`, and `breakdown_value`.
- `apple/PRBarShared/PostHogDashboardGrowthProvider.swift`: `BleepBlogDashboardNormalizer` switches on hard-coded insight names: `Weekly Visitors`, `Daily Pageviews`, `Traffic Sources`, and `Top Pages`.
- `apple/PRBarShared/PostHogDashboardGrowthProvider.swift`: unsupported tile names become `GrowthDashboardIssue`; this is a good pattern to preserve for unsupported chart shapes.
- `apple/PRBar/Growth/GrowthTrendChartView.swift`: chart renders `metric.title`, generated date/day x tick labels, generated y tick labels, and accessibility value `N points, y-axis 0 to ...`; no imported axis-title rendering.
- `apple/PRBarUITests/PRBarUITests.swift`: current Growth UI tests assert y-axis range metadata but not exact imported x/y label text.

## PostHog Source Evidence

- `PostHog/posthog frontend/src/types.ts`: `TrendsFilterType` includes `x_axis_label?: string`, `y_axis_label?: string`, and `y_axis_scale_type?: 'log10' | 'linear'`.
- `PostHog/posthog frontend/src/queries/nodes/InsightQuery/utils/filtersToQueryNode.ts`: legacy filters map to `xAxisLabel: filters.x_axis_label`, `yAxisLabel: filters.y_axis_label`, and `yAxisScaleType: filters.y_axis_scale_type`.
- `PostHog/posthog frontend/src/queries/nodes/InsightQuery/utils/queryNodeToFilter.ts`: query nodes map back to `x_axis_label`, `y_axis_label`, and `y_axis_scale_type`.
- `PostHog/posthog products/product_analytics/frontend/insights/trends/TrendsLineChart/TrendsLineChart.tsx`: Trends chart rendering passes `xAxisLabel: trendsFilter?.xAxisLabel` and `yAxisLabel: trendsFilter?.yAxisLabel`.
- `PostHog/posthog frontend/src/queries/schema/schema-general.ts`: generated schema includes `ChartAxis`, chart settings `xAxis`, `yAxis`, and Trends filter `xAxisLabel`/`yAxisLabel`.
- `PostHog/posthog posthog/hogql_queries/legacy_compatibility/filter_to_query.py`: legacy filter conversion carries `xAxisLabel=filter.get("x_axis_label")`, `yAxisLabel=filter.get("y_axis_label")`, and `yAxisScaleType=filter.get("y_axis_scale_type")`.

## Candidate Fixture Shape

Use a dashboard run fixture where a trend insight includes both legacy and/or query filter metadata, for example:

- `insight.name`: `Weekly Visitors`
- `insight.filters.x_axis_label`: `Signup date`
- `insight.filters.y_axis_label`: `Unique visitors`
- `insight.filters.y_axis_scale_type`: `linear`
- `insight.filters.display`: `ActionsLineGraph` or equivalent trend display
- optionally `insight.query.trendsFilter.xAxisLabel`: `Signup date`
- optionally `insight.query.trendsFilter.yAxisLabel`: `Unique visitors`
- result series: existing `data`, `days`, `count`, `label`

The importer should support both legacy snake_case and newer camelCase query filter shapes, preferring explicit query/trends filter metadata when present and falling back to legacy filters.

## Recommended Judge Decision

Approve one vertical implementation package:

1. Add a small semantic metadata model to `GrowthMetric`, such as `chart: GrowthMetricChartMetadata?` or direct optional fields:
   - `xAxisTitle`
   - `yAxisTitle`
   - `yAxisScale`
   - `chartKind` or `display`
   - optional source insight id/name for diagnostics
2. Decode PostHog dashboard insight `filters` and `query.trendsFilter` fields needed for axis metadata.
3. Preserve backward-compatible `Codable` decoding for existing cached Growth snapshots.
4. Carry axis metadata through dashboard tile metrics and daily-series augmentation.
5. Render x/y axis titles in `GrowthTrendChartView` with accessibility identifiers.
6. Add unit and UI tests that fail on the current implementation:
   - exact imported model labels;
   - visible/accessibility chart labels;
   - old Bleep fixture still works;
   - unsupported tiles still produce issues.

## Risks

- Live dashboard exact labels could be absent if the current Bleep dashboard has no custom axis titles configured; the implementation should support labels when present and use sane defaults/fallbacks when absent.
- Not every PostHog chart type maps to a mobile trend chart. Unsupported chart display values should become explicit issues, not misleading charts.
- Persisted Growth dashboard cache may decode older metrics; optional fields and explicit default decoding are important.

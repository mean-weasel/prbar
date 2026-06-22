import SwiftUI

struct GrowthView: View {
  @Bindable var store: PRBarStore
  @State private var selectedMetricID: GrowthMetric.ID?

  private var snapshot: GrowthDashboardSnapshot {
    store.growthSnapshot
  }

  private var visibleMetrics: [GrowthMetric] {
    Array(snapshot.visibleMetrics.prefix(4))
  }

  private var selectedMetric: GrowthMetric? {
    if let selectedMetricID,
      let metric = visibleMetrics.first(where: { $0.id == selectedMetricID })
    {
      return metric
    }
    return snapshot.defaultMetric
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: PRBarTheme.sectionSpacing) {
          header

          RangePickerView(selection: growthRangeBinding)

          if let issue = store.growthRefreshIssue {
            issueView(issue)
          }

          metricTiles

          if let selectedMetric {
            GrowthTrendChartView(
              metric: selectedMetric,
              range: store.growthRange,
              anchorDate: snapshot.anchorDate
            )
          }

          growthDetailsEntry
        }
        .padding()
        .padding(.bottom, PRBarTheme.tabContentBottomPadding)
      }
      .refreshable {
        await store.refreshGrowth()
      }
      .navigationTitle("Growth")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            Task { await store.refreshGrowth() }
          } label: {
            Label("Refresh PostHog growth", systemImage: "arrow.clockwise")
          }
          .disabled(store.isRefreshingGrowth)
        }
      }
      .task {
        selectedMetricID = selectedMetricID ?? snapshot.defaultMetric?.id
        await store.refreshGrowthIfNeeded()
      }
      .onChange(of: snapshot.defaultMetric?.id) { _, defaultMetricID in
        guard selectedMetricID == nil || selectedMetric == nil else {
          return
        }
        selectedMetricID = defaultMetricID
      }
    }
  }

  private var growthRangeBinding: Binding<ActivityRange> {
    Binding(
      get: { store.growthRange },
      set: { range in
        store.setGrowthRange(range)
        Task { await store.refreshGrowth() }
      }
    )
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Usage and search movement near shipped work")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Text(growthOverviewSummary)
        .font(.title3.weight(.bold))
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var growthOverviewSummary: String {
    guard let selectedMetric else {
      return "\(store.growthRange.windowLabel) movement across connected growth metrics."
    }

    if let delta = selectedMetric.delta {
      return "\(selectedMetric.title) is \(delta.formattedValue) over the \(store.growthRange.windowLabel.lowercased())."
    }

    return "\(selectedMetric.title) is \(selectedMetric.formattedValue) over the \(store.growthRange.windowLabel.lowercased())."
  }

  private var growthDetailsEntry: some View {
    NavigationLink {
      GrowthDetailsView(
        snapshot: snapshot,
        range: store.growthRange,
        refreshStatus: store.growthRefreshStatus
      )
    } label: {
      HStack(alignment: .center, spacing: 12) {
        Image(systemName: "doc.text.magnifyingglass")
          .font(.headline.weight(.semibold))
          .foregroundStyle(PRBarTheme.accent)
          .frame(width: 34, height: 34)
          .background(PRBarTheme.accent.opacity(0.10))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        VStack(alignment: .leading, spacing: 4) {
          Text("Growth details")
            .font(.headline)
            .foregroundStyle(.primary)

          Text("\(store.growthRange.windowLabel) source, dashboard, and shipping context.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 8)

        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(14)
      .background(Color(.secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("growth-details-entry")
  }

  private var metricTiles: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PRBarTheme.compactSpacing) {
      ForEach(visibleMetrics) { metric in
        Button {
          selectedMetricID = metric.id
        } label: {
          GrowthMetricTileView(metric: metric, isSelected: selectedMetric?.id == metric.id)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private func issueView(_ issue: AuthIssue) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(issue.title)
        .font(.headline)
      Text(issue.message)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Color.orange.opacity(0.14))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}

#Preview {
  GrowthView(store: .sample())
}

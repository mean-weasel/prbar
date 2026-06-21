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

          growthDetailsEntry

          if let selectedMetric {
            GrowthTrendChartView(
              metric: selectedMetric,
              range: store.growthRange,
              anchorDate: snapshot.anchorDate
            )
          }
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
    VStack(alignment: .leading, spacing: PRBarTheme.compactSpacing) {
      Text("Usage and search movement near shipped work")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      HStack(spacing: PRBarTheme.compactSpacing) {
        Label(snapshot.project.name, systemImage: "square.stack.3d.up")
          .font(.subheadline.weight(.semibold))

        Spacer()

        Label(
          snapshot.dataSource.displayName,
          systemImage: dataSourceSymbol(for: snapshot.dataSource)
        )
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(dataSourceBadgeColor(for: snapshot.dataSource))
        .clipShape(Capsule())
        .accessibilityHint(snapshot.dataSource.detail)
      }

      HStack(spacing: PRBarTheme.compactSpacing) {
        ForEach(snapshot.connections) { connection in
          Text(connection.provider.displayName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(connectionBadgeColor(for: connection.status))
            .clipShape(Capsule())
        }
      }
    }
  }

  private var growthDetailsEntry: some View {
    NavigationLink {
      GrowthDetailsView(
        snapshot: snapshot,
        range: store.growthRange,
        refreshStatus: store.growthRefreshStatus
      )
    } label: {
      HStack(alignment: .center, spacing: 10) {
        Image(systemName: dataSourceSymbol(for: snapshot.dataSource))
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(dataSourceIconColor(for: snapshot.dataSource))
          .frame(width: 24, height: 24)

        VStack(alignment: .leading, spacing: 2) {
          Text("Growth details")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
          Text("\(store.growthRange.windowLabel) / \(snapshot.dataSource.displayName)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
        }

        Spacer(minLength: 8)

        Text(growthUpdatedLabel)
          .font(.caption.weight(.semibold))
          .foregroundStyle(store.growthRefreshStatus.isFailed ? .orange : .secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.82)

        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(PRBarTheme.surfaceBackground)
      .clipShape(RoundedRectangle(cornerRadius: PRBarTheme.surfaceCornerRadius, style: .continuous))
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

  private var growthUpdatedLabel: String {
    switch store.growthRefreshStatus {
    case .loaded(let lastRefreshedAt, _):
      refreshDateLabel(for: lastRefreshedAt)
    case .loading:
      "Refreshing now"
    case .failed:
      "Refresh failed"
    case .idle:
      connectionRefreshLabel ?? "Not refreshed yet"
    }
  }

  private var connectionRefreshLabel: String? {
    snapshot.connections
      .compactMap(\.lastRefreshedAt)
      .max()
      .map { refreshDateLabel(for: $0) }
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

  private func connectionBadgeColor(for status: GrowthConnectionStatus) -> Color {
    switch status {
    case .connected, .refreshing:
      Color.green.opacity(0.14)
    case .notConnected, .needsAttention:
      Color.orange.opacity(0.14)
    }
  }

  private func dataSourceSymbol(for source: GrowthDataSource) -> String {
    switch source {
    case .sample:
      "sparkles"
    case .livePostHog:
      "dot.radiowaves.left.and.right"
    case .sampleFallback:
      "exclamationmark.triangle"
    }
  }

  private func dataSourceBadgeColor(for source: GrowthDataSource) -> Color {
    switch source {
    case .sample:
      Color.blue.opacity(0.14)
    case .livePostHog:
      Color.green.opacity(0.14)
    case .sampleFallback:
      Color.orange.opacity(0.14)
    }
  }

  private func dataSourceIconColor(for source: GrowthDataSource) -> Color {
    switch source {
    case .sample:
      PRBarTheme.accent
    case .livePostHog:
      .green
    case .sampleFallback:
      .orange
    }
  }

  private func refreshDateLabel(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

private extension GrowthRefreshStatus {
  var isFailed: Bool {
    if case .failed = self {
      return true
    }
    return false
  }
}

#Preview {
  GrowthView(store: .sample())
}

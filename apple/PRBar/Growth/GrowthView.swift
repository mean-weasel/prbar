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
        VStack(alignment: .leading, spacing: 24) {
          header

          RangePickerView(selection: growthRangeBinding)

          growthProvenancePanel

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

          shippingContext

          providerSections

          setupCards
        }
        .padding()
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
    VStack(alignment: .leading, spacing: 12) {
      Text("Usage and search movement near shipped work")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      HStack(spacing: 8) {
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

      HStack(spacing: 8) {
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

  private var metricTiles: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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

  private var growthProvenancePanel: some View {
    HStack(alignment: .top, spacing: 10) {
      provenanceIcon
        .font(.subheadline.weight(.semibold))
        .frame(width: 20, height: 20)

      VStack(alignment: .leading, spacing: 8) {
        Text(growthProvenanceTitle)
          .font(.subheadline.weight(.semibold))

        Text(growthProvenanceDetail)
          .font(.caption)
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 4) {
          provenanceRow(title: "Project", value: snapshot.project.name)
          provenanceRow(title: "Source", value: snapshot.dataSource.displayName)
          provenanceRow(title: "Updated", value: growthUpdatedLabel)
        }
      }

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .accessibilityIdentifier("growth-provenance-status")
  }

  @ViewBuilder
  private var provenanceIcon: some View {
    switch store.growthRefreshStatus {
    case .loading:
      ProgressView()
    case .failed:
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
    case .loaded:
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(.green)
    case .idle:
      Image(systemName: dataSourceSymbol(for: snapshot.dataSource))
        .foregroundStyle(dataSourceIconColor(for: snapshot.dataSource))
    }
  }

  private func provenanceRow(title: String, value: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(width: 48, alignment: .leading)
      Text(value)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)
        .lineLimit(2)
        .minimumScaleFactor(0.82)
    }
  }

  private var growthProvenanceTitle: String {
    switch store.growthRefreshStatus {
    case .loading:
      "Refreshing Growth from PostHog"
    case .loaded:
      "Growth data refreshed"
    case .failed:
      "Growth refresh needs attention"
    case .idle:
      "Growth data source"
    }
  }

  private var growthProvenanceDetail: String {
    switch store.growthRefreshStatus {
    case .loading(let message):
      "\(message) Pull to refresh reloads only this Growth dashboard."
    case .loaded(_, let source):
      """
      Showing \(source.displayName) data for \(snapshot.project.name) over the \(store.growthRange.growthRefreshDescription). \
      Pull to refresh reloads this Growth dashboard.
      """
    case .failed(let message):
      "\(message) Existing Growth data remains visible."
    case .idle:
      "\(snapshot.dataSource.detail) Pull to refresh reloads this Growth dashboard."
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

  private var shippingContext: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Shipping context")
        .font(.headline)
      Text(snapshot.shippingContext.summary)
        .font(.subheadline)
      if let topRepositoryName = snapshot.shippingContext.topRepositoryName {
        Text("Top included repo: \(topRepositoryName)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  @ViewBuilder
  private var providerSections: some View {
    if snapshot.connection(for: .postHog)?.status == .connected {
      GrowthProviderSectionView(provider: .postHog, rows: postHogSectionRows)
    }

    if snapshot.connection(for: .searchConsole)?.status == .connected {
      GrowthProviderSectionView(
        provider: .searchConsole,
        rows: snapshot.topQueries + snapshot.topPages
      )

      Text("Search Console data can lag by a few days.")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var setupCards: some View {
    ForEach(GrowthProviderKind.allCases) { provider in
      if let connection = snapshot.connection(for: provider),
        connection.status == .notConnected || connection.status == .needsAttention
      {
        GrowthSetupCardView(provider: provider, issue: connection.issue)
      }
    }
  }

  private var postHogSectionRows: [GrowthListRow] {
    if snapshot.connection(for: .searchConsole)?.status == .connected {
      return snapshot.topEvents
    }
    return snapshot.topEvents + snapshot.topPages
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

#Preview {
  GrowthView(store: .sample())
}

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
      let metric = visibleMetrics.first(where: { $0.id == selectedMetricID }) {
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

          if let issue = store.growthRefreshIssue {
            issueView(issue)
          }

          metricTiles

          if let selectedMetric {
            GrowthTrendChartView(metric: selectedMetric, range: store.growthRange, anchorDate: snapshot.anchorDate)
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
            Label("Refresh growth", systemImage: "arrow.clockwise")
          }
          .disabled(store.isRefreshingGrowth)
        }
      }
      .task {
        selectedMetricID = selectedMetricID ?? snapshot.defaultMetric?.id
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
      VStack(alignment: .leading, spacing: 6) {
        Text("Growth")
          .font(.largeTitle.weight(.bold))
        Text("Usage and search movement near shipped work")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      HStack(spacing: 8) {
        Label(snapshot.project.name, systemImage: "square.stack.3d.up")
          .font(.subheadline.weight(.semibold))

        Spacer()

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
      GrowthProviderSectionView(provider: .postHog, rows: snapshot.topEvents)
    }

    if snapshot.connection(for: .searchConsole)?.status == .connected {
      GrowthProviderSectionView(provider: .searchConsole, rows: snapshot.topQueries + snapshot.topPages)

      Text("Search Console data can lag by a few days.")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var setupCards: some View {
    ForEach(GrowthProviderKind.allCases) { provider in
      if let connection = snapshot.connection(for: provider),
        connection.status == .notConnected || connection.status == .needsAttention {
        GrowthSetupCardView(provider: provider, issue: connection.issue)
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

  private func connectionBadgeColor(for status: GrowthConnectionStatus) -> Color {
    switch status {
    case .connected, .refreshing:
      Color.green.opacity(0.14)
    case .notConnected, .needsAttention:
      Color.orange.opacity(0.14)
    }
  }
}

#Preview {
  GrowthView(store: .sample())
}

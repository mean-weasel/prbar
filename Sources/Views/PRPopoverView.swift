import SwiftUI

struct PRPopoverView: View {
  @Binding var store: PRActivityStore
  var releaseStore: ReleaseMomentStore = ReleaseMomentStore(releases: [])
  var releaseRefreshState: ReleaseRefreshState = .idle
  var refreshError: String?
  var isRefreshing = false
  var dataSource: PRActivityDataSource = .sample
  var onRefresh: () -> Void
  @State private var selectedBucketIndex = Int.max
  @State private var selectedTab = PopoverTab.activity
  @State private var sharePayload: ShareCardPayload?
  @State private var isShareSheetPresented = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      if let refreshError {
        RefreshErrorView(message: refreshError)
      }
      tabs
    }
    .padding(18)
    .sheet(isPresented: $isShareSheetPresented) {
      if let sharePayload {
        ShareCardPreviewSheet(payload: sharePayload)
      }
    }
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("PR Activity")
          .font(.headline)
        HStack(spacing: 8) {
          Text(store.summaryText)
          Label(dataSource.title, systemImage: dataSource.systemImage)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      Spacer()
      Button {
        onRefresh()
      } label: {
        HStack(spacing: 6) {
          if isRefreshing {
            ProgressView()
              .controlSize(.small)
          }
          Text(isRefreshing ? "Refreshing" : "Refresh")
        }
      }
      .buttonStyle(.bordered)
      .disabled(isRefreshing)
    }
  }

  private var tabs: some View {
    TabView(selection: $selectedTab) {
      activityTab
        .tabItem {
          Label("Activity", systemImage: "chart.bar.xaxis")
        }
        .tag(PopoverTab.activity)
      ReleasesView(
        releaseStore: releaseStore,
        refreshState: releaseRefreshState,
        repositories: store.repositories,
        onEditRepos: { selectedTab = .settings },
        onShare: presentShareCard
      )
      .tabItem {
        Label("Releases", systemImage: "shippingbox")
      }
      .tag(PopoverTab.releases)
      PRSettingsView(store: $store, dataSource: dataSource)
        .tabItem {
          Label("Settings", systemImage: "gearshape")
        }
        .tag(PopoverTab.settings)
    }
    .frame(minHeight: 430)
  }

  private var activityTab: some View {
    VStack(alignment: .leading, spacing: 16) {
      summary
      if store.hasVisibleActivity {
        ActivityChartView(store: store, selectedBucketIndex: selectedBucketBinding)
        BucketDetailView(store: store, bucketIndex: safeSelectedBucketIndex)
      } else {
        EmptyActivityView {
          store.includeAllRepositories()
        }
      }
      Button("Share PR Card") {
        presentShareCard(.prActivity(ShareCardBuilder.prActivityPayload(store: store)))
      }
      .buttonStyle(.borderedProminent)
      .disabled(store.hasVisibleActivity == false)
      footer
    }
  }

  private func presentShareCard(_ payload: ShareCardPayload) {
    sharePayload = payload
    isShareSheetPresented = true
  }

  private var summary: some View {
    HStack(spacing: 12) {
      MetricTile(value: "\(store.totalPullRequests)", label: "merged")
      MetricTile(value: "\(store.activeRepositoryCount)", label: "repos")
      MetricTile(value: "\(store.window.dayCount)", label: "days")
    }
  }

  private var footer: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(refreshStatusText)
      Text("Last refreshed \(store.refreshedAt.formatted(date: .omitted, time: .shortened))")
      Text(nextRefreshText)
    }
    .font(.caption2)
    .foregroundStyle(.tertiary)
  }

  private var nextRefreshText: String {
    let policy = RefreshPolicy(interval: store.refreshInterval)
    guard let next = policy.nextRefreshDate(lastRefreshedAt: store.refreshedAt) else {
      return "Manual refresh only"
    }
    return "Next refresh after \(next.formatted(date: .omitted, time: .shortened))"
  }

  private var refreshStatusText: String {
    isRefreshing ? "Refresh in progress" : "Refresh ready"
  }

  private var safeSelectedBucketIndex: Int {
    min(selectedBucketIndex, max(store.visibleBucketLabels.count - 1, 0))
  }

  private var selectedBucketBinding: Binding<Int> {
    Binding(
      get: { safeSelectedBucketIndex },
      set: { selectedBucketIndex = $0 }
    )
  }
}

private enum PopoverTab {
  case activity
  case releases
  case settings
}

private struct MetricTile: View {
  var value: String
  var label: String

  var body: some View {
    VStack(spacing: 2) {
      Text(value)
        .font(.title3.monospacedDigit().weight(.semibold))
      Text(label)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct BucketDetailView: View {
  var store: PRActivityStore
  var bucketIndex: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(store.visibleBucketLabels[bucketIndex])
          .font(.caption.weight(.semibold))
        Spacer()
        Text("\(store.bucketTotals[bucketIndex]) merged")
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
      }

      ForEach(store.bucketBreakdown(at: bucketIndex).prefix(4)) { item in
        HStack(spacing: 8) {
          Circle()
            .fill(Color(hex: item.repository.colorHex))
            .frame(width: 7, height: 7)
          Text(item.repository.name)
            .font(.caption)
          Spacer()
          Text("\(item.value)")
            .font(.caption.monospacedDigit().weight(.medium))
        }
      }
    }
    .padding(10)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct EmptyActivityView: View {
  var onIncludeAll: () -> Void

  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: "chart.bar.xaxis")
        .font(.title2)
        .foregroundStyle(.secondary)
      Text("No PR activity in this view")
        .font(.subheadline.weight(.semibold))
      Text("Include repositories or choose a wider time window.")
        .font(.caption)
        .foregroundStyle(.secondary)
      Button("Include all repositories", action: onIncludeAll)
        .buttonStyle(.bordered)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 18)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct RefreshErrorView: View {
  var message: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle")
        .foregroundStyle(.orange)
      Text(message)
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
    }
    .padding(10)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
  }
}

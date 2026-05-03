import SwiftUI

struct PRPopoverView: View {
  @Binding var store: PRActivityStore
  @State private var selectedBucketIndex = 0

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      controls
      summary
      ActivityChartView(store: store, selectedBucketIndex: selectedBucketBinding)
      BucketDetailView(store: store, bucketIndex: safeSelectedBucketIndex)
      repositoryList
      footer
    }
    .padding(18)
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("PR Activity")
          .font(.headline)
        Text(store.summaryText)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button("Refresh") {
        store.refreshedAt = Date()
      }
      .buttonStyle(.bordered)
    }
  }

  private var controls: some View {
    Picker("Window", selection: $store.window) {
      ForEach(ActivityWindow.allCases) { window in
        Text(window.rawValue).tag(window)
      }
    }
    .pickerStyle(.segmented)
  }

  private var summary: some View {
    HStack(spacing: 12) {
      MetricTile(value: "\(store.totalPullRequests)", label: "merged")
      MetricTile(value: "\(store.activeRepositoryCount)", label: "repos")
      MetricTile(value: "\(store.window.dayCount)", label: "days")
    }
  }

  private var repositoryList: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Repositories")
        .font(.caption)
        .foregroundStyle(.secondary)
      ForEach($store.repositories) { $repository in
        RepositoryActivityRow(repository: $repository, window: store.window)
      }
    }
  }

  private var footer: some View {
    Text("Last refreshed \(store.refreshedAt.formatted(date: .omitted, time: .shortened))")
      .font(.caption2)
      .foregroundStyle(.tertiary)
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

private struct RepositoryActivityRow: View {
  @Binding var repository: RepositoryActivity
  var window: ActivityWindow

  var body: some View {
    Toggle(isOn: $repository.isIncluded) {
      HStack(spacing: 10) {
        RoundedRectangle(cornerRadius: 3)
          .fill(Color(hex: repository.colorHex))
          .frame(width: 10, height: 24)
        VStack(alignment: .leading, spacing: 2) {
          Text(repository.name)
            .font(.subheadline.weight(.medium))
          Text(repository.owner)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Text("\(repository.visibleTotal(for: window))")
          .font(.subheadline.monospacedDigit().weight(.semibold))
      }
    }
    .toggleStyle(.checkbox)
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

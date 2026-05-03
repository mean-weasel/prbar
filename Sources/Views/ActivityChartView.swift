import SwiftUI

struct ActivityChartView: View {
  var store: PRActivityStore
  @Binding var selectedBucketIndex: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Merged PRs")
        .font(.caption)
        .foregroundStyle(.secondary)

      ScrollViewReader { proxy in
        ScrollView(.horizontal) {
          HStack(alignment: .bottom, spacing: columnSpacing) {
            ForEach(Array(store.visibleBucketLabels.enumerated()), id: \.offset) { index, label in
              ActivityChartColumn(
                label: label,
                total: store.bucketTotals[index],
                maxTotal: store.maxBucketTotal,
                repositories: store.includedRepositories,
                bucketIndex: index,
                window: store.window,
                bin: store.bin,
                isSelected: selectedBucketIndex == index
              )
              .id(index)
              .frame(width: columnWidth)
              .contentShape(Rectangle())
              .help(helpText(for: index, label: label))
              .onTapGesture {
                selectedBucketIndex = index
              }
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
          scrollToMostRecent(proxy)
        }
        .onChange(of: store.window) { _, _ in
          scrollToMostRecent(proxy)
        }
        .onChange(of: store.bin) { _, _ in
          scrollToMostRecent(proxy)
        }
      }
      .frame(height: 150)
    }
  }

  private func scrollToMostRecent(_ proxy: ScrollViewProxy) {
    guard let lastIndex = store.visibleBucketLabels.indices.last else {
      return
    }
    DispatchQueue.main.async {
      selectedBucketIndex = lastIndex
      proxy.scrollTo(lastIndex, anchor: .trailing)
    }
  }

  private func helpText(for index: Int, label: String) -> String {
    let total = store.bucketTotals[index]
    let repositories = store.bucketBreakdown(at: index).prefix(3).map { item in
      "\(item.repository.name): \(item.value)"
    }

    guard repositories.isEmpty == false else {
      return "\(label): \(total) merged PRs"
    }
    return "\(label): \(total) merged PRs\n\(repositories.joined(separator: "\n"))"
  }

  private var columnSpacing: CGFloat {
    store.bin == .day ? 4 : 8
  }

  private var columnWidth: CGFloat {
    switch store.bin {
    case .day:
      return 28
    case .week:
      return 84
    case .month:
      return 140
    }
  }
}

private struct ActivityChartColumn: View {
  var label: String
  var total: Int
  var maxTotal: Int
  var repositories: [RepositoryActivity]
  var bucketIndex: Int
  var window: ActivityWindow
  var bin: ActivityBin
  var isSelected: Bool

  var body: some View {
    VStack(spacing: 4) {
      Text("\(total)")
        .font(.caption2.monospacedDigit())
        .foregroundStyle(.secondary)
      GeometryReader { proxy in
        VStack(spacing: 0) {
          Spacer(minLength: 0)
          VStack(spacing: 0) {
            ForEach(repositoriesWithValues.reversed()) { repository in
              Rectangle()
                .fill(Color(hex: repository.colorHex))
                .frame(height: segmentHeight(for: repository, in: proxy.size.height))
            }
          }
          .clipShape(RoundedRectangle(cornerRadius: 4))
        }
      }
      Text(label)
        .font(.caption2)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(4)
    .background(isSelected ? Color.primary.opacity(0.08) : Color.clear)
    .clipShape(RoundedRectangle(cornerRadius: 6))
  }

  private var repositoriesWithValues: [RepositoryActivity] {
    repositories.filter { $0.visibleCounts(for: window, bin: bin)[bucketIndex] > 0 }
  }

  private func segmentHeight(for repository: RepositoryActivity, in availableHeight: CGFloat)
    -> CGFloat
  {
    let value = repository.visibleCounts(for: window, bin: bin)[bucketIndex]
    return CGFloat(value) / CGFloat(maxTotal) * max(availableHeight - 28, 1)
  }
}

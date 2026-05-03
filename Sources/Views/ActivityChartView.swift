import SwiftUI

struct ActivityChartView: View {
  var store: PRActivityStore
  @Binding var selectedBucketIndex: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Merged PRs")
        .font(.caption)
        .foregroundStyle(.secondary)

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
            .frame(width: columnWidth)
            .contentShape(Rectangle())
            .onTapGesture {
              selectedBucketIndex = index
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(height: 150)
    }
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

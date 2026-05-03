import SwiftUI

struct ActivityChartView: View {
  var store: PRActivityStore

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Merged PRs")
        .font(.caption)
        .foregroundStyle(.secondary)

      HStack(alignment: .bottom, spacing: 8) {
        ForEach(Array(store.visibleBucketLabels.enumerated()), id: \.offset) { index, label in
          ActivityChartColumn(
            label: label,
            total: store.bucketTotals[index],
            maxTotal: store.maxBucketTotal,
            repositories: store.includedRepositories,
            bucketIndex: index,
            window: store.window
          )
        }
      }
      .frame(height: 150)
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
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }

  private var repositoriesWithValues: [RepositoryActivity] {
    repositories.filter { $0.visibleCounts(for: window)[bucketIndex] > 0 }
  }

  private func segmentHeight(for repository: RepositoryActivity, in availableHeight: CGFloat)
    -> CGFloat
  {
    let value = repository.visibleCounts(for: window)[bucketIndex]
    return CGFloat(value) / CGFloat(maxTotal) * max(availableHeight - 28, 1)
  }
}

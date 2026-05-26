import SwiftUI

struct ActivityChartView: View {
  var store: PRActivityStore
  @Binding var selectedBucketIndex: Int
  @State private var hoveredBucketIndex: Int?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Merged PRs")
        .font(.caption)
        .foregroundStyle(.secondary)

      ZStack(alignment: .topTrailing) {
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
                .onHover { isHovering in
                  hoveredBucketIndex = isHovering ? index : nil
                }
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
            hoveredBucketIndex = nil
            scrollToMostRecent(proxy)
          }
          .onChange(of: store.bin) { _, _ in
            hoveredBucketIndex = nil
            scrollToMostRecent(proxy)
          }
        }

        if let text = hoveredTooltipText {
          ChartTooltip(text: text)
            .padding(.top, 2)
            .padding(.trailing, 2)
            .allowsHitTesting(false)
            .transition(.opacity)
            .zIndex(1)
        }
      }
      .frame(height: 200)
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

  private var hoveredTooltipText: String? {
    guard let hoveredBucketIndex,
      store.visibleBucketLabels.indices.contains(hoveredBucketIndex)
    else {
      return nil
    }
    return helpText(
      for: hoveredBucketIndex,
      label: store.visibleBucketLabels[hoveredBucketIndex]
    )
  }

  private var columnSpacing: CGFloat {
    store.bin == .day ? 6 : 12
  }

  private var columnWidth: CGFloat {
    switch store.bin {
    case .day:
      return 34
    case .week:
      return 98
    case .month:
      return 162
    }
  }
}

private struct ChartTooltip: View {
  var text: String

  var body: some View {
    Text(text)
      .font(.caption2.monospacedDigit())
      .foregroundStyle(.primary)
      .multilineTextAlignment(.leading)
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(Color.primary.opacity(0.12))
      )
      .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
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
    VStack(spacing: 6) {
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
    .padding(5)
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

import SwiftUI

struct WorkCardView: View {
  var source: WorkCardRenderer.CardSource
  var draft: WorkCardDraft

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Public side")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)

        Text(metric)
          .font(.system(.largeTitle, design: .rounded).weight(.bold))
          .minimumScaleFactor(0.8)

        Text(source.caption)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      HStack(alignment: .bottom, spacing: 8) {
        ForEach(Array(barHeights.enumerated()), id: \.offset) { index, height in
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(PRBarTheme.chartPalette[index % PRBarTheme.chartPalette.count].gradient)
            .frame(height: height)
        }
      }
      .frame(height: 86, alignment: .bottom)
      .accessibilityLabel("Card distribution chart")

      HStack(alignment: .firstTextBaseline) {
        Text(draft.showHandle ? "@neonwatty" : "handle hidden")
        Spacer(minLength: 12)
        Text(repoLine)
          .lineLimit(1)
      }
      .font(.caption.weight(.semibold))
      .foregroundStyle(.secondary)
    }
    .padding(18)
    .frame(maxWidth: .infinity, minHeight: 260, alignment: .leading)
    .background(cardBackground)
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(Color(.separator).opacity(0.4))
    )
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private var metric: String {
    if draft.exactCounts {
      return source.metric
    }

    return source.type == .activity ? "many merged" : source.metric
  }

  private var repoLine: String {
    guard draft.showRepos else {
      return "repos hidden"
    }

    return source.repoNames.isEmpty ? "selected repos" : source.repoNames.joined(separator: " · ")
  }

  private var barHeights: [CGFloat] {
    [28, 54, 40, 70, 50, 82]
  }

  private var cardBackground: Color {
    switch draft.theme {
    case .clean:
      Color(.systemBackground)
    case .terminal:
      Color(.secondarySystemBackground)
    case .launch:
      Color.blue.opacity(0.10)
    case .hype:
      Color.pink.opacity(0.10)
    case .minimal:
      Color(.tertiarySystemBackground)
    }
  }
}

#Preview {
  WorkCardView(source: WorkCardRenderer.source(for: PRBarStore.sample()), draft: PRBarStore.sample().cardDraft)
    .padding()
}

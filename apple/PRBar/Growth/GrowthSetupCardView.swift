import SwiftUI

struct GrowthSetupCardView: View {
  var provider: GrowthProviderKind
  var issue: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(title, systemImage: provider == .postHog ? "chart.xyaxis.line" : "magnifyingglass")
        .font(.headline)

      Text(detail)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      if let issue {
        Text(issue)
          .font(.caption)
          .foregroundStyle(.orange)
      }

      Button(action: {}) {
        Text(actionTitle)
          .font(.subheadline.weight(.semibold))
      }
      .buttonStyle(.bordered)
      .disabled(true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private var title: String {
    "Connect \(provider.displayName)"
  }

  private var detail: String {
    switch provider {
    case .postHog:
      "Track active users, key events, and conversion movement."
    case .searchConsole:
      "Track search clicks, impressions, CTR, and top queries."
    }
  }

  private var actionTitle: String {
    switch provider {
    case .postHog: "Add PostHog"
    case .searchConsole: "Add Search Console"
    }
  }
}

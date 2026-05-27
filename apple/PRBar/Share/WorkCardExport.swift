import SwiftUI
import UIKit

struct WorkCardExport: Equatable {
  var side: CardSide
  var source: WorkCardRenderer.CardSource
  var draft: WorkCardDraft
  var evidence: [WorkCardRenderer.EvidenceItem]
  var caption: String
  var provenance: String
  var freshness: String
  var privacyMessage: String
  var includesPrivateEvidence: Bool

  var sideLabel: String {
    side == .publicSide ? "Public side" : "Evidence side"
  }
}

enum WorkCardExportBuilder {
  static func export(for store: PRBarStore, side: CardSide? = nil) -> WorkCardExport {
    var draft = store.cardDraft
    if let side {
      draft.side = side
    }

    let source = WorkCardRenderer.source(for: store)
    let evidence = WorkCardRenderer.evidence(for: store)
    let includesPrivateEvidence = evidence.contains(where: \.isPrivate) || store.cardHasPrivateEvidence
    let freshness = freshnessLabel(for: store)
    let privacyMessage = privacyMessage(
      includesPrivateEvidence: includesPrivateEvidence,
      draft: draft
    )

    return WorkCardExport(
      side: draft.side,
      source: source,
      draft: draft,
      evidence: evidence,
      caption: caption(source: source, freshness: freshness, draft: draft),
      provenance: provenance(source: source, store: store),
      freshness: freshness,
      privacyMessage: privacyMessage,
      includesPrivateEvidence: includesPrivateEvidence
    )
  }

  private static func caption(
    source: WorkCardRenderer.CardSource,
    freshness: String,
    draft: WorkCardDraft
  ) -> String {
    let repoText = draft.showRepos && source.repoNames.isEmpty == false
      ? " Repos: \(source.repoNames.joined(separator: ", "))."
      : ""
    return "\(source.metric) via PRBar. \(source.caption). \(freshness).\(repoText)"
  }

  private static func provenance(
    source: WorkCardRenderer.CardSource,
    store: PRBarStore
  ) -> String {
    let repoCount = store.includedRepositories.count
    let repoLabel = repoCount == 1 ? "1 selected repo" : "\(repoCount) selected repos"
    return "\(source.captionKind) from \(repoLabel) · \(source.title)"
  }

  private static func privacyMessage(
    includesPrivateEvidence: Bool,
    draft: WorkCardDraft
  ) -> String {
    guard includesPrivateEvidence else {
      return "Only selected GitHub activity is included in this export."
    }

    if draft.showRepos || draft.exactCounts || draft.showPrivateLabels {
      return "Review carefully: this export may reveal private repo names, exact counts, PR titles, release notes, or private labels."
    }

    return "Private work is included, with repo names and exact counts hidden by your privacy defaults."
  }

  private static func freshnessLabel(for store: PRBarStore) -> String {
    if store.activityRefreshIssue != nil, let lastRefreshedAt = store.lastActivityRefreshAt {
      return "Cached GitHub data from \(dateLabel(for: lastRefreshedAt))"
    }

    if let lastRefreshedAt = store.lastActivityRefreshAt {
      return "Last refreshed \(dateLabel(for: lastRefreshedAt))"
    }

    return "Not refreshed yet"
  }

  private static func dateLabel(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

enum WorkCardImageRenderer {
  @MainActor
  static func image(for export: WorkCardExport) -> UIImage? {
    let content = WorkCardExportPreview(export: export)
      .frame(width: 360)
      .padding(16)
      .background(Color(.systemBackground))

    let renderer = ImageRenderer(content: content)
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage
  }
}

private struct WorkCardExportPreview: View {
  var export: WorkCardExport

  var body: some View {
    if export.side == .publicSide {
      WorkCardView(source: export.source, draft: export.draft)
    } else {
      WorkCardEvidenceView(
        source: export.source,
        draft: export.draft,
        evidence: export.evidence
      )
    }
  }
}

struct WorkCardActivityView: UIViewControllerRepresentable {
  var activityItems: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

import Foundation

enum ShareCardBuilder {
  static func prActivityPayload(store: PRActivityStore) -> PRShareCardPayload {
    let rangeLabel = rangeLabel(for: store.window)
    let repoRows = store.includedRepositories
      .map { repository in
        ShareCardRepoRow(
          id: repository.id,
          displayName: repository.shareDisplayName,
          count: repository.visibleTotal(for: store.window, bin: store.bin),
          colorHex: repository.colorHex
        )
      }
      .filter { $0.count > 0 }
      .sorted { lhs, rhs in
        if lhs.count == rhs.count {
          return lhs.displayName < rhs.displayName
        }
        return lhs.count > rhs.count
      }

    return PRShareCardPayload(
      headline: "\(store.totalPullRequests) merged PRs \(rangeLabel)",
      rangeLabel: rangeLabel,
      activeRepositoryCount: store.activeRepositoryCount,
      bucketTotals: store.bucketTotals,
      repoRows: repoRows
    )
  }

  static func releasePayload(
    release: ReleaseMoment,
    repository: RepositoryActivity?
  ) -> ReleaseShareCardPayload {
    ReleaseShareCardPayload(
      headline: "\(release.tag) \(release.title)",
      repositoryDisplayName: repository?.shareDisplayName ?? "Selected repo",
      dateLabel: release.date.formatted(date: .abbreviated, time: .omitted),
      notesExcerpt: release.notes,
      sourceLabel: release.source.shareCardSourceLabel
    )
  }

  private static func rangeLabel(for window: ActivityWindow) -> String {
    switch window {
    case .oneDay:
      return "today"
    case .oneWeek:
      return "this week"
    case .twoWeeks:
      return "these 2 weeks"
    case .oneMonth:
      return "this month"
    }
  }
}

extension RepositoryActivity {
  var shareDisplayName: String {
    isPrivate ? "Private repo" : name
  }
}

extension ReleaseMoment.Source {
  var shareCardSourceLabel: String {
    switch self {
    case .githubRelease:
      return "GitHub Release notes"
    case .tag:
      return "Tag-derived summary"
    }
  }
}

import Foundation

enum ShareCardBuilder {
  static func prActivityPayload(store: PRActivityStore) -> PRShareCardPayload {
    let rangeLabel = rangeLabel(for: store.window)
    let showPrivateNames = store.showPrivateRepositoryNamesInShare
    let repoRows = store.includedRepositories
      .map { repository in
        ShareCardRepoRow(
          id: repository.id,
          displayName: repository.shareDisplayName(revealingPrivateNames: showPrivateNames),
          count: store.visibleTotal(for: repository),
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
    let chartBuckets = store.visibleBucketLabels.indices.map { index in
      ShareCardBucket(
        id: "\(index)-\(store.visibleBucketLabels[index])",
        label: store.visibleBucketLabels[index],
        total: store.bucketTotals[index],
        segments: store.bucketBreakdown(at: index).map { item in
          ShareCardBucketSegment(
            id: item.repository.id,
            value: item.value,
            colorHex: item.repository.colorHex
          )
        }
      )
    }

    return PRShareCardPayload(
      headline: "\(store.totalPullRequests) merged PRs \(rangeLabel)",
      rangeLabel: rangeLabel,
      totalPullRequests: store.totalPullRequests,
      activeRepositoryCount: store.activeRepositoryCount,
      showsPrivateRepositoryNames: showPrivateNames,
      chartBuckets: chartBuckets,
      repoRows: repoRows
    )
  }

  static func releasePayload(
    release: ReleaseMoment,
    repository: RepositoryActivity?
  ) -> ReleaseShareCardPayload {
    releasePayload(
      release: release,
      repository: repository,
      revealingPrivateNames: false
    )
  }

  static func releasePayload(
    release: ReleaseMoment,
    repository: RepositoryActivity?,
    revealingPrivateNames: Bool
  ) -> ReleaseShareCardPayload {
    ReleaseShareCardPayload(
      headline: "\(release.tag) \(release.title)",
      repositoryDisplayName: repository?.shareDisplayName(
        revealingPrivateNames: revealingPrivateNames
      ) ?? "Selected repo",
      dateLabel: release.date.formatted(date: .abbreviated, time: .omitted),
      notesExcerpt: release.notes,
      sourceLabel: release.source.shareCardSourceLabel,
      showsPrivateRepositoryName: revealingPrivateNames && repository?.isPrivate == true
    )
  }

  private static func rangeLabel(for window: ActivityWindow) -> String {
    switch window {
    case .oneDay:
      return "today"
    case .oneWeek:
      return "past week"
    case .twoWeeks:
      return "past 2 weeks"
    case .oneMonth:
      return "past month"
    }
  }
}

extension RepositoryActivity {
  var shareDisplayName: String {
    shareDisplayName(revealingPrivateNames: false)
  }

  func shareDisplayName(revealingPrivateNames: Bool) -> String {
    isPrivate && revealingPrivateNames == false ? "Private repo" : name
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

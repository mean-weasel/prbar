import Foundation

enum WorkCardRenderer {
  struct CardSource: Equatable {
    enum SourceType: Equatable {
      case activity
      case release
    }

    var type: SourceType
    var title: String
    var metric: String
    var caption: String
    var captionKind: String
    var repoNames: [String]
    var notes: String
    var handle: String
  }

  struct EvidenceItem: Identifiable, Equatable {
    var id: String
    var title: String
    var detail: String
    var isPrivate: Bool
  }

  static func source(for store: PRBarStore) -> CardSource {
    switch store.cardDraft.source {
    case .shippingSnapshot:
      let pullRequests = pullRequestsInRange(for: store)
      let repoNames = uniqueRepoNames(for: pullRequests.map(\.repoID), in: store)

      return CardSource(
        type: .activity,
        title: "Shipping Snapshot · \(store.prRange.rawValue)",
        metric: "\(pullRequests.count) merged",
        caption: "Based on \(store.prRange.rawValue) merged PR activity from selected repositories",
        captionKind: "Progress recap",
        repoNames: repoNames,
        notes: "A visible proof-of-work snapshot from PRBar.",
        handle: handle(for: store)
      )

    case .releaseReceipt(let releaseID):
      let release = selectedRelease(for: store, draftReleaseID: releaseID)
      guard let release else {
        return CardSource(
          type: .release,
          title: "Release Receipt",
          metric: "Release",
          caption: "Based on GitHub Release notes from selected repositories",
          captionKind: "Launch note",
          repoNames: [],
          notes: "No release notes available.",
          handle: handle(for: store)
        )
      }

      let repository = repository(for: release.repoID, in: store)
      let sourceLabel = release.source == .tag ? "tag and PR activity" : "GitHub Release notes"

      return CardSource(
        type: .release,
        title: "Release Receipt · \(release.tag)",
        metric: release.tag,
        caption: "Based on \(sourceLabel) from \(repository?.name ?? release.repoID) on \(shortDateLabel(for: release.date))",
        captionKind: "Launch note",
        repoNames: [repository?.name ?? release.repoID],
        notes: release.notes,
        handle: handle(for: store)
      )
    }
  }

  static func evidence(for store: PRBarStore) -> [EvidenceItem] {
    switch store.cardDraft.source {
    case .shippingSnapshot:
      let pullRequestEvidence = pullRequestsInRange(for: store)
        .prefix(4)
        .compactMap { pullRequest -> EvidenceItem? in
          guard let repository = repository(for: pullRequest.repoID, in: store), repository.included else {
            return nil
          }

          return EvidenceItem(
            id: pullRequest.id,
            title: pullRequest.title,
            detail: "\(repository.name) #\(pullRequest.number)",
            isPrivate: repository.visibility == .private
          )
        }

      if pullRequestEvidence.isEmpty == false {
        return pullRequestEvidence
      }

      return Array(store.releases.prefix(4)).compactMap { release in
        guard let repository = repository(for: release.repoID, in: store), repository.included else {
          return nil
        }

        return EvidenceItem(
          id: release.id,
          title: "\(release.tag) \(release.title)",
          detail: repository.name,
          isPrivate: repository.visibility == .private
        )
      }

    case .releaseReceipt(let releaseID):
      guard let release = selectedRelease(for: store, draftReleaseID: releaseID) else {
        return []
      }

      let repository = repository(for: release.repoID, in: store)
      let releaseEvidence = EvidenceItem(
        id: release.id,
        title: "\(release.tag) \(repository?.name ?? release.repoID)",
        detail: release.notes,
        isPrivate: repository?.visibility == .private
      )

      let pullRequestEvidence = store.pullRequests
        .filter { $0.repoID == release.repoID }
        .prefix(3)
        .map { pullRequest in
          EvidenceItem(
            id: pullRequest.id,
            title: pullRequest.title,
            detail: "#\(pullRequest.number)",
            isPrivate: repository?.visibility == .private
          )
        }

      return [releaseEvidence] + pullRequestEvidence
    }
  }

  private static func pullRequestsInRange(for store: PRBarStore) -> [PullRequest] {
    let includedIDs = Set(store.includedRepositories.map(\.id))
    let startDate = CalendarDay.days(endingAt: store.activityAnchorDate, range: store.prRange).first?.date ?? store.activityAnchorDate

    return store.pullRequests.filter { pullRequest in
      includedIDs.contains(pullRequest.repoID) && pullRequest.mergedAt >= startDate
    }
  }

  private static func uniqueRepoNames(for repoIDs: [Repository.ID], in store: PRBarStore) -> [String] {
    var seen = Set<Repository.ID>()

    return repoIDs.compactMap { repoID in
      guard !seen.contains(repoID) else {
        return nil
      }

      seen.insert(repoID)
      return repository(for: repoID, in: store)?.name
    }
  }

  private static func repository(for id: Repository.ID, in store: PRBarStore) -> Repository? {
    store.repositories.first { $0.id == id }
  }

  private static func handle(for store: PRBarStore) -> String {
    guard let login = store.githubConnection.user?.login, login.isEmpty == false else {
      return "@github-user"
    }
    return "@\(login)"
  }

  private static func selectedRelease(for store: PRBarStore, draftReleaseID: ReleaseMoment.ID) -> ReleaseMoment? {
    store.releases.first { $0.id == draftReleaseID }
      ?? store.releases.first { $0.id == store.selectedReleaseID }
      ?? store.releases.first
  }

  private static func shortDateLabel(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
  }
}

import Foundation

extension GitHubPRActivityProvider {
  func mergedPullRequestsByRepository(
    owners: [GitHubSearchOwner],
    mergedBy: String,
    since: Date,
    until: Date,
    forceFullRefresh: Bool
  ) throws -> [String: [GitHubMergedPullRequest]] {
    let search = mergedPullRequestSearch(
      owners: owners,
      mergedBy: mergedBy,
      since: since,
      until: until,
      forceFullRefresh: forceFullRefresh
    )
    let metadata = [
      "owners": "\(owners.count)",
      "mode": search.mode.rawValue,
      "since": Self.metricDateString(search.since),
      "until": Self.metricDateString(search.until),
    ]

    return try measured("graphql.total", metadata: metadata) {
      var pullRequestsByID = search.cachedPullRequestsByID
      if search.mode.requiresNetwork {
        for owner in owners {
          for pullRequest in try mergedPullRequests(
            owner: owner,
            mergedBy: mergedBy,
            since: search.since,
            until: search.until
          ) {
            pullRequestsByID[pullRequest.id] = pullRequest
          }
        }
      }

      let currentPullRequestsByID = pullRequestsByID.filter { _, pullRequest in
        pullRequest.mergedAt >= since && pullRequest.mergedAt <= until
      }
      mergedPullRequestCache = GitHubMergedPullRequestCache(
        owners: owners,
        mergedBy: mergedBy,
        since: since,
        until: until,
        pullRequestsByID: currentPullRequestsByID
      )
      return Self.groupByRepository(currentPullRequestsByID.values)
    }
  }

  private func mergedPullRequestSearch(
    owners: [GitHubSearchOwner],
    mergedBy: String,
    since: Date,
    until: Date,
    forceFullRefresh: Bool
  ) -> GitHubMergedPullRequestSearch {
    guard
      forceFullRefresh == false,
      let cache = mergedPullRequestCache,
      cache.owners == owners,
      cache.mergedBy == mergedBy,
      since >= cache.since,
      until >= cache.until
    else {
      return GitHubMergedPullRequestSearch(
        mode: .full,
        since: since,
        until: until,
        cachedPullRequestsByID: [:]
      )
    }

    if until == cache.until {
      return GitHubMergedPullRequestSearch(
        mode: .cacheOnly,
        since: cache.until,
        until: until,
        cachedPullRequestsByID: cache.pullRequestsByID
      )
    }

    return GitHubMergedPullRequestSearch(
      mode: .incremental,
      since: cache.until,
      until: until,
      cachedPullRequestsByID: cache.pullRequestsByID
    )
  }

  private static func groupByRepository(
    _ pullRequests: Dictionary<String, GitHubMergedPullRequest>.Values
  ) -> [String: [GitHubMergedPullRequest]] {
    var grouped: [String: [GitHubMergedPullRequest]] = [:]
    for pullRequest in pullRequests {
      grouped[pullRequest.repositoryID, default: []].append(pullRequest)
    }
    return grouped
  }

  private static func metricDateString(_ date: Date) -> String {
    ISO8601DateFormatter.metric.string(from: date)
  }
}

struct GitHubMergedPullRequestCache {
  var owners: [GitHubSearchOwner]
  var mergedBy: String
  var since: Date
  var until: Date
  var pullRequestsByID: [String: GitHubMergedPullRequest]
}

private struct GitHubMergedPullRequestSearch {
  var mode: GitHubMergedPullRequestSearchMode
  var since: Date
  var until: Date
  var cachedPullRequestsByID: [String: GitHubMergedPullRequest]
}

private enum GitHubMergedPullRequestSearchMode: String {
  case full
  case incremental
  case cacheOnly = "cache_only"

  var requiresNetwork: Bool {
    self != .cacheOnly
  }
}

extension ISO8601DateFormatter {
  fileprivate static let metric: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }()
}

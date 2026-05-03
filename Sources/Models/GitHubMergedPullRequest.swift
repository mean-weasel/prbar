import Foundation

struct GitHubMergedPullRequestSearchResponse: Decodable, Equatable {
  var items: [GitHubMergedPullRequest]
}

struct GitHubMergedPullRequest: Decodable, Equatable {
  var title: String
  var mergedAt: Date

  private enum CodingKeys: String, CodingKey {
    case title
    case pullRequest = "pull_request"
  }

  private enum PullRequestKeys: String, CodingKey {
    case mergedAt = "merged_at"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    title = try container.decode(String.self, forKey: .title)
    let pullRequest = try container.nestedContainer(
      keyedBy: PullRequestKeys.self,
      forKey: .pullRequest
    )
    let mergedAtText = try pullRequest.decode(String.self, forKey: .mergedAt)
    guard let mergedAt = ISO8601DateFormatter.github.date(from: mergedAtText) else {
      throw DecodingError.dataCorruptedError(
        forKey: .mergedAt,
        in: pullRequest,
        debugDescription: "Invalid merged_at date"
      )
    }
    self.mergedAt = mergedAt
  }

  init(title: String, mergedAt: Date) {
    self.title = title
    self.mergedAt = mergedAt
  }
}

extension ISO8601DateFormatter {
  fileprivate static let github: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()
}

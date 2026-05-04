import Foundation

struct GitHubMergedPullRequestSearchResponse: Decodable, Equatable {
  var totalCount: Int
  var incompleteResults: Bool
  var items: [GitHubMergedPullRequest]

  func needsPagination(perPage: Int) -> Bool {
    totalCount > perPage
  }

  private enum CodingKeys: String, CodingKey {
    case totalCount = "total_count"
    case incompleteResults = "incomplete_results"
    case items
  }

  init(totalCount: Int, incompleteResults: Bool = false, items: [GitHubMergedPullRequest]) {
    self.totalCount = totalCount
    self.incompleteResults = incompleteResults
    self.items = items
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount) ?? 0
    incompleteResults =
      try container.decodeIfPresent(Bool.self, forKey: .incompleteResults) ?? false
    items = try container.decode([GitHubMergedPullRequest].self, forKey: .items)
  }
}

struct GitHubMergedPullRequest: Decodable, Equatable {
  var title: String
  var repositoryID: String
  var mergedAt: Date

  private enum CodingKeys: String, CodingKey {
    case title
    case repositoryURL = "repository_url"
    case pullRequest = "pull_request"
  }

  private enum PullRequestKeys: String, CodingKey {
    case mergedAt = "merged_at"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    title = try container.decode(String.self, forKey: .title)
    let repositoryURL = try container.decode(String.self, forKey: .repositoryURL)
    repositoryID = try Self.repositoryID(from: repositoryURL)
    let pullRequest = try container.nestedContainer(
      keyedBy: PullRequestKeys.self,
      forKey: .pullRequest
    )
    let mergedAtText = try pullRequest.decode(String.self, forKey: .mergedAt)
    guard let mergedAt = ISO8601DateFormatter.githubDate(from: mergedAtText) else {
      throw DecodingError.dataCorruptedError(
        forKey: .mergedAt,
        in: pullRequest,
        debugDescription: "Invalid merged_at date"
      )
    }
    self.mergedAt = mergedAt
  }

  init(title: String, repositoryID: String, mergedAt: Date) {
    self.title = title
    self.repositoryID = repositoryID
    self.mergedAt = mergedAt
  }

  private static func repositoryID(from repositoryURL: String) throws -> String {
    guard let url = URL(string: repositoryURL) else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: [], debugDescription: "Invalid repository_url")
      )
    }
    let parts = url.pathComponents.suffix(2)
    guard parts.count == 2 else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: [], debugDescription: "Invalid repository_url")
      )
    }
    return parts.joined(separator: "/")
  }
}

extension ISO8601DateFormatter {
  static func githubDate(from text: String) -> Date? {
    githubWithFractionalSeconds.date(from: text) ?? githubWithoutFractionalSeconds.date(from: text)
  }

  private static let githubWithFractionalSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let githubWithoutFractionalSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()
}

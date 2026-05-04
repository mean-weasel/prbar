import Foundation

struct GitHubSearchOwner: Equatable {
  enum Kind: String {
    case user
    case org
  }

  var kind: Kind
  var login: String

  var qualifier: String {
    "\(kind.rawValue):\(login)"
  }
}

enum GitHubGraphQLSearch {
  static func mergedPullRequestsRequest(
    token: String,
    owner: GitHubSearchOwner,
    mergedBy: String,
    since: Date,
    until: Date,
    first: Int,
    after: String?
  ) throws -> URLRequest {
    var request = URLRequest(
      url: URL(string: "https://api.github.com/graphql")!,
      timeoutInterval: 20
    )
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    request.httpBody = try JSONEncoder().encode(
      Payload(
        query: document,
        variables: Variables(
          query: searchQuery(owner: owner, mergedBy: mergedBy, since: since, until: until),
          first: first,
          after: after
        )
      )
    )
    return request
  }

  private static let document = """
    query MergedPullRequests($query: String!, $first: Int!, $after: String) {
      search(type: ISSUE, query: $query, first: $first, after: $after) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          ... on PullRequest {
            title
            mergedAt
            mergedBy {
              login
            }
            repository {
              nameWithOwner
            }
          }
        }
      }
    }
    """

  private static func searchQuery(
    owner: GitHubSearchOwner,
    mergedBy: String,
    since: Date,
    until: Date
  ) -> String {
    let inclusiveUntil =
      Calendar(identifier: .gregorian).date(
        byAdding: .day, value: 1, to: until
      ) ?? until
    return [
      owner.qualifier,
      "is:pr",
      "is:merged",
      "involves:\(mergedBy)",
      "merged:\(dateString(since))..\(dateString(inclusiveUntil))",
    ].joined(separator: " ")
  }

  private static func dateString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }

  private struct Payload: Encodable {
    var query: String
    var variables: Variables
  }

  private struct Variables: Encodable {
    var query: String
    var first: Int
    var after: String?
  }
}

struct GitHubGraphQLSearchResponse: Decodable {
  var data: DataContainer?
  var errors: [GraphQLError]?

  var search: Search? {
    data?.search
  }

  var errorMessage: String? {
    errors?.map(\.message).joined(separator: "; ")
  }

  struct DataContainer: Decodable {
    var search: Search
  }

  struct GraphQLError: Decodable {
    var message: String
  }

  struct Search: Decodable {
    var pageInfo: PageInfo
    var nodes: [PullRequest]
  }

  struct PageInfo: Decodable {
    var hasNextPage: Bool
    var endCursor: String?
  }

  struct PullRequest: Decodable {
    var title: String
    var mergedAt: Date
    var mergedBy: User?
    var repository: Repository

    private enum CodingKeys: String, CodingKey {
      case title
      case mergedAt
      case mergedBy
      case repository
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      title = try container.decode(String.self, forKey: .title)
      let mergedAtText = try container.decode(String.self, forKey: .mergedAt)
      guard let mergedAt = ISO8601DateFormatter.githubDate(from: mergedAtText) else {
        throw DecodingError.dataCorruptedError(
          forKey: .mergedAt,
          in: container,
          debugDescription: "Invalid mergedAt date"
        )
      }
      self.mergedAt = mergedAt
      mergedBy = try container.decodeIfPresent(User.self, forKey: .mergedBy)
      repository = try container.decode(Repository.self, forKey: .repository)
    }

    func mergedPullRequest() -> GitHubMergedPullRequest {
      GitHubMergedPullRequest(
        title: title,
        repositoryID: repository.nameWithOwner,
        mergedAt: mergedAt
      )
    }
  }

  struct User: Decodable {
    var login: String
  }

  struct Repository: Decodable {
    var nameWithOwner: String
  }
}

import Foundation

enum GitHubRepositoryError: Error, Equatable {
  case missingSession
  case invalidURL
  case invalidResponse
}

enum GitHubAPIError: Error, Equatable, Sendable {
  case unauthorized
  case forbidden
  case ssoRequired
  case rateLimited(resetAt: Date?)
  case notFound
  case server(statusCode: Int)
  case invalidResponse(statusCode: Int)
  case networkUnavailable
  case timedOut
}

enum GitHubRepositoryRequest {
  static func userRepositories(token: String, page: Int) throws -> URLRequest {
    guard
      let url = URL(
        string: "https://api.github.com/user/repos?affiliation=owner,collaborator,organization_member&per_page=100&page=\(page)&sort=pushed"
      )
    else {
      throw GitHubRepositoryError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    return request
  }
}

protocol GitHubRepositoryProviding {
  func repositories() throws -> [Repository]
}

protocol GitHubRepositoryTransport {
  func data(for request: URLRequest) throws -> Data
}

struct URLSessionGitHubRepositoryTransport: GitHubRepositoryTransport {
  func data(for request: URLRequest) throws -> Data {
    let semaphore = DispatchSemaphore(value: 0)
    let box = GitHubRepositoryTransportBox()

    URLSession.shared.dataTask(with: request) { data, response, error in
      defer { semaphore.signal() }
      if let error {
        box.result = .failure(GitHubAPIErrorMapper.networkError(for: error))
        return
      }
      guard
        let httpResponse = response as? HTTPURLResponse,
        let data
      else {
        box.result = .failure(GitHubRepositoryError.invalidResponse)
        return
      }
      guard (200..<300).contains(httpResponse.statusCode) else {
        box.result = .failure(
          GitHubAPIErrorMapper.error(
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields,
            body: data
          )
        )
        return
      }
      box.result = .success(data)
    }.resume()

    semaphore.wait()
    return try box.result?.get() ?? Data()
  }
}

enum GitHubAPIErrorMapper {
  static func networkError(for error: Error) -> Error {
    guard let urlError = error as? URLError else {
      return error
    }

    switch urlError.code {
    case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
      return GitHubAPIError.networkUnavailable
    case .timedOut:
      return GitHubAPIError.timedOut
    default:
      return error
    }
  }

  static func error(statusCode: Int, headers: [AnyHashable: Any], body: Data?) -> GitHubAPIError {
    switch statusCode {
    case 401:
      return .unauthorized
    case 403:
      if isRateLimited(headers: headers, body: body) {
        return .rateLimited(resetAt: resetDate(headers: headers))
      }
      if bodyText(body).localizedCaseInsensitiveContains("saml") ||
        bodyText(body).localizedCaseInsensitiveContains("sso") {
        return .ssoRequired
      }
      return .forbidden
    case 404:
      return .notFound
    case 429:
      return .rateLimited(resetAt: retryDate(headers: headers) ?? resetDate(headers: headers))
    case 500...599:
      return .server(statusCode: statusCode)
    default:
      return .invalidResponse(statusCode: statusCode)
    }
  }

  private static func isRateLimited(headers: [AnyHashable: Any], body: Data?) -> Bool {
    headerValue("x-ratelimit-remaining", in: headers) == "0" ||
      bodyText(body).localizedCaseInsensitiveContains("rate limit")
  }

  private static func retryDate(headers: [AnyHashable: Any]) -> Date? {
    guard let retryAfter = headerValue("retry-after", in: headers), let seconds = TimeInterval(retryAfter) else {
      return nil
    }
    return Date(timeIntervalSinceNow: seconds)
  }

  private static func resetDate(headers: [AnyHashable: Any]) -> Date? {
    guard let reset = headerValue("x-ratelimit-reset", in: headers), let seconds = TimeInterval(reset) else {
      return nil
    }
    return Date(timeIntervalSince1970: seconds)
  }

  private static func headerValue(_ key: String, in headers: [AnyHashable: Any]) -> String? {
    headers.first { header, _ in
      String(describing: header).caseInsensitiveCompare(key) == .orderedSame
    }
    .map { String(describing: $0.value) }
  }

  private static func bodyText(_ body: Data?) -> String {
    body.flatMap { String(data: $0, encoding: .utf8) } ?? ""
  }
}

private final class GitHubRepositoryTransportBox: @unchecked Sendable {
  var result: Result<Data, Error>?
}

final class FixtureGitHubRepositoryTransport: GitHubRepositoryTransport {
  private var results: [Result<Data, Error>]

  init(responses: [Data]) {
    self.results = responses.map(Result.success)
  }

  init(results: [Result<Data, Error>]) {
    self.results = results
  }

  func data(for request: URLRequest) throws -> Data {
    guard results.isEmpty == false else {
      return Data("[]".utf8)
    }
    return try results.removeFirst().get()
  }
}

struct GitHubRepositoryClient: GitHubRepositoryProviding {
  var sessionStore: GitHubSessionStoring
  var transport: GitHubRepositoryTransport

  func repositories() throws -> [Repository] {
    guard let session = try sessionStore.loadSession() else {
      throw GitHubRepositoryError.missingSession
    }

    var page = 1
    var repositories: [Repository] = []
    while true {
      let request = try GitHubRepositoryRequest.userRepositories(token: session.accessToken, page: page)
      let data = try transport.data(for: request)
      let pageRepositories = try JSONDecoder().decode([GitHubRepositoryPayload].self, from: data)
      repositories.append(contentsOf: pageRepositories.map(\.repository))
      if pageRepositories.count < 100 {
        break
      }
      page += 1
    }
    return repositories
  }
}

struct StaticGitHubRepositoryProvider: GitHubRepositoryProviding {
  var items: [Repository]

  init(repositories: [Repository]) {
    self.items = repositories
  }

  func repositories() throws -> [Repository] {
    items
  }
}

private struct GitHubRepositoryPayload: Decodable {
  struct Owner: Decodable {
    var login: String
  }

  struct Permissions: Decodable {
    var pull: Bool?
  }

  var fullName: String
  var name: String
  var isPrivate: Bool
  var owner: Owner
  var permissions: Permissions?

  var repository: Repository {
    let canPull = permissions?.pull ?? true
    return Repository(
      id: fullName,
      owner: owner.login,
      name: name,
      visibility: isPrivate ? .private : .public,
      colorHex: colorHex(for: fullName),
      included: false,
      recommended: false,
      access: canPull ? .ready : .sso,
      reason: "Fetched from GitHub"
    )
  }

  enum CodingKeys: String, CodingKey {
    case fullName = "full_name"
    case name
    case isPrivate = "private"
    case owner
    case permissions
  }

  private func colorHex(for value: String) -> String {
    let palette = RepositoryColorPalette.hexValues
    let index = abs(value.hashValue) % palette.count
    return palette[index]
  }
}

protocol RepositorySelectionStoring: AnyObject {
  func loadIncludedRepositoryIDs() throws -> [Repository.ID]?
  func saveIncludedRepositoryIDs(_ ids: [Repository.ID]) throws
  func clearIncludedRepositoryIDs() throws
}

final class InMemoryRepositorySelectionStore: RepositorySelectionStoring {
  private var includedRepositoryIDs: [Repository.ID]?

  init(includedRepositoryIDs: [Repository.ID]? = nil) {
    self.includedRepositoryIDs = includedRepositoryIDs
  }

  func loadIncludedRepositoryIDs() throws -> [Repository.ID]? {
    includedRepositoryIDs
  }

  func saveIncludedRepositoryIDs(_ ids: [Repository.ID]) throws {
    includedRepositoryIDs = ids
  }

  func clearIncludedRepositoryIDs() throws {
    includedRepositoryIDs = nil
  }
}

final class UserDefaultsRepositorySelectionStore: RepositorySelectionStoring {
  private let key: String
  private let defaults: UserDefaults

  init(key: String = "github.includedRepositoryIDs", defaults: UserDefaults = .standard) {
    self.key = key
    self.defaults = defaults
  }

  func loadIncludedRepositoryIDs() throws -> [Repository.ID]? {
    defaults.stringArray(forKey: key)
  }

  func saveIncludedRepositoryIDs(_ ids: [Repository.ID]) throws {
    defaults.set(ids, forKey: key)
  }

  func clearIncludedRepositoryIDs() throws {
    defaults.removeObject(forKey: key)
  }
}

protocol RepositoryColorStoring: AnyObject {
  func loadRepositoryColors() throws -> [Repository.ID: String]
  func saveRepositoryColor(_ colorHex: String, for repositoryID: Repository.ID) throws
  func clearRepositoryColors() throws
}

final class InMemoryRepositoryColorStore: RepositoryColorStoring {
  private var repositoryColors: [Repository.ID: String]

  init(repositoryColors: [Repository.ID: String] = [:]) {
    self.repositoryColors = repositoryColors
  }

  func loadRepositoryColors() throws -> [Repository.ID: String] {
    repositoryColors
  }

  func saveRepositoryColor(_ colorHex: String, for repositoryID: Repository.ID) throws {
    repositoryColors[repositoryID] = colorHex
  }

  func clearRepositoryColors() throws {
    repositoryColors = [:]
  }
}

final class UserDefaultsRepositoryColorStore: RepositoryColorStoring {
  private let key: String
  private let defaults: UserDefaults

  init(key: String = "github.repositoryColors", defaults: UserDefaults = .standard) {
    self.key = key
    self.defaults = defaults
  }

  func loadRepositoryColors() throws -> [Repository.ID: String] {
    defaults.dictionary(forKey: key) as? [Repository.ID: String] ?? [:]
  }

  func saveRepositoryColor(_ colorHex: String, for repositoryID: Repository.ID) throws {
    var repositoryColors = try loadRepositoryColors()
    repositoryColors[repositoryID] = colorHex
    defaults.set(repositoryColors, forKey: key)
  }

  func clearRepositoryColors() throws {
    defaults.removeObject(forKey: key)
  }
}

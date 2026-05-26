import Foundation

enum GitHubRepositoryError: Error, Equatable {
  case missingSession
  case invalidURL
  case invalidResponse
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
        box.result = .failure(error)
        return
      }
      guard
        let httpResponse = response as? HTTPURLResponse,
        (200..<300).contains(httpResponse.statusCode),
        let data
      else {
        box.result = .failure(GitHubRepositoryError.invalidResponse)
        return
      }
      box.result = .success(data)
    }.resume()

    semaphore.wait()
    return try box.result?.get() ?? Data()
  }
}

private final class GitHubRepositoryTransportBox: @unchecked Sendable {
  var result: Result<Data, Error>?
}

final class FixtureGitHubRepositoryTransport: GitHubRepositoryTransport {
  private var responses: [Data]

  init(responses: [Data]) {
    self.responses = responses
  }

  func data(for request: URLRequest) throws -> Data {
    guard responses.isEmpty == false else {
      return Data("[]".utf8)
    }
    return responses.removeFirst()
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
      included: canPull && isPrivate == false,
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
    let palette = ["#0ea5e9", "#16a34a", "#f59e0b", "#7c3aed", "#ef4444", "#14b8a6"]
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

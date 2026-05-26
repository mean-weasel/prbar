import Foundation
import Security

struct GitHubAuthSession: Codable, Equatable {
  var accessToken: String
  var tokenType: String
  var scopes: [String]
  var user: GitHubUser

  var connection: GitHubConnection {
    GitHubConnection(status: .connected, user: user)
  }
}

extension GitHubAuthSession {
  static let fixture = GitHubAuthSession(
    accessToken: "fixture-token",
    tokenType: "bearer",
    scopes: ["public_repo"],
    user: GitHubUser(login: "neonwatty", displayName: "Neon Watty")
  )
}

enum GitHubAuthError: Error, Equatable {
  case missingConfiguration
  case authorizationPending(GitHubDeviceAuthorization)
  case storageFailed
  case failed(String)
}

struct GitHubDeviceAuthorization: Codable, Equatable {
  var deviceCode: String
  var userCode: String
  var verificationURI: URL
  var expiresIn: Int
  var interval: Int
}

struct GitHubOAuthConfiguration: Equatable {
  var clientID: String?
  var scopes: [String]

  static func appDefault(environment: [String: String] = ProcessInfo.processInfo.environment) -> GitHubOAuthConfiguration {
    GitHubOAuthConfiguration(
      clientID: environment["PRBAR_IOS_GITHUB_CLIENT_ID"],
      scopes: ["public_repo"]
    )
  }
}

enum GitHubDeviceFlowRequest {
  static func deviceCode(clientID: String, scopes: [String]) throws -> URLRequest {
    try formRequest(
      url: "https://github.com/login/device/code",
      fields: [
        "client_id": clientID,
        "scope": scopes.joined(separator: " ")
      ]
    )
  }

  static func token(clientID: String, deviceCode: String) throws -> URLRequest {
    try formRequest(
      url: "https://github.com/login/oauth/access_token",
      fields: [
        "client_id": clientID,
        "device_code": deviceCode,
        "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
      ]
    )
  }

  private static func formRequest(url: String, fields: [String: String]) throws -> URLRequest {
    guard let url = URL(string: url) else {
      throw GitHubAuthError.failed("Invalid GitHub OAuth URL")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = fields
      .map { key, value in "\(escape(key))=\(escape(value))" }
      .sorted()
      .joined(separator: "&")
      .data(using: .utf8)
    return request
  }

  private static func escape(_ value: String) -> String {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "&+=")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
  }
}

protocol GitHubSessionStoring: AnyObject {
  func loadSession() throws -> GitHubAuthSession?
  func saveSession(_ session: GitHubAuthSession) throws
  func deleteSession() throws
}

final class InMemoryGitHubSessionStore: GitHubSessionStoring {
  private var session: GitHubAuthSession?

  init(session: GitHubAuthSession? = nil) {
    self.session = session
  }

  func loadSession() throws -> GitHubAuthSession? {
    session
  }

  func saveSession(_ session: GitHubAuthSession) throws {
    self.session = session
  }

  func deleteSession() throws {
    session = nil
  }
}

final class KeychainGitHubSessionStore: GitHubSessionStoring {
  private let service: String
  private let account: String
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  init(service: String = "com.neonwatty.PRBar.github", account: String = "github-session") {
    self.service = service
    self.account = account
  }

  func loadSession() throws -> GitHubAuthSession? {
    var query = baseQuery()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound {
      return nil
    }
    guard status == errSecSuccess, let data = item as? Data else {
      throw GitHubAuthError.storageFailed
    }
    return try decoder.decode(GitHubAuthSession.self, from: data)
  }

  func saveSession(_ session: GitHubAuthSession) throws {
    let data = try encoder.encode(session)
    var query = baseQuery()

    let updateStatus = SecItemUpdate(
      query as CFDictionary,
      [kSecValueData as String: data] as CFDictionary
    )
    if updateStatus == errSecSuccess {
      return
    }
    guard updateStatus == errSecItemNotFound else {
      throw GitHubAuthError.storageFailed
    }

    query[kSecValueData as String] = data
    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let addStatus = SecItemAdd(query as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      throw GitHubAuthError.storageFailed
    }
  }

  func deleteSession() throws {
    let status = SecItemDelete(baseQuery() as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw GitHubAuthError.storageFailed
    }
  }

  private func baseQuery() -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
  }
}

protocol GitHubAuthServicing {
  func restoreConnection() throws -> GitHubConnection?
  func connect() throws -> GitHubConnection
  func disconnect() throws
}

struct StaticGitHubAuthService: GitHubAuthServicing {
  var sessionStore: GitHubSessionStoring
  var result: Result<GitHubAuthSession, GitHubAuthError>

  init(
    sessionStore: GitHubSessionStoring,
    session: GitHubAuthSession = .fixture
  ) {
    self.sessionStore = sessionStore
    self.result = .success(session)
  }

  init(
    sessionStore: GitHubSessionStoring,
    result: Result<GitHubAuthSession, GitHubAuthError>
  ) {
    self.sessionStore = sessionStore
    self.result = result
  }

  func restoreConnection() throws -> GitHubConnection? {
    try sessionStore.loadSession()?.connection
  }

  func connect() throws -> GitHubConnection {
    let session = try result.get()
    try sessionStore.saveSession(session)
    return session.connection
  }

  func disconnect() throws {
    try sessionStore.deleteSession()
  }
}

struct GitHubDeviceFlowAuthService: GitHubAuthServicing {
  var configuration: GitHubOAuthConfiguration
  var sessionStore: GitHubSessionStoring

  func restoreConnection() throws -> GitHubConnection? {
    try sessionStore.loadSession()?.connection
  }

  func connect() throws -> GitHubConnection {
    guard configuration.clientID?.isEmpty == false else {
      throw GitHubAuthError.missingConfiguration
    }
    throw GitHubAuthError.failed("GitHub device authorization is not wired to the network transport yet.")
  }

  func disconnect() throws {
    try sessionStore.deleteSession()
  }
}

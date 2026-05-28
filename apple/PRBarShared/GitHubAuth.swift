import Foundation
import Security

struct GitHubAuthSession: Codable, Equatable, Sendable {
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

enum GitHubAuthError: Error, Equatable, Sendable {
  case missingConfiguration
  case authorizationPending(GitHubDeviceAuthorization)
  case storageFailed
  case failed(String)
}

struct GitHubDeviceAuthorization: Codable, Equatable, Sendable {
  var deviceCode: String
  var userCode: String
  var verificationURI: URL
  var expiresIn: Int
  var interval: Int
  var issuedAt: Date = Date()

  enum CodingKeys: String, CodingKey {
    case deviceCode = "device_code"
    case userCode = "user_code"
    case verificationURI = "verification_uri"
    case expiresIn = "expires_in"
    case interval
  }

  init(
    deviceCode: String,
    userCode: String,
    verificationURI: URL,
    expiresIn: Int,
    interval: Int,
    issuedAt: Date = Date()
  ) {
    self.deviceCode = deviceCode
    self.userCode = userCode
    self.verificationURI = verificationURI
    self.expiresIn = expiresIn
    self.interval = interval
    self.issuedAt = issuedAt
  }

  var expiresAt: Date {
    issuedAt.addingTimeInterval(TimeInterval(expiresIn))
  }

  func remainingSeconds(at date: Date = Date()) -> Int {
    max(0, Int(expiresAt.timeIntervalSince(date).rounded(.down)))
  }

  func isExpired(at date: Date = Date()) -> Bool {
    remainingSeconds(at: date) <= 0
  }
}

extension GitHubDeviceAuthorization {
  static let fixture = GitHubDeviceAuthorization(
    deviceCode: "fixture-device-code",
    userCode: "ABCD-EFGH",
    verificationURI: URL(string: "https://github.com/login/device")!,
    expiresIn: 900,
    interval: 5
  )
}

struct GitHubOAuthConfiguration: Equatable {
  var clientID: String?
  var scopes: [String]
  var maxTokenPollAttempts: Int

  init(clientID: String?, scopes: [String], maxTokenPollAttempts: Int = 1) {
    self.clientID = clientID
    self.scopes = scopes
    self.maxTokenPollAttempts = maxTokenPollAttempts
  }

  static func appDefault(
    environment: [String: String] = ProcessInfo.processInfo.environment,
    bundleInfo: [String: Any]? = Bundle.main.infoDictionary
  ) -> GitHubOAuthConfiguration {
    GitHubOAuthConfiguration(
      clientID: configuredClientID(environment: environment, bundleInfo: bundleInfo),
      scopes: [],
      maxTokenPollAttempts: 1
    )
  }

  private static func configuredClientID(
    environment: [String: String],
    bundleInfo: [String: Any]?
  ) -> String? {
    normalizedClientID(environment["PRBAR_IOS_GITHUB_CLIENT_ID"]) ??
      normalizedClientID(bundleInfo?["PRBarGitHubOAuthClientID"] as? String)
  }

  private static func normalizedClientID(_ value: String?) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), value.isEmpty == false else {
      return nil
    }
    guard value.hasPrefix("$(") == false else {
      return nil
    }
    return value
  }
}

enum GitHubDeviceFlowRequest {
  static func deviceCode(clientID: String, scopes: [String]) throws -> URLRequest {
    var fields = ["client_id": clientID]
    if scopes.isEmpty == false {
      fields["scope"] = scopes.joined(separator: " ")
    }

    return try formRequest(
      url: "https://github.com/login/device/code",
      fields: fields
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

  static func user(token: String) throws -> URLRequest {
    guard let url = URL(string: "https://api.github.com/user") else {
      throw GitHubAuthError.failed("Invalid GitHub user URL")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    return request
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
  func continueDeviceAuthorization(_ authorization: GitHubDeviceAuthorization) throws -> GitHubConnection
  func disconnect() throws
}

extension GitHubAuthServicing {
  func continueDeviceAuthorization(_ authorization: GitHubDeviceAuthorization) throws -> GitHubConnection {
    try connect()
  }
}

struct StaticGitHubAuthService: GitHubAuthServicing {
  var sessionStore: GitHubSessionStoring
  var result: Result<GitHubAuthSession, GitHubAuthError>
  var continuationResult: Result<GitHubAuthSession, GitHubAuthError>?

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
    self.continuationResult = nil
  }

  init(
    sessionStore: GitHubSessionStoring,
    result: Result<GitHubAuthSession, GitHubAuthError>,
    continuationResult: Result<GitHubAuthSession, GitHubAuthError>
  ) {
    self.sessionStore = sessionStore
    self.result = result
    self.continuationResult = continuationResult
  }

  func restoreConnection() throws -> GitHubConnection? {
    try sessionStore.loadSession()?.connection
  }

  func connect() throws -> GitHubConnection {
    let session = try result.get()
    try sessionStore.saveSession(session)
    return session.connection
  }

  func continueDeviceAuthorization(_ authorization: GitHubDeviceAuthorization) throws -> GitHubConnection {
    let session = try (continuationResult ?? result).get()
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
  var transport: GitHubRepositoryTransport = URLSessionGitHubRepositoryTransport()
  var currentDate: @Sendable () -> Date = Date.init

  func restoreConnection() throws -> GitHubConnection? {
    try sessionStore.loadSession()?.connection
  }

  func connect() throws -> GitHubConnection {
    guard let clientID = configuration.clientID, clientID.isEmpty == false else {
      throw GitHubAuthError.missingConfiguration
    }

    let authorization = try requestDeviceAuthorization(clientID: clientID)
    return try continueDeviceAuthorization(authorization)
  }

  func continueDeviceAuthorization(_ authorization: GitHubDeviceAuthorization) throws -> GitHubConnection {
    guard let clientID = configuration.clientID, clientID.isEmpty == false else {
      throw GitHubAuthError.missingConfiguration
    }

    let token = try pollToken(clientID: clientID, authorization: authorization)
    let user = try fetchUser(accessToken: token.accessToken)
    let session = GitHubAuthSession(
      accessToken: token.accessToken,
      tokenType: token.tokenType,
      scopes: token.scopes,
      user: user
    )
    try sessionStore.saveSession(session)
    return session.connection
  }

  func disconnect() throws {
    try sessionStore.deleteSession()
  }

  private func requestDeviceAuthorization(clientID: String) throws -> GitHubDeviceAuthorization {
    let request = try GitHubDeviceFlowRequest.deviceCode(clientID: clientID, scopes: configuration.scopes)
    let data = try transport.data(for: request)
    var authorization = try JSONDecoder().decode(GitHubDeviceAuthorization.self, from: data)
    authorization.issuedAt = currentDate()
    return authorization
  }

  private func pollToken(clientID: String, authorization: GitHubDeviceAuthorization) throws -> GitHubDeviceTokenPayload {
    let attempts = max(configuration.maxTokenPollAttempts, 1)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    for attempt in 0..<attempts {
      let request = try GitHubDeviceFlowRequest.token(clientID: clientID, deviceCode: authorization.deviceCode)
      let data = try transport.data(for: request)
      let tokenResponse = try decoder.decode(GitHubDeviceTokenResponse.self, from: data)
      if let token = tokenResponse.token {
        return token
      }

      if tokenResponse.error == "authorization_pending" {
        if attempt == attempts - 1 {
          throw GitHubAuthError.authorizationPending(authorization)
        }
        continue
      }

      if tokenResponse.error == "slow_down" {
        continue
      }

      throw GitHubAuthError.failed(tokenResponse.errorDescription ?? tokenResponse.error ?? "GitHub token polling failed")
    }

    throw GitHubAuthError.authorizationPending(authorization)
  }

  private func fetchUser(accessToken: String) throws -> GitHubUser {
    let request = try GitHubDeviceFlowRequest.user(token: accessToken)
    let data = try transport.data(for: request)
    let payload = try JSONDecoder().decode(GitHubUserPayload.self, from: data)
    return GitHubUser(login: payload.login, displayName: payload.name ?? payload.login)
  }
}

private struct GitHubDeviceTokenResponse: Decodable {
  var accessToken: String?
  var tokenType: String?
  var scope: String?
  var error: String?
  var errorDescription: String?

  var token: GitHubDeviceTokenPayload? {
    guard let accessToken else {
      return nil
    }

    return GitHubDeviceTokenPayload(
      accessToken: accessToken,
      tokenType: tokenType ?? "bearer",
      scopes: scope?.split(whereSeparator: { $0 == "," || $0 == " " }).map(String.init) ?? []
    )
  }
}

private struct GitHubDeviceTokenPayload: Equatable {
  var accessToken: String
  var tokenType: String
  var scopes: [String]
}

private struct GitHubUserPayload: Decodable {
  var login: String
  var name: String?
}

import CryptoKit
import Foundation

protocol GitHubDiscoveryCacheStoring {
  func load(token: String) -> GitHubPersistedDiscoveryCache?
  func save(_ cache: GitHubPersistedDiscoveryCache, token: String)
}

struct GitHubPersistedDiscoveryCache: Codable, Equatable {
  var cache: GitHubDiscoveryCache
  var responseCache: [String: GitHubCachedAPIResponse]
}

struct UserDefaultsGitHubDiscoveryCacheStore: GitHubDiscoveryCacheStoring {
  private let defaults: UserDefaults
  private let keyPrefix: String

  init(
    defaults: UserDefaults = .standard,
    keyPrefix: String = "pr-menu-bar.github.discovery-cache.v1"
  ) {
    self.defaults = defaults
    self.keyPrefix = keyPrefix
  }

  func load(token: String) -> GitHubPersistedDiscoveryCache? {
    guard let data = defaults.data(forKey: cacheKey(token: token)) else {
      return nil
    }
    return try? JSONDecoder().decode(GitHubPersistedDiscoveryCache.self, from: data)
  }

  func save(_ cache: GitHubPersistedDiscoveryCache, token: String) {
    guard let data = try? JSONEncoder().encode(cache) else {
      return
    }
    defaults.set(data, forKey: cacheKey(token: token))
  }

  func cacheKey(token: String) -> String {
    "\(keyPrefix).\(Self.tokenFingerprint(token))"
  }

  private static func tokenFingerprint(_ token: String) -> String {
    let digest = SHA256.hash(data: Data(token.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
  }
}

struct FileGitHubDiscoveryCacheStore: GitHubDiscoveryCacheStoring {
  private let directoryURL: URL
  private let filePrefix: String
  private let fileManager: FileManager

  init(
    directoryURL: URL = Self.defaultDirectoryURL(),
    filePrefix: String = "discovery-cache-v1",
    fileManager: FileManager = .default
  ) {
    self.directoryURL = directoryURL
    self.filePrefix = filePrefix
    self.fileManager = fileManager
  }

  func load(token: String) -> GitHubPersistedDiscoveryCache? {
    guard let data = try? Data(contentsOf: fileURL(token: token)) else {
      return nil
    }
    return try? JSONDecoder().decode(GitHubPersistedDiscoveryCache.self, from: data)
  }

  func save(_ cache: GitHubPersistedDiscoveryCache, token: String) {
    guard let data = try? JSONEncoder().encode(cache) else {
      return
    }
    do {
      try fileManager.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
      )
      try data.write(to: fileURL(token: token), options: .atomic)
    } catch {
      return
    }
  }

  func fileURL(token: String) -> URL {
    directoryURL.appendingPathComponent(
      "\(filePrefix).\(Self.tokenFingerprint(token)).json",
      isDirectory: false
    )
  }

  private static func defaultDirectoryURL() -> URL {
    let baseURL =
      FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      )
      .first ?? FileManager.default.temporaryDirectory
    return
      baseURL
      .appendingPathComponent("PRMenuBar", isDirectory: true)
      .appendingPathComponent("GitHubCache", isDirectory: true)
  }

  private static func tokenFingerprint(_ token: String) -> String {
    let digest = SHA256.hash(data: Data(token.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
  }
}

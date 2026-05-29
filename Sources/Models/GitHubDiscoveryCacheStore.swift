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

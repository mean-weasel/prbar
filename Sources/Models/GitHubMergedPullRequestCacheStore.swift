import CryptoKit
import Foundation

protocol GitHubMergedPullRequestCacheStoring {
  func load(token: String) -> GitHubMergedPullRequestCache?
  func save(_ cache: GitHubMergedPullRequestCache, token: String)
}

struct UserDefaultsGitHubMergedPullRequestCacheStore: GitHubMergedPullRequestCacheStoring {
  private let defaults: UserDefaults
  private let keyPrefix: String

  init(
    defaults: UserDefaults = .standard,
    keyPrefix: String = "pr-menu-bar.github.merged-pr-cache.v1"
  ) {
    self.defaults = defaults
    self.keyPrefix = keyPrefix
  }

  func load(token: String) -> GitHubMergedPullRequestCache? {
    guard let data = defaults.data(forKey: cacheKey(token: token)) else {
      return nil
    }
    return try? JSONDecoder().decode(GitHubMergedPullRequestCache.self, from: data)
  }

  func save(_ cache: GitHubMergedPullRequestCache, token: String) {
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

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

struct FileGitHubMergedPullRequestCacheStore: GitHubMergedPullRequestCacheStoring {
  private let directoryURL: URL
  private let filePrefix: String
  private let fileManager: FileManager

  init(
    directoryURL: URL = Self.defaultDirectoryURL(),
    filePrefix: String = "merged-pr-cache-v1",
    fileManager: FileManager = .default
  ) {
    self.directoryURL = directoryURL
    self.filePrefix = filePrefix
    self.fileManager = fileManager
  }

  func load(token: String) -> GitHubMergedPullRequestCache? {
    guard let data = try? Data(contentsOf: fileURL(token: token)) else {
      return nil
    }
    return try? JSONDecoder().decode(GitHubMergedPullRequestCache.self, from: data)
  }

  func save(_ cache: GitHubMergedPullRequestCache, token: String) {
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

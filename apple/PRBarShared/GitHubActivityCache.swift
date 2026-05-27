import Foundation

struct GitHubActivityCacheRecord: Codable, Equatable, Sendable {
  static let currentVersion = 1

  var version: Int
  var githubLogin: String
  var includedRepositoryIDs: [Repository.ID]
  var snapshot: GitHubActivitySnapshot
  var lastRefreshedAt: Date

  init(
    githubLogin: String,
    includedRepositoryIDs: [Repository.ID],
    snapshot: GitHubActivitySnapshot,
    lastRefreshedAt: Date,
    version: Int = Self.currentVersion
  ) {
    self.version = version
    self.githubLogin = githubLogin
    self.includedRepositoryIDs = Self.normalized(includedRepositoryIDs)
    self.snapshot = snapshot
    self.lastRefreshedAt = lastRefreshedAt
  }

  func matches(githubLogin: String, includedRepositoryIDs: [Repository.ID]) -> Bool {
    version == Self.currentVersion &&
      self.githubLogin == githubLogin &&
      self.includedRepositoryIDs == Self.normalized(includedRepositoryIDs)
  }

  private static func normalized(_ ids: [Repository.ID]) -> [Repository.ID] {
    Array(Set(ids)).sorted()
  }
}

protocol GitHubActivityCacheStoring: AnyObject {
  func load(githubLogin: String, includedRepositoryIDs: [Repository.ID]) throws -> GitHubActivityCacheRecord?
  func save(_ record: GitHubActivityCacheRecord) throws
  func clear() throws
}

final class InMemoryGitHubActivityCacheStore: GitHubActivityCacheStoring {
  private(set) var record: GitHubActivityCacheRecord?

  init(record: GitHubActivityCacheRecord? = nil) {
    self.record = record
  }

  func load(githubLogin: String, includedRepositoryIDs: [Repository.ID]) throws -> GitHubActivityCacheRecord? {
    guard let record, record.matches(githubLogin: githubLogin, includedRepositoryIDs: includedRepositoryIDs) else {
      return nil
    }
    return record
  }

  func save(_ record: GitHubActivityCacheRecord) throws {
    self.record = record
  }

  func clear() throws {
    record = nil
  }
}

final class FileGitHubActivityCacheStore: GitHubActivityCacheStoring {
  private let fileURL: URL
  private let fileManager: FileManager
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init(fileURL: URL? = nil, fileManager: FileManager = .default) {
    self.fileManager = fileManager
    self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
    self.encoder = JSONEncoder()
    self.encoder.dateEncodingStrategy = .iso8601
    self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    self.decoder = JSONDecoder()
    self.decoder.dateDecodingStrategy = .iso8601
  }

  func load(githubLogin: String, includedRepositoryIDs: [Repository.ID]) throws -> GitHubActivityCacheRecord? {
    guard fileManager.fileExists(atPath: fileURL.path) else {
      return nil
    }

    let data = try Data(contentsOf: fileURL)
    let record = try decoder.decode(GitHubActivityCacheRecord.self, from: data)
    guard record.matches(githubLogin: githubLogin, includedRepositoryIDs: includedRepositoryIDs) else {
      return nil
    }
    return record
  }

  func save(_ record: GitHubActivityCacheRecord) throws {
    let directory = fileURL.deletingLastPathComponent()
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    let data = try encoder.encode(record)
    try data.write(to: fileURL, options: [.atomic])
  }

  func clear() throws {
    guard fileManager.fileExists(atPath: fileURL.path) else {
      return
    }
    try fileManager.removeItem(at: fileURL)
  }

  private static func defaultFileURL(fileManager: FileManager) -> URL {
    let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? fileManager.temporaryDirectory
    return baseURL
      .appendingPathComponent("PRBar", isDirectory: true)
      .appendingPathComponent("GitHubActivityCache.json")
  }
}

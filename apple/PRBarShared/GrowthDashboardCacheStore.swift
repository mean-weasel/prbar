import Foundation

struct GrowthDashboardCacheRecord: Codable, Equatable, Sendable {
  var snapshot: GrowthDashboardSnapshot
  var savedAt: Date
}

protocol GrowthDashboardCacheStoring: Sendable {
  func load() throws -> GrowthDashboardCacheRecord?
  func save(_ record: GrowthDashboardCacheRecord) throws
  func clear() throws
}

final class InMemoryGrowthDashboardCacheStore: GrowthDashboardCacheStoring, @unchecked Sendable {
  private var record: GrowthDashboardCacheRecord?

  init(record: GrowthDashboardCacheRecord? = nil) {
    self.record = record
  }

  func load() throws -> GrowthDashboardCacheRecord? {
    record
  }

  func save(_ record: GrowthDashboardCacheRecord) throws {
    self.record = record
  }

  func clear() throws {
    record = nil
  }
}

struct FileGrowthDashboardCacheStore: GrowthDashboardCacheStoring {
  private let fileURL: URL

  init(fileURL: URL? = nil) {
    self.fileURL = fileURL ?? Self.defaultFileURL()
  }

  func load() throws -> GrowthDashboardCacheRecord? {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return nil
    }

    let data = try Data(contentsOf: fileURL)
    return try Self.decoder.decode(GrowthDashboardCacheRecord.self, from: data)
  }

  func save(_ record: GrowthDashboardCacheRecord) throws {
    let directory = fileURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let data = try Self.encoder.encode(record)
    try data.write(to: fileURL, options: [.atomic])
  }

  func clear() throws {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return
    }
    try FileManager.default.removeItem(at: fileURL)
  }

  private static var encoder: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return encoder
  }

  private static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }

  private static func defaultFileURL() -> URL {
    let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.temporaryDirectory
    return baseURL
      .appendingPathComponent("PRBar", isDirectory: true)
      .appendingPathComponent("growth-dashboard-cache.json")
  }
}

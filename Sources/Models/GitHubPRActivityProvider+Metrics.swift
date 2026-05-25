import Foundation

extension GitHubPRActivityProvider {
  func measured<T>(
    _ name: String,
    metadata: [String: String] = [:],
    _ work: () throws -> T
  ) throws -> T {
    let start = Date()
    do {
      let value = try work()
      recordMetric(name, startedAt: start, metadata: metadata)
      return value
    } catch {
      recordMetric(
        name,
        startedAt: start,
        metadata: metadata.merging(["result": "error"]) { $1 }
      )
      throw error
    }
  }

  func recordMetric(_ name: String, metadata: [String: String]) {
    metrics?.record(
      RefreshMetricEvent(name: name, durationMilliseconds: 0, metadata: metadata)
    )
  }

  private func recordMetric(
    _ name: String,
    startedAt: Date,
    metadata: [String: String]
  ) {
    metrics?.record(
      RefreshMetricEvent(
        name: name,
        durationMilliseconds: Date().timeIntervalSince(startedAt) * 1_000,
        metadata: metadata
      )
    )
  }
}

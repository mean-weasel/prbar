import Foundation

@testable import PRMenuBar

struct RefreshBenchmarkReport: Codable {
  var generatedAt: String
  var scenarios: [RefreshBenchmarkScenario]
}

struct RefreshBenchmarkScenario: Codable {
  var name: String
  var requestCount: Int
  var requestsByPath: [String: Int]
  var metrics: [RefreshMetricEvent]

  var metricNames: [String] {
    metrics.map(\.name)
  }

  func metric(named name: String) -> RefreshMetricEvent? {
    metrics.first { $0.name == name }
  }
}

extension JSONEncoder {
  static var prettyBenchmark: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return encoder
  }
}

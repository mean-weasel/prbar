import Foundation

struct PostHogDashboardRunResponse: Decodable, Equatable {
  var results: [PostHogDashboardTileResult]

  init(data: Data) throws {
    self = try JSONDecoder().decode(Self.self, from: data)
  }
}

struct PostHogDashboardTileResult: Decodable, Equatable {
  var id: Int
  var order: Int?
  var insight: PostHogDashboardInsight
}

struct PostHogDashboardInsight: Decodable, Equatable {
  var id: Int
  var shortID: String?
  var name: String?
  var derivedName: String?
  var result: [PostHogDashboardSeries]

  private enum CodingKeys: String, CodingKey {
    case id
    case shortID = "short_id"
    case name
    case derivedName = "derived_name"
    case result
  }
}

struct PostHogDashboardSeries: Decodable, Equatable {
  var data: [Double]
  var days: [String]
  var count: Double?
  var label: String?
  var breakdownValue: String?

  private enum CodingKeys: String, CodingKey {
    case data
    case days
    case count
    case label
    case breakdownValue = "breakdown_value"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    data = try container.decode([Double].self, forKey: .data)
    days = try container.decode([String].self, forKey: .days)
    count = try container.decodeFlexibleDoubleIfPresent(forKey: .count)
    label = try container.decodeIfPresent(String.self, forKey: .label)
    breakdownValue = try container.decodeIfPresent(String.self, forKey: .breakdownValue)
  }
}

private extension KeyedDecodingContainer {
  func decodeFlexibleDoubleIfPresent(forKey key: Key) throws -> Double? {
    if let double = try decodeIfPresent(Double.self, forKey: key) {
      return double
    }
    if let int = try decodeIfPresent(Int.self, forKey: key) {
      return Double(int)
    }
    return nil
  }
}

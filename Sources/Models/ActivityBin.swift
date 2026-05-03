import Foundation

enum ActivityBin: String, CaseIterable, Codable, Identifiable {
  case day = "Day"
  case week = "Week"
  case month = "Month"

  var id: String {
    rawValue
  }

  var sourceBucketGroupSize: Int {
    switch self {
    case .day, .week:
      return 1
    case .month:
      return 4
    }
  }
}

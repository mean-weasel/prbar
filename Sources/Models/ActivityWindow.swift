import Foundation

enum ActivityWindow: String, CaseIterable, Codable, Identifiable {
  case oneDay = "1 day"
  case oneWeek = "1 week"
  case twoWeeks = "2 weeks"
  case oneMonth = "1 month"

  var id: String {
    rawValue
  }

  var dayCount: Int {
    switch self {
    case .oneDay:
      return 1
    case .oneWeek:
      return 7
    case .twoWeeks:
      return 14
    case .oneMonth:
      return 30
    }
  }

  var visibleBucketCount: Int {
    switch self {
    case .oneDay, .oneWeek:
      return 1
    case .twoWeeks:
      return 2
    case .oneMonth:
      return 4
    }
  }
}

import Foundation

enum ActivityWindow: String, CaseIterable, Identifiable {
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
}

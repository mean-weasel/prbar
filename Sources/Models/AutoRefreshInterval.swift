import Foundation

enum AutoRefreshInterval: String, CaseIterable, Codable, Identifiable {
  case manual = "Manual"
  case daily = "Daily"

  var id: String {
    rawValue
  }

  var duration: TimeInterval? {
    switch self {
    case .manual:
      return nil
    case .daily:
      return 86_400
    }
  }
}

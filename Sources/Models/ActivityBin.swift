import Foundation

enum ActivityBin: String, CaseIterable, Codable, Identifiable {
  case day = "Day"
  case week = "Week"
  case month = "Month"

  var id: String {
    rawValue
  }
}

import Foundation

struct RepositoryActivity: Identifiable, Equatable {
  let id: String
  var owner: String
  var name: String
  var colorHex: String
  var weeklyCounts: [Int]
  var isIncluded: Bool

  var total: Int {
    guard isIncluded else {
      return 0
    }
    return weeklyCounts.reduce(0, +)
  }

  var displayName: String {
    "\(owner)/\(name)"
  }
}

extension RepositoryActivity {
  static let samples: [RepositoryActivity] = [
    RepositoryActivity(
      id: "mean-weasel/deckchecker",
      owner: "mean-weasel",
      name: "deckchecker",
      colorHex: "#818cf8",
      weeklyCounts: [45, 111],
      isIncluded: true
    ),
    RepositoryActivity(
      id: "mean-weasel/seatify",
      owner: "mean-weasel",
      name: "seatify",
      colorHex: "#c084fc",
      weeklyCounts: [40, 79],
      isIncluded: true
    ),
    RepositoryActivity(
      id: "neonwatty/RedditReminder",
      owner: "neonwatty",
      name: "RedditReminder",
      colorHex: "#4ade80",
      weeklyCounts: [11, 84],
      isIncluded: true
    ),
  ]
}

import Foundation

struct RepositoryActivity: Codable, Identifiable, Equatable {
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

  func visibleCounts(for window: ActivityWindow) -> [Int] {
    Array(weeklyCounts.suffix(window.visibleBucketCount))
  }

  func visibleTotal(for window: ActivityWindow) -> Int {
    guard isIncluded else {
      return 0
    }
    return visibleCounts(for: window).reduce(0, +)
  }
}

extension RepositoryActivity {
  static let samples: [RepositoryActivity] = [
    RepositoryActivity(
      id: "mean-weasel/deckchecker",
      owner: "mean-weasel",
      name: "deckchecker",
      colorHex: "#818cf8",
      weeklyCounts: [0, 13, 75, 42, 53, 23, 69, 45, 111],
      isIncluded: true
    ),
    RepositoryActivity(
      id: "mean-weasel/seatify",
      owner: "mean-weasel",
      name: "seatify",
      colorHex: "#c084fc",
      weeklyCounts: [15, 16, 34, 35, 20, 22, 113, 40, 79],
      isIncluded: true
    ),
    RepositoryActivity(
      id: "mean-weasel/issuectl",
      owner: "mean-weasel",
      name: "issuectl",
      colorHex: "#6366f1",
      weeklyCounts: [0, 0, 0, 0, 0, 51, 57, 69, 53],
      isIncluded: true
    ),
    RepositoryActivity(
      id: "mean-weasel/bleep-that-shit",
      owner: "mean-weasel",
      name: "bleep-that-shit",
      colorHex: "#a78bfa",
      weeklyCounts: [30, 41, 42, 33, 48, 21, 41, 31, 5],
      isIncluded: true
    ),
    RepositoryActivity(
      id: "mean-weasel/issuectl-ios",
      owner: "mean-weasel",
      name: "issuectl-ios",
      colorHex: "#4f46e5",
      weeklyCounts: [0, 0, 0, 0, 0, 0, 0, 2, 0],
      isIncluded: true
    ),
    RepositoryActivity(
      id: "neonwatty/RedditReminder",
      owner: "neonwatty",
      name: "RedditReminder",
      colorHex: "#4ade80",
      weeklyCounts: [0, 0, 0, 0, 0, 0, 0, 11, 84],
      isIncluded: true
    ),
    RepositoryActivity(
      id: "neonwatty/nav-map",
      owner: "neonwatty",
      name: "nav-map",
      colorHex: "#34d399",
      weeklyCounts: [0, 0, 35, 3, 0, 1, 1, 0, 42],
      isIncluded: true
    ),
    RepositoryActivity(
      id: "neonwatty/fleet",
      owner: "neonwatty",
      name: "fleet",
      colorHex: "#22d3ee",
      weeklyCounts: [0, 0, 0, 0, 0, 10, 7, 0, 30],
      isIncluded: true
    ),
    RepositoryActivity(
      id: "neonwatty/session-search",
      owner: "neonwatty",
      name: "session-search",
      colorHex: "#2dd4bf",
      weeklyCounts: [0, 0, 0, 0, 0, 0, 0, 7, 37],
      isIncluded: true
    ),
    RepositoryActivity(
      id: "neonwatty/playwright-dashboard",
      owner: "neonwatty",
      name: "playwright-dashboard",
      colorHex: "#a3e635",
      weeklyCounts: [0, 0, 0, 0, 0, 0, 0, 0, 20],
      isIncluded: true
    ),
    RepositoryActivity(
      id: "neonwatty/CCSwitcher-Codex",
      owner: "neonwatty",
      name: "CCSwitcher-Codex",
      colorHex: "#86efac",
      weeklyCounts: [0, 0, 0, 0, 0, 0, 0, 0, 1],
      isIncluded: true
    ),
  ]
}

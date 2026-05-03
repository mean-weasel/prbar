import Foundation

struct GitHubRepository: Decodable, Equatable {
  var fullName: String
  var owner: Owner
  var name: String
  var permissions: Permissions?

  var canPull: Bool {
    permissions?.pull ?? true
  }

  func activity(
    bucketCount: Int,
    dailyBucketCount: Int = 0,
    isIncluded: Bool = true
  ) -> RepositoryActivity {
    RepositoryActivity(
      id: fullName,
      owner: owner.login,
      name: name,
      colorHex: RepositoryColor.hexColor(for: fullName),
      weeklyCounts: Array(repeating: 0, count: bucketCount),
      dailyCounts: Array(repeating: 0, count: dailyBucketCount),
      isIncluded: isIncluded
    )
  }

  struct Owner: Decodable, Equatable {
    var login: String
  }

  struct Permissions: Decodable, Equatable {
    var pull: Bool?
  }

  private enum CodingKeys: String, CodingKey {
    case fullName = "full_name"
    case owner
    case name
    case permissions
  }
}

enum RepositoryColor {
  private static let palette = [
    "#818cf8", "#c084fc", "#6366f1", "#a78bfa", "#4f46e5", "#4ade80", "#34d399",
    "#22d3ee", "#2dd4bf", "#a3e635", "#86efac", "#f59e0b",
  ]

  static func hexColor(for id: String) -> String {
    let total = id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    return palette[total % palette.count]
  }
}

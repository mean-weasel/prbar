import Foundation

struct GitHubRepository: Decodable, Equatable {
  var fullName: String
  var owner: Owner
  var name: String
  var isPrivate: Bool
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
      isIncluded: isIncluded,
      isPrivate: isPrivate
    )
  }

  struct Owner: Decodable, Equatable {
    var login: String
  }

  struct Permissions: Decodable, Equatable {
    var pull: Bool?
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    fullName = try container.decode(String.self, forKey: .fullName)
    owner = try container.decode(Owner.self, forKey: .owner)
    name = try container.decode(String.self, forKey: .name)
    isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
    permissions = try container.decodeIfPresent(Permissions.self, forKey: .permissions)
  }

  private enum CodingKeys: String, CodingKey {
    case fullName = "full_name"
    case owner
    case name
    case isPrivate = "private"
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

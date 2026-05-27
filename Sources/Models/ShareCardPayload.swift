import Foundation

enum ShareCardPayload: Equatable {
  case prActivity(PRShareCardPayload)
  case release(ReleaseShareCardPayload)

  var title: String {
    switch self {
    case .prActivity:
      return "PR Card Preview"
    case .release:
      return "Release Card Preview"
    }
  }

  var privacyMessage: String {
    switch self {
    case .prActivity(let payload):
      if payload.showsPrivateRepositoryNames {
        return "Privacy warning: private repository names are visible in this export."
      }
      return "Privacy applied: private repository names are hidden before export."
    case .release(let payload):
      if payload.showsPrivateRepositoryName {
        return "Privacy warning: this private repository name is visible in this export."
      }
      if payload.repositoryDisplayName == "Private repo" {
        return "Privacy warning: this release comes from a private repository, "
          + "so the repo name is hidden."
      }
      return "Privacy applied: private repository names are hidden before export."
    }
  }

  var exportFilename: String {
    switch self {
    case .prActivity(let payload):
      return "prbar-pr-card-\(Self.slug(payload.rangeLabel)).png"
    case .release(let payload):
      return "prbar-release-card-\(Self.slug(payload.repositoryDisplayName))-"
        + "\(Self.slug(payload.headline)).png"
    }
  }

  private static func slug(_ value: String) -> String {
    let allowed = CharacterSet.alphanumerics
    var result = ""
    var previousWasSeparator = false

    for scalar in value.lowercased().unicodeScalars {
      if allowed.contains(scalar) {
        result.unicodeScalars.append(scalar)
        previousWasSeparator = false
      } else if !previousWasSeparator {
        result.append("-")
        previousWasSeparator = true
      }
    }

    let trimmed = result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    return trimmed.isEmpty ? "card" : trimmed
  }
}

struct PRShareCardPayload: Equatable {
  var headline: String
  var rangeLabel: String
  var totalPullRequests: Int
  var activeRepositoryCount: Int
  var showsPrivateRepositoryNames: Bool
  var chartBuckets: [ShareCardBucket]
  var repoRows: [ShareCardRepoRow]
}

struct ReleaseShareCardPayload: Equatable {
  var headline: String
  var repositoryDisplayName: String
  var dateLabel: String
  var notesExcerpt: String
  var sourceLabel: String
  var showsPrivateRepositoryName: Bool
}

struct ShareCardRepoRow: Identifiable, Equatable {
  var id: String
  var displayName: String
  var count: Int
  var colorHex: String
}

struct ShareCardBucket: Identifiable, Equatable {
  var id: String
  var label: String
  var total: Int
  var segments: [ShareCardBucketSegment]
}

struct ShareCardBucketSegment: Identifiable, Equatable {
  var id: String
  var value: Int
  var colorHex: String
}

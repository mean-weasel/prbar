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
    case .prActivity:
      return "Privacy applied: private repository names are hidden before export."
    case .release(let payload):
      if payload.repositoryDisplayName == "Private repo" {
        return "Privacy warning: this release comes from a private repository, "
          + "so the repo name is hidden."
      }
      return "Privacy applied: private repository names are hidden before export."
    }
  }
}

struct PRShareCardPayload: Equatable {
  var headline: String
  var rangeLabel: String
  var activeRepositoryCount: Int
  var bucketTotals: [Int]
  var repoRows: [ShareCardRepoRow]
}

struct ReleaseShareCardPayload: Equatable {
  var headline: String
  var repositoryDisplayName: String
  var dateLabel: String
  var notesExcerpt: String
  var sourceLabel: String
}

struct ShareCardRepoRow: Identifiable, Equatable {
  var id: String
  var displayName: String
  var count: Int
  var colorHex: String
}

import Foundation

struct ReleaseMoment: Identifiable, Equatable, Codable {
  enum Source: String, Codable {
    case githubRelease
    case tag

    var badgeText: String {
      switch self {
      case .githubRelease:
        return "Release"
      case .tag:
        return "Tag"
      }
    }

    var notesTitle: String {
      switch self {
      case .githubRelease:
        return "Original release notes"
      case .tag:
        return "Generated tag summary"
      }
    }
  }

  var id: String
  var repositoryID: String
  var title: String
  var tag: String
  var date: Date
  var notes: String
  var url: URL?
  var source: Source
}

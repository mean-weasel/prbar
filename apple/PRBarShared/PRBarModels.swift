import Foundation

struct Repository: Identifiable, Equatable {
  enum Visibility: String, CaseIterable, Codable {
    case `public`
    case `private`
  }

  enum Access: String, CaseIterable, Codable {
    case ready
    case sso
  }

  var id: String
  var owner: String
  var name: String
  var visibility: Visibility
  var colorHex: String
  var included: Bool
  var recommended: Bool
  var access: Access
  var reason: String
}

struct PullRequest: Identifiable, Equatable {
  var id: String
  var title: String
  var repoID: Repository.ID
  var number: Int
  var mergedAt: Date
}

struct ReleaseMoment: Identifiable, Equatable {
  enum Source: String, CaseIterable, Codable {
    case release
    case tag
  }

  var id: String
  var repoID: Repository.ID
  var title: String
  var tag: String
  var date: Date
  var source: Source
  var notes: String
  var url: URL
}

enum ActivityRange: String, CaseIterable, Identifiable {
  case day
  case week
  case month

  var id: String { rawValue }
}

enum CardSide: String, CaseIterable, Identifiable {
  case publicSide
  case evidenceSide

  var id: String { rawValue }
}

struct WorkCardDraft: Equatable {
  enum Source: Equatable {
    case shippingSnapshot
    case releaseReceipt(ReleaseMoment.ID)
  }

  enum Theme: String, CaseIterable, Identifiable {
    case clean
    case terminal
    case launch
    case hype
    case minimal

    var id: String { rawValue }
  }

  var source: Source
  var theme: Theme
  var side: CardSide
  var showRepos: Bool
  var showHandle: Bool
  var exactCounts: Bool
  var showPrivateLabels: Bool
}

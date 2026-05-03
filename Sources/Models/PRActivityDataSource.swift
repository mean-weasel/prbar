import Foundation

enum PRActivityDataSource: Equatable {
  case sample
  case github

  var title: String {
    switch self {
    case .sample:
      "Sample Data"
    case .github:
      "GitHub"
    }
  }

  var systemImage: String {
    switch self {
    case .sample:
      "shippingbox"
    case .github:
      "network"
    }
  }
}

struct PRActivityProviderSelection {
  var provider: PRActivityProviding
  var dataSource: PRActivityDataSource
}

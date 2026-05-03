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

  var connectionTitle: String {
    switch self {
    case .sample:
      "GitHub not connected"
    case .github:
      "GitHub connected"
    }
  }

  var connectionDetail: String {
    switch self {
    case .sample:
      "Using sample data. Launch with PR_MENU_BAR_GITHUB_TOKEN to load live GitHub activity."
    case .github:
      "Using live GitHub data from PR_MENU_BAR_GITHUB_TOKEN."
    }
  }
}

struct PRActivityProviderSelection {
  var provider: PRActivityProviding
  var dataSource: PRActivityDataSource
}

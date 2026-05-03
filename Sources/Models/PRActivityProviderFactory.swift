import Foundation

enum PRActivityProviderFactory {
  static let tokenEnvironmentKey = "PR_MENU_BAR_GITHUB_TOKEN"

  static func make(environment: [String: String] = ProcessInfo.processInfo.environment)
    -> PRActivityProviding
  {
    guard let token = environment[tokenEnvironmentKey], token.isEmpty == false else {
      return StaticPRActivityProvider()
    }

    return GitHubPRActivityProvider(
      token: token,
      transport: URLSessionGitHubAPITransport(),
      bucketLabels: PRActivityStore.sample().bucketLabels
    )
  }
}

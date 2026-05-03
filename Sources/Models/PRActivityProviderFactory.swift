import Foundation

enum PRActivityProviderFactory {
  static let tokenEnvironmentKey = "PR_MENU_BAR_GITHUB_TOKEN"

  static func make(environment: [String: String] = ProcessInfo.processInfo.environment)
    -> PRActivityProviding
  {
    guard
      let rawToken = environment[tokenEnvironmentKey],
      rawToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    else {
      return StaticPRActivityProvider()
    }
    let token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)

    return GitHubPRActivityProvider(
      token: token,
      transport: URLSessionGitHubAPITransport(),
      bucketLabels: PRActivityStore.sample().bucketLabels
    )
  }
}

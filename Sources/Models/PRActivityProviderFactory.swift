import Foundation

enum PRActivityProviderFactory {
  static let tokenEnvironmentKey = "PR_MENU_BAR_GITHUB_TOKEN"

  static func make(environment: [String: String] = ProcessInfo.processInfo.environment)
    -> PRActivityProviding
  {
    makeSelection(environment: environment).provider
  }

  static func makeSelection(environment: [String: String] = ProcessInfo.processInfo.environment)
    -> PRActivityProviderSelection
  {
    guard
      let rawToken = environment[tokenEnvironmentKey],
      rawToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    else {
      return PRActivityProviderSelection(
        provider: StaticPRActivityProvider(),
        dataSource: .sample
      )
    }
    let token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)

    return PRActivityProviderSelection(
      provider: GitHubPRActivityProvider(
        token: token,
        transport: URLSessionGitHubAPITransport(),
        bucketLabels: PRActivityStore.sample().bucketLabels
      ),
      dataSource: .github
    )
  }
}

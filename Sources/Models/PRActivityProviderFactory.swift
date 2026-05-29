import Foundation

enum PRActivityProviderFactory {
  static let tokenEnvironmentKey = "PR_MENU_BAR_GITHUB_TOKEN"
  static let fixturePathEnvironmentKey = "PR_MENU_BAR_FIXTURE_PATH"

  static func make(environment: [String: String] = ProcessInfo.processInfo.environment)
    -> PRActivityProviding
  {
    makeSelection(environment: environment).provider
  }

  static func makeSelection(environment: [String: String] = ProcessInfo.processInfo.environment)
    -> PRActivityProviderSelection
  {
    makeSelection(environment: environment, gitHubCLIToken: GitHubCLITokenResolver.token)
  }

  static func makeSelection(
    environment: [String: String],
    gitHubCLIToken: ([String: String]) -> String?
  ) -> PRActivityProviderSelection {
    if let fixturePath = environment[fixturePathEnvironmentKey],
      fixturePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    {
      return PRActivityProviderSelection(
        provider: FilePRActivityProvider(
          path: fixturePath.trimmingCharacters(in: .whitespacesAndNewlines)
        ),
        releaseProvider: SampleReleaseMomentProvider(),
        dataSource: .github
      )
    }

    guard let token = resolvedToken(environment: environment, gitHubCLIToken: gitHubCLIToken)
    else {
      return PRActivityProviderSelection(
        provider: StaticPRActivityProvider(),
        releaseProvider: SampleReleaseMomentProvider(),
        dataSource: .sample
      )
    }

    return PRActivityProviderSelection(
      provider: GitHubPRActivityProvider(
        token: token,
        transport: URLSessionGitHubAPITransport(),
        bucketLabels: PRActivityStore.sample().bucketLabels,
        mergedPullRequestCacheStore: UserDefaultsGitHubMergedPullRequestCacheStore(),
        discoveryCacheStore: UserDefaultsGitHubDiscoveryCacheStore()
      ),
      releaseProvider: GitHubReleaseMomentProvider(
        token: token,
        transport: URLSessionGitHubAPITransport()
      ),
      dataSource: .github
    )
  }

  private static func resolvedToken(
    environment: [String: String],
    gitHubCLIToken: ([String: String]) -> String?
  ) -> String? {
    if let rawToken = environment[tokenEnvironmentKey] {
      let token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
      if token.isEmpty == false {
        return token
      }
    }

    return gitHubCLIToken(environment)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .nonEmpty
  }
}

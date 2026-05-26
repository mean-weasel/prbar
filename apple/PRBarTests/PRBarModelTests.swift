import XCTest
@testable import PRBar

final class PRBarModelTests: XCTestCase {
  func testIncludedRepositoriesFilterPrivateAndPublicRepos() {
    let store = PRBarStore.sample()

    XCTAssertEqual(store.includedRepositories.map(\.id), ["prbar", "launch-kit", "client-api"])
    XCTAssertTrue(store.includedRepositories.contains { $0.visibility == .private })
  }

  func testSelectedDayPullRequestsAreFilteredByCalendarDate() {
    let store = PRBarStore.sample()
    store.selectedPRDate = SampleData.date("2026-05-24")

    XCTAssertEqual(store.filteredPullRequests.map(\.id), ["pr-39", "pr-38"])
  }

  func testReleaseMomentsAreFilteredBySelectedDate() {
    let store = PRBarStore.sample()
    store.selectedReleaseDate = SampleData.date("2026-05-21")

    XCTAssertEqual(store.filteredReleases.map(\.id), ["tag-launch-100"])
  }

  func testPrivateEvidenceRequiresExportWarning() {
    let store = PRBarStore.sample()

    XCTAssertTrue(store.cardHasPrivateEvidence)
  }

  func testGitHubConnectionStartsRepoSetupWithRecommendedReposIncluded() throws {
    let sessionStore = InMemoryGitHubSessionStore()
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(
        sessionStore: sessionStore,
        session: .fixture
      )
    )
    store.routeState = .signedOut
    store.repositories = store.repositories.map { repository in
      var repository = repository
      repository.included = false
      return repository
    }

    store.connectGitHub()

    XCTAssertEqual(store.routeState, .onboarding(.repositories))
    XCTAssertEqual(store.githubConnection.status, .connected)
    XCTAssertEqual(store.githubConnection.user?.login, "neonwatty")
    XCTAssertEqual(store.includedRepositories.map(\.id), ["prbar", "launch-kit"])
    XCTAssertEqual(try sessionStore.loadSession()?.user.login, "neonwatty")
  }

  func testMissingGitHubConfigurationShowsRecoverableIssue() {
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(
        sessionStore: InMemoryGitHubSessionStore(),
        result: .failure(.missingConfiguration)
      )
    )
    store.routeState = .signedOut

    store.connectGitHub()

    guard case let .issue(issue) = store.routeState else {
      return XCTFail("Expected a recoverable auth issue")
    }
    XCTAssertEqual(issue.id, "github-auth-missing-configuration")
    XCTAssertEqual(store.githubConnection.status, .signedOut)
  }

  func testRestoringGitHubSessionUsesStoredUser() throws {
    let sessionStore = InMemoryGitHubSessionStore()
    try sessionStore.saveSession(.fixture)
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: sessionStore)
    )
    store.githubConnection = .signedOut
    store.routeState = .signedOut

    store.restoreGitHubSession()

    XCTAssertEqual(store.githubConnection.status, .connected)
    XCTAssertEqual(store.githubConnection.user?.login, "neonwatty")
    XCTAssertEqual(store.routeState, .authenticated)
  }

  func testDisconnectingGitHubClearsIncludedReposAndReturnsToSignedOut() throws {
    let sessionStore = InMemoryGitHubSessionStore()
    try sessionStore.saveSession(.fixture)
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: sessionStore)
    )

    store.disconnectGitHub()

    XCTAssertEqual(store.routeState, .signedOut)
    XCTAssertEqual(store.githubConnection.status, .signedOut)
    XCTAssertNil(store.githubConnection.user)
    XCTAssertTrue(store.includedRepositories.isEmpty)
    XCTAssertNil(try sessionStore.loadSession())
  }

  func testInMemoryGitHubSessionStoreRoundTripsSession() throws {
    let sessionStore = InMemoryGitHubSessionStore()

    try sessionStore.saveSession(.fixture)

    XCTAssertEqual(try sessionStore.loadSession(), .fixture)
  }

  func testDeviceFlowAuthRequiresClientIDBeforeStarting() {
    let authService = GitHubDeviceFlowAuthService(
      configuration: GitHubOAuthConfiguration(clientID: nil, scopes: ["public_repo"]),
      sessionStore: InMemoryGitHubSessionStore()
    )

    XCTAssertThrowsError(try authService.connect()) { error in
      XCTAssertEqual(error as? GitHubAuthError, .missingConfiguration)
    }
  }

  func testDeviceFlowBuildsDeviceCodeRequest() throws {
    let request = try GitHubDeviceFlowRequest.deviceCode(
      clientID: "client-id",
      scopes: ["public_repo", "read:user"]
    )

    XCTAssertEqual(request.url?.absoluteString, "https://github.com/login/device/code")
    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
    XCTAssertEqual(String(data: try XCTUnwrap(request.httpBody), encoding: .utf8), "client_id=client-id&scope=public_repo%20read:user")
  }

  func testDeviceFlowBuildsTokenPollingRequest() throws {
    let request = try GitHubDeviceFlowRequest.token(
      clientID: "client-id",
      deviceCode: "device-code"
    )

    XCTAssertEqual(request.url?.absoluteString, "https://github.com/login/oauth/access_token")
    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertEqual(String(data: try XCTUnwrap(request.httpBody), encoding: .utf8), "client_id=client-id&device_code=device-code&grant_type=urn:ietf:params:oauth:grant-type:device_code")
  }

  func testGitHubRepositoryRequestUsesAuthenticatedReposEndpoint() throws {
    let request = try GitHubRepositoryRequest.userRepositories(token: "token", page: 2)

    XCTAssertEqual(request.url?.absoluteString, "https://api.github.com/user/repos?affiliation=owner,collaborator,organization_member&per_page=100&page=2&sort=pushed")
    XCTAssertEqual(request.httpMethod, "GET")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
    XCTAssertEqual(request.value(forHTTPHeaderField: "X-GitHub-Api-Version"), "2022-11-28")
  }

  func testGitHubRepositoryClientMapsPublicAndPrivateRepos() throws {
    let sessionStore = InMemoryGitHubSessionStore(session: .fixture)
    let provider = GitHubRepositoryClient(
      sessionStore: sessionStore,
      transport: FixtureGitHubRepositoryTransport(
        responses: [
          Data(
            """
            [
              {"full_name":"mean-weasel/prbar","name":"prbar","private":false,"owner":{"login":"mean-weasel"},"permissions":{"pull":true}},
              {"full_name":"example/client-api","name":"client-api","private":true,"owner":{"login":"example"},"permissions":{"pull":true}}
            ]
            """.utf8
          )
        ]
      )
    )

    let repositories = try provider.repositories()

    XCTAssertEqual(repositories.map(\.id), ["mean-weasel/prbar", "example/client-api"])
    XCTAssertEqual(repositories.map(\.visibility), [.public, .private])
    XCTAssertEqual(repositories.map(\.included), [true, false])
  }

  func testGitHubRepositoryClientFetchesAdditionalPages() throws {
    let sessionStore = InMemoryGitHubSessionStore(session: .fixture)
    let firstPage = (1...100)
      .map { index in
        """
        {"full_name":"mean-weasel/repo-\(index)","name":"repo-\(index)","private":false,"owner":{"login":"mean-weasel"},"permissions":{"pull":true}}
        """
      }
      .joined(separator: ",")
    let provider = GitHubRepositoryClient(
      sessionStore: sessionStore,
      transport: FixtureGitHubRepositoryTransport(
        responses: [
          Data("[\(firstPage)]".utf8),
          Data(
            """
            [
              {"full_name":"mean-weasel/repo-101","name":"repo-101","private":false,"owner":{"login":"mean-weasel"},"permissions":{"pull":true}}
            ]
            """.utf8
          )
        ]
      )
    )

    let repositories = try provider.repositories()

    XCTAssertEqual(repositories.count, 101)
    XCTAssertEqual(repositories.last?.id, "mean-weasel/repo-101")
  }

  func testConnectingGitHubLoadsFetchedRepositoriesWithPrivacyDefaults() {
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: InMemoryGitHubSessionStore(), session: .fixture),
      repositoryProvider: StaticGitHubRepositoryProvider(
        repositories: [
          Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub"),
          Repository(id: "example/client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub")
        ]
      ),
      repositorySelectionStore: InMemoryRepositorySelectionStore()
    )

    store.connectGitHub()

    XCTAssertEqual(store.repositories.map(\.id), ["mean-weasel/prbar", "example/client-api"])
    XCTAssertEqual(store.includedRepositories.map(\.id), ["mean-weasel/prbar"])
  }

  func testConnectingGitHubShowsIssueWhenRepositoryFetchFails() {
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: InMemoryGitHubSessionStore(), session: .fixture),
      repositoryProvider: ThrowingGitHubRepositoryProvider()
    )

    store.connectGitHub()

    guard case let .issue(issue) = store.routeState else {
      return XCTFail("Expected a repository fetch issue")
    }
    XCTAssertEqual(issue.id, "github-auth-failed")
    XCTAssertEqual(store.githubConnection.status, .signedOut)
  }

  func testConnectingGitHubRestoresPersistedRepositorySelection() throws {
    let selectionStore = InMemoryRepositorySelectionStore(includedRepositoryIDs: ["example/client-api"])
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: InMemoryGitHubSessionStore(), session: .fixture),
      repositoryProvider: StaticGitHubRepositoryProvider(
        repositories: [
          Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub"),
          Repository(id: "example/client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: false, recommended: false, access: .ready, reason: "Fetched from GitHub")
        ]
      ),
      repositorySelectionStore: selectionStore
    )

    store.connectGitHub()

    XCTAssertEqual(store.includedRepositories.map(\.id), ["example/client-api"])
  }

  func testFinishingRepositorySetupPersistsIncludedRepositories() throws {
    let selectionStore = InMemoryRepositorySelectionStore()
    let store = PRBarStore.sample(repositorySelectionStore: selectionStore)
    store.repositories = [
      Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub"),
      Repository(id: "example/client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: false, recommended: false, access: .ready, reason: "Fetched from GitHub")
    ]

    store.finishRepositorySetup()

    XCTAssertEqual(try selectionStore.loadIncludedRepositoryIDs(), ["mean-weasel/prbar"])
  }
}

private struct ThrowingGitHubRepositoryProvider: GitHubRepositoryProviding {
  func repositories() throws -> [Repository] {
    throw GitHubRepositoryError.invalidResponse
  }
}

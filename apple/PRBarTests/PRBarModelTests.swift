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

  func testWorkCardExportUsesCurrentStoreActivityAndGitHubHandle() {
    let store = PRBarStore.sample()
    store.githubConnection = GitHubConnection(status: .connected, user: GitHubUser(login: "octocat", displayName: "Octo Cat"))
    store.repositories = [
      Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub"),
      Repository(id: "example/client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: false, recommended: false, access: .ready, reason: "Fetched from GitHub")
    ]
    store.pullRequests = [
      PullRequest(id: "mean-weasel/prbar#101", title: "Share real proof", repoID: "mean-weasel/prbar", number: 101, mergedAt: SampleData.dateTime("2026-05-24T17:42:00Z")),
      PullRequest(id: "example/client-api#77", title: "Excluded private PR", repoID: "example/client-api", number: 77, mergedAt: SampleData.dateTime("2026-05-24T16:18:00Z"))
    ]
    store.releases = [
      ReleaseMoment(id: "mean-weasel/prbar@release:v1.0.0", repoID: "mean-weasel/prbar", title: "Share proof release", tag: "v1.0.0", date: SampleData.date("2026-05-24"), source: .release, notes: "Release notes from GitHub.", url: URL(string: "https://github.com/mean-weasel/prbar/releases/tag/v1.0.0")!)
    ]
    store.lastActivityRefreshAt = SampleData.dateTime("2026-05-24T18:30:00Z")

    let export = WorkCardExportBuilder.export(for: store)

    XCTAssertEqual(export.source.metric, "1 merged")
    XCTAssertEqual(export.source.repoNames, ["prbar"])
    XCTAssertEqual(export.source.handle, "@octocat")
    XCTAssertTrue(export.caption.contains("1 merged via PRBar"))
    XCTAssertTrue(export.caption.contains("Repos: prbar"))
    XCTAssertTrue(export.provenance.contains("1 selected repo"))
    XCTAssertTrue(export.freshness.contains("Last refreshed"))
    XCTAssertEqual(export.privacyMessage, "Only selected GitHub activity is included in this export.")
  }

  func testWorkCardExportLabelsCachedPrivateEvidenceBeforeSharing() {
    let store = PRBarStore.sample()
    store.repositories = [
      Repository(id: "example/client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub")
    ]
    store.pullRequests = [
      PullRequest(id: "example/client-api#77", title: "Private cached PR", repoID: "example/client-api", number: 77, mergedAt: SampleData.dateTime("2026-05-24T17:42:00Z"))
    ]
    store.releases = [
      ReleaseMoment(id: "example/client-api@release:v2.1.0", repoID: "example/client-api", title: "Private cached release", tag: "v2.1.0", date: SampleData.date("2026-05-24"), source: .release, notes: "Private release notes.", url: URL(string: "https://github.com/example/client-api/releases/tag/v2.1.0")!)
    ]
    store.lastActivityRefreshAt = SampleData.dateTime("2026-05-24T08:00:00Z")
    store.lastActivityRefreshAttemptAt = SampleData.dateTime("2026-05-24T09:00:00Z")
    store.activityRefreshIssue = AuthIssue(id: "github-network-unavailable", title: "Network unavailable", message: "GitHub is unavailable.")

    let export = WorkCardExportBuilder.export(for: store)

    XCTAssertTrue(export.includesPrivateEvidence)
    XCTAssertTrue(export.freshness.contains("Cached GitHub data"))
    XCTAssertTrue(export.privacyMessage.contains("private repo names"))
    XCTAssertTrue(export.evidence.contains { $0.isPrivate })
  }

  func testShippingSnapshotEvidenceIncludesPrivatePullRequestsWithoutReleases() {
    let store = PRBarStore.sample()
    store.repositories = [
      Repository(id: "example/client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub")
    ]
    store.pullRequests = [
      PullRequest(id: "example/client-api#77", title: "Private proof PR", repoID: "example/client-api", number: 77, mergedAt: SampleData.dateTime("2026-05-24T17:42:00Z"))
    ]
    store.releases = []
    store.prRange = .week
    store.activityAnchorDate = SampleData.date("2026-05-24")

    let export = WorkCardExportBuilder.export(for: store)

    XCTAssertEqual(export.source.metric, "1 merged")
    XCTAssertTrue(export.includesPrivateEvidence)
    XCTAssertTrue(export.evidence.contains {
      $0.title == "Private proof PR" &&
        $0.detail == "client-api #77" &&
        $0.isPrivate
    })
  }

  @MainActor
  func testWorkCardImageRendererProducesNativeImageArtifact() {
    let export = WorkCardExportBuilder.export(for: PRBarStore.sample(), side: .publicSide)

    let image = WorkCardImageRenderer.image(for: export)

    XCTAssertNotNil(image)
    XCTAssertGreaterThan(image?.size.width ?? 0, 0)
    XCTAssertGreaterThan(image?.size.height ?? 0, 0)
  }

  func testGitHubConnectionStartsRepoSetupWithNoReposIncludedByDefault() throws {
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
    XCTAssertEqual(store.includedRepositories.map(\.id), [])
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

  func testRestoringGitHubSessionWithoutStoredSelectionReturnsToRepoSetup() throws {
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
    XCTAssertEqual(store.routeState, .onboarding(.repositories))
  }

  func testRestoringGitHubSessionWithStoredSelectionDoesNotBlockOnActivityRefresh() throws {
    let sessionStore = InMemoryGitHubSessionStore()
    try sessionStore.saveSession(.fixture)
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: sessionStore),
      repositorySelectionStore: InMemoryRepositorySelectionStore(includedRepositoryIDs: ["prbar"])
    )
    store.githubConnection = .signedOut
    store.routeState = .signedOut

    store.restoreGitHubSession()

    XCTAssertEqual(store.githubConnection.status, .connected)
    XCTAssertEqual(store.routeState, .authenticated)
    XCTAssertEqual(store.includedRepositories.map(\.id), ["prbar"])
    XCTAssertNil(store.lastActivityRefreshAttemptAt)
  }

  func testRestoringGitHubSessionResetsOversizedStoredSelection() throws {
    let sessionStore = InMemoryGitHubSessionStore()
    try sessionStore.saveSession(.fixture)
    let repositories = Self.manyRepositories(count: 58)
    let selectionStore = InMemoryRepositorySelectionStore(includedRepositoryIDs: repositories.map(\.id))
    let cacheStore = InMemoryGitHubActivityCacheStore(
      record: GitHubActivityCacheRecord(
        githubLogin: "neonwatty",
        includedRepositoryIDs: repositories.map(\.id),
        snapshot: SampleData.activitySnapshot,
        lastRefreshedAt: SampleData.dateTime("2026-05-24T18:30:00Z")
      )
    )
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: sessionStore),
      repositoryProvider: StaticGitHubRepositoryProvider(repositories: repositories),
      repositorySelectionStore: selectionStore,
      activityCacheStore: cacheStore
    )

    store.restoreGitHubSession()

    XCTAssertEqual(store.routeState, .onboarding(.repositories))
    XCTAssertTrue(store.includedRepositories.isEmpty)
    XCTAssertNil(try selectionStore.loadIncludedRepositoryIDs())
    XCTAssertNil(cacheStore.record)
    XCTAssertNil(store.lastActivityRefreshAttemptAt)
  }

  func testRestoringGitHubSessionUsesCachedActivityWithoutBlockingOnRefresh() throws {
    let sessionStore = InMemoryGitHubSessionStore()
    try sessionStore.saveSession(.fixture)
    let cachedRefreshDate = SampleData.dateTime("2026-05-24T18:30:00Z")
    let cachedSnapshot = GitHubActivitySnapshot(
      pullRequests: [
        PullRequest(id: "prbar#424", title: "Cached relaunch PR", repoID: "prbar", number: 424, mergedAt: SampleData.dateTime("2026-05-24T19:30:00Z"))
      ],
      releases: [
        ReleaseMoment(id: "prbar@release:v4.2.4", repoID: "prbar", title: "Cached relaunch release", tag: "v4.2.4", date: SampleData.date("2026-05-24"), source: .release, notes: "Loaded from cache.", url: URL(string: "https://github.com/mean-weasel/prbar/releases/tag/v4.2.4")!)
      ],
      anchorDate: SampleData.date("2026-05-24")
    )
    let cacheStore = InMemoryGitHubActivityCacheStore(
      record: GitHubActivityCacheRecord(
        githubLogin: "neonwatty",
        includedRepositoryIDs: ["prbar"],
        snapshot: cachedSnapshot,
        lastRefreshedAt: cachedRefreshDate
      )
    )
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: sessionStore),
      activityProvider: ThrowingGitHubActivityProvider(error: GitHubAPIError.networkUnavailable),
      repositorySelectionStore: InMemoryRepositorySelectionStore(includedRepositoryIDs: ["prbar"]),
      activityCacheStore: cacheStore
    )
    store.githubConnection = .signedOut
    store.routeState = .signedOut

    store.restoreGitHubSession()

    XCTAssertEqual(store.routeState, .authenticated)
    XCTAssertEqual(store.pullRequests.map(\.id), ["prbar#424"])
    XCTAssertEqual(store.releases.map(\.id), ["prbar@release:v4.2.4"])
    XCTAssertEqual(store.lastActivityRefreshAt, cachedRefreshDate)
    XCTAssertNil(store.lastActivityRefreshAttemptAt)
    XCTAssertNil(store.activityRefreshIssue)
  }

  func testRestoringGitHubSessionWithoutMatchingCacheStillOpensAuthenticatedApp() throws {
    let sessionStore = InMemoryGitHubSessionStore()
    try sessionStore.saveSession(.fixture)
    let cacheStore = InMemoryGitHubActivityCacheStore(
      record: GitHubActivityCacheRecord(
        githubLogin: "octocat",
        includedRepositoryIDs: ["prbar"],
        snapshot: SampleData.activitySnapshot,
        lastRefreshedAt: SampleData.dateTime("2026-05-24T18:30:00Z")
      )
    )
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: sessionStore),
      activityProvider: ThrowingGitHubActivityProvider(error: GitHubAPIError.networkUnavailable),
      repositorySelectionStore: InMemoryRepositorySelectionStore(includedRepositoryIDs: ["prbar"]),
      activityCacheStore: cacheStore
    )

    store.restoreGitHubSession()

    XCTAssertEqual(store.routeState, .authenticated)
    XCTAssertEqual(store.includedRepositories.map(\.id), ["prbar"])
    XCTAssertNil(store.lastActivityRefreshAttemptAt)
    XCTAssertNil(store.activityRefreshIssue)
  }

  func testRestoringMissingGitHubSessionReturnsToSignedOut() {
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: InMemoryGitHubSessionStore())
    )

    store.restoreGitHubSession()

    XCTAssertEqual(store.githubConnection.status, .signedOut)
    XCTAssertEqual(store.routeState, .signedOut)
  }

  func testDisconnectingGitHubClearsIncludedReposAndReturnsToSignedOut() throws {
    let sessionStore = InMemoryGitHubSessionStore()
    try sessionStore.saveSession(.fixture)
    let cacheStore = InMemoryGitHubActivityCacheStore(
      record: GitHubActivityCacheRecord(
        githubLogin: "neonwatty",
        includedRepositoryIDs: ["prbar"],
        snapshot: SampleData.activitySnapshot,
        lastRefreshedAt: SampleData.dateTime("2026-05-24T18:30:00Z")
      )
    )
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: sessionStore),
      activityCacheStore: cacheStore
    )

    store.disconnectGitHub()

    XCTAssertEqual(store.routeState, .signedOut)
    XCTAssertEqual(store.githubConnection.status, .signedOut)
    XCTAssertNil(store.githubConnection.user)
    XCTAssertTrue(store.includedRepositories.isEmpty)
    XCTAssertNil(try sessionStore.loadSession())
    XCTAssertNil(cacheStore.record)
  }

  func testInMemoryGitHubSessionStoreRoundTripsSession() throws {
    let sessionStore = InMemoryGitHubSessionStore()

    try sessionStore.saveSession(.fixture)

    XCTAssertEqual(try sessionStore.loadSession(), .fixture)
  }

  func testGitHubOAuthConfigurationReadsClientIDFromEnvironmentBeforeBundleInfo() {
    let configuration = GitHubOAuthConfiguration.appDefault(
      environment: ["PRBAR_IOS_GITHUB_CLIENT_ID": "env-client-id"],
      bundleInfo: ["PRBarGitHubOAuthClientID": "bundle-client-id"]
    )

    XCTAssertEqual(configuration.clientID, "env-client-id")
    XCTAssertEqual(configuration.scopes, [])
  }

  func testGitHubOAuthConfigurationReadsClientIDFromBundleInfo() {
    let configuration = GitHubOAuthConfiguration.appDefault(
      environment: [:],
      bundleInfo: ["PRBarGitHubOAuthClientID": "bundle-client-id"]
    )

    XCTAssertEqual(configuration.clientID, "bundle-client-id")
  }

  func testGitHubOAuthConfigurationTreatsEmptyAndUnexpandedClientIDsAsMissing() {
    XCTAssertNil(
      GitHubOAuthConfiguration.appDefault(
        environment: [:],
        bundleInfo: ["PRBarGitHubOAuthClientID": "$(PRBAR_IOS_GITHUB_CLIENT_ID)"]
      ).clientID
    )
    XCTAssertNil(
      GitHubOAuthConfiguration.appDefault(
        environment: ["PRBAR_IOS_GITHUB_CLIENT_ID": "  "],
        bundleInfo: ["PRBarGitHubOAuthClientID": ""]
      ).clientID
    )
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

  func testDeviceFlowOmitsScopeForGitHubAppUserAuthorization() throws {
    let request = try GitHubDeviceFlowRequest.deviceCode(
      clientID: "client-id",
      scopes: []
    )

    XCTAssertEqual(String(data: try XCTUnwrap(request.httpBody), encoding: .utf8), "client_id=client-id")
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

  func testDeviceFlowBuildsUserRequest() throws {
    let request = try GitHubDeviceFlowRequest.user(token: "token")

    XCTAssertEqual(request.url?.absoluteString, "https://api.github.com/user")
    XCTAssertEqual(request.httpMethod, "GET")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
    XCTAssertEqual(request.value(forHTTPHeaderField: "X-GitHub-Api-Version"), "2022-11-28")
  }

  func testDeviceFlowAuthConnectRequestsDeviceCodeTokenAndUserAndStoresSession() throws {
    let sessionStore = InMemoryGitHubSessionStore()
    let transport = RecordingGitHubRepositoryTransport(
      responses: [
        Data(
          """
          {
            "device_code": "device-code",
            "user_code": "ABCD-EFGH",
            "verification_uri": "https://github.com/login/device",
            "expires_in": 900,
            "interval": 5
          }
          """.utf8
        ),
        Data(
          """
          {
            "access_token": "live-token",
            "token_type": "bearer",
            "scope": "public_repo read:user"
          }
          """.utf8
        ),
        Data(
          """
          {
            "login": "octocat",
            "name": "Octo Cat"
          }
          """.utf8
        )
      ]
    )
    let authService = GitHubDeviceFlowAuthService(
      configuration: GitHubOAuthConfiguration(
        clientID: "client-id",
        scopes: ["public_repo", "read:user"],
        maxTokenPollAttempts: 1
      ),
      sessionStore: sessionStore,
      transport: transport
    )

    let connection = try authService.connect()
    let savedSession = try XCTUnwrap(sessionStore.loadSession())

    XCTAssertEqual(connection.status, .connected)
    XCTAssertEqual(connection.user?.login, "octocat")
    XCTAssertEqual(connection.user?.displayName, "Octo Cat")
    XCTAssertEqual(savedSession.accessToken, "live-token")
    XCTAssertEqual(savedSession.tokenType, "bearer")
    XCTAssertEqual(savedSession.scopes, ["public_repo", "read:user"])
    XCTAssertEqual(
      transport.requests.map { $0.url?.absoluteString },
      [
        "https://github.com/login/device/code",
        "https://github.com/login/oauth/access_token",
        "https://api.github.com/user"
      ]
    )
    XCTAssertEqual(transport.requests.last?.value(forHTTPHeaderField: "Authorization"), "Bearer live-token")
  }

  func testDeviceFlowAuthReturnsPendingAuthorizationWhenTokenIsPending() throws {
    let transport = RecordingGitHubRepositoryTransport(
      responses: [
        Data(
          """
          {
            "device_code": "device-code",
            "user_code": "ABCD-EFGH",
            "verification_uri": "https://github.com/login/device",
            "expires_in": 900,
            "interval": 5
          }
          """.utf8
        ),
        Data(
          """
          {
            "error": "authorization_pending",
            "error_description": "authorization pending"
          }
          """.utf8
        )
      ]
    )
    let authService = GitHubDeviceFlowAuthService(
      configuration: GitHubOAuthConfiguration(
        clientID: "client-id",
        scopes: ["public_repo"],
        maxTokenPollAttempts: 1
      ),
      sessionStore: InMemoryGitHubSessionStore(),
      transport: transport
    )

    XCTAssertThrowsError(try authService.connect()) { error in
      guard case let GitHubAuthError.authorizationPending(authorization) = error else {
        return XCTFail("Expected authorization pending")
      }
      XCTAssertEqual(authorization.deviceCode, "device-code")
      XCTAssertEqual(authorization.userCode, "ABCD-EFGH")
      XCTAssertEqual(authorization.verificationURI.absoluteString, "https://github.com/login/device")
    }
    XCTAssertEqual(
      transport.requests.map { $0.url?.absoluteString },
      [
        "https://github.com/login/device/code",
        "https://github.com/login/oauth/access_token"
      ]
    )
  }

  func testConnectingGitHubCanResumePendingDeviceAuthorizationIntoRepoSetup() throws {
    let transport = RecordingGitHubRepositoryTransport(
      responses: [
        Data(
          """
          {
            "device_code": "device-code",
            "user_code": "ABCD-EFGH",
            "verification_uri": "https://github.com/login/device",
            "expires_in": 900,
            "interval": 5
          }
          """.utf8
        ),
        Data(
          """
          {
            "error": "authorization_pending",
            "error_description": "authorization pending"
          }
          """.utf8
        ),
        Data(
          """
          {
            "access_token": "live-token",
            "token_type": "bearer",
            "scope": "public_repo"
          }
          """.utf8
        ),
        Data(
          """
          {
            "login": "octocat",
            "name": "Octo Cat"
          }
          """.utf8
        )
      ]
    )
    let sessionStore = InMemoryGitHubSessionStore()
    let store = PRBarStore.sample(
      authService: GitHubDeviceFlowAuthService(
        configuration: GitHubOAuthConfiguration(
          clientID: "client-id",
          scopes: ["public_repo"],
          maxTokenPollAttempts: 1
        ),
        sessionStore: sessionStore,
        transport: transport
      ),
      repositoryProvider: StaticGitHubRepositoryProvider(
        repositories: [
          Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub")
        ]
      ),
      activityProvider: StaticGitHubActivityProvider(),
      repositorySelectionStore: InMemoryRepositorySelectionStore()
    )
    store.routeState = .signedOut
    store.githubConnection = .signedOut

    store.connectGitHub()

    guard case let .authorizing(authorization) = store.routeState else {
      return XCTFail("Expected pending device authorization")
    }
    XCTAssertEqual(authorization.userCode, "ABCD-EFGH")
    XCTAssertEqual(store.githubConnection.status, .signingIn)

    store.continueGitHubAuthorization()

    XCTAssertEqual(store.routeState, .onboarding(.repositories))
    XCTAssertEqual(store.githubConnection.user?.login, "octocat")
    XCTAssertEqual(try sessionStore.loadSession()?.accessToken, "live-token")
    XCTAssertEqual(store.includedRepositories.map(\.id), [])
    XCTAssertEqual(
      transport.requests.map { $0.url?.absoluteString },
      [
        "https://github.com/login/device/code",
        "https://github.com/login/oauth/access_token",
        "https://github.com/login/oauth/access_token",
        "https://api.github.com/user"
      ]
    )
  }

  func testDeviceAuthorizationTracksExpiryFromIssuedAt() throws {
    let issuedAt = Date(timeIntervalSince1970: 1_000)
    let authorization = GitHubDeviceAuthorization(
      deviceCode: "device-code",
      userCode: "ABCD-EFGH",
      verificationURI: try XCTUnwrap(URL(string: "https://github.com/login/device")),
      expiresIn: 900,
      interval: 5,
      issuedAt: issuedAt
    )

    XCTAssertEqual(authorization.expiresAt, Date(timeIntervalSince1970: 1_900))
    XCTAssertEqual(authorization.remainingSeconds(at: Date(timeIntervalSince1970: 1_060)), 840)
    XCTAssertFalse(authorization.isExpired(at: Date(timeIntervalSince1970: 1_899)))
    XCTAssertTrue(authorization.isExpired(at: Date(timeIntervalSince1970: 1_900)))
  }

  func testDeviceFlowAuthServiceStampsAuthorizationIssueTime() throws {
    let issuedAt = Date(timeIntervalSince1970: 2_000)
    let transport = RecordingGitHubRepositoryTransport(
      responses: [
        Data(
          """
          {
            "device_code": "device-code",
            "user_code": "ABCD-EFGH",
            "verification_uri": "https://github.com/login/device",
            "expires_in": 900,
            "interval": 5
          }
          """.utf8
        ),
        Data(
          """
          {
            "error": "authorization_pending",
            "error_description": "authorization pending"
          }
          """.utf8
        )
      ]
    )
    let service = GitHubDeviceFlowAuthService(
      configuration: GitHubOAuthConfiguration(
        clientID: "client-id",
        scopes: ["public_repo"],
        maxTokenPollAttempts: 1
      ),
      sessionStore: InMemoryGitHubSessionStore(),
      transport: transport,
      currentDate: { issuedAt }
    )

    XCTAssertThrowsError(try service.connect()) { error in
      guard case let GitHubAuthError.authorizationPending(authorization) = error else {
        return XCTFail("Expected pending authorization")
      }
      XCTAssertEqual(authorization.issuedAt, issuedAt)
      XCTAssertEqual(authorization.remainingSeconds(at: issuedAt.addingTimeInterval(10)), 890)
    }
  }

  func testExpiredDeviceAuthorizationRequiresFreshCodeBeforePolling() throws {
    let now = Date(timeIntervalSince1970: 2_000)
    let expiredAuthorization = GitHubDeviceAuthorization(
      deviceCode: "expired-device-code",
      userCode: "OLD-CODE",
      verificationURI: try XCTUnwrap(URL(string: "https://github.com/login/device")),
      expiresIn: 900,
      interval: 5,
      issuedAt: now.addingTimeInterval(-901)
    )
    let store = PRBarStore.sample(currentDate: { now })
    store.routeState = .authorizing(expiredAuthorization)
    store.githubConnection = GitHubConnection(status: .signingIn, user: nil)

    store.continueGitHubAuthorization()

    XCTAssertEqual(store.githubConnection, .signedOut)
    guard case let .issue(issue) = store.routeState else {
      return XCTFail("Expected expired-code issue")
    }
    XCTAssertEqual(issue.id, "github-device-code-expired")
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
    XCTAssertEqual(repositories.map(\.included), [false, false])
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
    XCTAssertEqual(store.includedRepositories.map(\.id), [])
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
    XCTAssertEqual(issue.id, "github-sync-failed")
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

  func testConnectingGitHubResetsOversizedPersistedRepositorySelection() throws {
    let repositories = Self.manyRepositories(count: 64)
    let selectionStore = InMemoryRepositorySelectionStore(includedRepositoryIDs: repositories.map(\.id))
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: InMemoryGitHubSessionStore(), session: .fixture),
      repositoryProvider: StaticGitHubRepositoryProvider(repositories: repositories),
      repositorySelectionStore: selectionStore
    )

    store.connectGitHub()

    XCTAssertEqual(store.routeState, .onboarding(.repositories))
    XCTAssertTrue(store.includedRepositories.isEmpty)
    XCTAssertNil(try selectionStore.loadIncludedRepositoryIDs())
  }

  func testRepositoryInclusionTogglePersistsSelectionImmediately() throws {
    let selectionStore = InMemoryRepositorySelectionStore(includedRepositoryIDs: ["mean-weasel/prbar"])
    let store = PRBarStore.sample(repositorySelectionStore: selectionStore)
    store.repositories = [
      Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub"),
      Repository(id: "example/client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: false, recommended: false, access: .ready, reason: "Fetched from GitHub")
    ]

    store.setRepositoryIncluded("example/client-api", included: true)
    XCTAssertEqual(try selectionStore.loadIncludedRepositoryIDs(), ["mean-weasel/prbar", "example/client-api"])

    store.setRepositoryIncluded("mean-weasel/prbar", included: false)
    XCTAssertEqual(try selectionStore.loadIncludedRepositoryIDs(), ["example/client-api"])
  }

  func testBatchRepositoryInclusionPersistsSelectionAndIgnoresBlockedRepos() throws {
    let selectionStore = InMemoryRepositorySelectionStore()
    let store = PRBarStore.sample(repositorySelectionStore: selectionStore)
    store.repositories = [
      Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: false, recommended: false, access: .ready, reason: "Fetched from GitHub"),
      Repository(id: "example/client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: false, recommended: false, access: .ready, reason: "Fetched from GitHub"),
      Repository(id: "example/sso", owner: "example", name: "sso", visibility: .private, colorHex: "#7c3aed", included: false, recommended: false, access: .sso, reason: "Needs SSO authorization")
    ]

    store.setRepositoriesIncluded(["mean-weasel/prbar", "example/client-api", "example/sso"], included: true)

    XCTAssertEqual(store.includedRepositories.map(\.id), ["mean-weasel/prbar", "example/client-api"])
    XCTAssertEqual(try selectionStore.loadIncludedRepositoryIDs(), ["mean-weasel/prbar", "example/client-api"])
  }

  @MainActor
  func testFinishingRepositorySetupPersistsIncludedRepositories() async throws {
    let selectionStore = InMemoryRepositorySelectionStore()
    let store = PRBarStore.sample(repositorySelectionStore: selectionStore)
    store.repositories = [
      Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub"),
      Repository(id: "example/client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: false, recommended: false, access: .ready, reason: "Fetched from GitHub")
    ]

    let refreshTask = store.finishRepositorySetup()
    await refreshTask?.value

    XCTAssertEqual(try selectionStore.loadIncludedRepositoryIDs(), ["mean-weasel/prbar"])
  }

  @MainActor
  func testFinishingRepositorySetupStartsRefreshWithoutBlockingSetup() async {
    let provider = SuspendedGitHubActivityProvider()
    let store = PRBarStore.sample(activityProvider: provider)
    store.repositories = [
      Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub")
    ]
    store.routeState = .onboarding(.repositories)

    let refreshTask = store.finishRepositorySetup()
    await Task.yield()

    XCTAssertEqual(store.routeState, .authenticated)
    XCTAssertTrue(store.isRefreshingActivity)
    XCTAssertEqual(store.activityRefreshProgress?.totalRepositories, 1)
    XCTAssertEqual(store.activityRefreshProgress?.currentRepositoryName, "prbar")

    provider.resume(
      with: GitHubActivitySnapshot(
        pullRequests: [
          PullRequest(id: "mean-weasel/prbar#41", title: "Async setup sync", repoID: "mean-weasel/prbar", number: 41, mergedAt: SampleData.dateTime("2026-05-24T12:00:00Z"))
        ],
        releases: [],
        anchorDate: SampleData.date("2026-05-24")
      )
    )
    await refreshTask?.value

    XCTAssertFalse(store.isRefreshingActivity)
    XCTAssertNil(store.activityRefreshProgress)
    XCTAssertEqual(store.pullRequests.map(\.id), ["mean-weasel/prbar#41"])
  }

  @MainActor
  func testFinishingRepositorySetupRefreshesActivityForIncludedRepositories() async {
    let refreshDate = SampleData.dateTime("2026-05-24T21:15:00Z")
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: InMemoryGitHubSessionStore(), session: .fixture),
      repositoryProvider: StaticGitHubRepositoryProvider(
        repositories: [
          Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub"),
          Repository(id: "example/client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub")
        ]
      ),
      activityProvider: StaticGitHubActivityProvider(
        snapshot: GitHubActivitySnapshot(
          pullRequests: [
            PullRequest(id: "mean-weasel/prbar#39", title: "Live merged PR", repoID: "mean-weasel/prbar", number: 39, mergedAt: SampleData.dateTime("2026-05-24T17:42:00Z")),
            PullRequest(id: "example/client-api#77", title: "Private should wait", repoID: "example/client-api", number: 77, mergedAt: SampleData.dateTime("2026-05-24T15:00:00Z"))
          ],
          releases: [
            ReleaseMoment(id: "mean-weasel/prbar@release:v1.4.0", repoID: "mean-weasel/prbar", title: "Live release", tag: "v1.4.0", date: SampleData.date("2026-05-24"), source: .release, notes: "Live release notes", url: URL(string: "https://github.com/mean-weasel/prbar/releases/tag/v1.4.0")!)
          ],
          anchorDate: SampleData.date("2026-05-24")
        )
      ),
      repositorySelectionStore: InMemoryRepositorySelectionStore(),
      currentDate: { refreshDate }
    )

    store.connectGitHub()
    store.repositories = store.repositories.map { repository in
      var repository = repository
      repository.included = repository.id == "mean-weasel/prbar"
      return repository
    }
    let refreshTask = store.finishRepositorySetup()
    await refreshTask?.value

    XCTAssertEqual(store.pullRequests.map(\.id), ["mean-weasel/prbar#39"])
    XCTAssertEqual(store.releases.map(\.id), ["mean-weasel/prbar@release:v1.4.0"])
    XCTAssertEqual(store.activityAnchorDate, SampleData.date("2026-05-24"))
    XCTAssertEqual(store.lastActivityRefreshAt, refreshDate)
  }

  @MainActor
  func testSuccessfulActivityRefreshWritesScopedCacheRecord() async {
    let refreshDate = SampleData.dateTime("2026-05-24T22:00:00Z")
    let cacheStore = InMemoryGitHubActivityCacheStore()
    let store = PRBarStore.sample(
      activityProvider: StaticGitHubActivityProvider(
        snapshot: GitHubActivitySnapshot(
          pullRequests: [
            PullRequest(id: "prbar#91", title: "Cache write PR", repoID: "prbar", number: 91, mergedAt: SampleData.dateTime("2026-05-24T20:00:00Z"))
          ],
          releases: [],
          anchorDate: SampleData.date("2026-05-24")
        )
      ),
      activityCacheStore: cacheStore,
      currentDate: { refreshDate }
    )
    store.repositories = [
      Repository(id: "prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub")
    ]

    await store.refreshActivity()

    XCTAssertEqual(cacheStore.record?.githubLogin, "neonwatty")
    XCTAssertEqual(cacheStore.record?.includedRepositoryIDs, ["prbar"])
    XCTAssertEqual(cacheStore.record?.snapshot.pullRequests.map(\.id), ["prbar#91"])
    XCTAssertEqual(cacheStore.record?.lastRefreshedAt, refreshDate)
  }

  @MainActor
  func testRefreshingActivityAppliesPartialSnapshotAndRecordsRepositoryIssues() async {
    let refreshDate = SampleData.dateTime("2026-05-24T22:05:00Z")
    let cacheStore = InMemoryGitHubActivityCacheStore()
    let store = PRBarStore.sample(
      activityProvider: StaticGitHubActivityProvider(
        snapshot: GitHubActivitySnapshot(
          pullRequests: [
            PullRequest(id: "mean-weasel/prbar#92", title: "Partial sync PR", repoID: "mean-weasel/prbar", number: 92, mergedAt: SampleData.dateTime("2026-05-24T20:30:00Z"))
          ],
          releases: [
            ReleaseMoment(id: "mean-weasel/prbar@release:v2.1.0", repoID: "mean-weasel/prbar", title: "Partial sync release", tag: "v2.1.0", date: SampleData.date("2026-05-24"), source: .release, notes: "Release notes", url: URL(string: "https://github.com/mean-weasel/prbar/releases/tag/v2.1.0")!)
          ],
          anchorDate: SampleData.date("2026-05-24"),
          repositoryIssues: [
            ActivityRepositoryIssue(
              repositoryID: "mean-weasel/private-api",
              repositoryFullName: "mean-weasel/private-api",
              title: "Repository needs attention",
              message: "Authorize SSO for mean-weasel/private-api, then refresh again."
            )
          ]
        )
      ),
      activityCacheStore: cacheStore,
      currentDate: { refreshDate }
    )
    store.repositories = [
      Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub"),
      Repository(id: "mean-weasel/private-api", owner: "mean-weasel", name: "private-api", visibility: .private, colorHex: "#f59e0b", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub")
    ]

    await store.refreshActivity()

    XCTAssertEqual(store.pullRequests.map(\.id), ["mean-weasel/prbar#92"])
    XCTAssertEqual(store.releases.map(\.id), ["mean-weasel/prbar@release:v2.1.0"])
    XCTAssertEqual(store.activityRepositoryIssues.map(\.repositoryID), ["mean-weasel/private-api"])
    XCTAssertNil(store.activityRefreshIssue)
    XCTAssertEqual(store.lastActivityRefreshAt, refreshDate)
    XCTAssertEqual(cacheStore.record?.snapshot.repositoryIssues.map(\.repositoryID), ["mean-weasel/private-api"])
  }

  @MainActor
  func testActivityRefreshFailureKeepsSampleActivityAndShowsIssue() async {
    let store = PRBarStore.sample(
      authService: StaticGitHubAuthService(sessionStore: InMemoryGitHubSessionStore(), session: .fixture),
      repositoryProvider: StaticGitHubRepositoryProvider(
        repositories: [
          Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub")
        ]
      ),
      activityProvider: ThrowingGitHubActivityProvider()
    )

    store.connectGitHub()
    store.repositories = store.repositories.map { repository in
      var repository = repository
      repository.included = true
      return repository
    }
    let refreshTask = store.finishRepositorySetup()
    await refreshTask?.value

    XCTAssertEqual(store.routeState, .authenticated)
    XCTAssertEqual(store.activityRefreshIssue?.id, "github-sync-failed")
    XCTAssertEqual(store.pullRequests.map(\.id), SampleData.pullRequests.map(\.id))
  }

  @MainActor
  func testRefreshingActivityReplacesPRsAndReleasesForIncludedRepositories() async {
    let refreshDate = SampleData.dateTime("2026-05-24T22:00:00Z")
    let refreshedSnapshot = GitHubActivitySnapshot(
      pullRequests: [
        PullRequest(id: "mean-weasel/prbar#90", title: "Refresh merged PR", repoID: "mean-weasel/prbar", number: 90, mergedAt: SampleData.dateTime("2026-05-24T19:00:00Z")),
        PullRequest(id: "example/client-api#22", title: "Excluded PR", repoID: "example/client-api", number: 22, mergedAt: SampleData.dateTime("2026-05-24T20:00:00Z"))
      ],
      releases: [
        ReleaseMoment(id: "mean-weasel/prbar@release:v2.0.0", repoID: "mean-weasel/prbar", title: "Refresh release", tag: "v2.0.0", date: SampleData.date("2026-05-24"), source: .release, notes: "Refreshed release notes", url: URL(string: "https://github.com/mean-weasel/prbar/releases/tag/v2.0.0")!),
        ReleaseMoment(id: "example/client-api@release:v1.0.0", repoID: "example/client-api", title: "Excluded release", tag: "v1.0.0", date: SampleData.date("2026-05-24"), source: .release, notes: "Should stay out", url: URL(string: "https://github.com/example/client-api/releases/tag/v1.0.0")!)
      ],
      anchorDate: SampleData.date("2026-05-24")
    )
    let store = PRBarStore.sample(
      activityProvider: SequencedGitHubActivityProvider(snapshots: [refreshedSnapshot]),
      currentDate: { refreshDate }
    )
    store.repositories = [
      Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub"),
      Repository(id: "example/client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: false, recommended: false, access: .ready, reason: "Fetched from GitHub")
    ]

    await store.refreshActivity()

    XCTAssertEqual(store.pullRequests.map(\.id), ["mean-weasel/prbar#90"])
    XCTAssertEqual(store.releases.map(\.id), ["mean-weasel/prbar@release:v2.0.0"])
    XCTAssertEqual(store.activityAnchorDate, SampleData.date("2026-05-24"))
    XCTAssertEqual(store.lastActivityRefreshAt, refreshDate)
    XCTAssertNil(store.activityRefreshIssue)
    XCTAssertNil(store.activityRefreshProgress)
    XCTAssertFalse(store.isRefreshingActivity)
  }

  @MainActor
  func testRefreshingActivityUsesCurrentDateAsActivityEndDate() async {
    let refreshDate = SampleData.dateTime("2026-05-30T10:00:00Z")
    let provider = RecordingGitHubActivityProvider()
    let store = PRBarStore.sample(
      activityProvider: provider,
      currentDate: { refreshDate }
    )
    store.activityAnchorDate = SampleData.date("2026-05-24")
    store.repositories = [
      Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: false, access: .ready, reason: "Fetched from GitHub")
    ]

    await store.refreshActivity()

    XCTAssertEqual(provider.requestedEndDates, [refreshDate])
    XCTAssertEqual(store.activityAnchorDate, SampleData.date("2026-05-30"))
    XCTAssertEqual(store.lastActivityRefreshAt, refreshDate)
  }

  @MainActor
  func testRefreshingActivityWithNoIncludedRepositoriesSkipsProviderAndClearsActivity() async {
    let refreshDate = SampleData.dateTime("2026-05-30T10:15:00Z")
    let provider = RecordingGitHubActivityProvider()
    let store = PRBarStore.sample(
      activityProvider: provider,
      currentDate: { refreshDate }
    )
    store.repositories = [
      Repository(id: "mean-weasel/prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: false, recommended: false, access: .ready, reason: "Fetched from GitHub")
    ]

    await store.refreshActivity()

    XCTAssertEqual(provider.activityAsyncCallCount, 0)
    XCTAssertTrue(store.pullRequests.isEmpty)
    XCTAssertTrue(store.releases.isEmpty)
    XCTAssertEqual(store.activityAnchorDate, SampleData.date("2026-05-30"))
    XCTAssertEqual(store.lastActivityRefreshAttemptAt, refreshDate)
    XCTAssertNil(store.lastActivityRefreshAt)
    XCTAssertNil(store.activityRefreshIssue)
    XCTAssertNil(store.activityRefreshProgress)
    XCTAssertFalse(store.isRefreshingActivity)
  }

  @MainActor
  func testRefreshingActivityFailureStaysInPlaceAndRecordsRefreshIssue() async {
    let attemptDate = SampleData.dateTime("2026-05-24T22:30:00Z")
    let store = PRBarStore.sample(
      activityProvider: ThrowingGitHubActivityProvider(),
      currentDate: { attemptDate }
    )
    let originalPullRequests = store.pullRequests
    let originalRefreshDate = SampleData.dateTime("2026-05-24T08:00:00Z")
    store.lastActivityRefreshAt = originalRefreshDate

    await store.refreshActivity()

    XCTAssertEqual(store.pullRequests, originalPullRequests)
    XCTAssertEqual(store.lastActivityRefreshAt, originalRefreshDate)
    XCTAssertEqual(store.lastActivityRefreshAttemptAt, attemptDate)
    XCTAssertEqual(store.activityRefreshIssue?.id, "github-sync-failed")
    XCTAssertFalse(store.isRefreshingActivity)
  }

  @MainActor
  func testRefreshingActivityRateLimitShowsSpecificRecoverableIssue() async {
    let store = PRBarStore.sample(
      activityProvider: ThrowingGitHubActivityProvider(error: GitHubAPIError.rateLimited(resetAt: nil))
    )

    await store.refreshActivity()

    XCTAssertEqual(store.activityRefreshIssue?.id, "github-rate-limited")
    XCTAssertEqual(store.activityRefreshIssue?.title, "GitHub rate limit reached")
    XCTAssertTrue(store.activityRefreshIssue?.message.contains("slow down") == true)
  }

  @MainActor
  func testRefreshingActivityUnauthorizedRemainsGlobalFailure() async {
    let store = PRBarStore.sample(
      activityProvider: ThrowingGitHubActivityProvider(error: GitHubAPIError.unauthorized)
    )
    store.activityRepositoryIssues = [
      ActivityRepositoryIssue(
        repositoryID: "mean-weasel/private-api",
        repositoryFullName: "mean-weasel/private-api",
        title: "Repository needs attention",
        message: "Authorize SSO for mean-weasel/private-api, then refresh again."
      )
    ]
    let originalPullRequests = store.pullRequests

    await store.refreshActivity()

    XCTAssertEqual(store.pullRequests, originalPullRequests)
    XCTAssertTrue(store.activityRepositoryIssues.isEmpty)
    XCTAssertEqual(store.activityRefreshIssue?.id, "github-session-expired")
    XCTAssertEqual(store.activityRefreshIssue?.title, "GitHub session expired")
  }

  @MainActor
  func testDuplicateRefreshWhileInFlightDoesNotStartSecondRefresh() async {
    let provider = SuspendedGitHubActivityProvider()
    let store = PRBarStore.sample(activityProvider: provider)

    let firstRefresh = Task {
      await store.refreshActivity()
    }
    for _ in 0..<1_000 where provider.activityAsyncCallCount == 0 {
      try? await Task.sleep(nanoseconds: 1_000_000)
    }

    XCTAssertEqual(provider.activityAsyncCallCount, 1)
    guard provider.activityAsyncCallCount == 1 else {
      provider.resume(with: GitHubActivitySnapshot(pullRequests: [], releases: [], anchorDate: SampleData.today))
      await firstRefresh.value
      return
    }

    await store.refreshActivity()

    XCTAssertEqual(provider.activityAsyncCallCount, 1)

    provider.resume(with: GitHubActivitySnapshot(pullRequests: [], releases: [], anchorDate: SampleData.today))
    await firstRefresh.value
    XCTAssertFalse(store.isRefreshingActivity)
  }

  @MainActor
  func testCancelledRefreshLeavesExistingDataWithoutRefreshIssue() async {
    let store = PRBarStore.sample(activityProvider: CancellingGitHubActivityProvider())
    let originalPullRequests = store.pullRequests

    await store.refreshActivity()

    XCTAssertEqual(store.pullRequests, originalPullRequests)
    XCTAssertNil(store.activityRefreshIssue)
    XCTAssertFalse(store.isRefreshingActivity)
  }
}

private extension PRBarModelTests {
  static func manyRepositories(count: Int) -> [Repository] {
    (0..<count).map { index in
      Repository(
        id: "neonwatty/repo-\(index)",
        owner: "neonwatty",
        name: "repo-\(index)",
        visibility: .public,
        colorHex: "#0ea5e9",
        included: false,
        recommended: false,
        access: .ready,
        reason: "Fetched from GitHub"
      )
    }
  }
}

private struct ThrowingGitHubRepositoryProvider: GitHubRepositoryProviding {
  func repositories() throws -> [Repository] {
    throw GitHubRepositoryError.invalidResponse
  }
}

private struct ThrowingGitHubActivityProvider: GitHubActivityProviding {
  var apiError: GitHubAPIError?

  init(error: GitHubAPIError? = nil) {
    self.apiError = error
  }

  func activity(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) throws -> GitHubActivitySnapshot {
    if let apiError {
      throw apiError
    }
    throw GitHubActivityError.invalidResponse
  }
}

private final class RecordingGitHubActivityProvider: GitHubActivityProviding, @unchecked Sendable {
  private(set) var requestedEndDates: [Date] = []
  private(set) var activityAsyncCallCount = 0

  func activity(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) throws -> GitHubActivitySnapshot {
    requestedEndDates.append(endDate)
    return snapshot(endingAt: endDate)
  }

  func activityAsync(
    for repositories: [Repository],
    endingAt endDate: Date,
    lookbackDays: Int,
    progress: (@MainActor (ActivityRefreshProgress) -> Void)?
  ) async throws -> GitHubActivitySnapshot {
    activityAsyncCallCount += 1
    requestedEndDates.append(endDate)
    let snapshot = snapshot(endingAt: endDate)
    await progress?(
      ActivityRefreshProgress(
        totalRepositories: repositories.count,
        completedRepositories: repositories.count,
        currentRepositoryName: nil,
        pullRequestCount: snapshot.pullRequests.count,
        releaseCount: snapshot.releases.count
      )
    )
    return snapshot
  }

  private func snapshot(endingAt endDate: Date) -> GitHubActivitySnapshot {
    GitHubActivitySnapshot(
      pullRequests: [
        PullRequest(id: "mean-weasel/prbar#101", title: "Current date refresh", repoID: "mean-weasel/prbar", number: 101, mergedAt: endDate)
      ],
      releases: [],
      anchorDate: Self.calendar.startOfDay(for: endDate)
    )
  }

  private static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }()
}

private final class SuspendedGitHubActivityProvider: GitHubActivityProviding, @unchecked Sendable {
  private var continuation: CheckedContinuation<GitHubActivitySnapshot, Error>?
  private var pendingSnapshot: GitHubActivitySnapshot?
  private(set) var activityAsyncCallCount = 0

  func activity(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) throws -> GitHubActivitySnapshot {
    GitHubActivitySnapshot(pullRequests: [], releases: [], anchorDate: endDate)
  }

  func activityAsync(
    for repositories: [Repository],
    endingAt endDate: Date,
    lookbackDays: Int,
    progress: (@MainActor (ActivityRefreshProgress) -> Void)?
  ) async throws -> GitHubActivitySnapshot {
    activityAsyncCallCount += 1
    await progress?(
      ActivityRefreshProgress(
        totalRepositories: repositories.count,
        completedRepositories: 0,
        currentRepositoryName: repositories.first?.name,
        pullRequestCount: 0,
        releaseCount: 0
      )
    )
    if let pendingSnapshot {
      self.pendingSnapshot = nil
      return pendingSnapshot
    }
    return try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
    }
  }

  func resume(with snapshot: GitHubActivitySnapshot) {
    if let continuation {
      continuation.resume(returning: snapshot)
      self.continuation = nil
    } else {
      pendingSnapshot = snapshot
    }
  }
}

private struct CancellingGitHubActivityProvider: GitHubActivityProviding {
  func activity(for repositories: [Repository], endingAt endDate: Date, lookbackDays: Int) throws -> GitHubActivitySnapshot {
    throw CancellationError()
  }
}

private final class RecordingGitHubRepositoryTransport: GitHubRepositoryTransport {
  private var responses: [Data]
  private(set) var requests: [URLRequest] = []

  init(responses: [Data]) {
    self.responses = responses
  }

  func data(for request: URLRequest) throws -> Data {
    requests.append(request)
    guard responses.isEmpty == false else {
      throw GitHubRepositoryError.invalidResponse
    }
    return responses.removeFirst()
  }
}

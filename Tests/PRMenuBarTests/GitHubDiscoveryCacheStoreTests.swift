import XCTest

@testable import PRMenuBar

final class GitHubDiscoveryCacheStoreTests: XCTestCase, GitHubPRActivityProviderTestHelpers {
  func testStorePersistsDiscoveryForTokenFingerprint() throws {
    let defaults = UserDefaults(suiteName: "GitHubDiscoveryCacheStoreTests")!
    defaults.removePersistentDomain(forName: "GitHubDiscoveryCacheStoreTests")
    let store = UserDefaultsGitHubDiscoveryCacheStore(defaults: defaults)
    let repositories = try JSONDecoder().decode(
      [GitHubRepository].self,
      from: repositoryDiscoveryData()
    )
    let cache = GitHubPersistedDiscoveryCache(
      cache: GitHubDiscoveryCache(
        createdAt: try date("2026-05-02T18:00:00Z"),
        authenticatedUser: GitHubAuthenticatedUser(login: "owner"),
        searchOwners: [GitHubSearchOwner(kind: .user, login: "owner")],
        pullableRepositories: repositories.filter(\.canPull)
      ),
      responseCache: [
        "/user": GitHubCachedAPIResponse(
          data: authenticatedUserData(),
          eTag: #""user-v1""#
        )
      ]
    )

    store.save(cache, token: "token-a")

    XCTAssertEqual(store.load(token: "token-a"), cache)
    XCTAssertNil(store.load(token: "token-b"))
    XCTAssertFalse(store.cacheKey(token: "token-a").contains("token-a"))
  }

  func testStoreReturnsNilForCorruptPayload() {
    let defaults = UserDefaults(suiteName: "GitHubDiscoveryCacheStoreCorruptTests")!
    defaults.removePersistentDomain(forName: "GitHubDiscoveryCacheStoreCorruptTests")
    let store = UserDefaultsGitHubDiscoveryCacheStore(defaults: defaults)

    defaults.set(Data("not-json".utf8), forKey: store.cacheKey(token: "token"))

    XCTAssertNil(store.load(token: "token"))
  }
}

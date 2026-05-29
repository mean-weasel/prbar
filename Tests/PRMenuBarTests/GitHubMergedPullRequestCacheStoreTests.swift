import XCTest

@testable import PRMenuBar

final class GitHubMergedPullRequestCacheStoreTests: XCTestCase,
  GitHubPRActivityProviderTestHelpers
{
  func testStorePersistsCacheForTokenFingerprint() throws {
    let defaults = UserDefaults(suiteName: "GitHubMergedPullRequestCacheStoreTests")!
    defaults.removePersistentDomain(forName: "GitHubMergedPullRequestCacheStoreTests")
    let store = UserDefaultsGitHubMergedPullRequestCacheStore(defaults: defaults)
    let cache = GitHubMergedPullRequestCache(
      owners: [GitHubSearchOwner(kind: .user, login: "owner")],
      mergedBy: "owner",
      repositoryIDs: ["owner/visible"],
      since: try date("2026-04-25T18:00:00Z"),
      until: try date("2026-05-02T18:00:00Z"),
      pullRequestsByID: [
        "PR_1": GitHubMergedPullRequest(
          id: "PR_1",
          title: "Merged",
          repositoryID: "owner/visible",
          mergedAt: try date("2026-04-27T12:00:00Z")
        )
      ]
    )

    store.save(cache, token: "token-a")

    XCTAssertEqual(store.load(token: "token-a"), cache)
    XCTAssertNil(store.load(token: "token-b"))
    XCTAssertFalse(store.cacheKey(token: "token-a").contains("token-a"))
  }

  func testStoreReturnsNilForCorruptPayload() throws {
    let defaults = UserDefaults(suiteName: "GitHubMergedPullRequestCacheStoreCorruptTests")!
    defaults.removePersistentDomain(forName: "GitHubMergedPullRequestCacheStoreCorruptTests")
    let store = UserDefaultsGitHubMergedPullRequestCacheStore(defaults: defaults)

    defaults.set(Data("not-json".utf8), forKey: store.cacheKey(token: "token"))

    XCTAssertNil(store.load(token: "token"))
  }
}

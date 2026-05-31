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

  func testFileStorePersistsCacheOutsideUserDefaults() throws {
    let directoryURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: directoryURL) }
    let store = FileGitHubMergedPullRequestCacheStore(directoryURL: directoryURL)
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
    XCTAssertTrue(FileManager.default.fileExists(atPath: store.fileURL(token: "token-a").path))
    XCTAssertFalse(store.fileURL(token: "token-a").lastPathComponent.contains("token-a"))
  }
}

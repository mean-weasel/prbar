import XCTest

@testable import PRMenuBar

final class PRInitialActivityStateTests: XCTestCase {
  func testGitHubStartupFailureUsesEmptyStoreInsteadOfSampleData() throws {
    let state = PRInitialActivityState.load(
      providerSelection: PRActivityProviderSelection(
        provider: FailingInitialProvider(),
        releaseProvider: SampleReleaseMomentProvider(),
        dataSource: .github
      ),
      now: try date("2026-05-04T20:00:00Z")
    )

    XCTAssertEqual(state.store.totalPullRequests, 0)
    XCTAssertEqual(state.store.activeRepositoryCount, 0)
    XCTAssertEqual(state.store.bucketTotals, [0, 0, 0, 0, 0, 0, 0])
    XCTAssertNotEqual(state.store.bucketTotals, [62, 64, 65, 66, 66, 69, 70])
    XCTAssertEqual(state.store.refreshedAt, .distantPast)
    XCTAssertTrue(state.refreshError?.hasPrefix("Scheduled refresh failed.") == true)
  }

  func testSampleStartupFailureStillUsesSampleStore() throws {
    let state = PRInitialActivityState.load(
      providerSelection: PRActivityProviderSelection(
        provider: FailingInitialProvider(),
        releaseProvider: SampleReleaseMomentProvider(),
        dataSource: .sample
      ),
      now: try date("2026-05-04T20:00:00Z")
    )

    XCTAssertEqual(state.store.bucketTotals, [62, 64, 65, 66, 66, 69, 70])
    XCTAssertNil(state.refreshError)
  }

  func testSuccessfulStartupUsesProviderStore() throws {
    let expected = PRActivityStore.empty(
      now: try date("2026-05-04T20:00:00Z"),
      refreshedAt: try date("2026-05-04T20:00:00Z"),
      calendar: .prActivityUTC
    )
    let state = PRInitialActivityState.load(
      providerSelection: PRActivityProviderSelection(
        provider: FixedInitialProvider(store: expected),
        releaseProvider: SampleReleaseMomentProvider(),
        dataSource: .github
      ),
      now: try date("2026-05-04T20:00:00Z")
    )

    XCTAssertEqual(state.store.refreshedAt, expected.refreshedAt)
    XCTAssertNil(state.refreshError)
  }

  private func date(_ text: String) throws -> Date {
    try XCTUnwrap(ISO8601DateFormatter().date(from: text))
  }
}

private struct FailingInitialProvider: PRActivityProviding {
  func load(now: Date) throws -> PRActivityStore {
    throw InitialProviderError.failure
  }
}

private struct FixedInitialProvider: PRActivityProviding {
  var store: PRActivityStore

  func load(now: Date) throws -> PRActivityStore {
    store
  }
}

private enum InitialProviderError: Error {
  case failure
}

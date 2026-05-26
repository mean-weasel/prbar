import XCTest
@testable import PRBar

final class PRBarModelTests: XCTestCase {
  func testIncludedRepositoriesFilterPrivateAndPublicRepos() {
    let store = PRBarStore.sample()

    XCTAssertEqual(store.includedRepositories.map(\.id), ["prbar", "launch-kit", "client-api"])
    XCTAssertTrue(store.includedRepositories.contains { $0.visibility == .private })
  }

  func testSelectedDayPullRequestsAreFilteredByCalendarDate() {
    var store = PRBarStore.sample()
    store.selectedPRDate = SampleData.date("2026-05-24")

    XCTAssertEqual(store.filteredPullRequests.map(\.id), ["pr-39", "pr-38"])
  }

  func testReleaseMomentsAreFilteredBySelectedDate() {
    var store = PRBarStore.sample()
    store.selectedReleaseDate = SampleData.date("2026-05-21")

    XCTAssertEqual(store.filteredReleases.map(\.id), ["tag-launch-100"])
  }

  func testPrivateEvidenceRequiresExportWarning() {
    let store = PRBarStore.sample()

    XCTAssertTrue(store.cardHasPrivateEvidence)
  }
}

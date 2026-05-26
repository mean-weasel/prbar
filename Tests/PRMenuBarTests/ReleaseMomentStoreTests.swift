import XCTest

@testable import PRMenuBar

final class ReleaseMomentStoreTests: XCTestCase {
  func testVisibleReleasesOnlyIncludesIncludedRepositoriesSortedNewestFirst() {
    let older = Date(timeIntervalSince1970: 100)
    let newer = Date(timeIntervalSince1970: 200)
    let store = ReleaseMomentStore(
      releases: [
        release(id: "excluded", repositoryID: "owner/hidden", date: newer),
        release(id: "older", repositoryID: "owner/included", date: older),
        release(id: "newer", repositoryID: "owner/included", date: newer),
      ]
    )
    let repositories = [
      repository(id: "owner/included", isIncluded: true),
      repository(id: "owner/hidden", isIncluded: false),
    ]

    let visible = store.visibleReleases(for: repositories)

    XCTAssertEqual(visible.map(\.id), ["newer", "older"])
  }

  func testReleaseSourceLabelsDistinguishOfficialReleaseFromTagFallback() {
    XCTAssertEqual(ReleaseMoment.Source.githubRelease.badgeText, "Release")
    XCTAssertEqual(ReleaseMoment.Source.githubRelease.notesTitle, "Original release notes")
    XCTAssertEqual(ReleaseMoment.Source.tag.badgeText, "Tag")
    XCTAssertEqual(ReleaseMoment.Source.tag.notesTitle, "Generated tag summary")
  }

  private func release(
    id: String,
    repositoryID: String,
    date: Date,
    source: ReleaseMoment.Source = .githubRelease
  ) -> ReleaseMoment {
    ReleaseMoment(
      id: id,
      repositoryID: repositoryID,
      title: "Release \(id)",
      tag: "v1.0.0",
      date: date,
      notes: "Release notes",
      url: URL(string: "https://github.com/\(repositoryID)/releases/tag/v1.0.0"),
      source: source
    )
  }

  private func repository(id: String, isIncluded: Bool) -> RepositoryActivity {
    RepositoryActivity(
      id: id,
      owner: id.components(separatedBy: "/").first ?? "owner",
      name: id.components(separatedBy: "/").last ?? "repo",
      colorHex: "#0ea5e9",
      weeklyCounts: [1],
      isIncluded: isIncluded
    )
  }
}

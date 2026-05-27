import XCTest

@testable import PRMenuBar

final class ShareCardBuilderTests: XCTestCase {
  func testPRActivityPayloadIncludesSortedRepoDistributionAndMasksPrivateRepos() {
    let store = PRActivityStore(
      bucketLabels: ["W1", "W2"],
      dailyBucketLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      window: .oneWeek,
      bin: .day,
      refreshInterval: .daily,
      repositories: [
        repository(id: "owner/public", name: "public", count: 3, isPrivate: false),
        repository(id: "owner/private", name: "client-secret", count: 5, isPrivate: true),
        repository(id: "owner/zero", name: "zero", count: 0, isPrivate: false),
      ],
      refreshedAt: Date(timeIntervalSince1970: 0)
    )

    let payload = ShareCardBuilder.prActivityPayload(store: store)

    XCTAssertEqual(payload.headline, "8 merged PRs past week")
    XCTAssertEqual(payload.totalPullRequests, 8)
    XCTAssertEqual(payload.repoRows.map(\.displayName), ["Private repo", "public"])
    XCTAssertEqual(payload.repoRows.map(\.count), [5, 3])
    XCTAssertFalse(payload.showsPrivateRepositoryNames)
    XCTAssertEqual(payload.chartBuckets.map(\.total), [0, 0, 0, 0, 0, 0, 8])
    XCTAssertEqual(payload.chartBuckets.last?.segments.map(\.value), [5, 3])
  }

  func testPRActivityPayloadCanRevealPrivateRepositoryNames() {
    let store = PRActivityStore(
      bucketLabels: ["W1", "W2"],
      dailyBucketLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      window: .oneWeek,
      bin: .day,
      refreshInterval: .daily,
      showPrivateRepositoryNamesInShare: true,
      repositories: [
        repository(id: "owner/private", name: "client-secret", count: 5, isPrivate: true)
      ],
      refreshedAt: Date(timeIntervalSince1970: 0)
    )

    let payload = ShareCardBuilder.prActivityPayload(store: store)

    XCTAssertTrue(payload.showsPrivateRepositoryNames)
    XCTAssertEqual(payload.repoRows.map(\.displayName), ["client-secret"])
  }

  func testReleasePayloadMasksPrivateRepositoryAndLabelsSource() {
    let release = ReleaseMoment(
      id: "rel",
      repositoryID: "owner/private",
      title: "Webhook retry hardening",
      tag: "v2.1.0",
      date: Date(timeIntervalSince1970: 0),
      notes: "Hardens webhook signature checks and adds clearer retry handling.",
      url: nil,
      source: .tag
    )
    let repository = repository(
      id: "owner/private",
      name: "client-secret",
      count: 5,
      isPrivate: true
    )

    let payload = ShareCardBuilder.releasePayload(release: release, repository: repository)

    XCTAssertEqual(payload.headline, "v2.1.0 Webhook retry hardening")
    XCTAssertEqual(payload.repositoryDisplayName, "Private repo")
    XCTAssertEqual(payload.sourceLabel, "Tag-derived summary")
    XCTAssertEqual(payload.notesExcerpt, release.notes)
    XCTAssertFalse(payload.showsPrivateRepositoryName)
  }

  func testReleasePayloadCanRevealPrivateRepositoryName() {
    let release = ReleaseMoment(
      id: "rel",
      repositoryID: "owner/private",
      title: "Webhook retry hardening",
      tag: "v2.1.0",
      date: Date(timeIntervalSince1970: 0),
      notes: "Hardens webhook signature checks and adds clearer retry handling.",
      url: nil,
      source: .tag
    )
    let repository = repository(
      id: "owner/private",
      name: "client-secret",
      count: 5,
      isPrivate: true
    )

    let payload = ShareCardBuilder.releasePayload(
      release: release,
      repository: repository,
      revealingPrivateNames: true
    )

    XCTAssertEqual(payload.repositoryDisplayName, "client-secret")
    XCTAssertTrue(payload.showsPrivateRepositoryName)
  }

  func testShareCardExportFilenamesAreSpecificAndFilesystemSafe() {
    let prPayload = ShareCardPayload.prActivity(
      PRShareCardPayload(
        headline: "12 merged PRs past week",
        rangeLabel: "Past Week",
        totalPullRequests: 12,
        activeRepositoryCount: 3,
        showsPrivateRepositoryNames: false,
        chartBuckets: [],
        repoRows: []
      )
    )
    let releasePayload = ShareCardPayload.release(
      ReleaseShareCardPayload(
        headline: "v2.1.0 Webhook / retry hardening",
        repositoryDisplayName: "owner/project",
        dateLabel: "May 26",
        notesExcerpt: "Release notes",
        sourceLabel: "GitHub Release",
        showsPrivateRepositoryName: false
      )
    )

    XCTAssertEqual(prPayload.exportFilename, "prbar-pr-card-past-week.png")
    XCTAssertEqual(
      releasePayload.exportFilename,
      "prbar-release-card-owner-project-v2-1-0-webhook-retry-hardening.png"
    )
  }

  private func repository(
    id: String,
    name: String,
    count: Int,
    isPrivate: Bool
  ) -> RepositoryActivity {
    RepositoryActivity(
      id: id,
      owner: "owner",
      name: name,
      colorHex: "#0ea5e9",
      weeklyCounts: [count],
      dailyCounts: [0, 0, 0, 0, 0, 0, count],
      isIncluded: true,
      isPrivate: isPrivate
    )
  }
}

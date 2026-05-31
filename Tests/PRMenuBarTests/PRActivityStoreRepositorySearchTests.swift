import XCTest

@testable import PRMenuBar

final class PRActivityStoreRepositorySearchTests: XCTestCase {
  func testRepositorySearchMatchesNameOwnerAndFullID() {
    let store = repositorySearchStore()

    XCTAssertEqual(
      store.repositoryIndices(matching: "deck").map { store.repositories[$0].id },
      ["mean-weasel/deckchecker"]
    )
    XCTAssertEqual(
      store.repositoryIndices(matching: "NEON").map { store.repositories[$0].id },
      ["neonwatty/RedditReminder", "neonwatty/nav-map"]
    )
    XCTAssertEqual(
      store.repositoryIndices(matching: "mean-weasel/seat").map { store.repositories[$0].id },
      ["mean-weasel/seatify"]
    )
  }

  func testRepositorySearchTrimsWhitespaceAndReturnsAllForEmptyQuery() {
    let store = repositorySearchStore()

    XCTAssertEqual(
      store.repositoryIndices(matching: "  reddit  ").map { store.repositories[$0].id },
      ["neonwatty/RedditReminder"]
    )
    XCTAssertEqual(
      store.repositoryIndices(matching: "").map { store.repositories[$0].id },
      store.repositories.map(\.id)
    )
    XCTAssertEqual(
      store.repositoryIndices(matching: "   ").map { store.repositories[$0].id },
      store.repositories.map(\.id)
    )
  }

  func testRepositorySearchReturnsEmptyForNoMatch() {
    let store = repositorySearchStore()

    XCTAssertTrue(store.repositoryIndices(matching: "missing").isEmpty)
  }

  func testSetRepositoriesIncludedMatchingQueryOnlyMutatesFilteredRepositories() {
    var store = repositorySearchStore()

    store.setRepositoriesIncluded(false, matching: "mean-weasel")

    XCTAssertEqual(
      repositoryInclusionSnapshot(store),
      [
        "mean-weasel/deckchecker:false",
        "mean-weasel/seatify:false",
        "neonwatty/RedditReminder:true",
        "neonwatty/nav-map:false",
      ]
    )

    store.setRepositoriesIncluded(true, matching: "nav")

    XCTAssertEqual(
      repositoryInclusionSnapshot(store),
      [
        "mean-weasel/deckchecker:false",
        "mean-weasel/seatify:false",
        "neonwatty/RedditReminder:true",
        "neonwatty/nav-map:true",
      ]
    )
  }

  func testSetRepositoriesIncludedWithEmptyAndMissingQueries() {
    var store = repositorySearchStore()

    store.setRepositoriesIncluded(false, matching: "missing")

    XCTAssertEqual(
      repositoryInclusionSnapshot(store),
      [
        "mean-weasel/deckchecker:true",
        "mean-weasel/seatify:false",
        "neonwatty/RedditReminder:true",
        "neonwatty/nav-map:false",
      ]
    )

    store.setRepositoriesIncluded(true, matching: " ")

    XCTAssertTrue(store.repositories.allSatisfy(\.isIncluded))
  }

  private func repositorySearchStore() -> PRActivityStore {
    PRActivityStore(
      bucketLabels: ["W1"],
      window: .twoWeeks,
      bin: .week,
      refreshInterval: .daily,
      repositories: [
        searchRepository(id: "mean-weasel/deckchecker", isIncluded: true),
        searchRepository(id: "mean-weasel/seatify", isIncluded: false),
        searchRepository(id: "neonwatty/RedditReminder", isIncluded: true),
        searchRepository(id: "neonwatty/nav-map", isIncluded: false),
      ],
      refreshedAt: Date()
    )
  }

  private func searchRepository(id: String, isIncluded: Bool) -> RepositoryActivity {
    let parts = id.split(separator: "/", maxSplits: 1).map(String.init)
    return RepositoryActivity(
      id: id,
      owner: parts[0],
      name: parts[1],
      colorHex: "#ffffff",
      weeklyCounts: [1],
      isIncluded: isIncluded
    )
  }

  private func repositoryInclusionSnapshot(_ store: PRActivityStore) -> [String] {
    store.repositories.map { "\($0.id):\($0.isIncluded)" }
  }
}

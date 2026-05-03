import XCTest

@testable import PRMenuBar

final class GitHubMergedPullRequestTests: XCTestCase {
  func testSearchResponseDecodesMergedPullRequests() throws {
    let data = Data(
      """
      {
        "total_count": 1,
        "incomplete_results": false,
        "items": [
          {
            "title": "Ship provider",
            "pull_request": {
              "merged_at": "2026-05-01T12:34:56.000Z"
            }
          }
        ]
      }
      """.utf8
    )

    let response = try JSONDecoder().decode(
      GitHubMergedPullRequestSearchResponse.self,
      from: data
    )

    XCTAssertEqual(response.items.count, 1)
    XCTAssertEqual(response.totalCount, 1)
    XCTAssertFalse(response.incompleteResults)
    XCTAssertFalse(response.needsPagination(perPage: 100))
    XCTAssertEqual(response.items.first?.title, "Ship provider")
    XCTAssertEqual(response.items.first?.mergedAt, Date(timeIntervalSince1970: 1_777_638_896))
  }

  func testSearchResponseDetectsPaginationNeed() {
    let response = GitHubMergedPullRequestSearchResponse(
      totalCount: 101,
      items: []
    )

    XCTAssertTrue(response.needsPagination(perPage: 100))
  }

  func testSearchResponseDecodesMergedAtWithoutFractionalSeconds() throws {
    let data = Data(
      """
      {
        "items": [
          {
            "title": "Ship provider",
            "pull_request": {
              "merged_at": "2026-05-01T12:34:56Z"
            }
          }
        ]
      }
      """.utf8
    )

    let response = try JSONDecoder().decode(
      GitHubMergedPullRequestSearchResponse.self,
      from: data
    )

    XCTAssertEqual(response.items.first?.mergedAt, Date(timeIntervalSince1970: 1_777_638_896))
  }

  func testSearchResponseRejectsInvalidMergedAtDate() {
    let data = Data(
      """
      {
        "items": [
          {
            "title": "Bad date",
            "pull_request": {
              "merged_at": "not-a-date"
            }
          }
        ]
      }
      """.utf8
    )

    XCTAssertThrowsError(
      try JSONDecoder().decode(GitHubMergedPullRequestSearchResponse.self, from: data)
    )
  }
}

import XCTest

@testable import PRMenuBar

final class GitHubRepositoryTests: XCTestCase {
  func testRepositoryDecodesAndMapsToActivity() throws {
    let data = Data(
      """
      {
        "full_name": "owner/project",
        "name": "project",
        "owner": { "login": "owner" },
        "permissions": { "pull": true }
      }
      """.utf8
    )

    let repository = try JSONDecoder().decode(GitHubRepository.self, from: data)
    let activity = repository.activity(bucketCount: 4)

    XCTAssertEqual(repository.fullName, "owner/project")
    XCTAssertTrue(repository.canPull)
    XCTAssertEqual(activity.id, "owner/project")
    XCTAssertEqual(activity.owner, "owner")
    XCTAssertEqual(activity.name, "project")
    XCTAssertEqual(activity.weeklyCounts, [0, 0, 0, 0])
    XCTAssertTrue(activity.isIncluded)
  }

  func testRepositoryWithoutPermissionsDefaultsToPullable() throws {
    let data = Data(
      """
      {
        "full_name": "owner/project",
        "name": "project",
        "owner": { "login": "owner" }
      }
      """.utf8
    )

    let repository = try JSONDecoder().decode(GitHubRepository.self, from: data)

    XCTAssertTrue(repository.canPull)
  }

  func testColorMappingIsDeterministic() {
    XCTAssertEqual(
      RepositoryColor.hexColor(for: "owner/project"),
      RepositoryColor.hexColor(for: "owner/project")
    )
  }
}

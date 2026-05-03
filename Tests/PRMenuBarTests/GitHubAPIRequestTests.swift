import XCTest

@testable import PRMenuBar

final class GitHubAPIRequestTests: XCTestCase {
  func testUserRepositoriesRequestIncludesAuthAndDiscoveryQuery() throws {
    let request = try GitHubAPIRequest.userRepositories(page: 2, perPage: 50)
      .urlRequest(token: "test-token")

    XCTAssertEqual(request.httpMethod, "GET")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
    XCTAssertEqual(request.value(forHTTPHeaderField: "X-GitHub-Api-Version"), "2022-11-28")
    XCTAssertEqual(request.url?.scheme, "https")
    XCTAssertEqual(request.url?.host, "api.github.com")
    XCTAssertEqual(request.url?.path, "/user/repos")

    let components = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)
    let queryItems = components?.queryItems ?? []
    let query = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value) })
    XCTAssertEqual(query["affiliation"], "owner,collaborator,organization_member")
    XCTAssertEqual(query["sort"], "pushed")
    XCTAssertEqual(query["direction"], "desc")
    XCTAssertEqual(query["per_page"], "50")
    XCTAssertEqual(query["page"], "2")
  }

  func testRequestCanUseFixtureBaseURL() throws {
    let request = try GitHubAPIRequest(path: "/repos/owner/repo/pulls")
      .urlRequest(token: "token", baseURL: URL(string: "https://example.test/api")!)

    XCTAssertEqual(request.url?.absoluteString, "https://example.test/api/repos/owner/repo/pulls")
  }
}

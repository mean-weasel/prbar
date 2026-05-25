import Foundation
import XCTest

@testable import PRMenuBar

final class FixtureGitHubAPITransport: GitHubAPITransport {
  var responses: [GitHubAPIResponse]
  private(set) var capturedRequests: [URLRequest] = []

  init(data: Data) {
    responses = [GitHubAPIResponse(data: data)]
  }

  init(responses: [Data]) {
    self.responses = responses.map { GitHubAPIResponse(data: $0) }
  }

  init(responses: [GitHubAPIResponse]) {
    self.responses = responses
  }

  func response(for request: URLRequest) throws -> GitHubAPIResponse {
    capturedRequests.append(request)
    guard responses.isEmpty == false else {
      return GitHubAPIResponse(data: Data())
    }
    return responses.removeFirst()
  }
}

protocol GitHubPRActivityProviderTestHelpers: XCTestCase {}

extension GitHubPRActivityProviderTestHelpers {
  func repositoryDiscoveryData() -> Data {
    repositoryDiscoveryData(
      repositories: [
        repositoryFixture(owner: "owner", name: "visible", canPull: true),
        repositoryFixture(owner: "owner", name: "hidden", canPull: false),
      ]
    )
  }

  func repositoryDiscoveryData(repositories: [String]) -> Data {
    Data(
      "[\(repositories.joined(separator: ","))]".utf8
    )
  }

  func repositoryFixture(owner: String, name: String, canPull: Bool) -> String {
    """
    {
      "full_name": "\(owner)/\(name)",
      "name": "\(name)",
      "owner": { "login": "\(owner)" },
      "permissions": { "pull": \(canPull) }
    }
    """
  }

  func authenticatedUserData(login: String = "owner") -> Data {
    Data(#"{ "login": "\#(login)" }"#.utf8)
  }

  func organizationsData(logins: [String] = []) -> Data {
    Data("[\(logins.map { #"{ "login": "\#($0)" }"# }.joined(separator: ","))]".utf8)
  }

  func graphQLMergedPullRequestData(
    mergedAt: String,
    mergedBy: String = "owner",
    id: String? = nil,
    hasNextPage: Bool = false,
    endCursor: String? = nil
  ) -> Data {
    let cursor = endCursor.map { #""\#($0)""# } ?? "null"
    let pullRequestID = id ?? "PR_\(mergedAt)"
    return Data(
      """
      {
        "data": {
          "search": {
            "pageInfo": {
              "hasNextPage": \(hasNextPage),
              "endCursor": \(cursor)
            },
            "nodes": [
              {
                "id": "\(pullRequestID)",
                "title": "Merged",
                "mergedAt": "\(mergedAt)",
                "mergedBy": { "login": "\(mergedBy)" },
                "repository": { "nameWithOwner": "owner/visible" }
              }
            ]
          }
        }
      }
      """.utf8
    )
  }

  func graphQLErrorData(message: String) -> Data {
    Data(
      """
      {
        "errors": [
          { "message": "\(message)" }
        ]
      }
      """.utf8
    )
  }

  func date(_ text: String) throws -> Date {
    try XCTUnwrap(ISO8601DateFormatter().date(from: text))
  }

  func queryValue(_ name: String, in request: URLRequest) -> String? {
    guard
      let url = request.url,
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else {
      return nil
    }
    return components.queryItems?.first { $0.name == name }?.value
  }

  func bodyString(in request: URLRequest) -> String? {
    request.httpBody.flatMap { String(data: $0, encoding: .utf8) }
  }
}

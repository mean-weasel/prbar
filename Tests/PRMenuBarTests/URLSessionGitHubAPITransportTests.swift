import XCTest

@testable import PRMenuBar

final class URLSessionGitHubAPITransportTests: XCTestCase {
  override func tearDown() {
    MockURLProtocol.handler = nil
    super.tearDown()
  }

  func testTransportReturnsSuccessfulResponseData() throws {
    MockURLProtocol.handler = { request in
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: try XCTUnwrap(request.url),
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )
      )
      return (response, Data("[{\"full_name\":\"owner/repo\"}]".utf8))
    }

    let transport = URLSessionGitHubAPITransport(session: mockSession())
    let response = try transport.response(
      for: URLRequest(url: URL(string: "https://example.test")!)
    )

    XCTAssertEqual(
      String(data: response.data, encoding: .utf8),
      "[{\"full_name\":\"owner/repo\"}]"
    )
    XCTAssertEqual(response.statusCode, 200)
  }

  func testTransportReturnsETagMetadata() throws {
    MockURLProtocol.handler = { request in
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: try XCTUnwrap(request.url),
          statusCode: 200,
          httpVersion: nil,
          headerFields: ["ETag": #""repos-v1""#]
        )
      )
      return (response, Data("[]".utf8))
    }

    let transport = URLSessionGitHubAPITransport(session: mockSession())
    let response = try transport.response(
      for: URLRequest(url: URL(string: "https://example.test")!)
    )

    XCTAssertEqual(response.eTag, #""repos-v1""#)
    XCTAssertEqual(response.statusCode, 200)
  }

  func testTransportTreatsNotModifiedAsSuccessfulMetadataResponse() throws {
    MockURLProtocol.handler = { request in
      let response = try XCTUnwrap(
        HTTPURLResponse(
          url: try XCTUnwrap(request.url),
          statusCode: 304,
          httpVersion: nil,
          headerFields: ["ETag": #""repos-v1""#]
        )
      )
      return (response, Data())
    }

    let transport = URLSessionGitHubAPITransport(session: mockSession())
    let response = try transport.response(
      for: URLRequest(url: URL(string: "https://example.test")!)
    )

    XCTAssertTrue(response.isNotModified)
    XCTAssertEqual(response.eTag, #""repos-v1""#)
    XCTAssertTrue(response.data.isEmpty)
  }

  func testTransportThrowsHTTPStatusErrors() {
    MockURLProtocol.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 403,
        httpVersion: nil,
        headerFields: nil
      )!
      return (response, Data())
    }

    let transport = URLSessionGitHubAPITransport(session: mockSession())

    XCTAssertThrowsError(
      try transport.data(for: URLRequest(url: URL(string: "https://example.test")!))
    ) { error in
      XCTAssertEqual(error as? URLSessionGitHubAPITransportError, .httpStatus(403))
    }
  }

  func testTransportIncludesRateLimitResetDateInHTTPStatusErrors() {
    MockURLProtocol.handler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 403,
        httpVersion: nil,
        headerFields: ["X-RateLimit-Reset": "1777638896"]
      )!
      return (response, Data())
    }

    let transport = URLSessionGitHubAPITransport(session: mockSession())

    XCTAssertThrowsError(
      try transport.data(for: URLRequest(url: URL(string: "https://example.test")!))
    ) { error in
      XCTAssertEqual(
        error as? URLSessionGitHubAPITransportError,
        .httpStatus(403, rateLimitReset: Date(timeIntervalSince1970: 1_777_638_896))
      )
    }
  }

  private func mockSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
  }
}

private final class MockURLProtocol: URLProtocol {
  static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    do {
      let (response, data) = try XCTUnwrap(Self.handler)(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}

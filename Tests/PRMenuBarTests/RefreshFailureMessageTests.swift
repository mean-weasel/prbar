import XCTest

@testable import PRMenuBar

final class RefreshFailureMessageTests: XCTestCase {
  func testManualMessageKeepsPreviousActivityForGenericErrors() {
    let message = RefreshFailureMessage.manual(error: SampleError())

    XCTAssertEqual(message, "Refresh failed. Keeping the previous activity.")
  }

  func testScheduledMessageIncludesRateLimitResetTime() {
    let resetDate = Date(timeIntervalSince1970: 1_777_638_896)
    let message = RefreshFailureMessage.scheduled(
      error: URLSessionGitHubAPITransportError.httpStatus(403, rateLimitReset: resetDate)
    )

    XCTAssertTrue(message.hasPrefix("Scheduled refresh failed. GitHub rate limit resets at "))
  }

  private struct SampleError: Error {}
}

import Foundation

enum RefreshFailureMessage {
  static func manual(error: Error) -> String {
    message(prefix: "Refresh failed", error: error)
  }

  static func scheduled(error: Error) -> String {
    message(prefix: "Scheduled refresh failed", error: error)
  }

  private static func message(prefix: String, error: Error) -> String {
    if case URLSessionGitHubAPITransportError.httpStatus(_, let rateLimitReset) = error,
      let rateLimitReset
    {
      return "\(prefix). GitHub rate limit resets at \(timeFormatter.string(from: rateLimitReset))."
    }

    return "\(prefix). Keeping the previous activity."
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }()
}

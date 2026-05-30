import Foundation

struct AppVersion: Equatable {
  var marketingVersion: String
  var buildNumber: String

  init(infoDictionary: [String: Any]) {
    marketingVersion = Self.value(
      for: "CFBundleShortVersionString",
      in: infoDictionary,
      fallback: "0.0.0"
    )
    buildNumber = Self.value(
      for: "CFBundleVersion",
      in: infoDictionary,
      fallback: "0"
    )
  }

  static var current: AppVersion {
    AppVersion(infoDictionary: Bundle.main.infoDictionary ?? [:])
  }

  var displayValue: String {
    "\(marketingVersion) (\(buildNumber))"
  }

  private static func value(
    for key: String,
    in infoDictionary: [String: Any],
    fallback: String
  ) -> String {
    guard let value = infoDictionary[key] as? String else {
      return fallback
    }

    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? fallback : trimmed
  }
}

import Foundation

enum GitHubCLITokenResolver {
  static let pathEnvironmentKey = "PR_MENU_BAR_GH_PATH"
  static let disabledEnvironmentKey = "PR_MENU_BAR_DISABLE_GH_AUTH"

  static func token(environment: [String: String] = ProcessInfo.processInfo.environment)
    -> String?
  {
    if environment[disabledEnvironmentKey] == "1" {
      return nil
    }

    guard let executablePath = executablePath(environment: environment) else {
      return nil
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: executablePath)
    process.arguments = ["auth", "token"]

    let output = Pipe()
    process.standardOutput = output
    process.standardError = Pipe()

    do {
      try process.run()
    } catch {
      return nil
    }
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      return nil
    }

    return String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .nonEmpty
  }

  private static func executablePath(environment: [String: String]) -> String? {
    if let configuredPath = environment[pathEnvironmentKey]?.nonEmpty,
      FileManager.default.isExecutableFile(atPath: configuredPath)
    {
      return configuredPath
    }

    let pathCandidates =
      environment["PATH", default: ""]
      .split(separator: ":")
      .map { String($0) + "/gh" }

    return (pathCandidates + commonExecutablePaths).first {
      FileManager.default.isExecutableFile(atPath: $0)
    }
  }

  private static let commonExecutablePaths = [
    "/opt/homebrew/bin/gh",
    "/usr/local/bin/gh",
    "/usr/bin/gh",
  ]
}

extension String {
  var nonEmpty: String? {
    isEmpty ? nil : self
  }
}

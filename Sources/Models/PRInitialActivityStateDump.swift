import Foundation

enum PRInitialActivityStateDump {
  static let pathEnvironmentKey = "PR_MENU_BAR_INITIAL_STATE_DUMP_PATH"

  static func writeIfRequested(
    state: PRInitialActivityState,
    dataSource: PRActivityDataSource,
    environment: [String: String] = ProcessInfo.processInfo.environment
  ) {
    guard let path = environment[pathEnvironmentKey],
      path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    else {
      return
    }
    try? write(state: state, dataSource: dataSource, path: path)
  }

  private static func write(
    state: PRInitialActivityState,
    dataSource: PRActivityDataSource,
    path: String
  ) throws {
    let payload = Payload(
      dataSourceTitle: dataSource.title,
      totalPullRequests: state.store.totalPullRequests,
      activeRepositoryCount: state.store.activeRepositoryCount,
      bucketTotals: state.store.bucketTotals,
      visibleBucketLabels: state.store.visibleBucketLabels,
      refreshError: state.refreshError
    )
    let data = try JSONEncoder.prettyPrinted.encode(payload)
    try data.write(to: URL(fileURLWithPath: path), options: .atomic)
  }

  private struct Payload: Encodable {
    var dataSourceTitle: String
    var totalPullRequests: Int
    var activeRepositoryCount: Int
    var bucketTotals: [Int]
    var visibleBucketLabels: [String]
    var refreshError: String?
  }
}

extension JSONEncoder {
  fileprivate static var prettyPrinted: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return encoder
  }
}

import Foundation

struct PRSettingsSnapshot: Codable, Equatable {
  var window: ActivityWindow
  var refreshInterval: AutoRefreshInterval
  var includedRepositoryIDs: [String]

  init(
    window: ActivityWindow,
    refreshInterval: AutoRefreshInterval = .daily,
    includedRepositoryIDs: [String]
  ) {
    self.window = window
    self.refreshInterval = refreshInterval
    self.includedRepositoryIDs = includedRepositoryIDs
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    window = try container.decode(ActivityWindow.self, forKey: .window)
    refreshInterval =
      try container.decodeIfPresent(AutoRefreshInterval.self, forKey: .refreshInterval) ?? .daily
    includedRepositoryIDs = try container.decode([String].self, forKey: .includedRepositoryIDs)
  }
}

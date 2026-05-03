import Foundation

struct PRSettingsSnapshot: Codable, Equatable {
  var window: ActivityWindow
  var refreshInterval: AutoRefreshInterval
  var includedRepositoryIDs: [String]
  var knownRepositoryIDs: [String]

  init(
    window: ActivityWindow,
    refreshInterval: AutoRefreshInterval = .daily,
    includedRepositoryIDs: [String],
    knownRepositoryIDs: [String]? = nil
  ) {
    self.window = window
    self.refreshInterval = refreshInterval
    self.includedRepositoryIDs = includedRepositoryIDs
    self.knownRepositoryIDs = knownRepositoryIDs ?? includedRepositoryIDs
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    window = try container.decode(ActivityWindow.self, forKey: .window)
    refreshInterval =
      try container.decodeIfPresent(AutoRefreshInterval.self, forKey: .refreshInterval) ?? .daily
    includedRepositoryIDs = try container.decode([String].self, forKey: .includedRepositoryIDs)
    knownRepositoryIDs =
      try container.decodeIfPresent([String].self, forKey: .knownRepositoryIDs)
      ?? includedRepositoryIDs
  }
}

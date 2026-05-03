import Foundation

struct PRSettingsSnapshot: Codable, Equatable {
  var window: ActivityWindow
  var bin: ActivityBin
  var refreshInterval: AutoRefreshInterval
  var includedRepositoryIDs: [String]
  var knownRepositoryIDs: [String]

  init(
    window: ActivityWindow,
    bin: ActivityBin = .week,
    refreshInterval: AutoRefreshInterval = .daily,
    includedRepositoryIDs: [String],
    knownRepositoryIDs: [String]? = nil
  ) {
    self.window = window
    self.bin = bin
    self.refreshInterval = refreshInterval
    self.includedRepositoryIDs = includedRepositoryIDs
    self.knownRepositoryIDs = knownRepositoryIDs ?? includedRepositoryIDs
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    window = try container.decode(ActivityWindow.self, forKey: .window)
    bin = try container.decodeIfPresent(ActivityBin.self, forKey: .bin) ?? .week
    refreshInterval =
      try container.decodeIfPresent(AutoRefreshInterval.self, forKey: .refreshInterval) ?? .daily
    includedRepositoryIDs = try container.decode([String].self, forKey: .includedRepositoryIDs)
    knownRepositoryIDs =
      try container.decodeIfPresent([String].self, forKey: .knownRepositoryIDs)
      ?? includedRepositoryIDs
  }
}

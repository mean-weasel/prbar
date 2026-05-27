import Foundation

struct PRSettingsSnapshot: Codable, Equatable {
  var window: ActivityWindow
  var bin: ActivityBin
  var refreshInterval: AutoRefreshInterval
  var showPrivateRepositoryNamesInShare: Bool
  var includedRepositoryIDs: [String]
  var knownRepositoryIDs: [String]

  init(
    window: ActivityWindow,
    bin: ActivityBin = .week,
    refreshInterval: AutoRefreshInterval = .daily,
    showPrivateRepositoryNamesInShare: Bool = false,
    includedRepositoryIDs: [String],
    knownRepositoryIDs: [String]? = nil
  ) {
    self.window = window
    self.bin = bin
    self.refreshInterval = refreshInterval
    self.showPrivateRepositoryNamesInShare = showPrivateRepositoryNamesInShare
    self.includedRepositoryIDs = includedRepositoryIDs
    self.knownRepositoryIDs = knownRepositoryIDs ?? includedRepositoryIDs
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    window = try container.decode(ActivityWindow.self, forKey: .window)
    bin = try container.decodeIfPresent(ActivityBin.self, forKey: .bin) ?? .week
    refreshInterval =
      try container.decodeIfPresent(AutoRefreshInterval.self, forKey: .refreshInterval) ?? .daily
    showPrivateRepositoryNamesInShare =
      try container.decodeIfPresent(Bool.self, forKey: .showPrivateRepositoryNamesInShare)
      ?? false
    includedRepositoryIDs = try container.decode([String].self, forKey: .includedRepositoryIDs)
    knownRepositoryIDs =
      try container.decodeIfPresent([String].self, forKey: .knownRepositoryIDs)
      ?? includedRepositoryIDs
  }
}

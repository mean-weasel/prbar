import Foundation

struct PRSettingsSnapshot: Codable, Equatable {
  var window: ActivityWindow
  var includedRepositoryIDs: [String]
}

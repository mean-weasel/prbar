import Foundation

struct PRSettingsStore {
  private let defaults: UserDefaults
  private let key = "pr-menu-bar.settings.v1"

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func load() -> PRSettingsSnapshot? {
    guard let data = defaults.data(forKey: key) else {
      return nil
    }
    return try? JSONDecoder().decode(PRSettingsSnapshot.self, from: data)
  }

  func save(_ snapshot: PRSettingsSnapshot) {
    guard let data = try? JSONEncoder().encode(snapshot) else {
      return
    }
    defaults.set(data, forKey: key)
  }

  func reset() {
    defaults.removeObject(forKey: key)
  }
}

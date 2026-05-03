import XCTest

@testable import PRMenuBar

final class PRSettingsStoreTests: XCTestCase {
  func testSaveLoadAndResetSettings() {
    let defaults = UserDefaults(suiteName: "PRSettingsStoreTests")!
    defaults.removePersistentDomain(forName: "PRSettingsStoreTests")
    let store = PRSettingsStore(defaults: defaults)
    let snapshot = PRSettingsSnapshot(
      window: .oneMonth,
      includedRepositoryIDs: ["a/repo", "b/repo"]
    )

    store.save(snapshot)

    XCTAssertEqual(store.load(), snapshot)

    store.reset()

    XCTAssertNil(store.load())
  }
}

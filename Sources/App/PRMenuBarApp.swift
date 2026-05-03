import SwiftUI

@main
struct PRMenuBarApp: App {
  private let settingsStore = PRSettingsStore()
  private let activityProvider: PRActivityProviding = StaticPRActivityProvider()
  @State private var store: PRActivityStore

  init() {
    let settingsStore = PRSettingsStore()
    let activityProvider = StaticPRActivityProvider()
    let sample = (try? activityProvider.load(now: Date())) ?? PRActivityStore.sample()
    _store = State(initialValue: settingsStore.load().map(sample.applying) ?? sample)
  }

  var body: some Scene {
    MenuBarExtra {
      PRPopoverView(store: $store) {
        let settings = store.settingsSnapshot
        let loaded = (try? activityProvider.load(now: Date())) ?? PRActivityStore.sample()
        store = loaded.applying(settings)
      }
      .frame(width: 460)
      .onChange(of: store.settingsSnapshot) { _, snapshot in
        settingsStore.save(snapshot)
      }
    } label: {
      Label(store.statusTitle, systemImage: "chart.bar.xaxis")
    }
    .menuBarExtraStyle(.window)
  }
}

import SwiftUI

@main
struct PRMenuBarApp: App {
  private let settingsStore = PRSettingsStore()
  @State private var store: PRActivityStore

  init() {
    let settingsStore = PRSettingsStore()
    let sample = PRActivityStore.sample()
    _store = State(initialValue: settingsStore.load().map(sample.applying) ?? sample)
  }

  var body: some Scene {
    MenuBarExtra {
      PRPopoverView(store: $store)
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

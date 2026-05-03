import SwiftUI

@main
struct PRMenuBarApp: App {
  private let settingsStore: PRSettingsStore
  private let providerSelection: PRActivityProviderSelection
  private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
  @State private var store: PRActivityStore
  @State private var refreshError: String?

  init() {
    let settingsStore = PRSettingsStore()
    let providerSelection = PRActivityProviderFactory.makeSelection()
    self.settingsStore = settingsStore
    self.providerSelection = providerSelection
    let sample = (try? providerSelection.provider.load(now: Date())) ?? PRActivityStore.sample()
    _store = State(initialValue: settingsStore.load().map(sample.applying) ?? sample)
  }

  var body: some Scene {
    MenuBarExtra {
      PRPopoverView(
        store: $store,
        refreshError: refreshError,
        dataSource: providerSelection.dataSource
      ) {
        refresh(now: Date())
      }
      .frame(width: 460)
      .onAppear {
        refreshIfDue(now: Date())
      }
      .onReceive(refreshTimer) { now in
        refreshIfDue(now: now)
      }
      .onChange(of: store.settingsSnapshot) { _, snapshot in
        settingsStore.save(snapshot)
      }
    } label: {
      Label(store.statusTitle, systemImage: "chart.bar.xaxis")
    }
    .menuBarExtraStyle(.window)
  }

  private func refresh(now: Date) {
    let refresher = PRActivityRefresher(provider: providerSelection.provider)
    do {
      store = try refresher.refresh(current: store, now: now)
      refreshError = nil
    } catch {
      refreshError = "Refresh failed. Keeping the previous activity."
    }
  }

  private func refreshIfDue(now: Date) {
    let refresher = PRActivityRefresher(provider: providerSelection.provider)
    do {
      guard let refreshed = try refresher.refreshIfDue(current: store, now: now) else {
        return
      }
      store = refreshed
      refreshError = nil
    } catch {
      refreshError = "Scheduled refresh failed. Keeping the previous activity."
    }
  }
}

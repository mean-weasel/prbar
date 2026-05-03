import SwiftUI

@main
struct PRMenuBarApp: App {
  private let settingsStore = PRSettingsStore()
  private let activityProvider: PRActivityProviding = StaticPRActivityProvider()
  private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
  @State private var store: PRActivityStore
  @State private var refreshError: String?

  init() {
    let settingsStore = PRSettingsStore()
    let activityProvider = StaticPRActivityProvider()
    let sample = (try? activityProvider.load(now: Date())) ?? PRActivityStore.sample()
    _store = State(initialValue: settingsStore.load().map(sample.applying) ?? sample)
  }

  var body: some Scene {
    MenuBarExtra {
      PRPopoverView(store: $store, refreshError: refreshError) {
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
    let refresher = PRActivityRefresher(provider: activityProvider)
    do {
      store = try refresher.refresh(current: store, now: now)
      refreshError = nil
    } catch {
      refreshError = "Refresh failed. Keeping the previous activity."
    }
  }

  private func refreshIfDue(now: Date) {
    let refresher = PRActivityRefresher(provider: activityProvider)
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

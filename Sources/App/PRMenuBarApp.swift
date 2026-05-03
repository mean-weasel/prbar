import SwiftUI

@main
struct PRMenuBarApp: App {
  private let settingsStore: PRSettingsStore
  private let providerSelection: PRActivityProviderSelection
  private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
  @State private var store: PRActivityStore
  @State private var refreshError: String?
  @State private var isRefreshing = false

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
        isRefreshing: isRefreshing,
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
    guard beginRefresh() else {
      return
    }
    defer {
      isRefreshing = false
    }
    let refresher = PRActivityRefresher(provider: providerSelection.provider)
    do {
      store = try refresher.refresh(current: store, now: now)
      refreshError = nil
    } catch {
      refreshError = RefreshFailureMessage.manual(error: error)
    }
  }

  private func refreshIfDue(now: Date) {
    let policy = RefreshPolicy(interval: store.refreshInterval)
    guard policy.isRefreshDue(lastRefreshedAt: store.refreshedAt, now: now) else {
      return
    }
    guard beginRefresh() else {
      return
    }
    defer {
      isRefreshing = false
    }
    let refresher = PRActivityRefresher(provider: providerSelection.provider)
    do {
      store = try refresher.refresh(current: store, now: now)
      refreshError = nil
    } catch {
      refreshError = RefreshFailureMessage.scheduled(error: error)
    }
  }

  private func beginRefresh() -> Bool {
    guard isRefreshing == false else {
      return false
    }
    isRefreshing = true
    return true
  }
}

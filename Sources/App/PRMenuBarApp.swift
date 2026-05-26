import SwiftUI

@main
struct PRMenuBarApp: App {
  private let settingsStore: PRSettingsStore
  private let providerSelection: PRActivityProviderSelection
  private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
  @State private var store: PRActivityStore
  @State private var releaseStore: ReleaseMomentStore
  @State private var refreshError: String?
  @State private var isRefreshing = false
  @State private var refreshGeneration = 0

  init() {
    let now = Date()
    let settingsStore = PRSettingsStore()
    let providerSelection = PRActivityProviderFactory.makeSelection()
    self.settingsStore = settingsStore
    self.providerSelection = providerSelection
    let initialState = PRInitialActivityState.load(providerSelection: providerSelection, now: now)
    PRInitialActivityStateDump.writeIfRequested(
      state: initialState,
      dataSource: providerSelection.dataSource
    )
    let initial = initialState.store

    _store = State(initialValue: settingsStore.load().map(initial.applying) ?? initial)
    _releaseStore = State(initialValue: Self.initialReleaseStore(providerSelection, now: now))
    _refreshError = State(initialValue: initialState.refreshError)
  }

  var body: some Scene {
    MenuBarExtra {
      PRPopoverView(
        store: $store,
        releaseStore: releaseStore,
        refreshError: refreshError,
        isRefreshing: isRefreshing,
        dataSource: providerSelection.dataSource
      ) {
        refresh(now: Date())
      }
      .frame(width: 460)
      .onAppear {
        refreshIfDue(now: Date())
        refreshReleases(now: Date())
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
    refresh(now: now, failureMessage: RefreshFailureMessage.manual)
  }

  private func refreshIfDue(now: Date) {
    let policy = RefreshPolicy(interval: store.refreshInterval)
    guard policy.isRefreshDue(lastRefreshedAt: store.refreshedAt, now: now) else {
      return
    }
    refresh(now: now, failureMessage: RefreshFailureMessage.scheduled)
  }

  private func refresh(now: Date, failureMessage: @escaping (Error) -> String) {
    guard beginRefresh() else {
      return
    }
    let refresher = PRActivityRefresher(provider: providerSelection.provider)
    let currentStore = store
    refreshGeneration += 1
    let generation = refreshGeneration

    DispatchQueue.global(qos: .userInitiated).async {
      let result = Result { try refresher.refresh(current: currentStore, now: now) }
      let releaseResult = result.flatMap { refreshedStore in
        Result {
          try providerSelection.releaseProvider.fetchReleaseMoments(
            repositories: refreshedStore.repositories,
            now: now
          )
        }
      }

      DispatchQueue.main.async {
        guard generation == refreshGeneration else {
          return
        }
        isRefreshing = false
        switch result {
        case .success(let refreshedStore):
          store = refreshedStore
          if case .success(let releases) = releaseResult {
            releaseStore = ReleaseMomentStore(releases: releases)
          }
          refreshError = nil
        case .failure(let error):
          refreshError = failureMessage(error)
        }
      }
    }
  }

  private func beginRefresh() -> Bool {
    guard isRefreshing == false else {
      return false
    }
    isRefreshing = true
    return true
  }

  private func refreshReleases(now: Date) {
    let repositories = store.repositories
    DispatchQueue.global(qos: .utility).async {
      let releases = try? providerSelection.releaseProvider.fetchReleaseMoments(
        repositories: repositories,
        now: now
      )

      DispatchQueue.main.async {
        if let releases {
          releaseStore = ReleaseMomentStore(releases: releases)
        }
      }
    }
  }

  private static func initialReleaseStore(
    _ providerSelection: PRActivityProviderSelection,
    now: Date
  ) -> ReleaseMomentStore {
    guard providerSelection.dataSource == .sample else {
      return ReleaseMomentStore(releases: [])
    }
    let releases =
      try? providerSelection.releaseProvider.fetchReleaseMoments(
        repositories: RepositoryActivity.samples,
        now: now
      )
    return ReleaseMomentStore(releases: releases ?? [])
  }
}

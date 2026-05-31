import SwiftUI

@main
struct PRMenuBarApp: App {
  private let settingsStore: PRSettingsStore
  private let providerSelection: PRActivityProviderSelection
  private let refreshMetrics: RefreshMetricsRecording
  private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
  @State private var store: PRActivityStore
  @State private var releaseStore: ReleaseMomentStore
  @State private var releaseRefreshState: ReleaseRefreshState
  @State private var refreshError: String?
  @State private var isRefreshing = false
  @State private var refreshGeneration = 0
  @State private var releaseRefreshGeneration = 0

  init() {
    let now = Date()
    let settingsStore = PRSettingsStore()
    let providerSelection = PRActivityProviderFactory.makeSelection()
    self.settingsStore = settingsStore
    self.providerSelection = providerSelection
    self.refreshMetrics = OSLogRefreshMetricsRecorder()
    let initialState = PRInitialActivityState.load(providerSelection: providerSelection, now: now)
    PRInitialActivityStateDump.writeIfRequested(
      state: initialState,
      dataSource: providerSelection.dataSource
    )
    let initial = initialState.store

    _store = State(initialValue: settingsStore.load().map(initial.applying) ?? initial)
    _releaseStore = State(initialValue: Self.initialReleaseStore(providerSelection, now: now))
    _releaseRefreshState = State(initialValue: .idle)
    _refreshError = State(initialValue: initialState.refreshError)
  }

  var body: some Scene {
    MenuBarExtra {
      PRPopoverView(
        store: $store,
        releaseStore: releaseStore,
        releaseRefreshState: releaseRefreshState,
        refreshError: refreshError,
        isRefreshing: isRefreshing,
        dataSource: providerSelection.dataSource
      ) {
        refresh(now: Date())
      }
      .frame(width: 560)
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
    let startedAt = Date()

    DispatchQueue.global(qos: .userInitiated).async {
      let result = Result { try refresher.refresh(current: currentStore, now: now) }
      let activityDuration = Date().timeIntervalSince(startedAt) * 1_000

      DispatchQueue.main.async {
        guard generation == refreshGeneration else {
          return
        }
        isRefreshing = false
        switch result {
        case .success(let refreshedStore):
          store = refreshedStore
          refreshError = nil
          recordRefreshMetric(
            "manual_refresh.activity",
            durationMilliseconds: activityDuration,
            metadata: [
              "repository_count": "\(refreshedStore.repositories.count)",
              "included_repository_count":
                "\(refreshedStore.repositories.filter(\.isIncluded).count)",
              "result": "success",
            ]
          )
          recordRefreshMetric(
            "manual_refresh.total",
            startedAt: startedAt,
            metadata: ["result": "activity_ready"]
          )
          refreshReleases(repositories: refreshedStore.repositories, now: now)
        case .failure(let error):
          refreshError = failureMessage(error)
          recordRefreshMetric(
            "manual_refresh.activity",
            durationMilliseconds: activityDuration,
            metadata: ["result": "error"]
          )
          recordRefreshMetric(
            "manual_refresh.total",
            startedAt: startedAt,
            metadata: ["result": "error"]
          )
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
    refreshReleases(repositories: store.repositories, now: now)
  }

  private func refreshReleases(repositories: [RepositoryActivity], now: Date) {
    releaseRefreshGeneration += 1
    let generation = releaseRefreshGeneration
    releaseRefreshState = .loading
    let startedAt = Date()
    DispatchQueue.global(qos: .utility).async {
      let result = Result {
        try providerSelection.releaseProvider.fetchReleaseMoments(
          repositories: repositories,
          now: now
        )
      }

      DispatchQueue.main.async {
        guard generation == releaseRefreshGeneration else {
          return
        }
        switch result {
        case .success(let releases):
          releaseStore = ReleaseMomentStore(releases: releases)
          releaseRefreshState = .idle
          recordRefreshMetric(
            "release_refresh.total",
            startedAt: startedAt,
            metadata: [
              "repository_count": "\(repositories.count)",
              "included_repository_count": "\(repositories.filter(\.isIncluded).count)",
              "moment_count": "\(releases.count)",
              "result": "success",
            ]
          )
        case .failure(let error):
          releaseRefreshState = .failed(Self.releaseRefreshMessage(for: error))
          recordRefreshMetric(
            "release_refresh.total",
            startedAt: startedAt,
            metadata: [
              "repository_count": "\(repositories.count)",
              "included_repository_count": "\(repositories.filter(\.isIncluded).count)",
              "result": "error",
            ]
          )
        }
      }
    }
  }

  private func recordRefreshMetric(
    _ name: String,
    startedAt: Date,
    metadata: [String: String]
  ) {
    recordRefreshMetric(
      name,
      durationMilliseconds: Date().timeIntervalSince(startedAt) * 1_000,
      metadata: metadata
    )
  }

  private func recordRefreshMetric(
    _ name: String,
    durationMilliseconds: Double,
    metadata: [String: String]
  ) {
    refreshMetrics.record(
      RefreshMetricEvent(
        name: name,
        durationMilliseconds: durationMilliseconds,
        metadata: metadata
      )
    )
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

  private static func releaseRefreshMessage(for error: Error) -> String {
    "Could not load release notes: \(error.localizedDescription)"
  }
}

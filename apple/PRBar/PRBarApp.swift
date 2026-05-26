import SwiftUI

@main
struct PRBarApp: App {
  @State private var store: PRBarStore

  init() {
    let store = PRBarStore.sample()
    if ProcessInfo.processInfo.arguments.contains("--signed-out") {
      store.routeState = .signedOut
    }
    _store = State(initialValue: store)
  }

  var body: some Scene {
    WindowGroup {
      RootTabView(store: store)
    }
  }
}

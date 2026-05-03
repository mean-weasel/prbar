import SwiftUI

@main
struct PRMenuBarApp: App {
  @State private var store = PRActivityStore.sample()

  var body: some Scene {
    MenuBarExtra {
      PRPopoverView(store: store)
        .frame(width: 420)
    } label: {
      Label(store.statusTitle, systemImage: "chart.bar.xaxis")
    }
    .menuBarExtraStyle(.window)
  }
}

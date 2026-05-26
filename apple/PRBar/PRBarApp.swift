import SwiftUI

@main
struct PRBarApp: App {
  var body: some Scene {
    WindowGroup {
      RootTabView(store: .sample())
    }
  }
}

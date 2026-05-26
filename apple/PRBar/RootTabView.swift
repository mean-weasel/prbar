import SwiftUI

struct RootTabView: View {
  @State var store: PRBarStore

  var body: some View {
    TabView {
      PRsView(store: store)
        .tabItem { Label("PRs", systemImage: "chart.bar.xaxis") }

      ReleasesView(store: store)
        .tabItem { Label("Releases", systemImage: "tag") }

      ShareView(store: store)
        .tabItem { Label("Share", systemImage: "square.and.arrow.up") }

      MoreView(store: store)
        .tabItem { Label("More", systemImage: "ellipsis") }
    }
    .tint(PRBarTheme.accent)
  }
}

#Preview {
  RootTabView(store: .sample())
}

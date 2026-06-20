import SwiftUI

struct RootTabView: View {
  @State var store: PRBarStore

  var body: some View {
    Group {
      switch store.routeState {
      case .authenticated:
        tabs
      case .signedOut, .authorizing, .onboarding, .issue:
        OnboardingView(store: store)
      }
    }
    .tint(PRBarTheme.accent)
  }

  private var tabs: some View {
    TabView {
      PRsView(store: store)
        .tabItem { Label("Activity", systemImage: "chart.bar.xaxis") }

      GrowthView(store: store)
        .tabItem { Label("Growth", systemImage: "chart.line.uptrend.xyaxis") }

      ShareView(store: store)
        .tabItem { Label("Share", systemImage: "square.and.arrow.up") }

      MoreView(store: store)
        .tabItem { Label("Settings", systemImage: "gearshape") }
    }
  }
}

#Preview {
  RootTabView(store: .sample())
}

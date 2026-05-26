import SwiftUI

struct MoreView: View {
  var store: PRBarStore

  var body: some View {
    NavigationStack {
      List {
        Section {
          Text("Menu")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Section {
          NavigationLink("Repos") {
            RepositorySetupView(store: store)
          }

          NavigationLink("Settings") {
            SettingsView(store: store)
          }

          NavigationLink("Privacy") {
            PrivacyDefaultsView(store: store)
          }
        }

        Section {
          Button("Sample Data") {}
          Button("About") {}
        }
      }
      .navigationTitle("More")
      .accessibilityIdentifier("MoreMenu")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Sign out") {
            store.routeState = .signedOut
          }
        }
      }
    }
  }
}

#Preview {
  MoreView(store: .sample())
}

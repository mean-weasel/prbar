import SwiftUI

struct MoreView: View {
  var store: PRBarStore
  @State private var isSignOutConfirmationPresented = false

  var body: some View {
    NavigationStack {
      List {
        Section("Account") {
          LabeledContent("Mode", value: store.settingsDiagnostics.auth)
          LabeledContent("Data", value: store.settingsDiagnostics.dataSource)
          LabeledContent("Repos", value: store.settingsDiagnostics.includedRepositories)
        }

        Section {
          NavigationLink("Repos") {
            RepositorySetupView(store: store)
          }

          NavigationLink("Account & data") {
            SettingsView(store: store)
          }

          NavigationLink("Privacy") {
            PrivacyDefaultsView(store: store)
          }
        }

        Section {
          Button(store.isUsingSampleData ? "Reset sample data" : "Switch to sample data") {
            store.useSampleData()
          }
          NavigationLink("About") {
            AboutView()
          }
        }
      }
      .navigationTitle("Settings")
      .accessibilityIdentifier("SettingsMenu")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          if store.isUsingSampleData == false && store.githubConnection.status == .connected {
            Button("Sign out", role: .destructive) {
              isSignOutConfirmationPresented = true
            }
          }
        }
      }
      .confirmationDialog("Sign out of GitHub?", isPresented: $isSignOutConfirmationPresented, titleVisibility: .visible) {
        Button("Sign out", role: .destructive) {
          store.disconnectGitHub()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("PRBar keeps local app data until you reconnect or switch to sample data.")
      }
    }
  }
}

#Preview {
  MoreView(store: .sample())
}

private struct AboutView: View {
  var version = AppVersion.current

  var body: some View {
    Form {
      Section("PRBar") {
        LabeledContent("Version", value: version.displayValue)
        LabeledContent("Product version", value: version.marketingVersion)
        LabeledContent("Build", value: version.buildNumber)
      }
    }
    .navigationTitle("About")
  }
}

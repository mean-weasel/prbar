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
          NavigationLink("About") {
            AboutView()
          }
        }
      }
      .navigationTitle("More")
      .accessibilityIdentifier("MoreMenu")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Sign out") {
            store.disconnectGitHub()
          }
        }
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

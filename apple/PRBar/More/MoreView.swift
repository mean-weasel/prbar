import SwiftUI

struct MoreView: View {
  var store: PRBarStore
  @State private var isSignOutConfirmationPresented = false

  var body: some View {
    NavigationStack {
      List {
        Section {
          VStack(alignment: .leading, spacing: 6) {
            Label(settingsStatusTitle, systemImage: store.isUsingSampleData ? "sparkles" : "person.crop.circle")
              .font(.headline)
            Text(settingsStatusDetail)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          .padding(.vertical, 4)
        }

        Section("Manage") {
          NavigationLink {
            RepositorySetupView(store: store)
          } label: {
            SettingsLinkRow(
              title: "Repos",
              detail: "Choose which repositories power Activity and exports.",
              systemImage: "folder.badge.gearshape"
            )
          }

          NavigationLink {
            PrivacyDefaultsView(store: store)
          } label: {
            SettingsLinkRow(
              title: "Privacy",
              detail: "Set the default detail level for work cards.",
              systemImage: "lock.shield"
            )
          }
        }

        Section("Diagnostics") {
          NavigationLink {
            SettingsView(store: store)
          } label: {
            SettingsLinkRow(
              title: "Account & data",
              detail: "Inspect GitHub sync, cached data, and Growth configuration.",
              systemImage: "stethoscope"
            )
          }
        }

        Section("App") {
          Button(store.isUsingSampleData ? "Reset sample data" : "Switch to sample data") {
            store.useSampleData()
          }
          NavigationLink {
            AboutView()
          } label: {
            SettingsLinkRow(
              title: "About",
              detail: "Version and build information.",
              systemImage: "info.circle"
            )
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

  private var settingsStatusTitle: String {
    if store.isUsingSampleData {
      return "Previewing sample data"
    }

    if let login = store.githubConnection.user?.login {
      return "Connected as @\(login)"
    }

    return store.settingsDiagnostics.auth
  }

  private var settingsStatusDetail: String {
    "\(store.settingsDiagnostics.dataSource) · \(store.settingsDiagnostics.includedRepositories)"
  }
}

#Preview {
  MoreView(store: .sample())
}

private struct SettingsLinkRow: View {
  var title: String
  var detail: String
  var systemImage: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: systemImage)
        .foregroundStyle(PRBarTheme.accent)
        .frame(width: 22)

      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.subheadline.weight(.semibold))
        Text(detail)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 3)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityHint(detail)
  }
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

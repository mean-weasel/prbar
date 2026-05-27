import SwiftUI
import UIKit

struct OnboardingView: View {
  var store: PRBarStore

  var body: some View {
    NavigationStack {
      Group {
        if store.routeState == .onboarding(.repositories) {
          RepositorySetupView(store: store, title: "Choose repos", showsFinishButton: true)
        } else if case let .authorizing(authorization) = store.routeState {
          TimelineView(.periodic(from: Date(), by: 1)) { context in
            authorizationList(authorization, now: context.date)
          }
        } else {
          signInList
        }
      }
    }
  }

  private func authorizationList(_ authorization: GitHubDeviceAuthorization, now: Date) -> some View {
    let isExpired = authorization.isExpired(at: now)

    return List {
      Section {
        VStack(alignment: .leading, spacing: 12) {
          Label("Authorize GitHub", systemImage: "key.horizontal")
            .font(.title3.weight(.semibold))

          Text(isExpired ? "This GitHub code expired. Request a fresh code to continue." : "Open GitHub on any device, enter this code, then return here.")
            .font(.subheadline)
            .foregroundStyle(isExpired ? .red : .secondary)

          Text(authorization.userCode)
            .font(.system(.largeTitle, design: .monospaced).weight(.bold))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 10)
            .textSelection(.enabled)
            .accessibilityLabel("GitHub device code \(authorization.userCode)")
            .accessibilityIdentifier("github-device-code")

          Label(expirationText(for: authorization, now: now), systemImage: isExpired ? "exclamationmark.triangle" : "clock")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isExpired ? .red : .secondary)
            .accessibilityIdentifier("github-device-code-expiration")

          HStack(spacing: 10) {
            Button {
              UIPasteboard.general.string = authorization.userCode
            } label: {
              Label("Copy code", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("copy-github-device-code")

            Button {
              UIPasteboard.general.string = authorization.verificationURI.absoluteString
            } label: {
              Label("Copy link", systemImage: "link")
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("copy-github-device-url")
          }

          Link(destination: authorization.verificationURI) {
            Label("Open here", systemImage: "arrow.up.forward.app")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .accessibilityIdentifier("open-github-device-url")

          VStack(alignment: .leading, spacing: 4) {
            Text("Verification URL")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)

            Link(destination: authorization.verificationURI) {
              Text(authorization.verificationURI.absoluteString)
                .font(.footnote.monospaced())
            }
            .accessibilityIdentifier("github-device-url")
          }
        }
        .padding(.vertical, 6)
      }

      Section {
        Button("I authorized GitHub") {
          store.continueGitHubAuthorization()
        }
        .buttonStyle(.borderedProminent)
        .disabled(isExpired)

        Button(isExpired ? "Get new code" : "Refresh code") {
          store.refreshGitHubAuthorization()
        }
        .accessibilityIdentifier("refresh-github-device-code")

        Button("Use sample data") {
          store.routeState = .authenticated
        }
      }
    }
    .navigationTitle("GitHub")
  }

  private var signInList: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: 10) {
          Label("Connect GitHub", systemImage: "person.crop.circle.badge.checkmark")
            .font(.title3.weight(.semibold))

          Text("Sign in to choose repositories, keep PR and release data synced, and decide what can leave the app.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
      }

      Section("Privacy defaults") {
        Label("Private by default", systemImage: "lock.shield")
        Label("Public cards hide private repo names", systemImage: "eye.slash")
      }

      Section("Setup") {
        row("Choose repos", step: .repositories, systemImage: "folder.badge.gearshape")
        row("Set privacy defaults", step: .privacy, systemImage: "lock.shield")
        row("Sync sample activity", step: .sync, systemImage: "arrow.triangle.2.circlepath")
      }

      if case let .issue(issue) = store.routeState {
        Section("Issue") {
          Text(issue.title)
            .font(.headline)
          Text(issue.message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }

      Section {
        Button("Continue with GitHub") {
          store.connectGitHub()
        }
        .buttonStyle(.borderedProminent)

        Button("Use sample data") {
          store.routeState = .authenticated
        }
      }
    }
    .navigationTitle("PRBar")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Done") {
          store.routeState = .authenticated
        }
      }
    }
  }

  private func row(_ title: String, step: OnboardingStep, systemImage: String) -> some View {
    Button {
      store.routeState = .onboarding(step)
    } label: {
      HStack {
        Label(title, systemImage: systemImage)
        Spacer()
        if store.routeState == .onboarding(step) {
          Image(systemName: "checkmark")
            .foregroundStyle(PRBarTheme.accent)
        }
      }
    }
  }

  private func expirationText(for authorization: GitHubDeviceAuthorization, now: Date) -> String {
    let remainingSeconds = authorization.remainingSeconds(at: now)
    guard remainingSeconds > 0 else {
      return "Code expired"
    }

    let minutes = remainingSeconds / 60
    let seconds = remainingSeconds % 60
    if minutes > 0 {
      return "Code expires in \(minutes)m \(seconds)s"
    }
    return "Code expires in \(seconds)s"
  }
}

#Preview {
  OnboardingView(store: .sample())
}

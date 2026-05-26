import SwiftUI

struct OnboardingView: View {
  var store: PRBarStore

  var body: some View {
    NavigationStack {
      List {
        Section {
          VStack(alignment: .leading, spacing: 10) {
            Label("Sign in with GitHub", systemImage: "person.crop.circle.badge.checkmark")
              .font(.title3.weight(.semibold))

            Text("Connect GitHub to turn merged PRs and releases into private, reviewable work cards.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 6)
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
            store.routeState = .onboarding(.repositories)
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
}

#Preview {
  OnboardingView(store: .sample())
}

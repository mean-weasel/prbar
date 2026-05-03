import SwiftUI

struct PRSettingsView: View {
  @Binding var store: PRActivityStore

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      controls
      repositoryList
    }
  }

  private var controls: some View {
    VStack(spacing: 8) {
      Picker("Window", selection: $store.window) {
        ForEach(ActivityWindow.allCases) { window in
          Text(window.rawValue).tag(window)
        }
      }
      .pickerStyle(.segmented)

      Picker("Bins", selection: $store.bin) {
        ForEach(ActivityBin.allCases) { bin in
          Text(bin.rawValue).tag(bin)
        }
      }
      .pickerStyle(.segmented)

      Picker("Refresh", selection: $store.refreshInterval) {
        ForEach(AutoRefreshInterval.allCases) { interval in
          Text(interval.rawValue).tag(interval)
        }
      }
      .pickerStyle(.segmented)
    }
  }

  private var repositoryList: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Included Repositories")
        .font(.caption)
        .foregroundStyle(.secondary)
      ForEach($store.repositories) { $repository in
        RepositoryActivityRow(repository: $repository, window: store.window, bin: store.bin)
      }
    }
  }
}

private struct RepositoryActivityRow: View {
  @Binding var repository: RepositoryActivity
  var window: ActivityWindow
  var bin: ActivityBin

  var body: some View {
    Toggle(isOn: $repository.isIncluded) {
      HStack(spacing: 10) {
        RoundedRectangle(cornerRadius: 3)
          .fill(Color(hex: repository.colorHex))
          .frame(width: 10, height: 24)
        VStack(alignment: .leading, spacing: 2) {
          Text(repository.name)
            .font(.subheadline.weight(.medium))
          Text(repository.owner)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Text("\(repository.visibleTotal(for: window, bin: bin))")
          .font(.subheadline.monospacedDigit().weight(.semibold))
      }
    }
    .toggleStyle(.checkbox)
  }
}

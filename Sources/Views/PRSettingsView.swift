import SwiftUI

struct PRSettingsView: View {
  @Binding var store: PRActivityStore
  var dataSource: PRActivityDataSource

  var body: some View {
    VStack(alignment: .leading, spacing: 26) {
      connectionStatus
      controls
      repositoryList
    }
  }

  private var connectionStatus: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: dataSource.systemImage)
        .foregroundStyle(dataSource == .github ? .green : .secondary)
        .frame(width: 18)
      VStack(alignment: .leading, spacing: 4) {
        Text(dataSource.connectionTitle)
          .font(.subheadline.weight(.semibold))
        Text(dataSource.connectionDetail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
  }

  private var controls: some View {
    VStack(spacing: 16) {
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

      Toggle(isOn: $store.showPrivateRepositoryNamesInShare) {
        VStack(alignment: .leading, spacing: 3) {
          Text("Show private repo names in share cards")
            .font(.subheadline.weight(.medium))
          Text("When off, private repositories are labeled as Private repo in exported cards.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .toggleStyle(.checkbox)
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
  }

  private var repositoryList: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Included Repositories")
        .font(.caption)
        .foregroundStyle(.secondary)
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 14) {
          ForEach($store.repositories) { $repository in
            RepositoryActivityRow(repository: $repository, window: store.window, bin: store.bin)
          }
        }
      }
      .frame(maxHeight: 330)
    }
  }
}

private struct RepositoryActivityRow: View {
  @Binding var repository: RepositoryActivity
  var window: ActivityWindow
  var bin: ActivityBin

  var body: some View {
    Toggle(isOn: $repository.isIncluded) {
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 3)
          .fill(Color(hex: repository.colorHex))
          .frame(width: 10, height: 28)
        VStack(alignment: .leading, spacing: 3) {
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

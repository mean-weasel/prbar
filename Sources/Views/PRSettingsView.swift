import SwiftUI

struct PRSettingsView: View {
  @Binding var store: PRActivityStore
  var dataSource: PRActivityDataSource

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      connectionStatus
      controls
      repositoryList
    }
  }

  private var connectionStatus: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: dataSource.systemImage)
        .foregroundStyle(dataSource == .github ? .green : .secondary)
        .frame(width: 18)
      VStack(alignment: .leading, spacing: 2) {
        Text(dataSource.connectionTitle)
          .font(.subheadline.weight(.semibold))
        Text(dataSource.connectionDetail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
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
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 8) {
          ForEach($store.repositories) { $repository in
            RepositoryActivityRow(repository: $repository, window: store.window, bin: store.bin)
          }
        }
      }
      .frame(maxHeight: 260)
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

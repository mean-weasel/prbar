import SwiftUI

struct ActivityWorkLogView: View {
  var rows: [ActivityWorkRow]
  var emptyDetail: String

  var body: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: 6) {
          Text("Work log")
            .font(.title2.weight(.bold))

          Text("Detailed pull requests, tags, and releases from the selected repositories.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
      }

      if rows.isEmpty {
        Section {
          ActivityEmptyStateView(
            title: "No recent activity",
            detail: emptyDetail,
            systemImage: "tray",
            identifier: "activity-empty-state"
          )
          .listRowSeparator(.hidden)
        }
      } else {
        Section("Recent work") {
          ForEach(rows) { row in
            ActivityWorkRowView(row: row, dateLabel: shortDateLabel(for: row.happenedAt))
          }
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Work log")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func shortDateLabel(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
  }
}

struct ActivityWorkRow: Identifiable {
  var id: String
  var kind: String
  var title: String
  var repositoryName: String
  var happenedAt: Date
  var systemImage: String
}

private struct ActivityWorkRowView: View {
  var row: ActivityWorkRow
  var dateLabel: String

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: row.systemImage)
        .font(.caption.weight(.semibold))
        .foregroundStyle(PRBarTheme.accent)
        .frame(width: 24, height: 24)
        .background(PRBarTheme.accent.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

      VStack(alignment: .leading, spacing: 3) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(row.kind)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
          Text(dateLabel)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Text(row.title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(3)

        Text(row.repositoryName)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
  }
}

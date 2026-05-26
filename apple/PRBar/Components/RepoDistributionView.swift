import SwiftUI

struct RepoDistributionRow: Identifiable {
  var repository: Repository
  var count: Int

  var id: Repository.ID { repository.id }
}

struct RepoDistributionView: View {
  var rows: [RepoDistributionRow]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Distribution by repo")
        .font(.headline)

      VStack(spacing: 8) {
        ForEach(rows) { row in
          NavigationLink(value: row.repository.id) {
            HStack(spacing: 12) {
              Circle()
                .fill(color(from: row.repository.colorHex))
                .frame(width: 10, height: 10)

              VStack(alignment: .leading, spacing: 2) {
                Text(row.repository.name)
                  .font(.subheadline.weight(.semibold))
                Text(row.repository.owner)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }

              Spacer()

              Text("\(row.count)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()

              Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private func color(from hex: String) -> Color {
    let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    guard let value = UInt64(trimmed, radix: 16) else {
      return PRBarTheme.accent
    }

    return Color(
      red: Double((value & 0xff0000) >> 16) / 255,
      green: Double((value & 0x00ff00) >> 8) / 255,
      blue: Double(value & 0x0000ff) / 255
    )
  }
}

#Preview {
  NavigationStack {
    RepoDistributionView(rows: [
      RepoDistributionRow(repository: SampleData.repositories[0], count: 3),
      RepoDistributionRow(repository: SampleData.repositories[1], count: 2),
    ])
    .padding()
  }
}

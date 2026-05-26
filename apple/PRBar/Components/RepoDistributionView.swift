import SwiftUI

struct RepoDistributionRow: Identifiable {
  var repository: Repository
  var count: Int

  var id: Repository.ID { repository.id }
}

struct RepoDistributionView: View {
  var rows: [RepoDistributionRow]

  private var maxCount: Int {
    max(rows.map(\.count).max() ?? 1, 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Distribution by repo")
        .font(.headline)

      VStack(spacing: 8) {
        ForEach(rows) { row in
          NavigationLink(value: row.repository.id) {
            HStack(spacing: 12) {
              Circle()
                .fill(PRBarTheme.repositoryColor(row.repository.colorHex))
                .frame(width: 10, height: 10)

              VStack(alignment: .leading, spacing: 2) {
                Text(row.repository.name)
                  .font(.subheadline.weight(.semibold))
                Text(row.repository.owner)
                  .font(.caption)
                  .foregroundStyle(.secondary)

                GeometryReader { proxy in
                  Capsule()
                    .fill(Color(.tertiarySystemFill))
                    .overlay(alignment: .leading) {
                      Capsule()
                        .fill(PRBarTheme.repositoryColor(row.repository.colorHex).gradient)
                        .frame(width: max(10, proxy.size.width * CGFloat(row.count) / CGFloat(maxCount)))
                    }
                }
                .frame(height: 7)
                .padding(.top, 4)
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

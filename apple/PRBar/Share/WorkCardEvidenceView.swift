import SwiftUI

struct WorkCardEvidenceView: View {
  var source: WorkCardRenderer.CardSource
  var draft: WorkCardDraft
  var evidence: [WorkCardRenderer.EvidenceItem]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Evidence side")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)

        Text(source.type == .release ? "Release receipt" : "Work evidence")
          .font(.title.weight(.bold))

        Text(source.type == .release ? "GitHub release or tag evidence reviewed before export." : "GitHub activity collected behind the public work card.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      VStack(alignment: .leading, spacing: 10) {
        ForEach(evidence) { item in
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            if item.isPrivate && draft.showPrivateLabels {
              Label("Private", systemImage: "lock.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.orange)
                .labelStyle(.titleAndIcon)
            }

            VStack(alignment: .leading, spacing: 3) {
              Text(item.title)
                .font(.subheadline.weight(.semibold))
              Text(item.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
          }
        }
      }

      Spacer(minLength: 0)

      HStack {
        Text(draft.showHandle ? source.handle : "handle hidden")
        Spacer()
        Text("evidence side")
      }
      .font(.caption.weight(.semibold))
      .foregroundStyle(.secondary)
    }
    .padding(18)
    .frame(maxWidth: .infinity, minHeight: 260, alignment: .leading)
    .background(Color(.systemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(Color(.separator).opacity(0.4))
    )
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}

#Preview {
  WorkCardEvidenceView(
    source: WorkCardRenderer.source(for: PRBarStore.sample()),
    draft: PRBarStore.sample().cardDraft,
    evidence: WorkCardRenderer.evidence(for: PRBarStore.sample())
  )
  .padding()
}

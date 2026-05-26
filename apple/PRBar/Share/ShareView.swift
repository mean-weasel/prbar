import SwiftUI

struct ShareView: View {
  @Bindable var store: PRBarStore

  @State private var isExportSheetPresented = false
  @State private var alertTitle = ""
  @State private var isAlertPresented = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          header
          sourcePanel

          if store.cardHasPrivateEvidence {
            privateWarningPanel
          }

          exportSummary

          Group {
            if store.cardDraft.side == .publicSide {
              WorkCardView(
                source: WorkCardRenderer.source(for: store),
                draft: store.cardDraft
              )
            } else {
              WorkCardEvidenceView(
                source: WorkCardRenderer.source(for: store),
                draft: store.cardDraft,
                evidence: WorkCardRenderer.evidence(for: store)
              )
            }
          }

          HStack(spacing: 10) {
            Button(store.cardDraft.side == .publicSide ? "Show evidence" : "Show public card") {
              store.cardDraft.side = store.cardDraft.side == .publicSide ? .evidenceSide : .publicSide
            }
            .buttonStyle(.bordered)

            Button("Style & Privacy") {
              presentAlert("Style & Privacy")
            }
            .buttonStyle(.bordered)
          }

          Button("Export card") {
            isExportSheetPresented = true
          }
          .buttonStyle(.borderedProminent)
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
      }
      .navigationTitle("Share")
      .sheet(isPresented: $isExportSheetPresented) {
        ExportCardSheet { action in
          presentAlert(action.rawValue)
        }
      }
      .alert(alertTitle, isPresented: $isAlertPresented) {
        Button("OK", role: .cancel) {}
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Create a work card")
        .font(.largeTitle.weight(.bold))
      Text("Work cards")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(PRBarTheme.accent)
    }
  }

  private var sourcePanel: some View {
    let source = WorkCardRenderer.source(for: store)

    return VStack(alignment: .leading, spacing: 8) {
      Text("Source")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(source.title)
        .font(.headline)
      Text(source.caption)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private var privateWarningPanel: some View {
    VStack(alignment: .leading, spacing: 6) {
      Label("This export may reveal private work", systemImage: "lock.shield")
        .font(.headline)
      Text("Review repo names, exact counts, PR titles, release notes, and the evidence side before exporting.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Color.orange.opacity(0.14))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private var exportSummary: some View {
    VStack(spacing: 10) {
      summaryRow(label: "Image", value: store.cardDraft.side == .publicSide ? "Public side" : "Evidence side")
      Divider()
      summaryRow(label: "Caption", value: WorkCardRenderer.source(for: store).captionKind)
    }
    .padding(14)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private func summaryRow(label: String, value: String) -> some View {
    HStack {
      Text(label)
        .foregroundStyle(.secondary)
      Spacer()
      Text(value)
        .fontWeight(.semibold)
    }
    .font(.subheadline)
  }

  private func presentAlert(_ title: String) {
    alertTitle = title
    isAlertPresented = true
  }
}

#Preview {
  ShareView(store: .sample())
}

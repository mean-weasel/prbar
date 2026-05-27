import SwiftUI
import UIKit

struct ShareView: View {
  @Bindable var store: PRBarStore

  @State private var isExportSheetPresented = false
  @State private var isNativeSharePresented = false
  @State private var nativeShareItems: [Any] = []
  @State private var exportMessage: String?
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

          provenancePanel
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

          if let exportMessage {
            Text(exportMessage)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding()
      }
      .navigationTitle("Share")
      .sheet(isPresented: $isExportSheetPresented) {
        ExportCardSheet(export: currentExport) { action in
          handleExportAction(action)
        }
      }
      .sheet(isPresented: $isNativeSharePresented) {
        WorkCardActivityView(activityItems: nativeShareItems)
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

  private var provenancePanel: some View {
    let export = currentExport

    return VStack(alignment: .leading, spacing: 8) {
      Text("Proof source")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(export.provenance)
        .font(.subheadline.weight(.semibold))
      Text(export.freshness)
        .font(.caption)
        .foregroundStyle(export.freshness.hasPrefix("Cached") ? .orange : .secondary)
      Text(export.privacyMessage)
        .font(.caption)
        .foregroundStyle(export.includesPrivateEvidence ? .orange : .secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Color(.secondarySystemBackground))
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

  private var currentExport: WorkCardExport {
    WorkCardExportBuilder.export(for: store)
  }

  private func handleExportAction(_ action: ExportAction) {
    switch action {
    case .sharePublicImage:
      share(side: .publicSide)
    case .copyImage:
      copyImage(side: store.cardDraft.side)
    case .copyCaption:
      copyCaption()
    case .exportEvidenceSide:
      share(side: .evidenceSide)
    case .exportBothSides:
      shareBothSides()
    }
  }

  @MainActor
  private func share(side: CardSide) {
    let export = WorkCardExportBuilder.export(for: store, side: side)
    guard let image = WorkCardImageRenderer.image(for: export) else {
      presentAlert("Could not render card image")
      return
    }

    nativeShareItems = [image, export.caption]
    exportMessage = "Native share prepared for \(export.sideLabel.lowercased())."
    isNativeSharePresented = true
  }

  @MainActor
  private func shareBothSides() {
    let publicExport = WorkCardExportBuilder.export(for: store, side: .publicSide)
    let evidenceExport = WorkCardExportBuilder.export(for: store, side: .evidenceSide)
    guard
      let publicImage = WorkCardImageRenderer.image(for: publicExport),
      let evidenceImage = WorkCardImageRenderer.image(for: evidenceExport)
    else {
      presentAlert("Could not render card images")
      return
    }

    nativeShareItems = [publicImage, evidenceImage, publicExport.caption]
    exportMessage = "Native share prepared for both card sides."
    isNativeSharePresented = true
  }

  @MainActor
  private func copyImage(side: CardSide) {
    let export = WorkCardExportBuilder.export(for: store, side: side)
    guard let image = WorkCardImageRenderer.image(for: export) else {
      presentAlert("Could not render card image")
      return
    }

    UIPasteboard.general.image = image
    exportMessage = "\(export.sideLabel) image copied."
  }

  private func copyCaption() {
    UIPasteboard.general.string = currentExport.caption
    exportMessage = "Caption copied from GitHub activity."
  }

  private func presentAlert(_ title: String) {
    alertTitle = title
    isAlertPresented = true
  }
}

#Preview {
  ShareView(store: .sample())
}

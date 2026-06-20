import SwiftUI
import UIKit

struct ShareView: View {
  @Bindable var store: PRBarStore

  @State private var isExportSheetPresented = false
  @State private var isStylePrivacyPresented = false
  @State private var isNativeSharePresented = false
  @State private var nativeShareItems: [Any] = []
  @State private var exportMessage: String?
  @State private var pendingSensitiveExportAction: ExportAction?
  @State private var isSensitiveExportConfirmationPresented = false
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
              isStylePrivacyPresented = true
            }
            .buttonStyle(.bordered)
          }

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
      .sheet(isPresented: $isStylePrivacyPresented) {
        StylePrivacySheet(store: store)
      }
      .sheet(isPresented: $isNativeSharePresented) {
        WorkCardActivityView(activityItems: nativeShareItems)
      }
      .alert(alertTitle, isPresented: $isAlertPresented) {
        Button("OK", role: .cancel) {}
      }
      .confirmationDialog("Export private evidence?", isPresented: $isSensitiveExportConfirmationPresented, titleVisibility: .visible) {
        Button(pendingSensitiveExportAction?.rawValue ?? "Export", role: .destructive) {
          if let pendingSensitiveExportAction {
            performExportAction(pendingSensitiveExportAction)
          }
          pendingSensitiveExportAction = nil
        }
        Button("Cancel", role: .cancel) {
          pendingSensitiveExportAction = nil
        }
      } message: {
        Text("This can include private repo names, PR titles, release notes, exact counts, or private labels. Review the evidence side before sharing.")
      }
      .safeAreaInset(edge: .bottom) {
        exportBar
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Share a work card")
        .font(.largeTitle.weight(.bold))
      Text("Public-safe by default, evidence available when you choose it.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
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

  private var exportBar: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Label(currentExport.includesPrivateEvidence ? "Review private evidence before export" : "Ready to export", systemImage: currentExport.includesPrivateEvidence ? "lock.shield" : "checkmark.shield")
          .font(.caption.weight(.semibold))
          .foregroundStyle(currentExport.includesPrivateEvidence ? .orange : .secondary)
        Spacer(minLength: 0)
      }

      Button {
        isExportSheetPresented = true
      } label: {
        Label("Export card", systemImage: "square.and.arrow.up")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
    }
    .padding(.horizontal)
    .padding(.top, 10)
    .padding(.bottom, 8)
    .background(.bar)
  }

  private func handleExportAction(_ action: ExportAction) {
    if action.needsSensitiveConfirmation && currentExport.includesPrivateEvidence {
      pendingSensitiveExportAction = action
      isSensitiveExportConfirmationPresented = true
      return
    }

    performExportAction(action)
  }

  private func performExportAction(_ action: ExportAction) {
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

private struct StylePrivacySheet: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var store: PRBarStore

  var body: some View {
    NavigationStack {
      Form {
        Section("Card side") {
          Picker("Card side", selection: $store.cardDraft.side) {
            Text("Public").tag(CardSide.publicSide)
            Text("Evidence").tag(CardSide.evidenceSide)
          }
          .pickerStyle(.segmented)
        }

        Section("Style") {
          Picker("Theme", selection: $store.cardDraft.theme) {
            ForEach(WorkCardDraft.Theme.allCases) { theme in
              Text(theme.displayName).tag(theme)
            }
          }
        }

        Section {
          Toggle("Show repos", isOn: $store.cardDraft.showRepos)
          Toggle("Show handle", isOn: $store.cardDraft.showHandle)
          Toggle("Exact counts", isOn: $store.cardDraft.exactCounts)
          Toggle("Show private labels", isOn: $store.cardDraft.showPrivateLabels)
        } header: {
          Text("Public card privacy")
        } footer: {
          Text("Private repo names, exact counts, PR titles, release notes, and private labels can reveal sensitive work. Review the evidence side before sharing beyond your team.")
        }
      }
      .navigationTitle("Style & Privacy")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
  }
}

private extension WorkCardDraft.Theme {
  var displayName: String {
    switch self {
    case .clean:
      "Clean"
    case .terminal:
      "Terminal"
    case .launch:
      "Launch"
    case .hype:
      "Hype"
    case .minimal:
      "Minimal"
    }
  }
}

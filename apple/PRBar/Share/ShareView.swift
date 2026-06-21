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

          cardControls
          workCardPreview
          primaryExportButton
          exportReadinessPanel

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
    }
  }

  private var cardControls: some View {
    HStack(spacing: PRBarTheme.compactSpacing) {
      Button {
        store.cardDraft.side = store.cardDraft.side == .publicSide ? .evidenceSide : .publicSide
      } label: {
        Label(store.cardDraft.side == .publicSide ? "Evidence" : "Public", systemImage: "doc.text.magnifyingglass")
      }
      .buttonStyle(.bordered)

      Button {
        isStylePrivacyPresented = true
      } label: {
        Label("Style", systemImage: "slider.horizontal.3")
      }
      .buttonStyle(.bordered)
    }
    .font(.subheadline.weight(.semibold))
  }

  @ViewBuilder
  private var workCardPreview: some View {
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

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Share a work card")
        .font(.largeTitle.weight(.bold))
      Text("Public-safe by default, evidence available when you choose it.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }

  private var exportReadinessPanel: some View {
    let export = currentExport

    return HStack(spacing: 8) {
      Image(systemName: export.includesPrivateEvidence ? "lock.shield" : "checkmark.shield")
        .foregroundStyle(export.includesPrivateEvidence ? .orange : PRBarTheme.accent)

      Text(export.includesPrivateEvidence ? "Evidence review available" : "Public-safe preview")
        .font(.caption.weight(.semibold))

      Spacer(minLength: 8)

      Text("Proof")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      Text(export.freshness)
        .font(.caption.weight(.semibold))
        .foregroundStyle(export.freshness.hasPrefix("Cached") ? .orange : .secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.82)
    }
    .padding(.horizontal, 4)
    .accessibilityElement(children: .combine)
  }

  private var currentExport: WorkCardExport {
    WorkCardExportBuilder.export(for: store)
  }

  private var primaryExportButton: some View {
    Button {
      isExportSheetPresented = true
    } label: {
      Label("Export card", systemImage: "square.and.arrow.up")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
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

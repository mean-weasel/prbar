import SwiftUI

enum ExportAction: String, CaseIterable, Identifiable {
  case sharePublicImage = "Share public-safe image"
  case copyImage = "Copy image"
  case copyCaption = "Copy caption"
  case exportEvidenceSide = "Export evidence side"
  case exportBothSides = "Export both sides"

  var id: String { rawValue }

  var systemImage: String {
    switch self {
    case .sharePublicImage:
      "square.and.arrow.up"
    case .copyImage:
      "photo.on.rectangle"
    case .copyCaption:
      "doc.on.doc"
    case .exportEvidenceSide:
      "lock.doc"
    case .exportBothSides:
      "rectangle.on.rectangle"
    }
  }

  var isPrimarySafeAction: Bool {
    self == .sharePublicImage
  }

  var needsSensitiveConfirmation: Bool {
    self == .exportEvidenceSide || self == .exportBothSides
  }

  static let copyActions: [ExportAction] = [.copyImage, .copyCaption]
  static let advancedActions: [ExportAction] = [.exportEvidenceSide, .exportBothSides]
}

struct ExportCardSheet: View {
  @Environment(\.dismiss) private var dismiss
  @State private var isAdvancedExpanded = false

  var export: WorkCardExport
  var onAction: (ExportAction) -> Void

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 18) {
        VStack(alignment: .leading, spacing: 6) {
          Text("Export card")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
          Text("Share public-safe card")
            .font(.title2.weight(.bold))
          Text("The default export uses the public side. Evidence exports stay tucked away until you ask for them.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .top, spacing: 6) {
            Image(systemName: export.includesPrivateEvidence ? "lock.shield" : "checkmark.shield")
              .font(.caption)
            Text(export.privacyMessage)
              .font(.caption)
              .fixedSize(horizontal: false, vertical: true)
          }
          .foregroundStyle(export.includesPrivateEvidence ? .orange : .secondary)
          Text(export.provenance)
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(export.freshness)
            .font(.caption.weight(.semibold))
            .foregroundStyle(export.freshness.hasPrefix("Cached") ? .orange : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        VStack(alignment: .leading, spacing: 10) {
          Text("Default")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
          actionButton(.sharePublicImage)
        }

        VStack(alignment: .leading, spacing: 10) {
          Text("Copy instead")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
          ForEach(ExportAction.copyActions) { action in
            actionButton(action)
          }
        }

        DisclosureGroup(isExpanded: $isAdvancedExpanded) {
          VStack(spacing: 8) {
            ForEach(ExportAction.advancedActions) { action in
              actionButton(action)
            }
          }
          .padding(.top, 8)
        } label: {
          Label("Advanced evidence exports", systemImage: "lock.doc")
            .font(.subheadline.weight(.semibold))
        }

        Spacer(minLength: 0)
      }
      .padding()
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.fraction(0.72), .large])
  }

  @ViewBuilder
  private func actionButton(_ action: ExportAction) -> some View {
    if action.isPrimarySafeAction {
      Button {
        select(action)
      } label: {
        actionLabel(action)
      }
      .buttonStyle(.borderedProminent)
    } else {
      Button {
        select(action)
      } label: {
        actionLabel(action)
      }
      .buttonStyle(.bordered)
      .tint(action.needsSensitiveConfirmation ? .orange : nil)
    }
  }

  private func actionLabel(_ action: ExportAction) -> some View {
    Label(action.rawValue, systemImage: action.systemImage)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func select(_ action: ExportAction) {
    dismiss()
    DispatchQueue.main.async {
      onAction(action)
    }
  }
}

#Preview {
  ExportCardSheet(export: WorkCardExportBuilder.export(for: .sample())) { _ in }
}

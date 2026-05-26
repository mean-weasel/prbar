import SwiftUI

enum ExportAction: String, CaseIterable, Identifiable {
  case sharePublicImage = "Share public-side image"
  case saveImage = "Save image"
  case copyImage = "Copy image"
  case copyCaption = "Copy caption"
  case exportEvidenceSide = "Export evidence side"
  case exportBothSides = "Export both sides"

  var id: String { rawValue }
}

struct ExportCardSheet: View {
  @Environment(\.dismiss) private var dismiss

  var onAction: (ExportAction) -> Void

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 6) {
          Text("Export card")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
          Text("Choose what leaves the app")
            .font(.title2.weight(.bold))
        }

        VStack(alignment: .leading, spacing: 6) {
          Text("Images are exported as PNGs")
            .font(.headline)
          Text("Messages and other apps decide how the image and optional caption appear after sharing.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        VStack(spacing: 8) {
          ForEach(ExportAction.allCases) { action in
            Button(action.rawValue) {
              dismiss()
              onAction(action)
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }

        Spacer(minLength: 0)
      }
      .padding()
      .navigationTitle("Export card")
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

#Preview {
  ExportCardSheet { _ in }
}

import AppKit
import SwiftUI

struct ShareCardPreviewSheet: View {
  var payload: ShareCardPayload
  var onClose: (() -> Void)?
  @Environment(\.dismiss) private var dismiss
  @State private var message: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ShareCardView(payload: payload)
        .frame(maxWidth: .infinity)

      Label(payload.privacyMessage, systemImage: "lock.fill")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)

      HStack(spacing: 10) {
        Button {
          share()
        } label: {
          Label("Share", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.borderedProminent)
        Button {
          copyImage()
        } label: {
          Label("Copy Image", systemImage: "doc.on.doc")
        }
        .buttonStyle(.bordered)
        Button {
          savePNG()
        } label: {
          Label("Save PNG", systemImage: "square.and.arrow.down")
        }
        .buttonStyle(.bordered)
      }
      .controlSize(.large)

      if let message {
        Text(message)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(16)
    .frame(width: 398, height: 448)
  }

  private func close() {
    if let onClose {
      onClose()
    } else {
      dismiss()
    }
  }

  @MainActor
  private func share() {
    guard let image = ShareCardRenderer.image(for: payload) else {
      message = "Could not render card image."
      return
    }
    guard let contentView = NSApp.keyWindow?.contentView else {
      message = "Could not open share sheet."
      return
    }
    NSSharingServicePicker(items: [image]).show(
      relativeTo: .zero,
      of: contentView,
      preferredEdge: .minY
    )
    message = "Share sheet opened."
  }

  @MainActor
  private func copyImage() {
    guard let image = ShareCardRenderer.image(for: payload) else {
      message = "Could not render card image."
      return
    }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.writeObjects([image])
    message = "Image copied."
  }

  @MainActor
  private func savePNG() {
    guard let image = ShareCardRenderer.image(for: payload),
      let data = image.pngData
    else {
      message = "Could not render card image."
      return
    }
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.png]
    panel.nameFieldStringValue = payload.exportFilename
    if panel.runModal() == .OK, let url = panel.url {
      do {
        try data.write(to: url)
        message = "Image saved."
      } catch {
        message = "Could not save image."
      }
    }
  }
}

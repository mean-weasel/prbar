import AppKit
import SwiftUI

struct ShareCardPreviewSheet: View {
  var payload: ShareCardPayload
  @Environment(\.dismiss) private var dismiss
  @State private var message: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text(payload.title)
          .font(.headline)
        Spacer()
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark")
        }
        .buttonStyle(.bordered)
      }

      ShareCardView(payload: payload)
        .frame(maxWidth: .infinity)

      Label(payload.privacyMessage, systemImage: "lock.fill")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

      HStack {
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

      if let message {
        Text(message)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(18)
    .frame(width: 420)
  }

  @MainActor
  private func share() {
    guard let image = ShareCardRenderer.image(for: payload) else {
      message = "Could not render card image."
      return
    }
    NSSharingServicePicker(items: [image]).show(
      relativeTo: .zero,
      of: NSApp.keyWindow?.contentView ?? NSView(),
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

extension NSImage {
  fileprivate var pngData: Data? {
    guard let tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffRepresentation)
    else {
      return nil
    }
    return bitmap.representation(using: .png, properties: [:])
  }
}

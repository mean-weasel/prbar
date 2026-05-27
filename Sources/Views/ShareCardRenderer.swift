import AppKit
import SwiftUI

enum ShareCardRenderer {
  @MainActor
  static func image(for payload: ShareCardPayload) -> NSImage? {
    let renderer = ImageRenderer(content: ShareCardView(payload: payload))
    renderer.scale = 2
    return renderer.nsImage
  }
}

extension NSImage {
  var pngData: Data? {
    guard let tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffRepresentation)
    else {
      return nil
    }
    return bitmap.representation(using: .png, properties: [:])
  }
}

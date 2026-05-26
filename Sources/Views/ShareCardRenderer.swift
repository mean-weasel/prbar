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

import AppKit
import SwiftUI

@MainActor
enum ShareCardPreviewPresenter {
  private static var controllers: [ShareCardPreviewWindowController] = []

  static func show(payload: ShareCardPayload) {
    let controller = ShareCardPreviewWindowController(payload: payload) { closedController in
      controllers.removeAll { $0 === closedController }
    }
    controllers.append(controller)
    controller.showWindow(nil)
    controller.window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}

@MainActor
private final class ShareCardPreviewWindowController: NSWindowController, NSWindowDelegate {
  private let onClose: (ShareCardPreviewWindowController) -> Void

  init(
    payload: ShareCardPayload,
    onClose: @escaping (ShareCardPreviewWindowController) -> Void
  ) {
    self.onClose = onClose
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 430, height: 510),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    window.title = payload.title
    window.isReleasedWhenClosed = false
    window.center()
    super.init(window: window)
    window.delegate = self
    window.contentViewController = NSHostingController(
      rootView: ShareCardPreviewSheet(payload: payload) { [weak self] in
        self?.close()
      }
    )
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func windowWillClose(_ notification: Notification) {
    onClose(self)
  }
}

import AppKit
import SwiftUI
import XCTest

@testable import PRMenuBar

final class PRSettingsViewRenderingTests: XCTestCase {
  @MainActor
  func testSettingsViewRendersRepositorySearchControls() throws {
    let image = try XCTUnwrap(
      settingsImage(
        store: PRActivityStore(
          bucketLabels: ["W1"],
          window: .twoWeeks,
          bin: .week,
          refreshInterval: .daily,
          repositories: [
            repository(id: "mean-weasel/deckchecker", isIncluded: true),
            repository(id: "mean-weasel/seatify", isIncluded: false),
            repository(id: "neonwatty/RedditReminder", isIncluded: true),
            repository(id: "neonwatty/nav-map", isIncluded: false),
          ],
          refreshedAt: Date(timeIntervalSince1970: 1_779_840_000)
        )
      )
    )

    XCTAssertGreaterThan(image.size.width, 500)
    XCTAssertGreaterThan(image.size.height, 650)

    let snapshotURL = URL(
      fileURLWithPath: ProcessInfo.processInfo.environment[
        "PR_MENU_BAR_SETTINGS_SNAPSHOT_PATH"
      ] ?? "/tmp/prbar-settings-view.png"
    )
    try FileManager.default.createDirectory(
      at: snapshotURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    let data = try XCTUnwrap(image.pngData)
    try data.write(to: snapshotURL)
    add(XCTAttachment(contentsOfFile: snapshotURL))
  }

  @MainActor
  private func settingsImage(store: PRActivityStore) -> NSImage? {
    let hostingView = NSHostingView(
      rootView: PRSettingsView(store: .constant(store), dataSource: .sample)
        .padding(24)
        .frame(width: 560, height: 760, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor))
    )
    hostingView.frame = NSRect(x: 0, y: 0, width: 560, height: 760)
    let window = NSWindow(
      contentRect: hostingView.bounds,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.contentView = hostingView
    hostingView.layoutSubtreeIfNeeded()

    guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
      return nil
    }
    hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
    let image = NSImage(size: hostingView.bounds.size)
    image.addRepresentation(bitmap)
    return image
  }

  private func repository(id: String, isIncluded: Bool) -> RepositoryActivity {
    let parts = id.split(separator: "/", maxSplits: 1).map(String.init)
    return RepositoryActivity(
      id: id,
      owner: parts[0],
      name: parts[1],
      colorHex: "#4f8cff",
      weeklyCounts: [1],
      isIncluded: isIncluded
    )
  }
}

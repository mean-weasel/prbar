import XCTest

@testable import PRMenuBar

final class ShareCardRenderingTests: XCTestCase {
  @MainActor
  func testPRShareCardRendersSnapshot() throws {
    var store = PRActivityStore.sample(now: Date(timeIntervalSince1970: 1_779_840_000))
    store.window = .twoWeeks
    store.bin = .day
    store.showPrivateRepositoryNamesInShare = true
    let payload = ShareCardPayload.prActivity(ShareCardBuilder.prActivityPayload(store: store))

    let image = try XCTUnwrap(ShareCardRenderer.image(for: payload))
    XCTAssertGreaterThan(image.size.width, 300)
    XCTAssertGreaterThan(image.size.height, 250)

    let snapshotPath =
      ProcessInfo.processInfo.environment["PR_MENU_BAR_SHARE_CARD_SNAPSHOT_PATH"]
      ?? "/tmp/prbar-share-card-pr-preview.png"

    let snapshotURL = URL(fileURLWithPath: snapshotPath)
    try FileManager.default.createDirectory(
      at: snapshotURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    let data = try XCTUnwrap(image.pngData)
    try data.write(to: snapshotURL)
    add(XCTAttachment(contentsOfFile: snapshotURL))
  }
}

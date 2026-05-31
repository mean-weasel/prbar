import Foundation

struct GitHubRelease: Decodable {
  var id: Int
  var tagName: String
  var name: String?
  var body: String?
  var publishedAt: Date
  var htmlURL: URL?

  func moment(repositoryID: String) -> ReleaseMoment {
    ReleaseMoment(
      id: "release-\(repositoryID)-\(id)",
      repositoryID: repositoryID,
      title: name?.nonEmpty ?? "Release",
      tag: tagName,
      date: publishedAt,
      notes: body?.nonEmpty ?? "No release notes provided.",
      url: htmlURL,
      source: .githubRelease
    )
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case tagName = "tag_name"
    case name
    case body
    case publishedAt = "published_at"
    case htmlURL = "html_url"
  }
}

struct GitHubTag: Decodable {
  var name: String

  func moment(repositoryID: String, now: Date) -> ReleaseMoment {
    ReleaseMoment(
      id: "tag-\(repositoryID)-\(name)",
      repositoryID: repositoryID,
      title: "Tagged version",
      tag: name,
      date: now,
      notes: "Generated from the latest Git tag because this repository has no GitHub Releases.",
      url: URL(string: "https://github.com/\(repositoryID)/releases/tag/\(name)"),
      source: .tag
    )
  }
}

struct ReleaseMomentCache {
  var createdAt: Date
  var repositoryIDs: [String]
  var releases: [ReleaseMoment]
}

final class ReleaseMomentRequestCounters {
  private let lock = NSLock()
  private var storedReleaseRequestCount = 0
  private var storedTagRequestCount = 0

  var releaseRequestCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return storedReleaseRequestCount
  }

  var tagRequestCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return storedTagRequestCount
  }

  func incrementReleaseRequestCount() {
    lock.lock()
    storedReleaseRequestCount += 1
    lock.unlock()
  }

  func incrementTagRequestCount() {
    lock.lock()
    storedTagRequestCount += 1
    lock.unlock()
  }
}

final class ReleaseMomentConcurrentResults {
  private let lock = NSLock()
  private var momentsByIndex: [ReleaseMoment?]
  private var firstError: Error?

  init(count: Int) {
    momentsByIndex = [ReleaseMoment?](repeating: nil, count: count)
  }

  var moments: [ReleaseMoment] {
    lock.lock()
    defer { lock.unlock() }
    return momentsByIndex.compactMap { $0 }
  }

  var error: Error? {
    lock.lock()
    defer { lock.unlock() }
    return firstError
  }

  func setMoment(_ moment: ReleaseMoment?, at index: Int) {
    lock.lock()
    momentsByIndex[index] = moment
    lock.unlock()
  }

  func setErrorIfNeeded(_ error: Error) {
    lock.lock()
    if firstError == nil {
      firstError = error
    }
    lock.unlock()
  }
}

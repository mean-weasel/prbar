import Foundation

protocol PRActivityProviding {
  func load(now: Date) throws -> PRActivityStore
}

struct StaticPRActivityProvider: PRActivityProviding {
  func load(now: Date = Date()) throws -> PRActivityStore {
    PRActivityStore.sample(now: now)
  }
}

struct JSONPRActivityProvider: PRActivityProviding {
  var data: Data

  func load(now: Date = Date()) throws -> PRActivityStore {
    let payload = try JSONDecoder().decode(PRActivityPayload.self, from: data)
    return PRActivityStore(
      bucketLabels: payload.bucketLabels,
      window: payload.defaultWindow,
      repositories: payload.repositories,
      refreshedAt: now
    )
  }
}

private struct PRActivityPayload: Codable {
  var bucketLabels: [String]
  var defaultWindow: ActivityWindow
  var repositories: [RepositoryActivity]
}

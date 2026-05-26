import Foundation

struct ReleaseMomentStore: Equatable {
  var releases: [ReleaseMoment]

  func visibleReleases(for repositories: [RepositoryActivity]) -> [ReleaseMoment] {
    let includedIDs = Set(repositories.filter(\.isIncluded).map(\.id))

    return
      releases
      .filter { includedIDs.contains($0.repositoryID) }
      .sorted { $0.date > $1.date }
  }
}

import Foundation

struct RepositoryBucketValue: Identifiable, Equatable {
  var repository: RepositoryActivity
  var value: Int

  var id: String {
    repository.id
  }
}

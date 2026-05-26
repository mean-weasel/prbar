import Foundation

enum ReleaseRefreshState: Equatable {
  case idle
  case loading
  case failed(String)
}

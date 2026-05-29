import Foundation

struct GitHubAuthenticatedUser: Codable, Equatable {
  var login: String
}

struct GitHubOrganization: Codable, Equatable {
  var login: String
}

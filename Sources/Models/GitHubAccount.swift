import Foundation

struct GitHubAuthenticatedUser: Decodable, Equatable {
  var login: String
}

struct GitHubOrganization: Decodable, Equatable {
  var login: String
}

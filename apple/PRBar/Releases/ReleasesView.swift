import SwiftUI

struct ReleasesView: View {
  var store: PRBarStore

  var body: some View {
    NavigationStack {
      Text("Shipping moments")
        .navigationTitle("Releases")
    }
  }
}

#Preview {
  ReleasesView(store: .sample())
}

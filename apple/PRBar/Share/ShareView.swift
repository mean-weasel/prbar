import SwiftUI

struct ShareView: View {
  var store: PRBarStore

  var body: some View {
    NavigationStack {
      Text("Create a work card")
        .navigationTitle("Share")
    }
  }
}

#Preview {
  ShareView(store: .sample())
}

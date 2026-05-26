import SwiftUI

struct MoreView: View {
  var store: PRBarStore

  var body: some View {
    NavigationStack {
      Text("Menu")
        .navigationTitle("More")
    }
  }
}

#Preview {
  MoreView(store: .sample())
}

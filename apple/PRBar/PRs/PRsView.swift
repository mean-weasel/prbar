import SwiftUI

struct PRsView: View {
  var store: PRBarStore

  var body: some View {
    NavigationStack {
      Text("Shipping rhythm")
        .navigationTitle("PRs")
    }
  }
}

#Preview {
  PRsView(store: .sample())
}

import SwiftUI

struct RangePickerView: View {
  @Binding var selection: ActivityRange

  var body: some View {
    Picker("Range", selection: $selection) {
      ForEach(ActivityRange.allCases) { range in
        Text(range.rawValue.capitalized)
          .tag(range)
      }
    }
    .pickerStyle(.segmented)
  }
}

#Preview {
  @Previewable @State var range = ActivityRange.week

  RangePickerView(selection: $range)
    .padding()
}

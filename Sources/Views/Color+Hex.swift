import SwiftUI

extension Color {
  init(hex: String) {
    let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    let scanner = Scanner(string: trimmed)
    var value: UInt64 = 0
    scanner.scanHexInt64(&value)

    let red = Double((value >> 16) & 0xff) / 255
    let green = Double((value >> 8) & 0xff) / 255
    let blue = Double(value & 0xff) / 255

    self.init(red: red, green: green, blue: blue)
  }
}

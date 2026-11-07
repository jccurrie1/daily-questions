import SwiftUI

enum Palette {
    static let ink = Color("Ink")
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let border = Color("Border")
    static let selection = Color("Selection")
    static let onInk = Color("OnInk")
    static let toggle = Color("Toggle")
}

extension View {
    func inkProminentButton() -> some View {
        buttonStyle(.borderedProminent).foregroundStyle(Palette.onInk)
    }

    func inkGlassButton() -> some View {
        buttonStyle(.glassProminent).tint(Palette.ink).foregroundStyle(Palette.onInk)
    }
}

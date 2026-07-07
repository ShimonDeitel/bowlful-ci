import SwiftUI

/// Bowlful's identity: a warm terracotta/cream/forest-green "feeding bowl"
/// palette — earthy and kitchen-like, distinct from every sibling app's
/// colors.
enum BWTheme {
    static let backdrop = Color(red: 0.973, green: 0.949, blue: 0.906)   // warm cream
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.949, green: 0.910, blue: 0.851)
    static let ink = Color(red: 0.247, green: 0.184, blue: 0.129)   // deep coffee-ink
    static let inkFaded = Color(red: 0.247, green: 0.184, blue: 0.129).opacity(0.55)
    static let rule = Color.black.opacity(0.08)

    static let terracotta = Color(red: 0.729, green: 0.373, blue: 0.216)
    static let terracottaBright = Color(red: 0.831, green: 0.463, blue: 0.271)
    static let forest = Color(red: 0.220, green: 0.408, blue: 0.263)
    static let forestBright = Color(red: 0.290, green: 0.514, blue: 0.325)
    static let danger = Color(red: 0.788, green: 0.259, blue: 0.220)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

// SPDX-License-Identifier: MIT
import SwiftUI

enum FinderTagColor: String, CaseIterable, Identifiable {
    case none, gray, green, purple, blue, yellow, red, orange

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .gray: return "Gray"
        case .green: return "Green"
        case .purple: return "Purple"
        case .blue: return "Blue"
        case .yellow: return "Yellow"
        case .red: return "Red"
        case .orange: return "Orange"
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .none: return .clear
        case .gray: return .gray
        case .green: return .green
        case .purple: return .purple
        case .blue: return .blue
        case .yellow: return .yellow
        case .red: return .red
        case .orange: return .orange
        }
    }

    static func color(forTagName name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "gray", "grey": return .gray
        default: return .secondary
        }
    }

    static var system: [FinderTagColor] {
        [.red, .orange, .yellow, .green, .blue, .purple, .gray]
    }
}

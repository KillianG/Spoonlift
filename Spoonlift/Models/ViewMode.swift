// SPDX-License-Identifier: MIT
import Foundation

enum ViewMode: String, CaseIterable, Identifiable, Codable {
    case list, icons, columns, brief

    var id: String { rawValue }

    var label: String {
        switch self {
        case .list: return "List"
        case .icons: return "Icons"
        case .columns: return "Columns"
        case .brief: return "Brief"
        }
    }

    var symbol: String {
        switch self {
        case .list: return "list.bullet"
        case .icons: return "square.grid.2x2"
        case .columns: return "rectangle.split.3x1"
        case .brief: return "list.dash"
        }
    }
}

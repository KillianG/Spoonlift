// SPDX-License-Identifier: MIT
import Foundation

enum SortField: String, CaseIterable, Identifiable, Codable {
    case name, size, kind, modified, created

    var id: String { rawValue }

    var label: String {
        switch self {
        case .name: return "Name"
        case .size: return "Size"
        case .kind: return "Kind"
        case .modified: return "Date Modified"
        case .created: return "Date Created"
        }
    }
}

enum SortDirection: String, Codable {
    case ascending, descending

    mutating func toggle() {
        self = (self == .ascending) ? .descending : .ascending
    }
}

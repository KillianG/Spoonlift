// SPDX-License-Identifier: MIT
import SwiftUI

struct TagEditorPopover: View {
    let urls: [URL]
    var onChange: () -> Void = {}
    @State private var applied: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tags").font(.headline)
            ForEach(FinderTagColor.system) { color in
                Button {
                    toggle(color.displayName)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: applied.contains(color.displayName)
                              ? "checkmark.circle.fill"
                              : "circle")
                            .foregroundStyle(applied.contains(color.displayName) ? Color.accentColor : .secondary)
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 12, height: 12)
                        Text(color.displayName)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(minWidth: 180)
        .onAppear { reload() }
    }

    private func reload() {
        var common: Set<String>? = nil
        for url in urls {
            let tags = Set(TagService.tags(of: url))
            common = common?.intersection(tags) ?? tags
        }
        applied = common ?? []
    }

    private func toggle(_ name: String) {
        let isSet = applied.contains(name)
        for url in urls {
            if isSet {
                try? TagService.removeTag(name, from: url)
            } else {
                try? TagService.addTag(name, to: url)
            }
        }
        reload()
        onChange()
    }
}

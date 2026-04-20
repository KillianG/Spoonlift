// SPDX-License-Identifier: MIT
import SwiftUI
import Quartz

struct PreviewPaneView: View {
    let urls: [URL]

    var body: some View {
        Group {
            if let url = urls.first {
                QLPreviewRepresentable(url: url)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("No Selection")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.windowBackground)
    }
}

private struct QLPreviewRepresentable: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal) ?? QLPreviewView()
        view.previewItem = url as NSURL
        view.autostarts = true
        return view
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        let currentURL = (nsView.previewItem as? URL) ?? (nsView.previewItem as? NSURL) as URL?
        if currentURL != url {
            nsView.previewItem = url as NSURL
        }
    }
}

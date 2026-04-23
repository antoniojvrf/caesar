import AppKit
import SwiftUI

struct WindowZoomTapZone: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        ZoomTapView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class ZoomTapView: NSView {
    override var acceptsFirstResponder: Bool { true }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)

        guard event.clickCount == 1, let window else { return }
        let targetFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame

        if let targetFrame {
            window.setFrame(targetFrame, display: true, animate: true)
        }
    }
}

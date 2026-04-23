import Foundation
import CoreText
#if canImport(AppKit)
import AppKit
#endif

enum FontLoader {
    /// Registers every bundled TTF/OTF inside `Resources/Fonts/` with Core Text
    /// so `Font(name:)` can resolve them without requiring Info.plist entries
    /// (Swift packages don't carry a host Info.plist).
    static func registerBundledFonts() {
        guard let resourceURL = Bundle.module.resourceURL else { return }
        let fontsURL = resourceURL.appendingPathComponent("Fonts", isDirectory: true)

        let enumerator = FileManager.default.enumerator(
            at: fontsURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        while let url = enumerator?.nextObject() as? URL {
            guard ["ttf", "otf"].contains(url.pathExtension.lowercased()) else { continue }
            registerFont(at: url)
        }
    }

    private static func registerFont(at url: URL) {
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            if let cfError = error?.takeRetainedValue() {
                // kCTFontManagerErrorAlreadyRegistered = 105 — benign on hot reload.
                let code = CFErrorGetCode(cfError)
                if code != 105 {
                    #if DEBUG
                    print("[FontLoader] failed to register \(url.lastPathComponent): \(cfError)")
                    #endif
                }
            }
        }
    }
}

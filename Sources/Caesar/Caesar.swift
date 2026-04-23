import CaesarCore
import AppKit
import SwiftUI

@main
struct CaesarApp: App {
    @StateObject private var store = AppStore(
        persistence: FilePersistence(),
        preferences: UserDefaultsWorkspacePreferences(),
        authentication: AllowAllWorkspaceAuthenticator()
    )

    init() {
        FontLoader.registerBundledFonts()

        NSApplication.shared.setActivationPolicy(.regular)
        NSWindow.allowsAutomaticWindowTabbing = false

        if let appIconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let appIcon = NSImage(contentsOf: appIconURL) {
            NSApplication.shared.applicationIconImage = appIcon
        }

        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .frame(minWidth: 1180, minHeight: 780)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

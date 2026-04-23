import Foundation

public enum WorkspaceProfile: String, Codable, CaseIterable, Identifiable {
    case real
    case demo

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .real: "Dados reais"
        case .demo: "Dados demo"
        }
    }

    public var workspaceFilename: String {
        switch self {
        case .real: "workspace-v1.json"
        case .demo: "workspace-demo.json"
        }
    }
}

public protocol WorkspacePreferencesManaging: AnyObject {
    var nextLaunchProfile: WorkspaceProfile { get set }
}

public final class InMemoryWorkspacePreferences: WorkspacePreferencesManaging {
    public var nextLaunchProfile: WorkspaceProfile

    public init(nextLaunchProfile: WorkspaceProfile = .real) {
        self.nextLaunchProfile = nextLaunchProfile
    }
}

public final class UserDefaultsWorkspacePreferences: WorkspacePreferencesManaging {
    private let defaults: UserDefaults
    private let key = "caesar.nextLaunchProfile"
    private let legacyKeys = [
        "mylifenative.nextLaunchProfile",
        "MyLifeNative.nextLaunchProfile",
        "workspace.nextLaunchProfile"
    ]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        migrateLegacyValueIfNeeded()
    }

    public var nextLaunchProfile: WorkspaceProfile {
        get {
            guard let raw = defaults.string(forKey: key),
                  let profile = WorkspaceProfile(rawValue: raw) else {
                return .real
            }
            return profile
        }
        set {
            defaults.set(newValue.rawValue, forKey: key)
        }
    }

    private func migrateLegacyValueIfNeeded() {
        guard defaults.string(forKey: key) == nil else { return }
        for legacyKey in legacyKeys {
            if let raw = defaults.string(forKey: legacyKey),
               WorkspaceProfile(rawValue: raw) != nil {
                defaults.set(raw, forKey: key)
                return
            }
        }
    }
}

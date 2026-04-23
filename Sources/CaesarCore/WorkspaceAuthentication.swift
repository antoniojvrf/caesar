import Foundation

public enum WorkspaceAuthenticationError: Error, Equatable {
    case unavailable
    case denied
}

@MainActor
public protocol WorkspaceAuthenticating {
    func authenticate(reason: String) async throws -> Bool
}

public struct AllowAllWorkspaceAuthenticator: WorkspaceAuthenticating {
    public init() {}

    public func authenticate(reason: String) async throws -> Bool {
        true
    }
}

public struct AppSession: Equatable {
    public var isAuthenticated: Bool
    public var profile: WorkspaceProfile
    public var lastError: String?

    public init(isAuthenticated: Bool = false, profile: WorkspaceProfile = .real, lastError: String? = nil) {
        self.isAuthenticated = isAuthenticated
        self.profile = profile
        self.lastError = lastError
    }
}

import CaesarCore
import Foundation
import LocalAuthentication

final class LocalAuthenticationManager: WorkspaceAuthenticating {
    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw WorkspaceAuthenticationError.unavailable
        }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            throw WorkspaceAuthenticationError.denied
        }
    }
}

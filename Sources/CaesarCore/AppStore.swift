import Combine
import Foundation

@MainActor
public final class AppStore: ObservableObject {
    @Published public private(set) var state: AppState
    @Published public private(set) var session: AppSession
    @Published public private(set) var canPersist: Bool
    @Published public private(set) var nextLaunchProfile: WorkspaceProfile

    private let persistence: PersistenceManaging
    private let preferences: WorkspacePreferencesManaging
    private let authenticator: WorkspaceAuthenticating

    public init(
        state: AppState = AppState.makeEmpty(),
        persistence: PersistenceManaging = InMemoryPersistence(),
        preferences: WorkspacePreferencesManaging = UserDefaultsWorkspacePreferences(defaults: UserDefaults(suiteName: "Caesar.preview") ?? .standard),
        authentication: WorkspaceAuthenticating = AllowAllWorkspaceAuthenticator()
    ) {
        self.state = state
        self.persistence = persistence
        self.preferences = preferences
        self.authenticator = authentication
        let preferredProfile = preferences.nextLaunchProfile
        self.session = AppSession(isAuthenticated: false, profile: preferredProfile)
        self.nextLaunchProfile = preferredProfile
        self.canPersist = true
    }

    public func unlock(reason: String = "Desbloquear o Caesar") async {
        do {
            let allowed = try await authenticator.authenticate(reason: reason)
            guard allowed else {
                session.lastError = "Autenticação recusada."
                return
            }
            session.isAuthenticated = true
            load(profile: session.profile)
        } catch {
            session.lastError = "Não foi possível autenticar agora."
        }
    }

    public func load(profile: WorkspaceProfile? = nil) {
        let selected = profile ?? preferences.nextLaunchProfile
        do {
            state = try persistence.load(profile: selected)
            preferences.nextLaunchProfile = selected
            nextLaunchProfile = selected
            session.profile = selected
            session.lastError = nil
            canPersist = true
        } catch {
            canPersist = false
            session.lastError = "O workspace não pôde ser carregado. Uma cópia inválida foi preservada."
            state = selected == .demo ? AppState.makeDemo() : AppState.makeEmpty()
        }
    }

    public func switchProfile(_ profile: WorkspaceProfile) {
        load(profile: profile)
    }

    public func setNextLaunchProfile(_ profile: WorkspaceProfile) {
        preferences.nextLaunchProfile = profile
        nextLaunchProfile = profile
    }

    public func dispatch(_ action: WorkspaceAction) {
        state = AppReducer.reduce(state, action)
        persistIfPossible()
    }

    public func persistIfPossible() {
        guard canPersist else { return }
        do {
            try persistence.save(state, profile: session.profile)
            session.lastError = nil
        } catch {
            canPersist = false
            session.lastError = "Não consegui salvar o workspace. Nenhum dado será sobrescrito até o problema ser corrigido."
        }
    }
}

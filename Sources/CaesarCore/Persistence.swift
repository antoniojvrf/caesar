import Foundation

public struct PersistedWorkspace: Codable, Equatable {
    public var appName: String
    public var schemaVersion: Int
    public var profile: WorkspaceProfile
    public var savedAt: String
    public var state: AppState

    public init(appName: String = "Caesar", schemaVersion: Int = AppState.schemaVersion, profile: WorkspaceProfile, savedAt: String = AppFormatting.isoDate(Date()), state: AppState) {
        self.appName = appName
        self.schemaVersion = schemaVersion
        self.profile = profile
        self.savedAt = savedAt
        self.state = state
    }
}

public protocol PersistenceManaging {
    func load(profile: WorkspaceProfile) throws -> AppState
    func save(_ state: AppState, profile: WorkspaceProfile) throws
    func workspaceURL(for profile: WorkspaceProfile) -> URL
}

public enum FilePersistenceError: Error, Equatable {
    case unreadable(URL)
}

public final class FilePersistence: PersistenceManaging {
    public let rootDirectory: URL
    public let legacyRootDirectory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        rootDirectory: URL? = nil,
        legacyRootDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.rootDirectory = rootDirectory ?? support.appendingPathComponent("Caesar", isDirectory: true)
        self.legacyRootDirectory = legacyRootDirectory ?? support.appendingPathComponent("MyLifeNative", isDirectory: true)

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder = JSONDecoder()
    }

    public func workspaceURL(for profile: WorkspaceProfile) -> URL {
        rootDirectory.appendingPathComponent(profile.workspaceFilename)
    }

    public func load(profile: WorkspaceProfile) throws -> AppState {
        try ensureRoot()
        let url = workspaceURL(for: profile)
        if FileManager.default.fileExists(atPath: url.path) {
            var loaded = try loadState(from: url, profile: profile)
            if profile == .demo, bootstrapDemoExamplesIfNeeded(&loaded) {
                try save(loaded, profile: profile)
            }
            return loaded
        }

        if profile == .real, let migrated = try migrateLegacyWorkspaceIfAvailable() {
            return migrated
        }

        let fresh = profile == .demo ? AppState.makeDemo() : AppState.makeEmpty()
        try save(fresh, profile: profile)
        return fresh
    }

    public func save(_ state: AppState, profile: WorkspaceProfile) throws {
        try ensureRoot()
        let normalized = AppState.normalized(state)
        let workspace = PersistedWorkspace(profile: profile, state: normalized)
        let data = try encoder.encode(workspace)
        try data.write(to: workspaceURL(for: profile), options: [.atomic])
    }

    private func ensureRoot() throws {
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }

    private func loadState(from url: URL, profile: WorkspaceProfile) throws -> AppState {
        do {
            let data = try Data(contentsOf: url)
            if let wrapped = try? decoder.decode(PersistedWorkspace.self, from: data) {
                return AppState.normalized(wrapped.state)
            }
            return AppState.normalized(try decoder.decode(AppState.self, from: data))
        } catch {
            let backup = url.deletingLastPathComponent()
                .appendingPathComponent("\(url.deletingPathExtension().lastPathComponent)-invalid-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.copyItem(at: url, to: backup)
            throw FilePersistenceError.unreadable(url)
        }
    }

    private func bootstrapDemoExamplesIfNeeded(_ state: inout AppState) -> Bool {
        guard state.processos.isEmpty,
              state.honorarios.isEmpty,
              state.contatos.isEmpty else {
            return false
        }

        let seed = AppState.makeDemo()
        state.contatos = seed.contatos
        state.processos = seed.processos
        state.honorarios = seed.honorarios
        state.updatedAt = AppFormatting.isoDate(Date())
        state.recalculateMonthlyFlow()
        return true
    }

    private func migrateLegacyWorkspaceIfAvailable() throws -> AppState? {
        let legacyURL = legacyRootDirectory.appendingPathComponent(WorkspaceProfile.real.workspaceFilename)
        guard FileManager.default.fileExists(atPath: legacyURL.path) else {
            return nil
        }
        let state = try loadState(from: legacyURL, profile: .real)
        try save(state, profile: .real)
        return state
    }
}

public final class InMemoryPersistence: PersistenceManaging {
    private var storage: [WorkspaceProfile: AppState]

    public init(storage: [WorkspaceProfile: AppState] = [:]) {
        self.storage = storage
    }

    public func load(profile: WorkspaceProfile) throws -> AppState {
        if let state = storage[profile] {
            return state
        }
        let state = profile == .demo ? AppState.makeDemo() : AppState.makeEmpty()
        storage[profile] = state
        return state
    }

    public func save(_ state: AppState, profile: WorkspaceProfile) throws {
        storage[profile] = state
    }

    public func workspaceURL(for profile: WorkspaceProfile) -> URL {
        URL(fileURLWithPath: "/memory/\(profile.workspaceFilename)")
    }
}

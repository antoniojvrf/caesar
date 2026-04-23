import Foundation

public enum DeveloperProjectStatus: String, Codable, CaseIterable, Identifiable {
    case discovery
    case design
    case build
    case review
    case shipped

    public var id: String { rawValue }
}

public enum DeveloperReceivableStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case pending
    case paid
    case overdue

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .draft: "Rascunho"
        case .pending: "Pendente"
        case .paid: "Recebido"
        case .overdue: "Atrasado"
        }
    }
}

public struct DeveloperProject: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var name: String
    public var client: String
    public var status: DeveloperProjectStatus
    public var progress: Int
    public var stack: [String]
    public var nextStep: String
    public var repository: String?
    public var previewURL: String?

    public init(
        id: String = UUID().uuidString,
        name: String,
        client: String,
        status: DeveloperProjectStatus = .discovery,
        progress: Int = 0,
        stack: [String] = [],
        nextStep: String = "",
        repository: String? = nil,
        previewURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.client = client
        self.status = status
        self.progress = progress
        self.stack = stack
        self.nextStep = nextStep
        self.repository = repository
        self.previewURL = previewURL
    }
}

public struct DeveloperUpdate: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var date: String
    public var title: String
    public var body: String
    public var projectId: String?

    public init(id: String = UUID().uuidString, date: String, title: String, body: String, projectId: String? = nil) {
        self.id = id
        self.date = date
        self.title = title
        self.body = body
        self.projectId = projectId
    }
}

public struct DeveloperReceivable: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var projectId: String?
    public var client: String
    public var description: String
    public var dueDate: String
    public var value: Double
    public var status: DeveloperReceivableStatus
    public var installmentLabel: String
    public var notes: String

    public init(
        id: String = UUID().uuidString,
        projectId: String? = nil,
        client: String,
        description: String,
        dueDate: String,
        value: Double,
        status: DeveloperReceivableStatus = .pending,
        installmentLabel: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.projectId = projectId
        self.client = client
        self.description = description
        self.dueDate = dueDate
        self.value = value
        self.status = status
        self.installmentLabel = installmentLabel
        self.notes = notes
    }
}

public struct DeveloperReceivableDraft: Codable, Equatable, Hashable {
    public var projectId: String?
    public var client: String
    public var description: String
    public var dueDate: String
    public var value: Double
    public var status: DeveloperReceivableStatus
    public var installmentLabel: String
    public var notes: String

    public init(
        projectId: String? = nil,
        client: String,
        description: String,
        dueDate: String,
        value: Double,
        status: DeveloperReceivableStatus = .pending,
        installmentLabel: String = "",
        notes: String = ""
    ) {
        self.projectId = projectId
        self.client = client
        self.description = description
        self.dueDate = dueDate
        self.value = value
        self.status = status
        self.installmentLabel = installmentLabel
        self.notes = notes
    }
}

public struct DeveloperIdea: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var body: String
    public var tags: [String]

    public init(id: String = UUID().uuidString, title: String, body: String = "", tags: [String] = []) {
        self.id = id
        self.title = title
        self.body = body
        self.tags = tags
    }
}

public struct DeveloperWorkspace: Codable, Equatable, Hashable {
    public var projects: [DeveloperProject]
    public var updates: [DeveloperUpdate]
    public var receivables: [DeveloperReceivable]
    public var ideas: [DeveloperIdea]
    public var notes: String

    public init(
        projects: [DeveloperProject] = [],
        updates: [DeveloperUpdate] = [],
        receivables: [DeveloperReceivable] = [],
        ideas: [DeveloperIdea] = [],
        notes: String = ""
    ) {
        self.projects = projects
        self.updates = updates
        self.receivables = receivables
        self.ideas = ideas
        self.notes = notes
    }

    public static func previewSeed(referenceDate: Date = Date()) -> DeveloperWorkspace {
        DeveloperWorkspace(
            projects: [
                DeveloperProject(
                    id: "dev-caesar",
                    name: "Caesar",
                    client: "Montalvão & Neves Oliveira",
                    status: .build,
                    progress: 74,
                    stack: ["SwiftUI", "SwiftPM", "Local JSON"],
                    nextStep: "Fechar paridade dos módulos nativos e manter persistência blindada.",
                    repository: "caesar",
                    previewURL: nil
                ),
                DeveloperProject(
                    id: "dev-web-mno",
                    name: "Site institucional MNO",
                    client: "Montalvão & Neves Oliveira",
                    status: .review,
                    progress: 92,
                    stack: ["React", "Vite", "Tailwind"],
                    nextStep: "Revisar copy final e publicar ajustes visuais.",
                    repository: "project-caesar"
                )
            ],
            updates: [
                DeveloperUpdate(date: AppFormatting.isoDate(referenceDate), title: "Reconstrução Swift", body: "Pacote Caesar recomposto com Core, telas nativas e persistência local.", projectId: "dev-caesar"),
                DeveloperUpdate(date: "2026-04-22", title: "Identidade Caesar", body: "Renome completo do antigo MyLifeNative para Caesar, mantendo importação automática do workspace legado.", projectId: "dev-caesar")
            ],
            receivables: [
                DeveloperReceivable(projectId: "dev-web-mno", client: "MNO", description: "Website institucional", dueDate: "2026-05-28", value: 2_000, status: .pending, installmentLabel: "Parcela única"),
                DeveloperReceivable(projectId: "dev-caesar", client: "Uso interno", description: "Sprint nativa Caesar", dueDate: AppFormatting.isoDate(referenceDate), value: 0, status: .draft, installmentLabel: "Controle interno")
            ],
            ideas: [
                DeveloperIdea(title: "Importador jurídico assistido", body: "Entrada humana guiada para PDF/DOCX com revisão antes de gravar.", tags: ["Processos", "IA local"]),
                DeveloperIdea(title: "Painel de caixa por projeto", body: "Cruzar produção, cobranças e histórico de alterações.", tags: ["Caixa", "Developer"])
            ],
            notes: "Área operacional para produção, caixa, sketchbook e novidades."
        )
    }
}

public struct DeveloperFinanceSummary: Codable, Equatable, Hashable {
    public var pending: Double
    public var paid: Double
    public var overdue: Double
    public var draft: Double

    public init(pending: Double, paid: Double, overdue: Double, draft: Double) {
        self.pending = pending
        self.paid = paid
        self.overdue = overdue
        self.draft = draft
    }
}

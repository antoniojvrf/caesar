import Foundation

public struct Attachment: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var name: String
    public var size: String
    public var url: String?

    public init(id: String = UUID().uuidString, name: String, size: String = "", url: String? = nil) {
        self.id = id
        self.name = name
        self.size = size
        self.url = url
    }
}

public struct ChecklistItem: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var text: String
    public var done: Bool

    public init(id: String = UUID().uuidString, text: String, done: Bool = false) {
        self.id = id
        self.text = text
        self.done = done
    }
}

public enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case baixa
    case media = "média"
    case alta

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .baixa: "Baixa"
        case .media: "Média"
        case .alta: "Alta"
        }
    }
}

public struct TaskItem: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var priority: TaskPriority
    public var tag: String
    public var goal: String
    public var categoriaId: String?
    public var dueDate: String
    public var notes: String
    public var checklist: [ChecklistItem]
    public var attachments: [Attachment]
    public var createdAt: String
    public var updatedAt: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        priority: TaskPriority = .media,
        tag: String = "Geral",
        goal: String = "",
        categoriaId: String? = nil,
        dueDate: String = "",
        notes: String = "",
        checklist: [ChecklistItem] = [],
        attachments: [Attachment] = [],
        createdAt: String = AppFormatting.isoDate(Date()),
        updatedAt: String = AppFormatting.isoDate(Date())
    ) {
        self.id = id
        self.title = title
        self.priority = priority
        self.tag = tag
        self.goal = goal
        self.categoriaId = categoriaId
        self.dueDate = dueDate
        self.notes = notes
        self.checklist = checklist
        self.attachments = attachments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct TaskDraft: Codable, Equatable, Hashable {
    public var title: String
    public var priority: TaskPriority
    public var tag: String
    public var goal: String
    public var categoriaId: String?
    public var dueDate: String
    public var notes: String

    public init(
        title: String,
        priority: TaskPriority = .media,
        tag: String = "Geral",
        goal: String = "",
        categoriaId: String? = nil,
        dueDate: String = "",
        notes: String = ""
    ) {
        self.title = title
        self.priority = priority
        self.tag = tag
        self.goal = goal
        self.categoriaId = categoriaId
        self.dueDate = dueDate
        self.notes = notes
    }
}

public struct TaskPatch: Codable, Equatable, Hashable {
    public var title: String?
    public var priority: TaskPriority?
    public var tag: String?
    public var goal: String?
    public var categoriaId: String?
    public var dueDate: String?
    public var notes: String?
    public var checklist: [ChecklistItem]?
    public var attachments: [Attachment]?

    public init(
        title: String? = nil,
        priority: TaskPriority? = nil,
        tag: String? = nil,
        goal: String? = nil,
        categoriaId: String? = nil,
        dueDate: String? = nil,
        notes: String? = nil,
        checklist: [ChecklistItem]? = nil,
        attachments: [Attachment]? = nil
    ) {
        self.title = title
        self.priority = priority
        self.tag = tag
        self.goal = goal
        self.categoriaId = categoriaId
        self.dueDate = dueDate
        self.notes = notes
        self.checklist = checklist
        self.attachments = attachments
    }
}

public struct TaskColumn: Codable, Equatable, Hashable {
    public var name: String
    public var tasks: [TaskItem]

    public init(name: String, tasks: [TaskItem] = []) {
        self.name = name
        self.tasks = tasks
    }
}

public struct GoalMilestone: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var label: String
    public var done: Bool

    public init(id: String = UUID().uuidString, label: String, done: Bool = false) {
        self.id = id
        self.label = label
        self.done = done
    }
}

public enum GoalType: String, Codable, CaseIterable, Identifiable {
    case financeira
    case pessoal
    case profissional
    case juridica = "jurídica"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .financeira: "Financeira"
        case .pessoal: "Pessoal"
        case .profissional: "Profissional"
        case .juridica: "Jurídica"
        }
    }
}

public struct GoalItem: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var type: GoalType
    public var progress: Int
    public var current: Double?
    public var target: Double?
    public var deadline: String
    public var milestones: [GoalMilestone]
    public var associatedIncomeIDs: [String]
    public var associatedHonorarioIDs: [String]
    public var notes: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        type: GoalType = .pessoal,
        progress: Int = 0,
        current: Double? = nil,
        target: Double? = nil,
        deadline: String = "",
        milestones: [GoalMilestone] = [],
        associatedIncomeIDs: [String] = [],
        associatedHonorarioIDs: [String] = [],
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.progress = progress
        self.current = current
        self.target = target
        self.deadline = deadline
        self.milestones = milestones
        self.associatedIncomeIDs = associatedIncomeIDs
        self.associatedHonorarioIDs = associatedHonorarioIDs
        self.notes = notes
    }
}

public struct GoalDraft: Codable, Equatable, Hashable {
    public var title: String
    public var type: GoalType
    public var current: Double?
    public var target: Double?
    public var deadline: String
    public var milestones: [GoalMilestone]

    public init(
        title: String,
        type: GoalType = .pessoal,
        current: Double? = nil,
        target: Double? = nil,
        deadline: String = "",
        milestones: [GoalMilestone] = []
    ) {
        self.title = title
        self.type = type
        self.current = current
        self.target = target
        self.deadline = deadline
        self.milestones = milestones
    }
}

public struct GoalPatch: Codable, Equatable, Hashable {
    public var title: String?
    public var type: GoalType?
    public var current: Double?
    public var target: Double?
    public var deadline: String?
    public var milestones: [GoalMilestone]?
    public var associatedIncomeIDs: [String]?
    public var associatedHonorarioIDs: [String]?
    public var notes: String?

    public init(
        title: String? = nil,
        type: GoalType? = nil,
        current: Double? = nil,
        target: Double? = nil,
        deadline: String? = nil,
        milestones: [GoalMilestone]? = nil,
        associatedIncomeIDs: [String]? = nil,
        associatedHonorarioIDs: [String]? = nil,
        notes: String? = nil
    ) {
        self.title = title
        self.type = type
        self.current = current
        self.target = target
        self.deadline = deadline
        self.milestones = milestones
        self.associatedIncomeIDs = associatedIncomeIDs
        self.associatedHonorarioIDs = associatedHonorarioIDs
        self.notes = notes
    }
}

public struct CategoryItem: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var name: String
    public var color: String
    public var recurring: Bool

    public init(id: String = UUID().uuidString, name: String, color: String = "#525252", recurring: Bool = false) {
        self.id = id
        self.name = name
        self.color = color
        self.recurring = recurring
    }
}

public struct CategoryDraft: Codable, Equatable, Hashable {
    public var name: String
    public var color: String
    public var recurring: Bool

    public init(name: String, color: String = "#525252", recurring: Bool = false) {
        self.name = name
        self.color = color
        self.recurring = recurring
    }
}

public enum BoletoStatus: String, Codable, CaseIterable, Identifiable {
    case pendente
    case pago
    case recorrente
    case vencido

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .pendente: "Pendente"
        case .pago: "Pago"
        case .recorrente: "Recorrente"
        case .vencido: "Vencido"
        }
    }
}

public enum FinanceRecurrence: String, Codable, CaseIterable, Identifiable {
    case fixa
    case variavel = "variável"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .fixa: "Fixa"
        case .variavel: "Variável"
        }
    }
}

public enum IncomeStatus: String, Codable, CaseIterable, Identifiable {
    case pendente
    case recebido

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .pendente: "Pendente"
        case .recebido: "Recebido"
        }
    }
}

public struct FinanceMonthlyAdjustment: Codable, Equatable, Identifiable, Hashable {
    public var id: String { month }
    public var month: String
    public var value: Double

    public init(month: String, value: Double) {
        self.month = month
        self.value = value
    }
}

public struct BoletoItem: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var categoriaId: String
    public var desc: String
    public var dueDate: String
    public var value: Double
    public var status: BoletoStatus
    public var recurrence: FinanceRecurrence
    public var paidAt: String?
    public var monthlyAdjustments: [FinanceMonthlyAdjustment]
    public var barcode: String?
    public var notes: String

    public init(
        id: String = UUID().uuidString,
        categoriaId: String,
        desc: String,
        dueDate: String,
        value: Double,
        status: BoletoStatus = .pendente,
        recurrence: FinanceRecurrence = .variavel,
        paidAt: String? = nil,
        monthlyAdjustments: [FinanceMonthlyAdjustment] = [],
        barcode: String? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.categoriaId = categoriaId
        self.desc = desc
        self.dueDate = dueDate
        self.value = value
        self.status = status
        self.recurrence = recurrence
        self.paidAt = paidAt
        self.monthlyAdjustments = monthlyAdjustments
        self.barcode = barcode
        self.notes = notes
    }

    public func effectiveStatus(referenceDate: Date = Date()) -> BoletoStatus {
        guard status == .pendente, let due = AppFormatting.date(fromISO: dueDate) else {
            return status
        }
        return due < Calendar.current.startOfDay(for: referenceDate) ? .vencido : status
    }

    public func value(forMonth month: String) -> Double {
        monthlyAdjustments.first { $0.month == month }?.value ?? value
    }
}

public struct BoletoDraft: Codable, Equatable, Hashable {
    public var categoriaId: String
    public var desc: String
    public var dueDate: String
    public var value: Double
    public var status: BoletoStatus
    public var recurrence: FinanceRecurrence
    public var monthlyAdjustments: [FinanceMonthlyAdjustment]
    public var barcode: String?
    public var notes: String

    public init(
        categoriaId: String,
        desc: String,
        dueDate: String,
        value: Double,
        status: BoletoStatus = .pendente,
        recurrence: FinanceRecurrence = .variavel,
        monthlyAdjustments: [FinanceMonthlyAdjustment] = [],
        barcode: String? = nil,
        notes: String = ""
    ) {
        self.categoriaId = categoriaId
        self.desc = desc
        self.dueDate = dueDate
        self.value = value
        self.status = status
        self.recurrence = recurrence
        self.monthlyAdjustments = monthlyAdjustments
        self.barcode = barcode
        self.notes = notes
    }
}

public enum IncomeType: String, Codable, CaseIterable, Identifiable {
    case fixa
    case variavel = "variável"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .fixa: "Fixa"
        case .variavel: "Variável"
        }
    }
}

public struct IncomeItem: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var desc: String
    public var type: IncomeType
    public var value: Double
    public var startDate: String?
    public var durationMonths: Int?
    public var status: IncomeStatus
    public var receivedAt: String?
    public var monthlyAdjustments: [FinanceMonthlyAdjustment]
    public var notes: String

    public init(
        id: String = UUID().uuidString,
        desc: String,
        type: IncomeType,
        value: Double,
        startDate: String? = nil,
        durationMonths: Int? = nil,
        status: IncomeStatus = .pendente,
        receivedAt: String? = nil,
        monthlyAdjustments: [FinanceMonthlyAdjustment] = [],
        notes: String = ""
    ) {
        self.id = id
        self.desc = desc
        self.type = type
        self.value = value
        self.startDate = startDate
        self.durationMonths = durationMonths
        self.status = status
        self.receivedAt = receivedAt
        self.monthlyAdjustments = monthlyAdjustments
        self.notes = notes
    }

    public func value(forMonth month: String) -> Double {
        monthlyAdjustments.first { $0.month == month }?.value ?? value
    }
}

public struct IncomeDraft: Codable, Equatable, Hashable {
    public var desc: String
    public var type: IncomeType
    public var value: Double
    public var startDate: String?
    public var durationMonths: Int?
    public var monthlyAdjustments: [FinanceMonthlyAdjustment]
    public var notes: String

    public init(desc: String, type: IncomeType, value: Double, startDate: String? = nil, durationMonths: Int? = nil, monthlyAdjustments: [FinanceMonthlyAdjustment] = [], notes: String = "") {
        self.desc = desc
        self.type = type
        self.value = value
        self.startDate = startDate
        self.durationMonths = durationMonths
        self.monthlyAdjustments = monthlyAdjustments
        self.notes = notes
    }
}

public struct MonthlyFlowItem: Codable, Equatable, Identifiable, Hashable {
    public var id: String { month }
    public var month: String
    public var label: String
    public var `in`: Double
    public var out: Double

    public init(month: String, label: String, in incoming: Double = 0, out: Double = 0) {
        self.month = month
        self.label = label
        self.in = incoming
        self.out = out
    }
}

public enum ContactEntityType: String, Codable, CaseIterable, Identifiable {
    case pessoaFisica
    case pessoaJuridica
    case escritorio
    case orgaoJudicial
    case outro

    public var id: String { rawValue }
}

public enum ContactRole: String, Codable, CaseIterable, Identifiable {
    case cliente
    case parteContraria
    case advogado
    case testemunha
    case juizo
    case outro

    public var id: String { rawValue }
}

public struct ContatoItem: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var name: String
    public var entityType: ContactEntityType
    public var role: ContactRole
    public var document: String
    public var email: String
    public var phone: String
    public var address: String
    public var notes: String

    public init(
        id: String = UUID().uuidString,
        name: String,
        entityType: ContactEntityType = .pessoaFisica,
        role: ContactRole = .cliente,
        document: String = "",
        email: String = "",
        phone: String = "",
        address: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.entityType = entityType
        self.role = role
        self.document = document
        self.email = email
        self.phone = phone
        self.address = address
        self.notes = notes
    }
}

public struct ContatoDraft: Codable, Equatable, Hashable {
    public var name: String
    public var entityType: ContactEntityType
    public var role: ContactRole
    public var document: String
    public var email: String
    public var phone: String
    public var address: String
    public var notes: String

    public init(
        name: String,
        entityType: ContactEntityType = .pessoaFisica,
        role: ContactRole = .cliente,
        document: String = "",
        email: String = "",
        phone: String = "",
        address: String = "",
        notes: String = ""
    ) {
        self.name = name
        self.entityType = entityType
        self.role = role
        self.document = document
        self.email = email
        self.phone = phone
        self.address = address
        self.notes = notes
    }
}

public enum ProcessoTipo: String, Codable, CaseIterable, Identifiable {
    case judicial
    case extrajudicial
    case consultivo

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .judicial: "Judicial"
        case .extrajudicial: "Extrajudicial"
        case .consultivo: "Consultivo"
        }
    }
}

public enum ProcessoStatus: String, Codable, CaseIterable, Identifiable {
    case ativo
    case suspenso
    case encerrado
    case acordo

    public var id: String { rawValue }
}

public enum ProcessoPrioridade: String, Codable, CaseIterable, Identifiable {
    case baixa
    case media = "média"
    case alta
    case critica = "crítica"

    public var id: String { rawValue }
}

public enum ProcessoAtoTipo: String, Codable, CaseIterable, Identifiable {
    case prazo
    case audiencia = "audiência"
    case peticao = "petição"
    case acordo
    case pagamento
    case observacao = "observação"

    public var id: String { rawValue }
}

public enum SuccessProbability: String, Codable, CaseIterable, Identifiable {
    case baixa
    case media = "média"
    case alta

    public var id: String { rawValue }

    public var weight: Double {
        switch self {
        case .baixa: 0.25
        case .media: 0.50
        case .alta: 0.75
        }
    }
}

public enum ExitoBaseCalculo: String, Codable, CaseIterable, Identifiable {
    case valorCausa = "valor_causa"
    case valorCondenacao = "valor_condenacao"
    case proveitoEconomico = "proveito_economico"
    case valorAcordo = "valor_acordo"
    case personalizada = "personalizada"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .valorCausa: "Valor da causa"
        case .valorCondenacao: "Valor da condenação"
        case .proveitoEconomico: "Proveito econômico"
        case .valorAcordo: "Valor do acordo"
        case .personalizada: "Base personalizada"
        }
    }
}

public struct ExitoPrazo: Codable, Equatable, Hashable {
    public var year: Int
    public var month: Int
    public var day: Int?

    public init(year: Int, month: Int, day: Int? = nil) {
        self.year = year
        self.month = month
        self.day = day
    }

    public var label: String {
        if let day {
            return String(format: "%02d/%02d/%04d", day, month, year)
        }
        let symbols = Calendar.current.shortMonthSymbols
        let monthName = symbols.indices.contains(month - 1) ? symbols[month - 1] : "\(month)"
        return "\(monthName.capitalized)/\(year)"
    }
}

public struct ProcessoPrazo: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var date: String
    public var type: ProcessoAtoTipo
    public var done: Bool
    public var notes: String

    public init(id: String = UUID().uuidString, title: String, date: String, type: ProcessoAtoTipo = .prazo, done: Bool = false, notes: String = "") {
        self.id = id
        self.title = title
        self.date = date
        self.type = type
        self.done = done
        self.notes = notes
    }
}

public struct ProcessoAndamento: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var date: String
    public var time: String
    public var title: String
    public var summary: String
    public var type: ProcessoAtoTipo

    public init(id: String = UUID().uuidString, date: String, time: String = "", title: String, summary: String, type: ProcessoAtoTipo = .observacao) {
        self.id = id
        self.date = date
        self.time = time
        self.title = title
        self.summary = summary
        self.type = type
    }
}

public struct ProcessoContatoVinculo: Codable, Equatable, Identifiable, Hashable {
    public var id: String { contatoId }
    public var contatoId: String
    public var role: ContactRole

    public init(contatoId: String, role: ContactRole) {
        self.contatoId = contatoId
        self.role = role
    }
}

public enum ProcessoRepresentacaoPolo: String, Codable, CaseIterable, Identifiable {
    case autor
    case reu = "réu"
    case terceiro

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .autor: "Autor"
        case .reu: "Réu"
        case .terceiro: "Terceiro interessado"
        }
    }
}

public struct ProcessoItem: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var numero: String
    public var tituloAcao: String
    public var cliente: String
    public var autores: [String]
    public var parteContraria: String
    public var reus: [String]
    public var parteRepresentada: String
    public var poloRepresentado: ProcessoRepresentacaoPolo
    public var tipoCaso: ProcessoTipo
    public var area: String
    public var fase: String
    public var status: ProcessoStatus
    public var prioridade: ProcessoPrioridade
    public var orgaoJulgador: String
    public var comarca: String
    public var vara: String
    public var tribunal: String
    public var dataDistribuicao: String
    public var proxAto: String
    public var proxAtoDesc: String
    public var valorCausa: Double
    public var exitoPercentual: Double
    public var exitoChancePercentual: Double
    public var exitoProbabilidade: SuccessProbability
    public var exitoPrazo: String
    public var exitoBaseCalculo: ExitoBaseCalculo
    public var exitoValorCondenacaoEstimado: Double
    public var exitoProveitoEconomicoEstimado: Double
    public var exitoValorAcordoEstimado: Double
    public var exitoBasePersonalizadaRotulo: String
    public var exitoBasePersonalizadaValor: Double
    public var resumo: String
    public var resumoInicial: String
    public var tesePrincipal: String
    public var pedidos: [String]
    public var riscos: String
    public var estrategia: String
    public var resultadoEsperado: String
    public var observacoes: String
    public var contatos: [ProcessoContatoVinculo]
    public var prazos: [ProcessoPrazo]
    public var andamentos: [ProcessoAndamento]
    public var createdAt: String
    public var updatedAt: String

    public init(
        id: String = UUID().uuidString,
        numero: String,
        tituloAcao: String = "",
        cliente: String,
        autores: [String] = [],
        parteContraria: String = "",
        reus: [String] = [],
        parteRepresentada: String = "",
        poloRepresentado: ProcessoRepresentacaoPolo = .autor,
        tipoCaso: ProcessoTipo = .judicial,
        area: String,
        fase: String,
        status: ProcessoStatus = .ativo,
        prioridade: ProcessoPrioridade = .media,
        orgaoJulgador: String = "",
        comarca: String = "",
        vara: String = "",
        tribunal: String = "",
        dataDistribuicao: String = "",
        proxAto: String = "",
        proxAtoDesc: String = "",
        valorCausa: Double = 0,
        exitoPercentual: Double = 0,
        exitoChancePercentual: Double = 50,
        exitoProbabilidade: SuccessProbability = .media,
        exitoPrazo: String = "",
        exitoBaseCalculo: ExitoBaseCalculo = .valorCausa,
        exitoValorCondenacaoEstimado: Double = 0,
        exitoProveitoEconomicoEstimado: Double = 0,
        exitoValorAcordoEstimado: Double = 0,
        exitoBasePersonalizadaRotulo: String = "",
        exitoBasePersonalizadaValor: Double = 0,
        resumo: String = "",
        resumoInicial: String = "",
        tesePrincipal: String = "",
        pedidos: [String] = [],
        riscos: String = "",
        estrategia: String = "",
        resultadoEsperado: String = "",
        observacoes: String = "",
        contatos: [ProcessoContatoVinculo] = [],
        prazos: [ProcessoPrazo] = [],
        andamentos: [ProcessoAndamento] = [],
        createdAt: String = AppFormatting.isoDate(Date()),
        updatedAt: String = AppFormatting.isoDate(Date())
    ) {
        self.id = id
        self.numero = numero
        self.tituloAcao = tituloAcao
        self.cliente = cliente
        self.autores = autores
        self.parteContraria = parteContraria
        self.reus = reus
        self.parteRepresentada = parteRepresentada
        self.poloRepresentado = poloRepresentado
        self.tipoCaso = tipoCaso
        self.area = area
        self.fase = fase
        self.status = status
        self.prioridade = prioridade
        self.orgaoJulgador = orgaoJulgador
        self.comarca = comarca
        self.vara = vara
        self.tribunal = tribunal
        self.dataDistribuicao = dataDistribuicao
        self.proxAto = proxAto
        self.proxAtoDesc = proxAtoDesc
        self.valorCausa = valorCausa
        self.exitoPercentual = exitoPercentual
        self.exitoChancePercentual = exitoChancePercentual
        self.exitoProbabilidade = exitoProbabilidade
        self.exitoPrazo = exitoPrazo
        self.exitoBaseCalculo = exitoBaseCalculo
        self.exitoValorCondenacaoEstimado = exitoValorCondenacaoEstimado
        self.exitoProveitoEconomicoEstimado = exitoProveitoEconomicoEstimado
        self.exitoValorAcordoEstimado = exitoValorAcordoEstimado
        self.exitoBasePersonalizadaRotulo = exitoBasePersonalizadaRotulo
        self.exitoBasePersonalizadaValor = exitoBasePersonalizadaValor
        self.resumo = resumo
        self.resumoInicial = resumoInicial
        self.tesePrincipal = tesePrincipal
        self.pedidos = pedidos
        self.riscos = riscos
        self.estrategia = estrategia
        self.resultadoEsperado = resultadoEsperado
        self.observacoes = observacoes
        self.contatos = contatos
        self.prazos = prazos
        self.andamentos = andamentos
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct ProcessoDraft: Codable, Equatable, Hashable {
    public var numero: String
    public var tituloAcao: String
    public var cliente: String
    public var autores: [String]
    public var parteContraria: String
    public var reus: [String]
    public var parteRepresentada: String
    public var poloRepresentado: ProcessoRepresentacaoPolo
    public var tipoCaso: ProcessoTipo
    public var area: String
    public var fase: String
    public var status: ProcessoStatus
    public var prioridade: ProcessoPrioridade
    public var orgaoJulgador: String
    public var comarca: String
    public var vara: String
    public var tribunal: String
    public var dataDistribuicao: String
    public var proxAto: String
    public var proxAtoDesc: String
    public var valorCausa: Double
    public var exitoPercentual: Double
    public var exitoChancePercentual: Double
    public var exitoProbabilidade: SuccessProbability
    public var exitoPrazo: String
    public var exitoBaseCalculo: ExitoBaseCalculo
    public var exitoValorCondenacaoEstimado: Double
    public var exitoProveitoEconomicoEstimado: Double
    public var exitoValorAcordoEstimado: Double
    public var exitoBasePersonalizadaRotulo: String
    public var exitoBasePersonalizadaValor: Double
    public var resumo: String
    public var resumoInicial: String
    public var tesePrincipal: String
    public var pedidos: [String]
    public var riscos: String
    public var estrategia: String
    public var resultadoEsperado: String
    public var observacoes: String

    public init(
        numero: String,
        tituloAcao: String = "",
        cliente: String,
        autores: [String] = [],
        parteContraria: String = "",
        reus: [String] = [],
        parteRepresentada: String = "",
        poloRepresentado: ProcessoRepresentacaoPolo = .autor,
        tipoCaso: ProcessoTipo = .judicial,
        area: String,
        fase: String,
        status: ProcessoStatus = .ativo,
        prioridade: ProcessoPrioridade = .media,
        orgaoJulgador: String = "",
        comarca: String = "",
        vara: String = "",
        tribunal: String = "",
        dataDistribuicao: String = "",
        proxAto: String = "",
        proxAtoDesc: String = "",
        valorCausa: Double = 0,
        exitoPercentual: Double = 0,
        exitoChancePercentual: Double = 50,
        exitoProbabilidade: SuccessProbability = .media,
        exitoPrazo: String = "",
        exitoBaseCalculo: ExitoBaseCalculo = .valorCausa,
        exitoValorCondenacaoEstimado: Double = 0,
        exitoProveitoEconomicoEstimado: Double = 0,
        exitoValorAcordoEstimado: Double = 0,
        exitoBasePersonalizadaRotulo: String = "",
        exitoBasePersonalizadaValor: Double = 0,
        resumo: String = "",
        resumoInicial: String = "",
        tesePrincipal: String = "",
        pedidos: [String] = [],
        riscos: String = "",
        estrategia: String = "",
        resultadoEsperado: String = "",
        observacoes: String = ""
    ) {
        self.numero = numero
        self.tituloAcao = tituloAcao
        self.cliente = cliente
        self.autores = autores
        self.parteContraria = parteContraria
        self.reus = reus
        self.parteRepresentada = parteRepresentada
        self.poloRepresentado = poloRepresentado
        self.tipoCaso = tipoCaso
        self.area = area
        self.fase = fase
        self.status = status
        self.prioridade = prioridade
        self.orgaoJulgador = orgaoJulgador
        self.comarca = comarca
        self.vara = vara
        self.tribunal = tribunal
        self.dataDistribuicao = dataDistribuicao
        self.proxAto = proxAto
        self.proxAtoDesc = proxAtoDesc
        self.valorCausa = valorCausa
        self.exitoPercentual = exitoPercentual
        self.exitoChancePercentual = exitoChancePercentual
        self.exitoProbabilidade = exitoProbabilidade
        self.exitoPrazo = exitoPrazo
        self.exitoBaseCalculo = exitoBaseCalculo
        self.exitoValorCondenacaoEstimado = exitoValorCondenacaoEstimado
        self.exitoProveitoEconomicoEstimado = exitoProveitoEconomicoEstimado
        self.exitoValorAcordoEstimado = exitoValorAcordoEstimado
        self.exitoBasePersonalizadaRotulo = exitoBasePersonalizadaRotulo
        self.exitoBasePersonalizadaValor = exitoBasePersonalizadaValor
        self.resumo = resumo
        self.resumoInicial = resumoInicial
        self.tesePrincipal = tesePrincipal
        self.pedidos = pedidos
        self.riscos = riscos
        self.estrategia = estrategia
        self.resultadoEsperado = resultadoEsperado
        self.observacoes = observacoes
    }
}

public struct ProcessoPatch: Codable, Equatable, Hashable {
    public var numero: String?
    public var tituloAcao: String?
    public var cliente: String?
    public var autores: [String]?
    public var parteContraria: String?
    public var reus: [String]?
    public var parteRepresentada: String?
    public var poloRepresentado: ProcessoRepresentacaoPolo?
    public var tipoCaso: ProcessoTipo?
    public var area: String?
    public var fase: String?
    public var status: ProcessoStatus?
    public var prioridade: ProcessoPrioridade?
    public var orgaoJulgador: String?
    public var comarca: String?
    public var vara: String?
    public var tribunal: String?
    public var dataDistribuicao: String?
    public var proxAto: String?
    public var proxAtoDesc: String?
    public var valorCausa: Double?
    public var exitoPercentual: Double?
    public var exitoChancePercentual: Double?
    public var exitoProbabilidade: SuccessProbability?
    public var exitoPrazo: String?
    public var exitoBaseCalculo: ExitoBaseCalculo?
    public var exitoValorCondenacaoEstimado: Double?
    public var exitoProveitoEconomicoEstimado: Double?
    public var exitoValorAcordoEstimado: Double?
    public var exitoBasePersonalizadaRotulo: String?
    public var exitoBasePersonalizadaValor: Double?
    public var resumo: String?
    public var resumoInicial: String?
    public var tesePrincipal: String?
    public var pedidos: [String]?
    public var riscos: String?
    public var estrategia: String?
    public var resultadoEsperado: String?
    public var observacoes: String?

    public init(
        numero: String? = nil,
        tituloAcao: String? = nil,
        cliente: String? = nil,
        autores: [String]? = nil,
        parteContraria: String? = nil,
        reus: [String]? = nil,
        parteRepresentada: String? = nil,
        poloRepresentado: ProcessoRepresentacaoPolo? = nil,
        tipoCaso: ProcessoTipo? = nil,
        area: String? = nil,
        fase: String? = nil,
        status: ProcessoStatus? = nil,
        prioridade: ProcessoPrioridade? = nil,
        orgaoJulgador: String? = nil,
        comarca: String? = nil,
        vara: String? = nil,
        tribunal: String? = nil,
        dataDistribuicao: String? = nil,
        proxAto: String? = nil,
        proxAtoDesc: String? = nil,
        valorCausa: Double? = nil,
        exitoPercentual: Double? = nil,
        exitoChancePercentual: Double? = nil,
        exitoProbabilidade: SuccessProbability? = nil,
        exitoPrazo: String? = nil,
        exitoBaseCalculo: ExitoBaseCalculo? = nil,
        exitoValorCondenacaoEstimado: Double? = nil,
        exitoProveitoEconomicoEstimado: Double? = nil,
        exitoValorAcordoEstimado: Double? = nil,
        exitoBasePersonalizadaRotulo: String? = nil,
        exitoBasePersonalizadaValor: Double? = nil,
        resumo: String? = nil,
        resumoInicial: String? = nil,
        tesePrincipal: String? = nil,
        pedidos: [String]? = nil,
        riscos: String? = nil,
        estrategia: String? = nil,
        resultadoEsperado: String? = nil,
        observacoes: String? = nil
    ) {
        self.numero = numero
        self.tituloAcao = tituloAcao
        self.cliente = cliente
        self.autores = autores
        self.parteContraria = parteContraria
        self.reus = reus
        self.parteRepresentada = parteRepresentada
        self.poloRepresentado = poloRepresentado
        self.tipoCaso = tipoCaso
        self.area = area
        self.fase = fase
        self.status = status
        self.prioridade = prioridade
        self.orgaoJulgador = orgaoJulgador
        self.comarca = comarca
        self.vara = vara
        self.tribunal = tribunal
        self.dataDistribuicao = dataDistribuicao
        self.proxAto = proxAto
        self.proxAtoDesc = proxAtoDesc
        self.valorCausa = valorCausa
        self.exitoPercentual = exitoPercentual
        self.exitoChancePercentual = exitoChancePercentual
        self.exitoProbabilidade = exitoProbabilidade
        self.exitoPrazo = exitoPrazo
        self.exitoBaseCalculo = exitoBaseCalculo
        self.exitoValorCondenacaoEstimado = exitoValorCondenacaoEstimado
        self.exitoProveitoEconomicoEstimado = exitoProveitoEconomicoEstimado
        self.exitoValorAcordoEstimado = exitoValorAcordoEstimado
        self.exitoBasePersonalizadaRotulo = exitoBasePersonalizadaRotulo
        self.exitoBasePersonalizadaValor = exitoBasePersonalizadaValor
        self.resumo = resumo
        self.resumoInicial = resumoInicial
        self.tesePrincipal = tesePrincipal
        self.pedidos = pedidos
        self.riscos = riscos
        self.estrategia = estrategia
        self.resultadoEsperado = resultadoEsperado
        self.observacoes = observacoes
    }
}

public extension ProcessoItem {
    var exitoBaseValor: Double {
        switch exitoBaseCalculo {
        case .valorCausa:
            return valorCausa
        case .valorCondenacao:
            return exitoValorCondenacaoEstimado
        case .proveitoEconomico:
            return exitoProveitoEconomicoEstimado
        case .valorAcordo:
            return exitoValorAcordoEstimado
        case .personalizada:
            return exitoBasePersonalizadaValor
        }
    }

    var exitoBaseLabel: String {
        switch exitoBaseCalculo {
        case .personalizada:
            let label = exitoBasePersonalizadaRotulo.trimmingCharacters(in: .whitespacesAndNewlines)
            return label.isEmpty ? exitoBaseCalculo.label : label
        default:
            return exitoBaseCalculo.label
        }
    }

    var exitoValorHonorariosEstimado: Double {
        exitoBaseValor * exitoPercentual / 100
    }

    var exitoValorPonderado: Double {
        exitoValorHonorariosEstimado * exitoChancePercentual / 100
    }
}

public enum HonorarioStatus: String, Codable, CaseIterable, Identifiable {
    case pendente
    case pago
    case atrasado
    case renegociado

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .pendente: "Pendente"
        case .pago: "Pago"
        case .atrasado: "Atrasado"
        case .renegociado: "Renegociado"
        }
    }
}

public enum HonorarioLaunchType: String, Codable, CaseIterable, Identifiable {
    case parcelaUnica = "parcela_unica"
    case avulso
    case parcelado

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .parcelaUnica: "Parcela única"
        case .avulso: "Pagamento avulso"
        case .parcelado: "Parcelamento"
        }
    }
}

public enum HonorarioReceiptMethod: String, Codable, CaseIterable, Identifiable {
    case pix
    case tedDoc = "ted_doc"
    case cedula
    case cartaoCredito = "cartao_credito"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .pix: "Pix"
        case .tedDoc: "TED/DOC"
        case .cedula: "Cédula"
        case .cartaoCredito: "Cartão de crédito"
        }
    }
}

public struct HonorarioItem: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var processoId: String
    public var cliente: String
    public var processo: String
    public var tipo: String
    public var venc: String
    public var valor: Double
    public var launchType: HonorarioLaunchType
    public var parcelaIndice: Int?
    public var parcelaTotal: Int?
    public var status: HonorarioStatus
    public var dataRecebimento: String?
    public var recebimentoMetodo: HonorarioReceiptMethod?
    public var recebimentoObservacao: String
    public var notes: String

    public init(
        id: String = UUID().uuidString,
        processoId: String,
        cliente: String,
        processo: String,
        tipo: String,
        venc: String,
        valor: Double,
        launchType: HonorarioLaunchType = .parcelaUnica,
        parcelaIndice: Int? = nil,
        parcelaTotal: Int? = nil,
        status: HonorarioStatus = .pendente,
        dataRecebimento: String? = nil,
        recebimentoMetodo: HonorarioReceiptMethod? = nil,
        recebimentoObservacao: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.processoId = processoId
        self.cliente = cliente
        self.processo = processo
        self.tipo = tipo
        self.venc = venc
        self.valor = valor
        self.launchType = launchType
        self.parcelaIndice = parcelaIndice
        self.parcelaTotal = parcelaTotal
        self.status = status
        self.dataRecebimento = dataRecebimento
        self.recebimentoMetodo = recebimentoMetodo
        self.recebimentoObservacao = recebimentoObservacao
        self.notes = notes
    }

    public func effectiveStatus(referenceDate: Date = Date()) -> HonorarioStatus {
        guard status != .pago else { return .pago }
        guard status != .renegociado else { return .renegociado }
        guard let dueDate = AppFormatting.date(fromISO: venc) else { return status }
        return dueDate < Calendar.current.startOfDay(for: referenceDate) ? .atrasado : .pendente
    }
}

public struct HonorarioDraft: Codable, Equatable, Hashable {
    public var processoId: String
    public var cliente: String
    public var processo: String
    public var tipo: String
    public var venc: String
    public var valor: Double
    public var launchType: HonorarioLaunchType
    public var parcelaIndice: Int?
    public var parcelaTotal: Int?
    public var status: HonorarioStatus
    public var dataRecebimento: String?
    public var recebimentoMetodo: HonorarioReceiptMethod?
    public var recebimentoObservacao: String
    public var notes: String

    public init(
        processoId: String,
        cliente: String,
        processo: String,
        tipo: String,
        venc: String,
        valor: Double,
        launchType: HonorarioLaunchType = .parcelaUnica,
        parcelaIndice: Int? = nil,
        parcelaTotal: Int? = nil,
        status: HonorarioStatus = .pendente,
        dataRecebimento: String? = nil,
        recebimentoMetodo: HonorarioReceiptMethod? = nil,
        recebimentoObservacao: String = "",
        notes: String = ""
    ) {
        self.processoId = processoId
        self.cliente = cliente
        self.processo = processo
        self.tipo = tipo
        self.venc = venc
        self.valor = valor
        self.launchType = launchType
        self.parcelaIndice = parcelaIndice
        self.parcelaTotal = parcelaTotal
        self.status = status
        self.dataRecebimento = dataRecebimento
        self.recebimentoMetodo = recebimentoMetodo
        self.recebimentoObservacao = recebimentoObservacao
        self.notes = notes
    }
}

public struct HonorarioPatch: Codable, Equatable, Hashable {
    public var processoId: String?
    public var cliente: String?
    public var processo: String?
    public var tipo: String?
    public var venc: String?
    public var valor: Double?
    public var launchType: HonorarioLaunchType?
    public var parcelaIndice: Int?
    public var parcelaTotal: Int?
    public var status: HonorarioStatus?
    public var dataRecebimento: String?
    public var recebimentoMetodo: HonorarioReceiptMethod?
    public var recebimentoObservacao: String?
    public var notes: String?

    public init(
        processoId: String? = nil,
        cliente: String? = nil,
        processo: String? = nil,
        tipo: String? = nil,
        venc: String? = nil,
        valor: Double? = nil,
        launchType: HonorarioLaunchType? = nil,
        parcelaIndice: Int? = nil,
        parcelaTotal: Int? = nil,
        status: HonorarioStatus? = nil,
        dataRecebimento: String? = nil,
        recebimentoMetodo: HonorarioReceiptMethod? = nil,
        recebimentoObservacao: String? = nil,
        notes: String? = nil
    ) {
        self.processoId = processoId
        self.cliente = cliente
        self.processo = processo
        self.tipo = tipo
        self.venc = venc
        self.valor = valor
        self.launchType = launchType
        self.parcelaIndice = parcelaIndice
        self.parcelaTotal = parcelaTotal
        self.status = status
        self.dataRecebimento = dataRecebimento
        self.recebimentoMetodo = recebimentoMetodo
        self.recebimentoObservacao = recebimentoObservacao
        self.notes = notes
    }
}

import Foundation

public struct AppState: Codable, Equatable {
    public static let schemaVersion = 5
    public static let taskColumnOrder = ["hoje", "semana", "proximas"]

    public var schemaVersion: Int
    public var tarefas: [String: TaskColumn]
    public var metas: [GoalItem]
    public var categorias: [CategoryItem]
    public var boletos: [BoletoItem]
    public var incomes: [IncomeItem]
    public var monthlyFlow: [MonthlyFlowItem]
    public var contatos: [ContatoItem]
    public var processos: [ProcessoItem]
    public var honorarios: [HonorarioItem]
    public var developer: DeveloperWorkspace
    public var updatedAt: String

    public init(
        schemaVersion: Int = AppState.schemaVersion,
        tarefas: [String: TaskColumn],
        metas: [GoalItem] = [],
        categorias: [CategoryItem] = [],
        boletos: [BoletoItem] = [],
        incomes: [IncomeItem] = [],
        monthlyFlow: [MonthlyFlowItem] = [],
        contatos: [ContatoItem] = [],
        processos: [ProcessoItem] = [],
        honorarios: [HonorarioItem] = [],
        developer: DeveloperWorkspace = DeveloperWorkspace(),
        updatedAt: String = AppFormatting.isoDate(Date())
    ) {
        self.schemaVersion = schemaVersion
        self.tarefas = tarefas
        self.metas = metas
        self.categorias = categorias
        self.boletos = boletos
        self.incomes = incomes
        self.monthlyFlow = monthlyFlow
        self.contatos = contatos
        self.processos = processos
        self.honorarios = honorarios
        self.developer = developer
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case tarefas
        case metas
        case categorias
        case boletos
        case incomes
        case monthlyFlow
        case contatos
        case processos
        case honorarios
        case developer
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        tarefas = try container.decodeIfPresent([String: TaskColumn].self, forKey: .tarefas) ?? AppState.defaultTaskColumns()
        metas = try container.decodeIfPresent([GoalItem].self, forKey: .metas) ?? []
        categorias = try container.decodeIfPresent([CategoryItem].self, forKey: .categorias) ?? []
        boletos = try container.decodeIfPresent([BoletoItem].self, forKey: .boletos) ?? []
        incomes = try container.decodeIfPresent([IncomeItem].self, forKey: .incomes) ?? []
        monthlyFlow = try container.decodeIfPresent([MonthlyFlowItem].self, forKey: .monthlyFlow) ?? AppState.makeTwelveMonths()
        contatos = try container.decodeIfPresent([ContatoItem].self, forKey: .contatos) ?? []
        processos = try container.decodeIfPresent([ProcessoItem].self, forKey: .processos) ?? []
        honorarios = try container.decodeIfPresent([HonorarioItem].self, forKey: .honorarios) ?? []
        developer = try container.decodeIfPresent(DeveloperWorkspace.self, forKey: .developer) ?? DeveloperWorkspace.previewSeed()
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? AppFormatting.isoDate(Date())
        self = AppState.normalized(self)
    }

    public static func defaultTaskColumns() -> [String: TaskColumn] {
        [
            "hoje": TaskColumn(name: "Hoje"),
            "semana": TaskColumn(name: "Esta semana"),
            "proximas": TaskColumn(name: "Próximas")
        ]
    }

    public static func makeTwelveMonths(referenceDate: Date = Date(), count: Int = 12, pastCount: Int = 2) -> [MonthlyFlowItem] {
        let calendar = Calendar(identifier: .gregorian)
        return (-pastCount..<(count - pastCount)).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: offset, to: referenceDate) else {
                return nil
            }
            let key = AppFormatting.monthKey(date, calendar: calendar)
            let rawLabel = AppFormatting.monthLabelFormatter.string(from: date).replacingOccurrences(of: ".", with: "")
            let label = rawLabel.prefix(1).uppercased() + rawLabel.dropFirst()
            return MonthlyFlowItem(month: key, label: label)
        }
    }

    public static func makeEmpty(referenceDate: Date = Date()) -> AppState {
        AppState(
            tarefas: defaultTaskColumns(),
            monthlyFlow: makeTwelveMonths(referenceDate: referenceDate),
            developer: DeveloperWorkspace.previewSeed(referenceDate: referenceDate)
        )
    }

    public static func makeDemo(referenceDate: Date = Date()) -> AppState {
        var state = AppState(
            tarefas: [
                "hoje": TaskColumn(name: "Hoje", tasks: [
                    TaskItem(id: "t1", title: "Revisar investimentos", priority: .alta, tag: "Finanças", goal: "Reserva de emergência", dueDate: "2026-04-17", notes: "Conferir carteira e rebalancear exposição."),
                    TaskItem(id: "t2", title: "Ligar para seguradora", priority: .media, tag: "Carro", dueDate: "2026-04-17")
                ]),
                "semana": TaskColumn(name: "Esta semana", tasks: [
                    TaskItem(id: "t3", title: "Agendar check-up médico", priority: .alta, tag: "Saúde", goal: "Saúde em dia", dueDate: "2026-04-22"),
                    TaskItem(id: "t4", title: "Organizar documentos IR", priority: .media, tag: "Finanças", dueDate: "2026-04-25")
                ]),
                "proximas": TaskColumn(name: "Próximas", tasks: [
                    TaskItem(id: "t5", title: "Pesquisar cursos de inglês", priority: .baixa, tag: "Estudo", goal: "Fluência em inglês")
                ])
            ],
            metas: [
                GoalItem(id: "m1", title: "Reserva de emergência", type: .financeira, progress: 58, current: 17_400, target: 30_000, deadline: "Dez 2026", milestones: [
                    GoalMilestone(label: "R$ 10.000", done: true),
                    GoalMilestone(label: "R$ 20.000"),
                    GoalMilestone(label: "R$ 30.000")
                ]),
                GoalItem(id: "m2", title: "Saúde em dia", type: .pessoal, progress: 70, deadline: "Contínuo", milestones: [
                    GoalMilestone(label: "Check-up anual", done: true),
                    GoalMilestone(label: "3x academia/semana", done: true),
                    GoalMilestone(label: "Dentista")
                ])
            ],
            categorias: [
                CategoryItem(id: "c1", name: "Seguro do Carro", color: "#3F3F46"),
                CategoryItem(id: "c2", name: "Internet", color: "#525252", recurring: true),
                CategoryItem(id: "c3", name: "Academia", color: "#737373", recurring: true),
                CategoryItem(id: "c4", name: "Cartão Nubank", color: "#262626")
            ],
            boletos: [
                BoletoItem(id: "b1", categoriaId: "c1", desc: "Parcela 04/12", dueDate: "2026-04-20", value: 348.90),
                BoletoItem(id: "b2", categoriaId: "c2", desc: "Mensalidade abril", dueDate: "2026-04-22", value: 129.90),
                BoletoItem(id: "b3", categoriaId: "c3", desc: "Mensalidade abril", dueDate: "2026-04-25", value: 99.90, recurrence: .fixa),
                BoletoItem(id: "b4", categoriaId: "c4", desc: "Fatura abril", dueDate: "2026-04-28", value: 2_140.50)
            ],
            incomes: [
                IncomeItem(id: "i1", desc: "Salário CLT", type: .fixa, value: 9_500),
                IncomeItem(id: "i2", desc: "Freelance Projeto X", type: .variavel, value: 2_400, startDate: "2026-04-01", durationMonths: 1)
            ],
            monthlyFlow: [
                MonthlyFlowItem(month: "2025-11", label: "Nov", in: 11_800, out: 4_200),
                MonthlyFlowItem(month: "2025-12", label: "Dez", in: 14_200, out: 6_100),
                MonthlyFlowItem(month: "2026-01", label: "Jan", in: 11_500, out: 3_800),
                MonthlyFlowItem(month: "2026-02", label: "Fev", in: 12_100, out: 4_500),
                MonthlyFlowItem(month: "2026-03", label: "Mar", in: 12_400, out: 4_900),
                MonthlyFlowItem(month: "2026-04", label: "Abr", in: 12_400, out: 3_219)
            ],
            contatos: [
                ContatoItem(id: "ct1", name: "Maria Eduarda Almeida", role: .cliente, document: "123.456.789-00", email: "maria.almeida@example.com", phone: "(91) 99999-0000", notes: "Autora da ação indenizatória contra instituição financeira."),
                ContatoItem(id: "ct2", name: "Oliveira & Ramos Arquitetura Ltda.", entityType: .pessoaJuridica, role: .cliente, document: "12.345.678/0001-90", email: "socios@oliveiraramos.example", phone: "(91) 98888-0000", notes: "Cliente empresarial em negociação extrajudicial de rescisão contratual.")
            ],
            processos: [
                ProcessoItem(
                    id: "p1",
                    numero: "0801234-77.2026.8.14.0301",
                    tituloAcao: "Ação de Indenização por Danos Morais",
                    cliente: "Maria Eduarda Almeida",
                    autores: ["Maria Eduarda Almeida"],
                    parteContraria: "Banco Atlântico S.A.",
                    reus: ["Banco Atlântico S.A."],
                    parteRepresentada: "Maria Eduarda Almeida",
                    poloRepresentado: .autor,
                    tipoCaso: .judicial,
                    area: "Cível",
                    fase: "Contestação",
                    prioridade: .alta,
                    orgaoJulgador: "2ª Vara Cível e Empresarial de Belém",
                    comarca: "Belém/PA",
                    vara: "2ª Vara Cível e Empresarial",
                    tribunal: "TJPA",
                    dataDistribuicao: "2026-03-18",
                    proxAto: "2026-04-29",
                    proxAtoDesc: "Analisar contestação e preparar réplica",
                    valorCausa: 35_000,
                    exitoPercentual: 20,
                    exitoChancePercentual: 62,
                    exitoProbabilidade: .media,
                    exitoPrazo: "Set/2026",
                    exitoBaseCalculo: .valorCondenacao,
                    exitoValorCondenacaoEstimado: 12_000,
                    resumo: "Cliente relata bloqueio indevido de conta, recusa de atendimento resolutivo e restrição temporária de acesso a valores essenciais. A ação busca reparação moral e confirmação da falha de serviço.",
                    resumoInicial: "A inicial sustenta relação de consumo, defeito na prestação bancária e dano moral decorrente de bloqueio sem comunicação adequada. Foram juntados protocolos, extratos e prints de atendimento.",
                    tesePrincipal: "Responsabilidade objetiva da instituição financeira por falha na prestação do serviço e violação do dever de informação.",
                    pedidos: ["Indenização por danos morais", "Declaração de falha na prestação do serviço", "Condenação em custas e honorários sucumbenciais"],
                    riscos: "Risco de o juízo entender o bloqueio como medida de segurança regular, reduzindo a indenização ou exigindo prova mais robusta do abalo.",
                    estrategia: "Destacar a sequência de protocolos, a duração do bloqueio e o impacto concreto sobre compromissos financeiros da autora.",
                    resultadoEsperado: "Composição ou sentença com indenização entre R$ 8.000 e R$ 15.000.",
                    observacoes: "Priorizar linguagem objetiva na réplica e preparar quadro cronológico dos atendimentos.",
                    contatos: [ProcessoContatoVinculo(contatoId: "ct1", role: .cliente)],
                    prazos: [
                        ProcessoPrazo(title: "Réplica à contestação", date: "2026-04-29", type: .peticao, notes: "Conferir documentos bancários antes do protocolo."),
                        ProcessoPrazo(title: "Audiência de conciliação", date: "2026-05-20", type: .audiencia, notes: "Levar proposta mínima de acordo.")
                    ],
                    andamentos: [
                        ProcessoAndamento(date: "2026-04-19", time: "10:30", title: "Contestação disponibilizada", summary: "Banco alegou bloqueio preventivo por suspeita transacional. Necessário rebater ausência de comunicação clara.", type: .peticao),
                        ProcessoAndamento(date: "2026-03-18", time: "15:12", title: "Distribuição da ação", summary: "Processo distribuído no TJPA com pedido indenizatório e documentos principais anexados.", type: .observacao)
                    ]
                ),
                ProcessoItem(
                    id: "p2",
                    numero: "",
                    tituloAcao: "Caso Extrajudicial de Rescisão Contratual",
                    cliente: "Oliveira & Ramos Arquitetura Ltda.",
                    autores: ["Oliveira & Ramos Arquitetura Ltda."],
                    parteContraria: "Construtora Norte Prime",
                    reus: ["Construtora Norte Prime"],
                    parteRepresentada: "Oliveira & Ramos Arquitetura Ltda.",
                    poloRepresentado: .autor,
                    tipoCaso: .extrajudicial,
                    area: "Contratos",
                    fase: "Negociação",
                    status: .acordo,
                    prioridade: .media,
                    proxAto: "2026-05-03",
                    proxAtoDesc: "Enviar minuta revisada de distrato",
                    valorCausa: 120_000,
                    exitoPercentual: 12,
                    exitoChancePercentual: 80,
                    exitoProbabilidade: .alta,
                    exitoPrazo: "Jun/2026",
                    exitoBaseCalculo: .valorAcordo,
                    exitoValorAcordoEstimado: 72_000,
                    resumo: "Cliente busca encerrar contrato de prestação de serviços arquitetônicos após atrasos de pagamento e mudanças sucessivas de escopo sem aditivo formal.",
                    resumoInicial: "Ainda não judicializado. A narrativa documental mostra aceite de entregáveis, inadimplemento parcial e tentativa de impor novas etapas sem remuneração adicional.",
                    tesePrincipal: "Rescisão motivada por inadimplemento contratual da contratante, com cobrança de saldo pendente e preservação dos direitos autorais técnicos.",
                    pedidos: ["Pagamento do saldo contratual", "Quitação das etapas aprovadas", "Cláusula de não utilização dos projetos sem pagamento integral"],
                    riscos: "A construtora pode alegar entrega incompleta e tentar compensar valores com supostos retrabalhos.",
                    estrategia: "Manter negociação documentada, enviar minuta equilibrada e preparar notificação extrajudicial caso não haja resposta objetiva.",
                    resultadoEsperado: "Distrato assinado com pagamento mínimo de R$ 72.000 em até três parcelas.",
                    observacoes: "Caso evolua para judicial, reaproveitar histórico de e-mails e atas de reunião.",
                    contatos: [ProcessoContatoVinculo(contatoId: "ct2", role: .cliente)],
                    prazos: [
                        ProcessoPrazo(title: "Minuta revisada de distrato", date: "2026-05-03", type: .acordo, notes: "Incluir cláusula de uso condicionado dos projetos."),
                        ProcessoPrazo(title: "Data-limite para resposta da construtora", date: "2026-05-10", type: .prazo, notes: "Se não houver retorno, preparar notificação.")
                    ],
                    andamentos: [
                        ProcessoAndamento(date: "2026-04-21", time: "17:40", title: "Reunião de negociação", summary: "Construtora sinalizou pagamento parcelado, mas resistiu à multa e ao reconhecimento integral dos entregáveis.", type: .acordo),
                        ProcessoAndamento(date: "2026-04-12", time: "09:00", title: "Análise documental", summary: "Contratos, e-mails e aprovações técnicas indicam saldo relevante em aberto.", type: .observacao)
                    ]
                )
            ],
            honorarios: [
                HonorarioItem(id: "h1", processoId: "p1", cliente: "Maria Eduarda Almeida", processo: "0801234-77.2026", tipo: "Entrada contratual", venc: "2026-04-20", valor: 2_500, launchType: .parcelaUnica, status: .pago, dataRecebimento: "2026-04-20", recebimentoMetodo: .pix, recebimentoObservacao: "Entrada confirmada no ato da assinatura."),
                HonorarioItem(id: "h2", processoId: "p1", cliente: "Maria Eduarda Almeida", processo: "0801234-77.2026", tipo: "Parcelamento contratual", venc: "2026-05-20", valor: 1_500, launchType: .parcelado, parcelaIndice: 2, parcelaTotal: 3),
                HonorarioItem(id: "h3", processoId: "p2", cliente: "Oliveira & Ramos Arquitetura Ltda.", processo: "Extrajudicial", tipo: "Negociação e minuta extrajudicial", venc: "2026-05-05", valor: 6_000, launchType: .avulso, notes: "Cobrança avulsa atrelada à rodada final da minuta.")
            ],
            developer: DeveloperWorkspace.previewSeed(referenceDate: referenceDate)
        )
        state = normalized(state)
        state.recalculateMonthlyFlow(referenceDate: referenceDate)
        return state
    }

    public static func normalized(_ input: AppState) -> AppState {
        var state = input
        for key in taskColumnOrder where state.tarefas[key] == nil {
            state.tarefas[key] = defaultTaskColumns()[key]
        }
        if state.monthlyFlow.isEmpty {
            state.monthlyFlow = makeTwelveMonths()
        }
        if state.developer.projects.isEmpty && state.developer.receivables.isEmpty {
            state.developer = DeveloperWorkspace.previewSeed()
        }
        state.seedProcessDeadlinesFromLegacyFields()
        state.backfillProcessRepresentation()
        state.schemaVersion = schemaVersion
        return state
    }

    public var allTasks: [TaskItem] {
        AppState.taskColumnOrder.flatMap { tarefas[$0]?.tasks ?? [] }
    }

    public func tasks(in columnID: String) -> [TaskItem] {
        tarefas[columnID]?.tasks ?? []
    }

    public func categoryName(for id: String) -> String {
        categorias.first { $0.id == id }?.name ?? "Sem categoria"
    }

    public func processo(for id: String) -> ProcessoItem? {
        processos.first { $0.id == id }
    }

    public func goalCurrentValue(for goal: GoalItem) -> Double {
        let incomeTotal = incomes
            .filter { goal.associatedIncomeIDs.contains($0.id) }
            .reduce(0) { $0 + $1.value }
        let honorarioTotal = honorarios
            .filter { goal.associatedHonorarioIDs.contains($0.id) && $0.status == .pago }
            .reduce(0) { $0 + $1.valor }
        return (goal.current ?? 0) + incomeTotal + honorarioTotal
    }

    public func goalProgress(for goal: GoalItem) -> Int {
        if let target = goal.target, target > 0 {
            return min(100, max(0, Int((goalCurrentValue(for: goal) / target * 100).rounded())))
        }
        guard !goal.milestones.isEmpty else {
            return min(100, max(0, goal.progress))
        }
        let done = goal.milestones.filter(\.done).count
        return Int((Double(done) / Double(goal.milestones.count) * 100).rounded())
    }

    public mutating func recalculateMonthlyFlow(referenceDate: Date = Date()) {
        var flow = monthlyFlow.isEmpty ? AppState.makeTwelveMonths(referenceDate: referenceDate) : monthlyFlow
        flow = flow.map { MonthlyFlowItem(month: $0.month, label: $0.label) }

        for income in incomes {
            for index in flow.indices {
                let month = flow[index].month
                if income.type == .fixa {
                    if let start = AppFormatting.date(fromISO: income.startDate ?? "") {
                        guard month >= AppFormatting.monthKey(start) else { continue }
                    }
                    flow[index].in += income.value(forMonth: month)
                } else {
                    let start = AppFormatting.date(fromISO: income.startDate ?? "") ?? referenceDate
                    let monthDate = AppFormatting.date(fromISO: "\(flow[index].month)-01") ?? referenceDate
                    let diff = Calendar.current.dateComponents([.month], from: start, to: monthDate).month ?? 0
                    if diff >= 0 && diff < (income.durationMonths ?? 1) {
                        flow[index].in += income.value(forMonth: month)
                    }
                }
            }
        }

        for boleto in boletos {
            for index in flow.indices {
                let month = flow[index].month
                if boleto.status == .pago {
                    let paidMonth = AppFormatting.monthKey(AppFormatting.date(fromISO: boleto.paidAt ?? boleto.dueDate) ?? referenceDate)
                    if paidMonth == month {
                        flow[index].out += boleto.value(forMonth: month)
                    }
                } else if boleto.recurrence == .fixa {
                    if let due = AppFormatting.date(fromISO: boleto.dueDate),
                       let monthDate = AppFormatting.date(fromISO: "\(flow[index].month)-01"),
                       monthDate >= Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: due)) ?? due {
                        flow[index].out += boleto.value(forMonth: month)
                    }
                } else if boleto.status != .pago && AppFormatting.monthKey(AppFormatting.date(fromISO: boleto.dueDate) ?? referenceDate) == flow[index].month {
                    flow[index].out += boleto.value(forMonth: month)
                }
            }
        }

        monthlyFlow = flow
    }

    private mutating func seedProcessDeadlinesFromLegacyFields() {
        processos = processos.map { processo in
            var copy = processo
            if copy.prazos.isEmpty, !copy.proxAto.isEmpty {
                copy.prazos = [
                    ProcessoPrazo(
                        title: copy.proxAtoDesc.isEmpty ? "Próximo ato" : copy.proxAtoDesc,
                        date: copy.proxAto,
                        type: copy.proxAtoDesc.localizedCaseInsensitiveContains("audi") ? .audiencia : .prazo
                    )
                ]
            }
            if copy.andamentos.isEmpty, !copy.resumo.isEmpty {
                copy.andamentos = [
                    ProcessoAndamento(
                        date: copy.updatedAt,
                        title: "Resumo inicial",
                        summary: copy.resumo,
                        type: .observacao
                    )
                ]
            }
            return copy
        }
    }

    private mutating func backfillProcessRepresentation() {
        processos = processos.map { processo in
            var copy = processo
            if copy.parteRepresentada.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let primaryAuthor = copy.autores
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .first { !$0.isEmpty }
                let fallbackClient = copy.cliente.trimmingCharacters(in: .whitespacesAndNewlines)
                copy.parteRepresentada = primaryAuthor ?? (fallbackClient.isEmpty ? "" : fallbackClient)
            }
            return copy
        }
    }
}

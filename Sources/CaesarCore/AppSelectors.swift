import Foundation

public struct FinancasSummary: Codable, Equatable, Hashable {
    public var entradasFixas: Double
    public var entradasVariaveis: Double
    public var saidasProjetadas: Double
    public var contasPagas: Double
    public var ganhosRecebidos: Double
    public var saldoFinal: Double

    public init(entradasFixas: Double, entradasVariaveis: Double, saidasProjetadas: Double, contasPagas: Double, ganhosRecebidos: Double, saldoFinal: Double) {
        self.entradasFixas = entradasFixas
        self.entradasVariaveis = entradasVariaveis
        self.saidasProjetadas = saidasProjetadas
        self.contasPagas = contasPagas
        self.ganhosRecebidos = ganhosRecebidos
        self.saldoFinal = saldoFinal
    }
}

public struct HonorariosSummary: Codable, Equatable, Hashable {
    public var previstoContratual: Double
    public var total: Double
    public var pendente: Double
    public var recebido: Double
    public var atrasado: Double

    public init(previstoContratual: Double, total: Double, pendente: Double, recebido: Double, atrasado: Double) {
        self.previstoContratual = previstoContratual
        self.total = total
        self.pendente = pendente
        self.recebido = recebido
        self.atrasado = atrasado
    }
}

public struct BoletoCategorySummary: Codable, Equatable, Identifiable, Hashable {
    public var id: String { category.id }
    public var category: CategoryItem
    public var boletos: [BoletoItem]
    public var nextBoleto: BoletoItem?
    public var pendingTotal: Double

    public init(category: CategoryItem, boletos: [BoletoItem], nextBoleto: BoletoItem?, pendingTotal: Double) {
        self.category = category
        self.boletos = boletos
        self.nextBoleto = nextBoleto
        self.pendingTotal = pendingTotal
    }
}

public struct FinanceCategorySpend: Codable, Equatable, Identifiable, Hashable {
    public var id: String { categoryID }
    public var categoryID: String
    public var name: String
    public var color: String
    public var total: Double

    public init(categoryID: String, name: String, color: String, total: Double) {
        self.categoryID = categoryID
        self.name = name
        self.color = color
        self.total = total
    }
}

public struct ExitoCase: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var caso: String
    public var processoReferencia: String
    public var area: String
    public var baseCalculo: ExitoBaseCalculo
    public var baseLabel: String
    public var percentual: Double
    public var chancePercentual: Double
    public var valorBase: Double
    public var probabilidade: SuccessProbability
    public var prazoEstimado: String
    public var valorBrutoEstimado: Double
    public var valorEstimado: Double
    public var valorPonderado: Double

    public init(id: String, caso: String, processoReferencia: String, area: String, baseCalculo: ExitoBaseCalculo, baseLabel: String, percentual: Double, chancePercentual: Double, valorBase: Double, probabilidade: SuccessProbability, prazoEstimado: String, valorBrutoEstimado: Double, valorEstimado: Double, valorPonderado: Double) {
        self.id = id
        self.caso = caso
        self.processoReferencia = processoReferencia
        self.area = area
        self.baseCalculo = baseCalculo
        self.baseLabel = baseLabel
        self.percentual = percentual
        self.chancePercentual = chancePercentual
        self.valorBase = valorBase
        self.probabilidade = probabilidade
        self.prazoEstimado = prazoEstimado
        self.valorBrutoEstimado = valorBrutoEstimado
        self.valorEstimado = valorEstimado
        self.valorPonderado = valorPonderado
    }
}

public enum AgendaItemKind: String, Codable, CaseIterable, Identifiable {
    case tarefa
    case boleto
    case prazoProcessual
    case honorario

    public var id: String { rawValue }
}

public struct AgendaItem: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var kind: AgendaItemKind
    public var title: String
    public var subtitle: String
    public var date: String
    public var amount: Double?
    public var routeHint: String

    public init(id: String, kind: AgendaItemKind, title: String, subtitle: String, date: String, amount: Double? = nil, routeHint: String) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.date = date
        self.amount = amount
        self.routeHint = routeHint
    }
}

public struct AgendaBucket: Codable, Equatable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var items: [AgendaItem]

    public init(id: String, title: String, items: [AgendaItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}

public enum AppSelectors {
    public static func financasSummary(for state: AppState, referenceDate: Date = Date()) -> FinancasSummary {
        let currentMonth = AppFormatting.monthKey(referenceDate)
        let entradasFixas = state.incomes
            .filter { $0.type == .fixa }
            .filter { isIncomeActive($0, inMonth: currentMonth, referenceDate: referenceDate) }
            .reduce(0) { $0 + $1.value(forMonth: currentMonth) }
        let entradasVariaveis = state.incomes
            .filter { $0.type == .variavel }
            .filter { isIncomeActive($0, inMonth: currentMonth, referenceDate: referenceDate) }
            .reduce(0) { $0 + $1.value(forMonth: currentMonth) }
        let saidasProjetadas = state.boletos
            .filter { $0.status != .pago }
            .filter { isExpenseActive($0, inMonth: currentMonth, referenceDate: referenceDate) }
            .reduce(0) { $0 + $1.value(forMonth: currentMonth) }
        let contasPagas = state.boletos
            .filter { $0.status == .pago }
            .filter { AppFormatting.monthKey(AppFormatting.date(fromISO: $0.paidAt ?? $0.dueDate) ?? referenceDate) == currentMonth }
            .reduce(0) { $0 + $1.value(forMonth: currentMonth) }
        let ganhosRecebidos = state.incomes
            .filter { $0.status == .recebido }
            .filter { AppFormatting.monthKey(AppFormatting.date(fromISO: $0.receivedAt ?? $0.startDate ?? "") ?? referenceDate) == currentMonth }
            .reduce(0) { $0 + $1.value(forMonth: currentMonth) }
        let entradas = entradasFixas + entradasVariaveis
        return FinancasSummary(
            entradasFixas: entradasFixas,
            entradasVariaveis: entradasVariaveis,
            saidasProjetadas: saidasProjetadas,
            contasPagas: contasPagas,
            ganhosRecebidos: ganhosRecebidos,
            saldoFinal: entradas - saidasProjetadas
        )
    }

    public static func spendingByCategory(for state: AppState, referenceDate: Date = Date()) -> [FinanceCategorySpend] {
        let month = AppFormatting.monthKey(referenceDate)
        return state.categorias.compactMap { category in
            let total = state.boletos
                .filter { $0.categoriaId == category.id }
                .filter { isExpenseActive($0, inMonth: month, referenceDate: referenceDate) || ($0.status == .pago && AppFormatting.monthKey(AppFormatting.date(fromISO: $0.paidAt ?? $0.dueDate) ?? referenceDate) == month) }
                .reduce(0) { $0 + $1.value(forMonth: month) }
            guard total > 0 else { return nil }
            return FinanceCategorySpend(categoryID: category.id, name: category.name, color: category.color, total: total)
        }
        .sorted { $0.total > $1.total }
    }

    public static func boletosByCategoria(for state: AppState, referenceDate: Date = Date()) -> [BoletoCategorySummary] {
        state.categorias.compactMap { category in
            let boletos = state.boletos.filter { $0.categoriaId == category.id }
            guard !boletos.isEmpty else { return nil }
            let pending = boletos
                .filter { $0.effectiveStatus(referenceDate: referenceDate) != .pago }
                .sorted { $0.dueDate < $1.dueDate }
            return BoletoCategorySummary(
                category: category,
                boletos: boletos,
                nextBoleto: pending.first,
                pendingTotal: pending.reduce(0) { $0 + $1.value }
            )
        }
    }

    public static func honorariosSummary(for state: AppState, referenceDate: Date = Date()) -> HonorariosSummary {
        let total = state.honorarios.reduce(0) { $0 + $1.valor }
        let received = state.honorarios.filter { $0.status == .pago }.reduce(0) { $0 + $1.valor }
        let overdue = state.honorarios
            .filter { $0.effectiveStatus(referenceDate: referenceDate) == .atrasado }
            .reduce(0) { $0 + $1.valor }
        let pending = state.honorarios
            .filter {
                let status = $0.effectiveStatus(referenceDate: referenceDate)
                return status == .pendente || status == .renegociado || status == .atrasado
            }
            .reduce(0) { $0 + $1.valor }
        return HonorariosSummary(previstoContratual: total, total: total, pendente: pending, recebido: received, atrasado: overdue)
    }

    public static func exitoCases(for state: AppState) -> [ExitoCase] {
        state.processos
            .filter { $0.exitoPercentual > 0 && $0.exitoBaseValor > 0 }
            .map { processo in
                let estimated = processo.exitoValorHonorariosEstimado
                return ExitoCase(
                    id: processo.id,
                    caso: processo.cliente,
                    processoReferencia: processo.numero.isEmpty ? (processo.tituloAcao.isEmpty ? processo.cliente : processo.tituloAcao) : processo.numero,
                    area: processo.area,
                    baseCalculo: processo.exitoBaseCalculo,
                    baseLabel: processo.exitoBaseLabel,
                    percentual: processo.exitoPercentual,
                    chancePercentual: processo.exitoChancePercentual,
                    valorBase: processo.exitoBaseValor,
                    probabilidade: processo.exitoProbabilidade,
                    prazoEstimado: processo.exitoPrazo,
                    valorBrutoEstimado: processo.exitoBaseValor,
                    valorEstimado: estimated,
                    valorPonderado: processo.exitoValorPonderado
                )
            }
            .sorted { $0.valorPonderado > $1.valorPonderado }
    }

    public static func agendaSections(for state: AppState, referenceDate: Date = Date()) -> [AgendaBucket] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let sevenDays = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        var items: [AgendaItem] = []

        for task in state.allTasks where !task.dueDate.isEmpty {
            items.append(AgendaItem(id: "task-\(task.id)", kind: .tarefa, title: task.title, subtitle: task.tag, date: task.dueDate, routeHint: "tarefas"))
        }

        for boleto in state.boletos where boleto.status != .pago {
            items.append(AgendaItem(id: "boleto-\(boleto.id)", kind: .boleto, title: boleto.desc, subtitle: state.categoryName(for: boleto.categoriaId), date: boleto.dueDate, amount: boleto.value, routeHint: "financas"))
        }

        for processo in state.processos {
            for prazo in processo.prazos where !prazo.done {
                items.append(AgendaItem(id: "prazo-\(processo.id)-\(prazo.id)", kind: .prazoProcessual, title: prazo.title, subtitle: processo.numero, date: prazo.date, routeHint: "processos"))
            }
        }

        for honorario in state.honorarios where honorario.status != .pago {
            items.append(AgendaItem(id: "hon-\(honorario.id)", kind: .honorario, title: honorario.tipo, subtitle: honorario.cliente, date: honorario.venc, amount: honorario.valor, routeHint: "honorarios"))
        }

        let sorted = items.sorted { $0.date < $1.date }
        func dateFor(_ item: AgendaItem) -> Date {
            AppFormatting.date(fromISO: item.date) ?? today
        }

        let overdue = sorted.filter { dateFor($0) < today }
        let dueToday = sorted.filter { calendar.isDate(dateFor($0), inSameDayAs: today) }
        let nextSeven = sorted.filter {
            let date = dateFor($0)
            return date > today && date <= sevenDays
        }

        return [
            AgendaBucket(id: "atrasados", title: "Atrasados", items: overdue),
            AgendaBucket(id: "hoje", title: "Hoje", items: dueToday),
            AgendaBucket(id: "proximos", title: "Próximos 7 dias", items: nextSeven)
        ]
    }

    public static func developerFinance(for state: AppState, referenceDate: Date = Date()) -> DeveloperFinanceSummary {
        let start = Calendar.current.startOfDay(for: referenceDate)
        return state.developer.receivables.reduce(DeveloperFinanceSummary(pending: 0, paid: 0, overdue: 0, draft: 0)) { summary, receivable in
            var copy = summary
            switch receivable.status {
            case .paid:
                copy.paid += receivable.value
            case .draft:
                copy.draft += receivable.value
            case .pending:
                if let due = AppFormatting.date(fromISO: receivable.dueDate), due < start {
                    copy.overdue += receivable.value
                } else {
                    copy.pending += receivable.value
                }
            case .overdue:
                copy.overdue += receivable.value
            }
            return copy
        }
    }

    private static func isIncomeActive(_ income: IncomeItem, inMonth month: String, referenceDate: Date) -> Bool {
        if income.status == .recebido {
            let receivedMonth = AppFormatting.monthKey(AppFormatting.date(fromISO: income.receivedAt ?? income.startDate ?? "") ?? referenceDate)
            return receivedMonth == month
        }
        if income.type == .fixa {
            guard let startDate = AppFormatting.date(fromISO: income.startDate ?? "") else {
                return true
            }
            return month >= AppFormatting.monthKey(startDate)
        }
        guard let startDate = AppFormatting.date(fromISO: income.startDate ?? "") else {
            return true
        }
        let monthDate = AppFormatting.date(fromISO: "\(month)-01") ?? referenceDate
        let diff = Calendar.current.dateComponents([.month], from: startDate, to: monthDate).month ?? 0
        return diff >= 0 && diff < (income.durationMonths ?? 1)
    }

    private static func isExpenseActive(_ expense: BoletoItem, inMonth month: String, referenceDate: Date) -> Bool {
        if expense.recurrence == .fixa {
            guard let due = AppFormatting.date(fromISO: expense.dueDate) else {
                return true
            }
            return month >= AppFormatting.monthKey(due)
        }
        return AppFormatting.monthKey(AppFormatting.date(fromISO: expense.dueDate) ?? referenceDate) == month
    }
}

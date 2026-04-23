import CaesarCore
import SwiftUI

struct FinancasView: View {
    @ObservedObject var store: AppStore
    @State private var selectedTab: FinanceTab = .abertos
    @State private var draftKind: DraftKind = .despesa
    @State private var draftName = ""
    @State private var draftCategory = "Geral"
    @State private var draftValue = ""
    @State private var draftDueDate = AppFormatting.isoDate(Date())
    @State private var draftRecurrence: FinanceRecurrence = .variavel
    @State private var draftDuration = "1"
    @State private var adjustmentTargetID = ""
    @State private var adjustmentMonth = AppFormatting.monthKey(Date())
    @State private var adjustmentValue = ""

    var body: some View {
        ModuleScroll {
            let summary = AppSelectors.financasSummary(for: store.state)
            let openExpenses = store.state.boletos.filter { $0.status != .pago }.sorted { $0.dueDate < $1.dueDate }
            let paidExpenses = store.state.boletos.filter { $0.status == .pago }.sorted { ($0.paidAt ?? $0.dueDate) > ($1.paidAt ?? $1.dueDate) }
            let openIncomes = store.state.incomes.filter { $0.status != .recebido }.sorted { ($0.startDate ?? "") < ($1.startDate ?? "") }
            let receivedIncomes = store.state.incomes.filter { $0.status == .recebido }.sorted { ($0.receivedAt ?? $0.startDate ?? "") > ($1.receivedAt ?? $1.startDate ?? "") }
            let categorySpend = AppSelectors.spendingByCategory(for: store.state)

            VStack(alignment: .leading, spacing: 22) {
                SectionHeader(eyebrow: "Financeiro pessoal", title: "Finanças") {
                    Picker("", selection: $selectedTab) {
                        ForEach(FinanceTab.allCases) { tab in
                            Text(tab.label).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 330)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
                    MetricCard(title: "Ganhos fixos", value: AppFormatting.currency(summary.entradasFixas), subtitle: "Pessoais no mês", tone: AppTheme.success)
                    MetricCard(title: "Ganhos variáveis", value: AppFormatting.currency(summary.entradasVariaveis), subtitle: "Recebíveis pessoais", tone: AppTheme.accent)
                    MetricCard(title: "Contas abertas", value: AppFormatting.currency(summary.saidasProjetadas), subtitle: "A pagar no mês", tone: AppTheme.warning)
                    MetricCard(title: "Saldo pessoal", value: AppFormatting.currency(summary.saldoFinal), subtitle: "Sem advocacia/dev", tone: summary.saldoFinal >= 0 ? AppTheme.success : AppTheme.danger)
                }

                FinanceComposer(
                    draftKind: $draftKind,
                    name: $draftName,
                    category: $draftCategory,
                    value: $draftValue,
                    dueDate: $draftDueDate,
                    recurrence: $draftRecurrence,
                    duration: $draftDuration
                ) {
                    addFinanceItem()
                }

                switch selectedTab {
                case .abertos:
                    HStack(alignment: .top, spacing: 16) {
                        PayablesPanel(
                            openExpenses: openExpenses,
                            paidExpenses: Array(paidExpenses.prefix(8)),
                            categoryName: { store.state.categoryName(for: $0) },
                            markPaid: { store.dispatch(.boletoUpdateStatus(id: $0, status: .pago)) },
                            reopen: { store.dispatch(.boletoUpdateStatus(id: $0, status: .pendente)) },
                            delete: { store.dispatch(.boletoDelete(id: $0)) }
                        )

                        FinanceListPanel(title: "Dinheiro a receber", empty: "Nenhum ganho pessoal aberto.", isEmpty: openIncomes.isEmpty) {
                            ForEach(openIncomes) { income in
                                IncomeRow(income: income, isHistory: false) {
                                    store.dispatch(.incomeUpdateStatus(id: income.id, status: .recebido))
                                } delete: {
                                    store.dispatch(.incomeDelete(id: income.id))
                                }
                            }
                        }
                    }

                    FinanceAdjustmentPanel(
                        expenses: openExpenses.filter { $0.recurrence == .fixa },
                        incomes: openIncomes.filter { $0.type == .fixa },
                        targetID: $adjustmentTargetID,
                        month: $adjustmentMonth,
                        value: $adjustmentValue
                    ) {
                        applyMonthlyAdjustment()
                    }

                case .historico:
                    HStack(alignment: .top, spacing: 16) {
                        FinanceListPanel(title: "Histórico de contas pagas", empty: "Nenhuma conta paga ainda.", isEmpty: paidExpenses.isEmpty) {
                            ForEach(paidExpenses) { expense in
                                ExpenseRow(expense: expense, category: store.state.categoryName(for: expense.categoriaId), isHistory: true) {
                                    store.dispatch(.boletoUpdateStatus(id: expense.id, status: .pendente))
                                } delete: {
                                    store.dispatch(.boletoDelete(id: expense.id))
                                }
                            }
                        }

                        FinanceListPanel(title: "Histórico de ganhos recebidos", empty: "Nenhum ganho recebido ainda.", isEmpty: receivedIncomes.isEmpty) {
                            ForEach(receivedIncomes) { income in
                                IncomeRow(income: income, isHistory: true) {
                                    store.dispatch(.incomeUpdateStatus(id: income.id, status: .pendente))
                                } delete: {
                                    store.dispatch(.incomeDelete(id: income.id))
                                }
                            }
                        }
                    }

                case .analise:
                    HStack(alignment: .top, spacing: 16) {
                        SpendingChartPanel(items: categorySpend)
                        MonthlyComparisonPanel(flow: Array(store.state.monthlyFlow.suffix(8)))
                    }
                }
            }
        }
    }

    private func addFinanceItem() {
        let amount = parseCurrency(draftValue)
        guard amount > 0 else { return }
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        switch draftKind {
        case .despesa:
            let categoryID = ensureCategory(named: draftCategory)
            store.dispatch(.boletoAdd(BoletoDraft(
                categoriaId: categoryID,
                desc: name,
                dueDate: draftDueDate,
                value: amount,
                recurrence: draftRecurrence
            )))
        case .ganho:
            store.dispatch(.incomeAdd(IncomeDraft(
                desc: name,
                type: draftRecurrence == .fixa ? .fixa : .variavel,
                value: amount,
                startDate: draftDueDate,
                durationMonths: max(1, Int(draftDuration) ?? 1)
            )))
        }

        draftName = ""
        draftValue = ""
        draftDuration = "1"
    }

    private func applyMonthlyAdjustment() {
        let amount = parseCurrency(adjustmentValue)
        guard amount > 0, !adjustmentTargetID.isEmpty else { return }
        let adjustment = FinanceMonthlyAdjustment(month: adjustmentMonth, value: amount)
        if adjustmentTargetID.hasPrefix("expense:") {
            store.dispatch(.boletoAddAdjustment(id: String(adjustmentTargetID.dropFirst("expense:".count)), adjustment: adjustment))
        } else if adjustmentTargetID.hasPrefix("income:") {
            store.dispatch(.incomeAddAdjustment(id: String(adjustmentTargetID.dropFirst("income:".count)), adjustment: adjustment))
        }
        adjustmentValue = ""
    }

    private func ensureCategory(named rawName: String) -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Geral" : rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = store.state.categorias.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
            return existing.id
        }
        store.dispatch(.categoriaAdd(CategoryDraft(name: name, color: "#737373", recurring: draftRecurrence == .fixa)))
        return store.state.categorias.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }?.id ?? (store.state.categorias.first?.id ?? "")
    }

    private func parseCurrency(_ raw: String) -> Double {
        let normalized = raw
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(normalized) ?? 0
    }
}

private enum FinanceTab: String, CaseIterable, Identifiable {
    case abertos
    case historico
    case analise

    var id: String { rawValue }

    var label: String {
        switch self {
        case .abertos: "Abertos"
        case .historico: "Histórico"
        case .analise: "Análise"
        }
    }
}

private enum DraftKind: String, CaseIterable, Identifiable {
    case despesa
    case ganho

    var id: String { rawValue }

    var label: String {
        switch self {
        case .despesa: "Conta a pagar"
        case .ganho: "Ganho pessoal"
        }
    }
}

private struct FinanceComposer: View {
    @Binding var draftKind: DraftKind
    @Binding var name: String
    @Binding var category: String
    @Binding var value: String
    @Binding var dueDate: String
    @Binding var recurrence: FinanceRecurrence
    @Binding var duration: String
    var action: () -> Void

    var body: some View {
        CaesarPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    SectionHeader(eyebrow: "Cadastro manual", title: "Novo lançamento")
                    Spacer()
                    Picker("", selection: $draftKind) {
                        ForEach(DraftKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                }

                HStack(alignment: .bottom, spacing: 12) {
                    FinanceTextField(title: "Nome", text: $name, placeholder: draftKind == .despesa ? "Internet, aluguel, cartão..." : "Salário, ajuda mensal...")
                    if draftKind == .despesa {
                        FinanceTextField(title: "Categoria", text: $category, placeholder: "Moradia, saúde, estudo...")
                    }
                    FinanceTextField(title: "Valor", text: $value, placeholder: "100,00")
                        .frame(maxWidth: 140)
                    FinanceTextField(title: "Vencimento", text: $dueDate, placeholder: "2026-05-10")
                        .frame(maxWidth: 150)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tipo")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Picker("", selection: $recurrence) {
                            ForEach(FinanceRecurrence.allCases) { item in
                                Text(item.label).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .frame(width: 170)
                    if draftKind == .ganho && recurrence == .variavel {
                        FinanceTextField(title: "Meses", text: $duration, placeholder: "1")
                            .frame(maxWidth: 88)
                    }
                    PrimaryGlassButton(title: "Adicionar", systemImage: "plus", action: action)
                }
            }
        }
    }
}

private struct FinanceTextField: View {
    var title: String
    @Binding var text: String
    var placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.secondaryText)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(AppTypography.body(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(AppTheme.elevated))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AppTheme.stroke, lineWidth: 1))
        }
    }
}

private struct PayablesPanel: View {
    var openExpenses: [BoletoItem]
    var paidExpenses: [BoletoItem]
    var categoryName: (String) -> String
    var markPaid: (String) -> Void
    var reopen: (String) -> Void
    var delete: (String) -> Void

    var body: some View {
        CaesarPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(eyebrow: "", title: "Contas a pagar")

                VStack(alignment: .leading, spacing: 10) {
                    if openExpenses.isEmpty {
                        Text("Nenhuma conta aberta.")
                            .font(AppTypography.bodyRegular)
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(openExpenses) { expense in
                            ExpenseRow(expense: expense, category: categoryName(expense.categoriaId), isHistory: false) {
                                markPaid(expense.id)
                            } delete: {
                                delete(expense.id)
                            }
                        }
                    }
                }

                Divider().overlay(AppTheme.stroke.opacity(0.7))

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Pagas recentemente")
                            .font(AppTypography.body(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.text)
                        Spacer()
                        Text("últimos meses")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    if paidExpenses.isEmpty {
                        Text("Quando você pagar uma conta, ela aparece aqui também.")
                            .font(AppTypography.bodyRegular)
                            .foregroundStyle(AppTheme.secondaryText)
                    } else {
                        ForEach(paidExpenses) { expense in
                            ExpenseRow(expense: expense, category: categoryName(expense.categoriaId), isHistory: true) {
                                reopen(expense.id)
                            } delete: {
                                delete(expense.id)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

private struct FinanceListPanel<Content: View>: View {
    var title: String
    var empty: String
    var isEmpty: Bool
    @ViewBuilder var content: Content

    var body: some View {
        CaesarPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(eyebrow: "", title: title)
                if isEmpty {
                    Text(empty)
                        .font(AppTypography.bodyRegular)
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 10) {
                        content
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

private struct ExpenseRow: View {
    var expense: BoletoItem
    var category: String
    var isHistory: Bool
    var action: () -> Void
    var delete: () -> Void

    var body: some View {
        RowShell {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.desc)
                    .font(AppTypography.body(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                Text("\(category) · \(expense.recurrence.label) · \(AppFormatting.shortDate(expense.paidAt ?? expense.dueDate))")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Text(AppFormatting.currency(expense.value))
                .font(AppTypography.body(size: 13, weight: .medium).monospacedDigit())
                .foregroundStyle(AppTheme.text)
            StatusPill(text: isHistory ? "Paga" : expense.effectiveStatus().label, tone: isHistory ? AppTheme.success : AppTheme.warning)
            InlineActionButton(isHistory ? "Reabrir" : "Pagar", systemImage: isHistory ? "arrow.uturn.backward" : "checkmark", action: action)
            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct IncomeRow: View {
    var income: IncomeItem
    var isHistory: Bool
    var action: () -> Void
    var delete: () -> Void

    var body: some View {
        RowShell {
            VStack(alignment: .leading, spacing: 4) {
                Text(income.desc)
                    .font(AppTypography.body(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                Text("\(income.type.label) · \(AppFormatting.shortDate(income.receivedAt ?? income.startDate ?? ""))")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Text(AppFormatting.currency(income.value))
                .font(AppTypography.body(size: 13, weight: .medium).monospacedDigit())
                .foregroundStyle(AppTheme.text)
            StatusPill(text: income.status.label, tone: isHistory ? AppTheme.success : AppTheme.accent)
            InlineActionButton(isHistory ? "Reabrir" : "Receber", systemImage: isHistory ? "arrow.uturn.backward" : "checkmark", action: action)
            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct FinanceAdjustmentPanel: View {
    var expenses: [BoletoItem]
    var incomes: [IncomeItem]
    @Binding var targetID: String
    @Binding var month: String
    @Binding var value: String
    var action: () -> Void

    var body: some View {
        CaesarPanel(padding: 22) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reajuste de item fixo")
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppTheme.text)
                    Text("Use para salário que aumenta em um mês específico ou conta fixa com valor diferente.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Picker("Item", selection: $targetID) {
                    Text("Selecione").tag("")
                    ForEach(expenses) { item in
                        Text("Conta: \(item.desc)").tag("expense:\(item.id)")
                    }
                    ForEach(incomes) { item in
                        Text("Ganho: \(item.desc)").tag("income:\(item.id)")
                    }
                }
                .frame(width: 240)
                FinanceTextField(title: "Mês", text: $month, placeholder: "2026-06")
                    .frame(width: 120)
                FinanceTextField(title: "Valor", text: $value, placeholder: "120,00")
                    .frame(width: 130)
                PrimaryGlassButton(title: "Aplicar", systemImage: "slider.horizontal.3", action: action)
            }
        }
    }
}

private struct SpendingChartPanel: View {
    var items: [FinanceCategorySpend]

    var body: some View {
        CaesarPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(eyebrow: "Gastos", title: "Onde você gasta mais")
                let maxValue = items.map(\.total).max() ?? 1
                if items.isEmpty {
                    Text("Sem gastos pessoais neste mês.")
                        .font(AppTypography.bodyRegular)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack {
                                Text(item.name)
                                    .font(AppTypography.body(size: 13, weight: .semibold))
                                    .foregroundStyle(AppTheme.text)
                                Spacer()
                                Text(AppFormatting.currency(item.total))
                                    .font(AppTypography.caption.monospacedDigit())
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            MiniBar(value: item.total, maxValue: maxValue, tone: Color(hex: item.color))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

private struct MonthlyComparisonPanel: View {
    var flow: [MonthlyFlowItem]

    var body: some View {
        CaesarPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(eyebrow: "Comparativo", title: "Mês a mês")
                let maxValue = flow.map { max($0.in, $0.out) }.max() ?? 1
                ForEach(flow) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.label)
                                .font(AppTypography.eyebrow)
                                .tracking(1.0)
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            Text("\(AppFormatting.currency(item.in)) / \(AppFormatting.currency(item.out))")
                                .font(AppTypography.body(size: 11, weight: .regular).monospacedDigit())
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        MiniBar(value: item.in, maxValue: maxValue, tone: AppTheme.success)
                        MiniBar(value: item.out, maxValue: maxValue, tone: AppTheme.warning)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

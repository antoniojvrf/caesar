import CaesarCore
import SwiftUI

struct HonorariosView: View {
    @ObservedObject var store: AppStore

    @State private var selectedProcessFilter = "all"
    @State private var selectedMonthFilter = "all"
    @State private var activeSheet: HonorarioSheet?

    private var summary: HonorariosSummary {
        AppSelectors.honorariosSummary(for: store.state)
    }

    private var processOptions: [ProcessoItem] {
        store.state.processos.sorted { $0.displayTitle < $1.displayTitle }
    }

    private var monthOptions: [MonthFilterOption] {
        let keys = Set(store.state.honorarios.map { AppFormatting.monthKey(AppFormatting.date(fromISO: $0.venc) ?? Date()) })
        return keys
            .sorted()
            .map { key in
                MonthFilterOption(
                    id: key,
                    label: AppFormatting.shortDate("\(key)-01").split(separator: "/").prefix(2).joined(separator: "/").capitalized
                )
            }
    }

    private var filteredHonorarios: [HonorarioItem] {
        store.state.honorarios
            .filter { selectedProcessFilter == "all" || $0.processoId == selectedProcessFilter }
            .filter {
                guard selectedMonthFilter != "all" else { return true }
                let month = AppFormatting.monthKey(AppFormatting.date(fromISO: $0.venc) ?? Date())
                return month == selectedMonthFilter
            }
            .sorted { lhs, rhs in
                if lhs.venc == rhs.venc {
                    return lhs.cliente < rhs.cliente
                }
                return lhs.venc < rhs.venc
            }
    }

    var body: some View {
        ModuleScroll {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(eyebrow: "Finance", title: "Honorários a Receber") {
                    PrimaryGlassButton(title: "Novo honorário", systemImage: "plus") {
                        activeSheet = .newHonorario(nil)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    MetricCard(title: "Previsto contratual", value: AppFormatting.currency(summary.previstoContratual), subtitle: "Sem incluir êxito", tone: AppTheme.accent)
                    MetricCard(title: "Em aberto", value: AppFormatting.currency(summary.pendente), subtitle: "Pendentes e renegociados", tone: AppTheme.warning)
                    MetricCard(title: "Recebido", value: AppFormatting.currency(summary.recebido), subtitle: "Já realizado", tone: AppTheme.success)
                    MetricCard(title: "Atrasado", value: AppFormatting.currency(summary.atrasado), subtitle: "Exige acompanhamento", tone: AppTheme.danger)
                }

                CaesarPanel(padding: 22) {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(eyebrow: "Controle", title: "Recebíveis jurídicos")

                        if processOptions.isEmpty {
                            EmptyModuleState(
                                title: "Cadastre um processo primeiro",
                                subtitle: "Todo honorário desta aba precisa estar vinculado a um processo existente.",
                                systemImage: "briefcase"
                            )
                        } else {
                            HStack(spacing: 12) {
                                filterPicker(title: "Processo", selection: $selectedProcessFilter) {
                                    Text("Todos os processos").tag("all")
                                    ForEach(processOptions) { processo in
                                        Text(processo.displayTitle).tag(processo.id)
                                    }
                                }

                                filterPicker(title: "Mês de vencimento", selection: $selectedMonthFilter) {
                                    Text("Todos os meses").tag("all")
                                    ForEach(monthOptions) { option in
                                        Text(option.label).tag(option.id)
                                    }
                                }
                            }

                            if filteredHonorarios.isEmpty {
                                EmptyModuleState(
                                    title: "Nenhum honorário nesse filtro",
                                    subtitle: "Ajuste processo ou mês de vencimento, ou cadastre um novo recebível.",
                                    systemImage: "line.3.horizontal.decrease.circle"
                                )
                            } else {
                                ForEach(filteredHonorarios) { honorario in
                                    HonorarioLedgerRow(
                                        honorario: honorario,
                                        effectiveStatus: honorario.effectiveStatus(),
                                        processTitle: processTitle(for: honorario.processoId),
                                        onReceive: { activeSheet = .receiveHonorario(honorario.id) },
                                        onReopen: {
                                            store.dispatch(.honorarioUpdateStatus(id: honorario.id, status: .pendente, receivedAt: nil, method: nil, receiptNote: nil))
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case let .newHonorario(initialProcessID):
                HonorarioFormView(title: "Novo honorário", processos: store.state.processos, initialProcessID: initialProcessID) { drafts in
                    drafts.forEach { store.dispatch(.honorarioAdd($0)) }
                    activeSheet = nil
                } onCancel: {
                    activeSheet = nil
                }
            case let .receiveHonorario(honorarioID):
                if let honorario = store.state.honorarios.first(where: { $0.id == honorarioID }) {
                    HonorarioRecebimentoView(honorario: honorario) { date, method, note in
                        store.dispatch(.honorarioUpdateStatus(id: honorarioID, status: .pago, receivedAt: date, method: method, receiptNote: note))
                        activeSheet = nil
                    } onCancel: {
                        activeSheet = nil
                    }
                }
            }
        }
    }

    private func processTitle(for processID: String) -> String {
        store.state.processo(for: processID)?.displayTitle ?? "Processo vinculado"
    }

    private func filterPicker<Content: View>(title: String, selection: Binding<String>, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(AppTypography.eyebrow)
                .tracking(1.1)
                .foregroundStyle(AppTheme.mutedText)
            Picker(title, selection: selection) {
                content()
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private enum HonorarioSheet: Identifiable {
    case newHonorario(String?)
    case receiveHonorario(String)

    var id: String {
        switch self {
        case let .newHonorario(processID):
            "novo-\(processID ?? "geral")"
        case let .receiveHonorario(id):
            "receber-\(id)"
        }
    }
}

private struct MonthFilterOption: Identifiable {
    var id: String
    var label: String
}

private struct HonorarioLedgerRow: View {
    var honorario: HonorarioItem
    var effectiveStatus: HonorarioStatus
    var processTitle: String
    var onReceive: () -> Void
    var onReopen: () -> Void

    private var statusTone: Color {
        switch effectiveStatus {
        case .pago: AppTheme.success
        case .atrasado: AppTheme.danger
        case .renegociado: AppTheme.gold
        case .pendente: AppTheme.warning
        }
    }

    private var launchBadge: String {
        switch honorario.launchType {
        case .parcelaUnica:
            return "Parcela única"
        case .avulso:
            return "Avulso"
        case .parcelado:
            if let indice = honorario.parcelaIndice, let total = honorario.parcelaTotal {
                return "Parcela \(indice)/\(total)"
            }
            return "Parcelado"
        }
    }

    var body: some View {
        RowShell {
            VStack(alignment: .leading, spacing: 6) {
                Text(honorario.cliente)
                    .font(AppTypography.body(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                Text(processTitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text("\(honorario.tipo) • \(launchBadge)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(AppFormatting.currency(honorario.valor))
                    .font(AppTypography.body(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(AppTheme.text)
                Text(effectiveStatus == .pago ? "Recebido em \(AppFormatting.shortDate(honorario.dataRecebimento ?? ""))" : "Vence em \(AppFormatting.shortDate(honorario.venc))")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            StatusPill(text: effectiveStatus.label, tone: statusTone)

            if effectiveStatus == .pago {
                InlineActionButton("Reabrir", systemImage: "arrow.uturn.backward", action: onReopen)
            } else {
                InlineActionButton("Receber", systemImage: "checkmark.circle", action: onReceive)
            }
        }
    }
}

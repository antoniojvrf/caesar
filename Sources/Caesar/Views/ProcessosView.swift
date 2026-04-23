import CaesarCore
import SwiftUI

struct ProcessosView: View {
    @ObservedObject var store: AppStore
    @State private var selectedProcessID: String?
    @State private var searchText = ""
    @State private var activeSheet: ProcessoSheet?

    private var filteredProcessos: [ProcessoItem] {
        let processos = store.state.processos.sorted { lhs, rhs in
            if lhs.status == rhs.status {
                return lhs.updatedAt > rhs.updatedAt
            }
            return lhs.status == .ativo && rhs.status != .ativo
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return processos }

        return processos.filter { processo in
            [
                processo.tituloAcao,
                processo.cliente,
                processo.numero,
                processo.parteContraria,
                processo.area,
                processo.fase
            ]
            .joined(separator: " ")
            .lowercased()
            .contains(query)
        }
    }

    private var selectedProcess: ProcessoItem? {
        let id = selectedProcessID ?? filteredProcessos.first?.id ?? store.state.processos.first?.id
        return store.state.processos.first { $0.id == id }
    }

    private var summary: ProcessosSummary {
        ProcessosSummary(processos: store.state.processos, honorarios: store.state.honorarios)
    }

    var body: some View {
        ModuleScroll {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(eyebrow: "Painel do Advogado", title: "Processos") {
                    PrimaryGlassButton(title: "Novo processo", systemImage: "plus") {
                        activeSheet = .newProcess
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 5), spacing: 16) {
                    MetricCard(title: "Ativos", value: "\(summary.ativos)", subtitle: "Em acompanhamento", tone: AppTheme.accent)
                    MetricCard(title: "Extrajudiciais", value: "\(summary.extrajudiciais)", subtitle: "Sem CNJ", tone: AppTheme.gold)
                    MetricCard(title: "Próximos atos", value: "\(summary.proximosAtos)", subtitle: "Prazos em aberto", tone: AppTheme.warning)
                    MetricCard(title: "Honorários", value: AppFormatting.currency(summary.honorariosPendentes), subtitle: "Vinculados", tone: AppTheme.success)
                    MetricCard(title: "Êxito estimado", value: AppFormatting.currency(summary.exitoEstimado), subtitle: "Carteira provável", tone: AppTheme.gold)
                }

                HStack(alignment: .top, spacing: 16) {
                    CaesarPanel(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(eyebrow: "Carteira", title: "Casos")
                            GlassSearchField(text: $searchText, placeholder: "Buscar por ação, cliente, CNJ ou fase")

                            if filteredProcessos.isEmpty {
                                EmptyModuleState(title: "Nenhum caso encontrado", subtitle: "Ajuste a busca ou cadastre um novo processo.", systemImage: "doc.text.magnifyingglass")
                            } else {
                                ForEach(filteredProcessos) { processo in
                                    ProcessoCard(
                                        processo: processo,
                                        honorarios: honorarios(for: processo.id),
                                        selected: processo.id == selectedProcess?.id
                                    ) {
                                        selectedProcessID = processo.id
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 470)

                    if let processo = selectedProcess {
                        ProcessoDetailPane(
                            processo: processo,
                            honorarios: honorarios(for: processo.id),
                            onEditProcess: { activeSheet = .editProcess(processo.id) },
                            onAddPrazo: { activeSheet = .addPrazo(processo.id) },
                            onEditPrazo: { prazo in activeSheet = .editPrazo(processo.id, prazo.id) },
                            onAddAndamento: { activeSheet = .addAndamento(processo.id) },
                            onEditAndamento: { andamento in activeSheet = .editAndamento(processo.id, andamento.id) },
                            onAddHonorario: { activeSheet = .addHonorario(processo.id) },
                            onReceiveHonorario: { honorario in activeSheet = .receiveHonorario(honorario.id) },
                            onReopenHonorario: { honorario in
                                store.dispatch(.honorarioUpdateStatus(id: honorario.id, status: .pendente, receivedAt: nil, method: nil, receiptNote: nil))
                            }
                        )
                    } else {
                        EmptyModuleState(
                            title: "Nenhum processo",
                            subtitle: "Cadastre um processo para abrir a ficha completa do caso.",
                            systemImage: "briefcase"
                        )
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(sheet)
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: ProcessoSheet) -> some View {
        switch sheet {
        case .newProcess:
            ProcessoFormView(title: "Novo processo", processo: nil) { draft in
                store.dispatch(.processoAdd(draft))
                selectedProcessID = store.state.processos.last?.id
                activeSheet = nil
            } onCancel: {
                activeSheet = nil
            }
        case let .editProcess(id):
            if let processo = store.state.processo(for: id) {
                ProcessoFormView(title: "Editar ficha", processo: processo) { draft in
                    store.dispatch(.processoUpdate(id: id, patch: ProcessoPatch(draft: draft)))
                    activeSheet = nil
                } onCancel: {
                    activeSheet = nil
                }
            }
        case let .addPrazo(processoID):
            PrazoFormView(title: "Novo prazo", prazo: nil) { prazo in
                store.dispatch(.processoPrazoAdd(processoID: processoID, prazo: prazo))
                activeSheet = nil
            } onDelete: {
                activeSheet = nil
            } onCancel: {
                activeSheet = nil
            }
        case let .editPrazo(processoID, prazoID):
            if let prazo = store.state.processo(for: processoID)?.prazos.first(where: { $0.id == prazoID }) {
                PrazoFormView(title: "Editar prazo", prazo: prazo) { prazo in
                    store.dispatch(.processoPrazoUpdate(processoID: processoID, prazoID: prazoID, prazo: prazo))
                    activeSheet = nil
                } onDelete: {
                    store.dispatch(.processoPrazoDelete(processoID: processoID, prazoID: prazoID))
                    activeSheet = nil
                } onCancel: {
                    activeSheet = nil
                }
            }
        case let .addAndamento(processoID):
            AndamentoFormView(title: "Novo andamento", andamento: nil) { andamento in
                store.dispatch(.processoAndamentoAdd(processoID: processoID, andamento: andamento))
                activeSheet = nil
            } onDelete: {
                activeSheet = nil
            } onCancel: {
                activeSheet = nil
            }
        case let .editAndamento(processoID, andamentoID):
            if let andamento = store.state.processo(for: processoID)?.andamentos.first(where: { $0.id == andamentoID }) {
                AndamentoFormView(title: "Editar andamento", andamento: andamento) { andamento in
                    store.dispatch(.processoAndamentoUpdate(processoID: processoID, andamentoID: andamentoID, andamento: andamento))
                    activeSheet = nil
                } onDelete: {
                    store.dispatch(.processoAndamentoDelete(processoID: processoID, andamentoID: andamentoID))
                    activeSheet = nil
                } onCancel: {
                    activeSheet = nil
                }
            }
        case let .addHonorario(processoID):
            HonorarioFormView(title: "Novo honorário", processos: store.state.processos, initialProcessID: processoID) { drafts in
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

    private func honorarios(for processoID: String) -> [HonorarioItem] {
        store.state.honorarios
            .filter { $0.processoId == processoID }
            .sorted { $0.venc < $1.venc }
    }
}

private enum ProcessoSheet: Identifiable {
    case newProcess
    case editProcess(String)
    case addPrazo(String)
    case editPrazo(String, String)
    case addAndamento(String)
    case editAndamento(String, String)
    case addHonorario(String)
    case receiveHonorario(String)

    var id: String {
        switch self {
        case .newProcess: "new-process"
        case let .editProcess(id): "edit-process-\(id)"
        case let .addPrazo(id): "add-prazo-\(id)"
        case let .editPrazo(processoID, prazoID): "edit-prazo-\(processoID)-\(prazoID)"
        case let .addAndamento(id): "add-andamento-\(id)"
        case let .editAndamento(processoID, andamentoID): "edit-andamento-\(processoID)-\(andamentoID)"
        case let .addHonorario(id): "add-honorario-\(id)"
        case let .receiveHonorario(id): "receive-honorario-\(id)"
        }
    }
}

private struct ProcessosSummary {
    var ativos: Int
    var extrajudiciais: Int
    var proximosAtos: Int
    var honorariosPendentes: Double
    var exitoEstimado: Double

    init(processos: [ProcessoItem], honorarios: [HonorarioItem]) {
        ativos = processos.filter { $0.status == .ativo || $0.status == .acordo }.count
        extrajudiciais = processos.filter { $0.tipoCaso == .extrajudicial }.count
        proximosAtos = processos.reduce(0) { partial, processo in
            partial + processo.prazos.filter { !$0.done }.count
        }
        let processIDs = Set(processos.map(\.id))
        honorariosPendentes = honorarios
            .filter { processIDs.contains($0.processoId) && $0.status != .pago }
            .reduce(0) { $0 + $1.valor }
        exitoEstimado = processos.reduce(0) { partial, processo in
            partial + processo.exitoValorPonderado
        }
    }
}

private struct ProcessoCard: View {
    var processo: ProcessoItem
    var honorarios: [HonorarioItem]
    var selected: Bool
    var action: () -> Void

    private var pendingHonorarios: Double {
        honorarios.filter { $0.status != .pago }.reduce(0) { $0 + $1.valor }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: processo.tipoCaso == .judicial ? "building.columns" : "doc.text")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(selected ? AppTheme.surface : AppTheme.accent)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(selected ? AppTheme.accent : AppTheme.accent.opacity(0.10)))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(processo.displayTitle)
                            .font(AppTypography.body(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(2)
                        Text(processo.partiesLine)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(2)
                    }
                    Spacer()
                    StatusPill(text: processo.prioridade.rawValue, tone: processo.priorityTone)
                }

                HStack(spacing: 8) {
                    StatusPill(text: processo.tipoCaso.label, tone: AppTheme.accent)
                    StatusPill(text: processo.fase, tone: AppTheme.gold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(processo.numero.isEmpty ? "Sem judicialização" : processo.numero)
                        .font(AppTypography.caption.monospaced())
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(processo.proxAtoDesc.isEmpty ? "Próximo ato não cadastrado" : "\(AppFormatting.shortDate(processo.proxAto)) · \(processo.proxAtoDesc)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                HStack {
                    Label(AppFormatting.currency(processo.valorCausa), systemImage: "sum")
                    Spacer()
                    Label(AppFormatting.currency(pendingHonorarios), systemImage: "banknote")
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                    .fill(selected ? AppTheme.accent.opacity(0.08) : AppTheme.surface.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                    .stroke(selected ? AppTheme.accent.opacity(0.45) : AppTheme.stroke.opacity(0.34), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ProcessoDetailPane: View {
    var processo: ProcessoItem
    var honorarios: [HonorarioItem]
    var onEditProcess: () -> Void
    var onAddPrazo: () -> Void
    var onEditPrazo: (ProcessoPrazo) -> Void
    var onAddAndamento: () -> Void
    var onEditAndamento: (ProcessoAndamento) -> Void
    var onAddHonorario: () -> Void
    var onReceiveHonorario: (HonorarioItem) -> Void
    var onReopenHonorario: (HonorarioItem) -> Void

    private var honorariosPendentes: Double {
        honorarios.filter { $0.status != .pago }.reduce(0) { $0 + $1.valor }
    }

    private var honorariosPagos: Double {
        honorarios.filter { $0.status == .pago }.reduce(0) { $0 + $1.valor }
    }

    private var exitoEstimado: Double {
        processo.exitoValorHonorariosEstimado
    }

    var body: some View {
        CaesarPanel(padding: 24) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(processo.tipoCaso.label.uppercased())
                            .font(AppTypography.eyebrow)
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.mutedText)
                        Text(processo.displayTitle)
                            .font(AppTypography.display(size: 24, weight: .semibold))
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(2)
                        Text(processo.partiesLine)
                            .font(AppTypography.body(size: 13, weight: .regular))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        StatusPill(text: processo.status.rawValue.capitalized, tone: processo.statusTone, filled: true)
                        SecondaryGlassButton(title: "Editar ficha", systemImage: "pencil", action: onEditProcess)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
                    MetricCard(title: "Valor da causa", value: AppFormatting.currency(processo.valorCausa), subtitle: processo.area, compact: true)
                    MetricCard(title: "Honorários pendentes", value: AppFormatting.currency(honorariosPendentes), subtitle: "\(honorarios.count) lançamento(s)", tone: AppTheme.warning, compact: true)
                    MetricCard(title: "Honorários pagos", value: AppFormatting.currency(honorariosPagos), subtitle: "Realizado", tone: AppTheme.success, compact: true)
                    MetricCard(title: "Êxito", value: AppFormatting.currency(exitoEstimado), subtitle: "\(AppFormatting.percent(processo.exitoPercentual)) sobre \(processo.exitoBaseLabel)", tone: AppTheme.gold, compact: true)
                }

                ProcessoFichaSection(processo: processo)

                ProcessoTextSection(title: "Resumo do caso", content: processo.resumo, placeholder: "Sem resumo cadastrado.")
                ProcessoTextSection(title: "Resumo da inicial ou narrativa base", content: processo.resumoInicial, placeholder: "Sem resumo da inicial cadastrado.")
                ProcessoTextSection(title: "Tese, riscos e estratégia", content: processo.strategyLine, placeholder: "Sem estratégia cadastrada.")

                if !processo.pedidos.isEmpty {
                    ProcessoListSection(title: "Pedidos e objetivos", items: processo.pedidos)
                }

                HStack(alignment: .top, spacing: 16) {
                    ProcessoPrazosSection(prazos: processo.prazos, onAdd: onAddPrazo, onEdit: onEditPrazo)
                    ProcessoAndamentosSection(andamentos: processo.andamentos, onAdd: onAddAndamento, onEdit: onEditAndamento)
                }

                ProcessoHonorariosSection(
                    honorarios: honorarios,
                    onAdd: onAddHonorario,
                    onReceive: onReceiveHonorario,
                    onReopen: onReopenHonorario
                )
            }
        }
    }
}

private struct ProcessoFichaSection: View {
    var processo: ProcessoItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(eyebrow: "Ficha", title: "Dados do caso")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                FichaField(label: "CNJ", value: processo.numero.isEmpty ? "Sem judicialização" : processo.numero)
                FichaField(label: "Órgão julgador", value: processo.orgaoJulgador)
                FichaField(label: "Comarca", value: processo.comarca)
                FichaField(label: "Vara", value: processo.vara)
                FichaField(label: "Tribunal", value: processo.tribunal)
                FichaField(label: "Distribuição", value: processo.dataDistribuicao.isEmpty ? "Não informada" : AppFormatting.shortDate(processo.dataDistribuicao))
                FichaField(label: "Área", value: processo.area)
                FichaField(label: "Fase", value: processo.fase)
                FichaField(label: "Representando", value: processo.representationLine)
                FichaField(label: "Próximo ato", value: processo.proxAtoDesc.isEmpty ? "Não cadastrado" : "\(AppFormatting.shortDate(processo.proxAto)) · \(processo.proxAtoDesc)")
                FichaField(label: "Base do êxito", value: "\(processo.exitoBaseLabel) · \(AppFormatting.currency(processo.exitoBaseValor))")
                FichaField(label: "Honorário de êxito", value: "\(AppFormatting.percent(processo.exitoPercentual)) · estimado \(AppFormatting.currency(processo.exitoValorHonorariosEstimado))")
                FichaField(label: "Chance de êxito", value: "\(AppFormatting.percent(processo.exitoChancePercentual)) · faixa \(processo.exitoProbabilidade.rawValue.capitalized)")
                FichaField(label: "Prazo do êxito", value: processo.exitoPrazo)
            }
        }
    }
}

private struct FichaField: View {
    var label: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(AppTypography.eyebrow)
                .tracking(1.1)
                .foregroundStyle(AppTheme.mutedText)
            Text(value.isEmpty ? "Não informado" : value)
                .font(AppTypography.body(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.text)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                .fill(AppTheme.elevated.opacity(0.7))
        )
    }
}

private struct ProcessoTextSection: View {
    var title: String
    var content: String
    var placeholder: String

    var bodyView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.body(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.text)
            Text(content.isEmpty ? placeholder : content)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(content.isEmpty ? AppTheme.mutedText : AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View { bodyView }
}

private struct ProcessoListSection: View {
    var title: String
    var items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.body(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.text)
            ForEach(items, id: \.self) { item in
                Label(item, systemImage: "checkmark.circle")
                    .font(AppTypography.body(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}

private struct ProcessoPrazosSection: View {
    var prazos: [ProcessoPrazo]
    var onAdd: () -> Void
    var onEdit: (ProcessoPrazo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(eyebrow: "Prazos", title: "Agenda jurídica") {
                InlineActionButton("Adicionar", systemImage: "calendar.badge.plus", action: onAdd)
            }
            if prazos.isEmpty {
                Text("Nenhum prazo cadastrado.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.mutedText)
            } else {
                ForEach(prazos.sorted { $0.date < $1.date }) { prazo in
                    Button { onEdit(prazo) } label: {
                        RowShell {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prazo.title)
                                    .font(AppTypography.body(size: 13, weight: .medium))
                                    .foregroundStyle(AppTheme.text)
                                Text(prazo.notes.isEmpty ? AppFormatting.shortDate(prazo.date) : "\(AppFormatting.shortDate(prazo.date)) · \(prazo.notes)")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .lineLimit(2)
                            }
                            Spacer()
                            StatusPill(text: prazo.type.rawValue)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct ProcessoAndamentosSection: View {
    var andamentos: [ProcessoAndamento]
    var onAdd: () -> Void
    var onEdit: (ProcessoAndamento) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(eyebrow: "Andamentos", title: "Histórico") {
                InlineActionButton("Adicionar", systemImage: "text.badge.plus", action: onAdd)
            }
            if andamentos.isEmpty {
                Text("Nenhum andamento registrado.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.mutedText)
            } else {
                ForEach(andamentos) { andamento in
                    Button { onEdit(andamento) } label: {
                        RowShell {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(andamento.title)
                                    .font(AppTypography.body(size: 13, weight: .medium))
                                    .foregroundStyle(AppTheme.text)
                                Text("\(AppFormatting.shortDate(andamento.date)) \(andamento.time) · \(andamento.summary)")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .lineLimit(3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct ProcessoHonorariosSection: View {
    var honorarios: [HonorarioItem]
    var onAdd: () -> Void
    var onReceive: (HonorarioItem) -> Void
    var onReopen: (HonorarioItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(eyebrow: "Honorários", title: "Valores vinculados") {
                InlineActionButton("Novo", systemImage: "banknote", action: onAdd)
            }

            if honorarios.isEmpty {
                Text("Nenhum honorário vinculado a este processo.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.mutedText)
            } else {
                ForEach(honorarios) { honorario in
                    let effectiveStatus = honorario.effectiveStatus()
                    RowShell {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(honorario.tipo)
                                .font(AppTypography.body(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.text)
                            Text(effectiveStatus == .pago ? "Recebido em \(AppFormatting.shortDate(honorario.dataRecebimento ?? ""))" : "Vence em \(AppFormatting.shortDate(honorario.venc))")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        Text(AppFormatting.currency(honorario.valor))
                            .font(AppTypography.body(size: 13, weight: .semibold).monospacedDigit())
                            .foregroundStyle(AppTheme.text)
                        StatusPill(text: effectiveStatus.label, tone: effectiveStatus == .pago ? AppTheme.success : (effectiveStatus == .atrasado ? AppTheme.danger : AppTheme.warning))
                        if effectiveStatus == .pago {
                            InlineActionButton("Reabrir", systemImage: "arrow.uturn.backward", action: {
                                onReopen(honorario)
                            })
                        } else {
                            InlineActionButton("Receber", systemImage: "checkmark.circle", action: {
                                onReceive(honorario)
                            })
                        }
                    }
                }
            }
        }
    }
}

private struct ProcessoFormView: View {
    var title: String
    var processo: ProcessoItem?
    var onSave: (ProcessoDraft) -> Void
    var onCancel: () -> Void

    @State private var model: ProcessoFormModel

    init(title: String, processo: ProcessoItem?, onSave: @escaping (ProcessoDraft) -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.processo = processo
        self.onSave = onSave
        self.onCancel = onCancel
        _model = State(initialValue: ProcessoFormModel(processo: processo))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(title)
                    .font(AppTypography.display(size: 24, weight: .semibold))
                    .foregroundStyle(AppTheme.text)

                FormGrid {
                    LabeledField("Título da ação", text: $model.tituloAcao)
                    LabeledField("Cliente principal", text: $model.cliente)
                    LabeledField("Número CNJ", text: $model.numero)
                    LabeledField("Parte contrária", text: $model.parteContraria)
                    LabeledField("Parte que represento", text: $model.parteRepresentada)
                    LabeledField("Área", text: $model.area)
                    LabeledField("Fase", text: $model.fase)
                    LabeledField("Órgão julgador", text: $model.orgaoJulgador)
                    LabeledField("Comarca", text: $model.comarca)
                    LabeledField("Vara", text: $model.vara)
                    LabeledField("Tribunal", text: $model.tribunal)
                    LabeledField("Distribuição", text: $model.dataDistribuicao)
                    LabeledField("Próximo ato", text: $model.proxAtoDesc)
                    LabeledField("Data do próximo ato", text: $model.proxAto)
                    LabeledField("Valor da causa", text: $model.valorCausa)
                    LabeledField("Honorário de êxito %", text: $model.exitoPercentual)
                    LabeledField("Chance de êxito %", text: $model.exitoChancePercentual)
                    LabeledField("Prazo do êxito", text: $model.exitoPrazo)
                    LabeledField("Valor da condenação estimado", text: $model.exitoValorCondenacaoEstimado)
                    LabeledField("Proveito econômico estimado", text: $model.exitoProveitoEconomicoEstimado)
                    LabeledField("Valor do acordo estimado", text: $model.exitoValorAcordoEstimado)
                    LabeledField("Rótulo da base personalizada", text: $model.exitoBasePersonalizadaRotulo)
                    LabeledField("Valor da base personalizada", text: $model.exitoBasePersonalizadaValor)
                }

                HStack(spacing: 12) {
                    Picker("Tipo", selection: $model.tipoCaso) {
                        ForEach(ProcessoTipo.allCases) { tipo in
                            Text(tipo.label).tag(tipo)
                        }
                    }
                    Picker("Polo representado", selection: $model.poloRepresentado) {
                        ForEach(ProcessoRepresentacaoPolo.allCases) { polo in
                            Text(polo.label).tag(polo)
                        }
                    }
                    Picker("Status", selection: $model.status) {
                        ForEach(ProcessoStatus.allCases) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                    Picker("Prioridade", selection: $model.prioridade) {
                        ForEach(ProcessoPrioridade.allCases) { prioridade in
                            Text(prioridade.rawValue.capitalized).tag(prioridade)
                        }
                    }
                    Picker("Probabilidade", selection: $model.exitoProbabilidade) {
                        ForEach(SuccessProbability.allCases) { probabilidade in
                            Text(probabilidade.rawValue.capitalized).tag(probabilidade)
                        }
                    }
                    Picker("Base do êxito", selection: $model.exitoBaseCalculo) {
                        ForEach(ExitoBaseCalculo.allCases) { base in
                            Text(base.label).tag(base)
                        }
                    }
                }
                .pickerStyle(.menu)

                LabeledTextEditor("Autores ou requerentes, um por linha", text: $model.autores)
                LabeledTextEditor("Réus ou parte contrária, um por linha", text: $model.reus)
                LabeledTextEditor("Resumo do caso", text: $model.resumo)
                LabeledTextEditor("Resumo da inicial ou narrativa base", text: $model.resumoInicial)
                LabeledTextEditor("Tese principal", text: $model.tesePrincipal)
                LabeledTextEditor("Pedidos e objetivos, um por linha", text: $model.pedidos)
                LabeledTextEditor("Riscos", text: $model.riscos)
                LabeledTextEditor("Estratégia", text: $model.estrategia)
                LabeledTextEditor("Resultado esperado", text: $model.resultadoEsperado)
                LabeledTextEditor("Observações internas", text: $model.observacoes)

                HStack {
                    SecondaryGlassButton(title: "Cancelar", systemImage: "xmark", action: onCancel)
                    Spacer()
                    PrimaryGlassButton(title: "Salvar ficha", systemImage: "checkmark") {
                        onSave(model.draft())
                    }
                }
            }
            .padding(24)
        }
        .frame(minWidth: 760, minHeight: 760)
        .background(AppTheme.background)
    }
}

private struct PrazoFormView: View {
    var title: String
    var prazo: ProcessoPrazo?
    var onSave: (ProcessoPrazo) -> Void
    var onDelete: () -> Void
    var onCancel: () -> Void

    @State private var formTitle: String
    @State private var date: String
    @State private var notes: String
    @State private var type: ProcessoAtoTipo
    @State private var done: Bool

    init(title: String, prazo: ProcessoPrazo?, onSave: @escaping (ProcessoPrazo) -> Void, onDelete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.prazo = prazo
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        _formTitle = State(initialValue: prazo?.title ?? "")
        _date = State(initialValue: prazo?.date ?? AppFormatting.isoDate(Date()))
        _notes = State(initialValue: prazo?.notes ?? "")
        _type = State(initialValue: prazo?.type ?? .prazo)
        _done = State(initialValue: prazo?.done ?? false)
    }

    var body: some View {
        SheetFormShell(title: title) {
            LabeledField("Título", text: $formTitle)
            LabeledField("Data", text: $date)
            Picker("Tipo", selection: $type) {
                ForEach(ProcessoAtoTipo.allCases) { item in
                    Text(item.rawValue.capitalized).tag(item)
                }
            }
            Toggle("Concluído", isOn: $done)
            LabeledTextEditor("Notas", text: $notes)
        } footer: {
            if prazo != nil {
                InlineActionButton("Excluir", systemImage: "trash", role: .destructive, action: onDelete)
            }
            Spacer()
            SecondaryGlassButton(title: "Cancelar", systemImage: "xmark", action: onCancel)
            PrimaryGlassButton(title: "Salvar", systemImage: "checkmark") {
                onSave(ProcessoPrazo(id: prazo?.id ?? UUID().uuidString, title: formTitle, date: date, type: type, done: done, notes: notes))
            }
        }
    }
}

private struct AndamentoFormView: View {
    var title: String
    var andamento: ProcessoAndamento?
    var onSave: (ProcessoAndamento) -> Void
    var onDelete: () -> Void
    var onCancel: () -> Void

    @State private var date: String
    @State private var time: String
    @State private var formTitle: String
    @State private var summary: String
    @State private var type: ProcessoAtoTipo

    init(title: String, andamento: ProcessoAndamento?, onSave: @escaping (ProcessoAndamento) -> Void, onDelete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.andamento = andamento
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        _date = State(initialValue: andamento?.date ?? AppFormatting.isoDate(Date()))
        _time = State(initialValue: andamento?.time ?? "")
        _formTitle = State(initialValue: andamento?.title ?? "")
        _summary = State(initialValue: andamento?.summary ?? "")
        _type = State(initialValue: andamento?.type ?? .observacao)
    }

    var body: some View {
        SheetFormShell(title: title) {
            LabeledField("Título", text: $formTitle)
            LabeledField("Data", text: $date)
            LabeledField("Horário", text: $time)
            Picker("Tipo", selection: $type) {
                ForEach(ProcessoAtoTipo.allCases) { item in
                    Text(item.rawValue.capitalized).tag(item)
                }
            }
            LabeledTextEditor("Resumo", text: $summary)
        } footer: {
            if andamento != nil {
                InlineActionButton("Excluir", systemImage: "trash", role: .destructive, action: onDelete)
            }
            Spacer()
            SecondaryGlassButton(title: "Cancelar", systemImage: "xmark", action: onCancel)
            PrimaryGlassButton(title: "Salvar", systemImage: "checkmark") {
                onSave(ProcessoAndamento(id: andamento?.id ?? UUID().uuidString, date: date, time: time, title: formTitle, summary: summary, type: type))
            }
        }
    }
}

private struct SheetFormShell<Content: View, Footer: View>: View {
    var title: String
    var content: Content
    var footer: Footer

    init(title: String, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.title = title
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(AppTypography.display(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.text)
            content
            HStack(spacing: 12) { footer }
        }
        .padding(24)
        .frame(minWidth: 520)
        .background(AppTheme.background)
    }
}

private struct FormGrid<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            content
        }
    }
}

private struct LabeledField: View {
    var label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        _text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(AppTypography.eyebrow)
                .tracking(1.1)
                .foregroundStyle(AppTheme.mutedText)
            TextField(label, text: $text)
                .textFieldStyle(.plain)
                .font(AppTypography.body(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                        .fill(AppTheme.elevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                        .stroke(AppTheme.stroke, lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LabeledTextEditor: View {
    var label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        _text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(AppTypography.eyebrow)
                .tracking(1.1)
                .foregroundStyle(AppTheme.mutedText)
            TextEditor(text: $text)
                .font(AppTypography.body(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.text)
                .frame(minHeight: 74)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                        .fill(AppTheme.elevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                        .stroke(AppTheme.stroke, lineWidth: 1)
                )
        }
    }
}

private struct ProcessoFormModel {
    var numero = ""
    var tituloAcao = ""
    var cliente = ""
    var autores = ""
    var parteContraria = ""
    var reus = ""
    var parteRepresentada = ""
    var poloRepresentado: ProcessoRepresentacaoPolo = .autor
    var tipoCaso: ProcessoTipo = .judicial
    var area = "Cível"
    var fase = "Inicial"
    var status: ProcessoStatus = .ativo
    var prioridade: ProcessoPrioridade = .media
    var orgaoJulgador = ""
    var comarca = ""
    var vara = ""
    var tribunal = ""
    var dataDistribuicao = ""
    var proxAto = AppFormatting.isoDate(Date())
    var proxAtoDesc = ""
    var valorCausa = "0"
    var exitoPercentual = "0"
    var exitoChancePercentual = "50"
    var exitoProbabilidade: SuccessProbability = .media
    var exitoPrazo = ""
    var exitoBaseCalculo: ExitoBaseCalculo = .valorCausa
    var exitoValorCondenacaoEstimado = "0"
    var exitoProveitoEconomicoEstimado = "0"
    var exitoValorAcordoEstimado = "0"
    var exitoBasePersonalizadaRotulo = ""
    var exitoBasePersonalizadaValor = "0"
    var resumo = ""
    var resumoInicial = ""
    var tesePrincipal = ""
    var pedidos = ""
    var riscos = ""
    var estrategia = ""
    var resultadoEsperado = ""
    var observacoes = ""

    init() {}

    init(processo: ProcessoItem?) {
        guard let processo else { return }
        numero = processo.numero
        tituloAcao = processo.tituloAcao
        cliente = processo.cliente
        autores = processo.autores.joined(separator: "\n")
        parteContraria = processo.parteContraria
        reus = processo.reus.joined(separator: "\n")
        parteRepresentada = processo.parteRepresentada
        poloRepresentado = processo.poloRepresentado
        tipoCaso = processo.tipoCaso
        area = processo.area
        fase = processo.fase
        status = processo.status
        prioridade = processo.prioridade
        orgaoJulgador = processo.orgaoJulgador
        comarca = processo.comarca
        vara = processo.vara
        tribunal = processo.tribunal
        dataDistribuicao = processo.dataDistribuicao
        proxAto = processo.proxAto
        proxAtoDesc = processo.proxAtoDesc
        valorCausa = decimalText(processo.valorCausa)
        exitoPercentual = decimalText(processo.exitoPercentual)
        exitoChancePercentual = decimalText(processo.exitoChancePercentual)
        exitoProbabilidade = processo.exitoProbabilidade
        exitoPrazo = processo.exitoPrazo
        exitoBaseCalculo = processo.exitoBaseCalculo
        exitoValorCondenacaoEstimado = decimalText(processo.exitoValorCondenacaoEstimado)
        exitoProveitoEconomicoEstimado = decimalText(processo.exitoProveitoEconomicoEstimado)
        exitoValorAcordoEstimado = decimalText(processo.exitoValorAcordoEstimado)
        exitoBasePersonalizadaRotulo = processo.exitoBasePersonalizadaRotulo
        exitoBasePersonalizadaValor = decimalText(processo.exitoBasePersonalizadaValor)
        resumo = processo.resumo
        resumoInicial = processo.resumoInicial
        tesePrincipal = processo.tesePrincipal
        pedidos = processo.pedidos.joined(separator: "\n")
        riscos = processo.riscos
        estrategia = processo.estrategia
        resultadoEsperado = processo.resultadoEsperado
        observacoes = processo.observacoes
    }

    func draft() -> ProcessoDraft {
        ProcessoDraft(
            numero: numero,
            tituloAcao: tituloAcao,
            cliente: cliente.isEmpty ? "Cliente sem nome" : cliente,
            autores: lineItems(autores),
            parteContraria: parteContraria,
            reus: lineItems(reus),
            parteRepresentada: representedPartyName(),
            poloRepresentado: poloRepresentado,
            tipoCaso: tipoCaso,
            area: area.isEmpty ? "Geral" : area,
            fase: fase.isEmpty ? "Inicial" : fase,
            status: status,
            prioridade: prioridade,
            orgaoJulgador: orgaoJulgador,
            comarca: comarca,
            vara: vara,
            tribunal: tribunal,
            dataDistribuicao: dataDistribuicao,
            proxAto: proxAto,
            proxAtoDesc: proxAtoDesc,
            valorCausa: parseDecimal(valorCausa),
            exitoPercentual: parseDecimal(exitoPercentual),
            exitoChancePercentual: parseDecimal(exitoChancePercentual),
            exitoProbabilidade: exitoProbabilidade,
            exitoPrazo: exitoPrazo,
            exitoBaseCalculo: exitoBaseCalculo,
            exitoValorCondenacaoEstimado: parseDecimal(exitoValorCondenacaoEstimado),
            exitoProveitoEconomicoEstimado: parseDecimal(exitoProveitoEconomicoEstimado),
            exitoValorAcordoEstimado: parseDecimal(exitoValorAcordoEstimado),
            exitoBasePersonalizadaRotulo: exitoBasePersonalizadaRotulo,
            exitoBasePersonalizadaValor: parseDecimal(exitoBasePersonalizadaValor),
            resumo: resumo,
            resumoInicial: resumoInicial,
            tesePrincipal: tesePrincipal,
            pedidos: lineItems(pedidos),
            riscos: riscos,
            estrategia: estrategia,
            resultadoEsperado: resultadoEsperado,
            observacoes: observacoes
        )
    }

    private func representedPartyName() -> String {
        let explicit = parteRepresentada.trimmingCharacters(in: .whitespacesAndNewlines)
        if !explicit.isEmpty { return explicit }

        switch poloRepresentado {
        case .autor:
            return lineItems(autores).first ?? cliente
        case .reu:
            return lineItems(reus).first ?? parteContraria
        case .terceiro:
            return ""
        }
    }
}

private extension ProcessoPatch {
    init(draft: ProcessoDraft) {
        self.init(
            numero: draft.numero,
            tituloAcao: draft.tituloAcao,
            cliente: draft.cliente,
            autores: draft.autores,
            parteContraria: draft.parteContraria,
            reus: draft.reus,
            parteRepresentada: draft.parteRepresentada,
            poloRepresentado: draft.poloRepresentado,
            tipoCaso: draft.tipoCaso,
            area: draft.area,
            fase: draft.fase,
            status: draft.status,
            prioridade: draft.prioridade,
            orgaoJulgador: draft.orgaoJulgador,
            comarca: draft.comarca,
            vara: draft.vara,
            tribunal: draft.tribunal,
            dataDistribuicao: draft.dataDistribuicao,
            proxAto: draft.proxAto,
            proxAtoDesc: draft.proxAtoDesc,
            valorCausa: draft.valorCausa,
            exitoPercentual: draft.exitoPercentual,
            exitoChancePercentual: draft.exitoChancePercentual,
            exitoProbabilidade: draft.exitoProbabilidade,
            exitoPrazo: draft.exitoPrazo,
            exitoBaseCalculo: draft.exitoBaseCalculo,
            exitoValorCondenacaoEstimado: draft.exitoValorCondenacaoEstimado,
            exitoProveitoEconomicoEstimado: draft.exitoProveitoEconomicoEstimado,
            exitoValorAcordoEstimado: draft.exitoValorAcordoEstimado,
            exitoBasePersonalizadaRotulo: draft.exitoBasePersonalizadaRotulo,
            exitoBasePersonalizadaValor: draft.exitoBasePersonalizadaValor,
            resumo: draft.resumo,
            resumoInicial: draft.resumoInicial,
            tesePrincipal: draft.tesePrincipal,
            pedidos: draft.pedidos,
            riscos: draft.riscos,
            estrategia: draft.estrategia,
            resultadoEsperado: draft.resultadoEsperado,
            observacoes: draft.observacoes
        )
    }
}

extension ProcessoItem {
    var displayTitle: String {
        if !tituloAcao.isEmpty { return tituloAcao }
        return cliente.isEmpty ? "Processo sem título" : cliente
    }

    var primaryAuthors: [String] {
        let explicit = autores.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if !explicit.isEmpty { return explicit }
        let fallback = cliente.trimmingCharacters(in: .whitespacesAndNewlines)
        return fallback.isEmpty ? [] : [fallback]
    }

    var primaryAuthorsLine: String {
        primaryAuthors.joined(separator: ", ")
    }

    var partiesLine: String {
        let activeAuthors = primaryAuthors
        let activeReus = reus.isEmpty ? [parteContraria].filter { !$0.isEmpty } : reus
        let left = activeAuthors.isEmpty ? "Autor não informado" : activeAuthors.joined(separator: ", ")
        let right = activeReus.isEmpty ? "parte contrária não informada" : activeReus.joined(separator: ", ")
        return "\(left) x \(right)"
    }

    var representationLine: String {
        let represented = parteRepresentada.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !represented.isEmpty else { return "Não informado" }
        return "\(represented) • \(poloRepresentado.label)"
    }

    var strategyLine: String {
        [
            tesePrincipal.isEmpty ? "" : "Tese: \(tesePrincipal)",
            riscos.isEmpty ? "" : "Riscos: \(riscos)",
            estrategia.isEmpty ? "" : "Estratégia: \(estrategia)",
            resultadoEsperado.isEmpty ? "" : "Resultado esperado: \(resultadoEsperado)"
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    }

    var priorityTone: Color {
        switch prioridade {
        case .critica: AppTheme.danger
        case .alta: AppTheme.warning
        case .media: AppTheme.accent
        case .baixa: AppTheme.secondaryText
        }
    }

    var statusTone: Color {
        switch status {
        case .ativo: AppTheme.accent
        case .acordo: AppTheme.success
        case .suspenso: AppTheme.warning
        case .encerrado: AppTheme.secondaryText
        }
    }
}

private func lineItems(_ text: String) -> [String] {
    text
        .split(whereSeparator: \.isNewline)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}

private func parseDecimal(_ value: String) -> Double {
    let normalized = value
        .replacingOccurrences(of: "R$", with: "")
        .replacingOccurrences(of: ".", with: "")
        .replacingOccurrences(of: ",", with: ".")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return Double(normalized) ?? 0
}

private func decimalText(_ value: Double) -> String {
    value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : "\(value)"
}

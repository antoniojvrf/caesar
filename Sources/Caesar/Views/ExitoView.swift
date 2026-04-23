import CaesarCore
import SwiftUI

struct ExitoView: View {
    @ObservedObject var store: AppStore
    @State private var editingProcessID: String?

    private var cases: [ExitoCase] {
        AppSelectors.exitoCases(for: store.state)
    }

    private var totalBruto: Double {
        cases.reduce(0) { $0 + $1.valorBrutoEstimado }
    }

    private var totalHonorarios: Double {
        cases.reduce(0) { $0 + $1.valorEstimado }
    }

    private var totalPonderado: Double {
        cases.reduce(0) { $0 + $1.valorPonderado }
    }

    var body: some View {
        ModuleScroll {
            VStack(alignment: .leading, spacing: 24) {
                summaryGrid
                filterBar

                HStack(alignment: .lastTextBaseline) {
                    Text("Casos previstos")
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Text("\(cases.count) resultado(s)")
                        .font(AppTypography.body(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(cases) { item in
                        ExitoCaseCard(item: item) {
                            editingProcessID = item.id
                        }
                    }
                }
            }
        }
        .sheet(isPresented: Binding(get: { editingProcessID != nil }, set: { if !$0 { editingProcessID = nil } })) {
            Group {
                if let processID = editingProcessID,
                   let processo = store.state.processos.first(where: { $0.id == processID }) {
                    ExitoQuickEditSheet(processo: processo) { patch in
                        store.dispatch(.processoUpdate(id: processID, patch: patch))
                        editingProcessID = nil
                    } onCancel: {
                        editingProcessID = nil
                    }
                } else {
                    EmptyView()
                }
            }
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
            MetricCard(title: "Base bruta", value: AppFormatting.currency(totalBruto), subtitle: "Somatório das bases escolhidas", tone: AppTheme.accent)
            MetricCard(title: "Honorários estimados", value: AppFormatting.currency(totalHonorarios), subtitle: "Percentual sobre a base", tone: AppTheme.gold)
            MetricCard(title: "Pipeline ponderado", value: AppFormatting.currency(totalPonderado), subtitle: "Aplicando chance de êxito", tone: AppTheme.success)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            FilterPill("Ordenação", icon: "chevron.down")
            FilterPill("Área", icon: "chevron.down")
            FilterPill("Probabilidade", icon: "chevron.down")
            FilterPill("Base", icon: "chevron.down")
            FilterPill("Prazo", icon: "chevron.down")
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(AppTheme.elevated)
        )
    }
}

private struct FilterPill: View {
    var title: String
    var icon: String

    init(_ title: String, icon: String) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
        }
        .font(AppTypography.body(size: 12, weight: .bold))
        .foregroundStyle(AppTheme.secondaryText)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black.opacity(0.055))
        )
    }
}

private struct ExitoCaseCard: View {
    var item: ExitoCase
    var onEdit: () -> Void

    var body: some View {
        CaesarPanel(padding: 22, interactive: true) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.caso)
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(2)
                        Text(item.processoReferencia)
                            .font(AppTypography.body(size: 13, weight: .bold).monospaced())
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer()

                    StatusPill(text: item.probabilidade.rawValue.capitalized, tone: tone(for: item.probabilidade))
                }

                HStack(spacing: 8) {
                    StatusPill(text: item.area, tone: AppTheme.accent)
                    StatusPill(text: item.baseLabel, tone: AppTheme.gold)
                    StatusPill(text: item.prazoEstimado.isEmpty ? "Sem prazo" : item.prazoEstimado, tone: AppTheme.success)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Honorários estimados")
                        .font(AppTypography.body(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(AppFormatting.currency(item.valorEstimado))
                        .font(AppTypography.display(size: 31, weight: .bold))
                        .foregroundStyle(AppTheme.success)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                    ExitoMetricChip(title: "Valor bruto", value: AppFormatting.currency(item.valorBrutoEstimado))
                    ExitoMetricChip(title: "Percentual", value: AppFormatting.percent(item.percentual))
                    ExitoMetricChip(title: "Chance", value: AppFormatting.percent(item.chancePercentual))
                    ExitoMetricChip(title: "Ponderado", value: AppFormatting.currency(item.valorPonderado))
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Chance de êxito")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                        Text(AppFormatting.percent(item.chancePercentual))
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    MiniBar(value: item.chancePercentual / 100, maxValue: 1, tone: tone(for: item.probabilidade))
                }

                HStack(spacing: 10) {
                    PrimaryGlassButton(title: "Editar êxito", systemImage: "square.and.pencil", action: onEdit)
                }
            }
        }
    }

    private func tone(for probability: SuccessProbability) -> Color {
        switch probability {
        case .alta: AppTheme.success
        case .media: AppTheme.warning
        case .baixa: AppTheme.danger
        }
    }
}

private struct ExitoMetricChip: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(AppTypography.eyebrow)
                .tracking(1)
                .foregroundStyle(AppTheme.mutedText)
            Text(value)
                .font(AppTypography.body(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                .fill(AppTheme.surface.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall, style: .continuous)
                .stroke(AppTheme.stroke.opacity(0.38), lineWidth: 1)
        )
    }
}

private struct ExitoQuickEditSheet: View {
    var processo: ProcessoItem
    var onSave: (ProcessoPatch) -> Void
    var onCancel: () -> Void

    @State private var percentual: String
    @State private var chance: String
    @State private var probabilidade: SuccessProbability
    @State private var prazo: String
    @State private var baseCalculo: ExitoBaseCalculo
    @State private var valorCondenacao: String
    @State private var proveitoEconomico: String
    @State private var valorAcordo: String
    @State private var basePersonalizadaRotulo: String
    @State private var basePersonalizadaValor: String

    init(processo: ProcessoItem, onSave: @escaping (ProcessoPatch) -> Void, onCancel: @escaping () -> Void) {
        self.processo = processo
        self.onSave = onSave
        self.onCancel = onCancel
        _percentual = State(initialValue: exitoDecimalText(processo.exitoPercentual))
        _chance = State(initialValue: exitoDecimalText(processo.exitoChancePercentual))
        _probabilidade = State(initialValue: processo.exitoProbabilidade)
        _prazo = State(initialValue: processo.exitoPrazo)
        _baseCalculo = State(initialValue: processo.exitoBaseCalculo)
        _valorCondenacao = State(initialValue: exitoDecimalText(processo.exitoValorCondenacaoEstimado))
        _proveitoEconomico = State(initialValue: exitoDecimalText(processo.exitoProveitoEconomicoEstimado))
        _valorAcordo = State(initialValue: exitoDecimalText(processo.exitoValorAcordoEstimado))
        _basePersonalizadaRotulo = State(initialValue: processo.exitoBasePersonalizadaRotulo)
        _basePersonalizadaValor = State(initialValue: exitoDecimalText(processo.exitoBasePersonalizadaValor))
    }

    private var valorBaseSelecionada: Double {
        switch baseCalculo {
        case .valorCausa:
            return processo.valorCausa
        case .valorCondenacao:
            return exitoParseDecimal(valorCondenacao)
        case .proveitoEconomico:
            return exitoParseDecimal(proveitoEconomico)
        case .valorAcordo:
            return exitoParseDecimal(valorAcordo)
        case .personalizada:
            return exitoParseDecimal(basePersonalizadaValor)
        }
    }

    private var honorarioEstimado: Double {
        valorBaseSelecionada * exitoParseDecimal(percentual) / 100
    }

    private var ponderado: Double {
        honorarioEstimado * exitoParseDecimal(chance) / 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Editar êxito previsto")
                .font(AppTypography.display(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.text)

            Text(processo.displayTitle)
                .font(AppTypography.body(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)

            ExitoFormGrid {
                ExitoLabeledField("Honorário de êxito %", text: $percentual)
                ExitoLabeledField("Chance de êxito %", text: $chance)
                ExitoLabeledField("Prazo do êxito", text: $prazo)
                ExitoLabeledField("Valor da condenação estimado", text: $valorCondenacao)
                ExitoLabeledField("Proveito econômico estimado", text: $proveitoEconomico)
                ExitoLabeledField("Valor do acordo estimado", text: $valorAcordo)
                ExitoLabeledField("Rótulo da base personalizada", text: $basePersonalizadaRotulo)
                ExitoLabeledField("Valor da base personalizada", text: $basePersonalizadaValor)
            }

            HStack(spacing: 12) {
                Picker("Faixa", selection: $probabilidade) {
                    ForEach(SuccessProbability.allCases) { item in
                        Text(item.rawValue.capitalized).tag(item)
                    }
                }
                Picker("Base", selection: $baseCalculo) {
                    ForEach(ExitoBaseCalculo.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
            }
            .pickerStyle(.menu)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ExitoMetricChip(title: "Base atual", value: AppFormatting.currency(valorBaseSelecionada))
                ExitoMetricChip(title: "Honorários", value: AppFormatting.currency(honorarioEstimado))
                ExitoMetricChip(title: "Ponderado", value: AppFormatting.currency(ponderado))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Barra de chance")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Text(AppFormatting.percent(exitoParseDecimal(chance)))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                MiniBar(value: min(max(exitoParseDecimal(chance) / 100, 0), 1), maxValue: 1, tone: color(for: probabilidade))
            }

            HStack {
                SecondaryGlassButton(title: "Cancelar", systemImage: "xmark", action: onCancel)
                Spacer()
                PrimaryGlassButton(title: "Salvar ajustes", systemImage: "checkmark") {
                    onSave(
                        ProcessoPatch(
                            exitoPercentual: exitoParseDecimal(percentual),
                            exitoChancePercentual: exitoParseDecimal(chance),
                            exitoProbabilidade: probabilidade,
                            exitoPrazo: prazo,
                            exitoBaseCalculo: baseCalculo,
                            exitoValorCondenacaoEstimado: exitoParseDecimal(valorCondenacao),
                            exitoProveitoEconomicoEstimado: exitoParseDecimal(proveitoEconomico),
                            exitoValorAcordoEstimado: exitoParseDecimal(valorAcordo),
                            exitoBasePersonalizadaRotulo: basePersonalizadaRotulo,
                            exitoBasePersonalizadaValor: exitoParseDecimal(basePersonalizadaValor)
                        )
                    )
                }
            }
        }
        .padding(24)
        .frame(minWidth: 760)
        .background(AppTheme.background)
    }

    private func color(for probability: SuccessProbability) -> Color {
        switch probability {
        case .alta: AppTheme.success
        case .media: AppTheme.warning
        case .baixa: AppTheme.danger
        }
    }
}

private struct ExitoFormGrid<Content: View>: View {
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

private struct ExitoLabeledField: View {
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
    }
}

private func exitoParseDecimal(_ value: String) -> Double {
    let normalized = value
        .replacingOccurrences(of: ".", with: "")
        .replacingOccurrences(of: ",", with: ".")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return Double(normalized) ?? 0
}

private func exitoDecimalText(_ value: Double) -> String {
    if value.rounded() == value {
        return String(Int(value))
    }
    return value.formatted(.number.precision(.fractionLength(0 ... 2)))
}

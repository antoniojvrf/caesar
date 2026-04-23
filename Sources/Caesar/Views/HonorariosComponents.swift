import CaesarCore
import SwiftUI

struct HonorarioFormView: View {
    var title: String
    var processos: [ProcessoItem]
    var initialProcessID: String?
    var onSave: ([HonorarioDraft]) -> Void
    var onCancel: () -> Void

    @State private var processoId: String
    @State private var descricao = ""
    @State private var vencimento = AppFormatting.isoDate(Date())
    @State private var valor = ""
    @State private var launchType: HonorarioLaunchType = .parcelaUnica
    @State private var parcelas = "2"
    @State private var notes = ""

    init(title: String, processos: [ProcessoItem], initialProcessID: String? = nil, onSave: @escaping ([HonorarioDraft]) -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.processos = processos.sorted { $0.displayTitle < $1.displayTitle }
        self.initialProcessID = initialProcessID
        self.onSave = onSave
        self.onCancel = onCancel
        _processoId = State(initialValue: initialProcessID ?? processos.sorted { $0.displayTitle < $1.displayTitle }.first?.id ?? "")
    }

    private var processoSelecionado: ProcessoItem? {
        processos.first { $0.id == processoId }
    }

    private var valorNumerico: Double? {
        parseDecimal(valor)
    }

    private var quantidadeParcelas: Int {
        max(2, Int(parcelas) ?? 2)
    }

    private var totalParcelado: Double {
        guard let valorNumerico else { return 0 }
        return valorNumerico * Double(quantidadeParcelas)
    }

    private var canSave: Bool {
        guard processoSelecionado != nil else { return false }
        guard !descricao.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard AppDateValidation.normalizedISODate(vencimento) != nil else { return false }
        guard let valorNumerico, valorNumerico > 0 else { return false }
        if launchType == .parcelado {
            return quantidadeParcelas >= 2
        }
        return true
    }

    var body: some View {
        HonorarioSheetShell(title: title) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PROCESSO".uppercased())
                        .font(AppTypography.eyebrow)
                        .tracking(1.1)
                        .foregroundStyle(AppTheme.mutedText)
                    Picker("Processo", selection: $processoId) {
                        ForEach(processos) { processo in
                            Text(processo.displayTitle).tag(processo.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let processoSelecionado {
                    CaesarPanel(padding: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(processoSelecionado.displayTitle)
                                .font(AppTypography.body(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.text)
                            Text(processoSelecionado.numero.isEmpty ? processoSelecionado.tipoCaso.label : processoSelecionado.numero)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            if !processoSelecionado.primaryAuthorsLine.isEmpty {
                                Text("Autores: \(processoSelecionado.primaryAuthorsLine)")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            if !processoSelecionado.parteRepresentada.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("Representando \(processoSelecionado.parteRepresentada) • \(processoSelecionado.poloRepresentado.label)")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Text("\(processoSelecionado.area) • \(processoSelecionado.fase)")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }

                HonorarioFormGrid {
                    HonorarioLabeledField("Descrição do honorário", text: $descricao)
                    HonorarioLabeledField(launchType == .parcelado ? "Primeiro vencimento" : "Vencimento", text: $vencimento)
                    HonorarioLabeledField(launchType == .parcelado ? "Valor da parcela" : "Valor", text: $valor)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("MODALIDADE".uppercased())
                            .font(AppTypography.eyebrow)
                            .tracking(1.1)
                            .foregroundStyle(AppTheme.mutedText)
                        Picker("Modalidade", selection: $launchType) {
                            ForEach(HonorarioLaunchType.allCases) { type in
                                Text(type.label).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                if launchType == .parcelado {
                    HonorarioFormGrid {
                        HonorarioLabeledField("Quantidade de parcelas", text: $parcelas)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PROJEÇÃO".uppercased())
                                .font(AppTypography.eyebrow)
                                .tracking(1.1)
                                .foregroundStyle(AppTheme.mutedText)
                            CaesarPanel(padding: 14) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(quantidadeParcelas) parcelas de \(AppFormatting.currency(valorNumerico ?? 0))")
                                        .font(AppTypography.body(size: 13, weight: .semibold))
                                        .foregroundStyle(AppTheme.text)
                                    Text("Total previsto: \(AppFormatting.currency(totalParcelado))")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                        }
                    }
                }

                HonorarioLabeledTextEditor("Observações internas (opcional)", text: $notes)
            }
        } footer: {
            SecondaryGlassButton(title: "Cancelar", systemImage: "xmark", action: onCancel)
            Spacer()
            PrimaryGlassButton(title: launchType == .parcelado ? "Gerar parcelas" : "Salvar honorário", systemImage: "checkmark") {
                guard let drafts = makeDrafts() else { return }
                onSave(drafts)
            }
        }
        .frame(minWidth: 620)
        .disabled(processos.isEmpty)
    }

    private func makeDrafts() -> [HonorarioDraft]? {
        guard let processoSelecionado else { return nil }
        guard let vencimentoBase = AppDateValidation.normalizedISODate(vencimento),
              let valorNumerico,
              valorNumerico > 0 else { return nil }

        let descricaoFinal = descricao.trimmingCharacters(in: .whitespacesAndNewlines)
        let observacao = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let processoRef = processoSelecionado.numero.isEmpty ? processoSelecionado.tipoCaso.label : String(processoSelecionado.numero.prefix(14))

        if launchType == .parcelado {
            return (0..<quantidadeParcelas).map { index in
                HonorarioDraft(
                    processoId: processoSelecionado.id,
                    cliente: processoSelecionado.cliente,
                    processo: processoRef,
                    tipo: descricaoFinal,
                    venc: AppFormatting.addingMonths(index, toISODate: vencimentoBase),
                    valor: valorNumerico,
                    launchType: .parcelado,
                    parcelaIndice: index + 1,
                    parcelaTotal: quantidadeParcelas,
                    notes: observacao
                )
            }
        }

        return [
            HonorarioDraft(
                processoId: processoSelecionado.id,
                cliente: processoSelecionado.cliente,
                processo: processoRef,
                tipo: descricaoFinal,
                venc: vencimentoBase,
                valor: valorNumerico,
                launchType: launchType,
                notes: observacao
            )
        ]
    }
}

struct HonorarioRecebimentoView: View {
    var honorario: HonorarioItem
    var onSave: (String, HonorarioReceiptMethod, String) -> Void
    var onCancel: () -> Void

    @State private var receivedAt = AppFormatting.isoDate(Date())
    @State private var method: HonorarioReceiptMethod = .pix
    @State private var note = ""

    private var canSave: Bool {
        AppDateValidation.normalizedISODate(receivedAt) != nil
    }

    var body: some View {
        HonorarioSheetShell(title: "Registrar recebimento") {
            VStack(alignment: .leading, spacing: 16) {
                CaesarPanel(padding: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(honorario.cliente)
                            .font(AppTypography.body(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.text)
                        Text(honorario.tipo)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("Valor: \(AppFormatting.currency(honorario.valor))")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                HonorarioFormGrid {
                    HonorarioLabeledField("Data de recebimento", text: $receivedAt)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("TIPO DE RECEBIMENTO".uppercased())
                            .font(AppTypography.eyebrow)
                            .tracking(1.1)
                            .foregroundStyle(AppTheme.mutedText)
                        Picker("Tipo de recebimento", selection: $method) {
                            ForEach(HonorarioReceiptMethod.allCases) { item in
                                Text(item.label).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HonorarioLabeledTextEditor("Observação opcional do recebimento", text: $note)
                    Text("\(note.count)/200")
                        .font(AppTypography.caption)
                        .foregroundStyle(note.count > 200 ? AppTheme.danger : AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        } footer: {
            SecondaryGlassButton(title: "Cancelar", systemImage: "xmark", action: onCancel)
            Spacer()
            PrimaryGlassButton(title: "Confirmar recebimento", systemImage: "checkmark.circle") {
                guard canSave else { return }
                onSave(receivedAt, method, String(note.prefix(200)))
            }
        }
        .frame(minWidth: 560)
        .onChange(of: note) { _, newValue in
            if newValue.count > 200 {
                note = String(newValue.prefix(200))
            }
        }
    }
}

private struct HonorarioSheetShell<Content: View, Footer: View>: View {
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
            HStack(spacing: 12) {
                footer
            }
        }
        .padding(24)
        .background(AppTheme.background)
    }
}

private struct HonorarioFormGrid<Content: View>: View {
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

private struct HonorarioLabeledField: View {
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

private struct HonorarioLabeledTextEditor: View {
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
                .frame(minHeight: 84)
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

private func parseDecimal(_ text: String) -> Double? {
    let normalized = text
        .replacingOccurrences(of: "R$", with: "")
        .replacingOccurrences(of: ".", with: "")
        .replacingOccurrences(of: ",", with: ".")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return Double(normalized)
}

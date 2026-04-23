import CaesarCore
import SwiftUI

struct ContatosView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        ModuleScroll {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(eyebrow: "", title: "Contatos do workspace") {
                    StatusPill(text: "\(store.state.contatos.count) contato(s)", tone: AppTheme.accent)
                }

                CaesarPanel(padding: 22) {
                    VStack(alignment: .leading, spacing: 12) {
                        if store.state.contatos.isEmpty {
                            Text("Nenhum contato cadastrado ainda.")
                                .font(AppTypography.bodyRegular)
                                .foregroundStyle(AppTheme.secondaryText)
                        } else {
                            ForEach(store.state.contatos) { contato in
                                RowShell {
                                    Image(systemName: symbol(for: contato.entityType))
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(AppTheme.accent)
                                        .frame(width: 30, height: 30)
                                        .background(Circle().fill(AppPalette.softBlue))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(contato.name)
                                            .font(AppTypography.body(size: 14, weight: .bold))
                                            .foregroundStyle(AppTheme.text)
                                        Text(detail(for: contato))
                                            .font(AppTypography.caption)
                                            .foregroundStyle(AppTheme.secondaryText)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    StatusPill(text: roleLabel(contato.role), tone: AppTheme.success)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func detail(for contato: ContatoItem) -> String {
        [contato.email, contato.phone, contato.document]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private func roleLabel(_ role: ContactRole) -> String {
        switch role {
        case .cliente: "Cliente"
        case .parteContraria: "Parte contrária"
        case .advogado: "Advogado"
        case .testemunha: "Testemunha"
        case .juizo: "Juízo"
        case .outro: "Outro"
        }
    }

    private func symbol(for type: ContactEntityType) -> String {
        switch type {
        case .pessoaFisica: "person"
        case .pessoaJuridica: "building.2"
        case .escritorio: "briefcase"
        case .orgaoJudicial: "building.columns"
        case .outro: "person.crop.circle"
        }
    }
}

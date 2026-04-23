import CaesarCore
import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        ModuleScroll {
            let finance = AppSelectors.financasSummary(for: store.state)
            let upcomingAccounts = store.state.boletos
                .filter { $0.status != .pago }
                .sorted { $0.dueDate < $1.dueDate }
            let upcomingTasks = store.state.allTasks
                .filter { !$0.dueDate.isEmpty }
                .sorted { $0.dueDate < $1.dueDate }
            let upcomingActs = store.state.processos
                .filter { !$0.proxAto.isEmpty }
                .sorted { $0.proxAto < $1.proxAto }

            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(eyebrow: "", title: "Snapshot do workspace local")

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    MetricCard(title: "Metas ativas", value: "\(store.state.metas.count)", subtitle: "", tone: AppTheme.accent)
                    MetricCard(title: "Contas pendentes", value: "\(upcomingAccounts.count)", subtitle: "", tone: AppTheme.warning)
                    MetricCard(title: "Processos ativos", value: "\(store.state.processos.filter { $0.status == .ativo }.count)", subtitle: "", tone: AppTheme.success)
                    MetricCard(title: "Saldo projetado", value: AppFormatting.currency(finance.saldoFinal), subtitle: "", tone: AppTheme.success)
                }

                HStack(alignment: .top, spacing: 16) {
                    DashboardListPanel(title: "Próximos vencimentos") {
                        ForEach(upcomingAccounts.prefix(4)) { boleto in
                            DashboardValueRow(
                                title: boleto.desc,
                                subtitle: "Vence em \(AppFormatting.shortDate(boleto.dueDate))",
                                value: AppFormatting.currency(boleto.value)
                            )
                        }
                    }

                    DashboardListPanel(title: "Tarefas até hoje") {
                        ForEach(upcomingTasks.prefix(3)) { task in
                            DashboardValueRow(
                                title: task.title,
                                subtitle: task.tag,
                                value: AppFormatting.shortDate(task.dueDate)
                            )
                        }
                    }
                }

                DashboardListPanel(title: "Próximos atos jurídicos") {
                    ForEach(upcomingActs.prefix(5)) { processo in
                        DashboardValueRow(
                            title: processo.cliente,
                            subtitle: processo.proxAtoDesc.isEmpty ? processo.numero : processo.proxAtoDesc,
                            value: AppFormatting.shortDate(processo.proxAto)
                        )
                    }
                }
            }
        }
    }
}

private struct DashboardListPanel<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        CaesarPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppTheme.text)

                VStack(spacing: 0) {
                    content
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DashboardValueRow: View {
    var title: String
    var subtitle: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(AppTypography.body(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                Text(subtitle)
                    .font(AppTypography.body(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Text(value)
                .font(AppTypography.body(size: 14, weight: .bold).monospacedDigit())
                .foregroundStyle(AppTheme.text)
        }
        .padding(.vertical, 11)
    }
}

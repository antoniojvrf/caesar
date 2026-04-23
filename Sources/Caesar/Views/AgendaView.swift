import CaesarCore
import SwiftUI

struct AgendaView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        ModuleScroll {
            let buckets = AppSelectors.agendaSections(for: store.state)
            let overdue = buckets.first { $0.id == "atrasados" }?.items ?? []
            let today = buckets.first { $0.id == "hoje" }?.items ?? []
            let nextSeven = buckets.first { $0.id == "proximos" }?.items ?? []
            let openAccounts = nextSeven.filter { $0.kind == .boleto }.reduce(0) { $0 + ($1.amount ?? 0) }
            let allItems = buckets.flatMap(\.items)

            VStack(alignment: .leading, spacing: 24) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    AgendaSummaryCard(icon: "calendar.badge.clock", title: "Itens na agenda", value: "\(allItems.count)", subtitle: "Consolidação do workspace", tone: AppTheme.accent)
                    AgendaSummaryCard(icon: "calendar.badge.exclamationmark", title: "Atrasados", value: "\(overdue.count)", subtitle: "Precisam de ação primeiro", tone: AppTheme.danger)
                    AgendaSummaryCard(icon: "calendar", title: "Hoje", value: "\(today.count)", subtitle: "vencimentos do dia", tone: AppTheme.warning)
                    AgendaSummaryCard(icon: "calendar.badge.plus", title: "Contas em aberto", value: AppFormatting.currency(openAccounts), subtitle: "\(nextSeven.filter { $0.kind == .boleto }.count) item(ns) nos próximos 7 dias", tone: AppTheme.success)
                }

                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Fila de execução")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppTheme.text)
                        Text("Tarefas, contas e prazos processuais reunidos na mesma leitura")
                            .font(AppTypography.body(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Text("Atualizado agora")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                ForEach(buckets) { bucket in
                    AgendaBucketPanel(bucket: bucket, store: store)
                }
            }
        }
    }
}

private struct AgendaSummaryCard: View {
    var icon: String
    var title: String
    var value: String
    var subtitle: String
    var tone: Color

    var body: some View {
        CaesarPanel(padding: 20) {
            VStack(alignment: .leading, spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tone)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tone.opacity(0.12))
                    )
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(value)
                    .font(AppTypography.metricValue)
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct AgendaBucketPanel: View {
    var bucket: AgendaBucket
    @ObservedObject var store: AppStore

    var body: some View {
        CaesarPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(bucket.title)
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Text("\(bucket.items.count) item(ns)")
                        .font(AppTypography.body(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(.bottom, 12)

                if bucket.items.isEmpty {
                    Text("Nada nesta faixa.")
                        .font(AppTypography.bodyRegular)
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.vertical, 10)
                } else {
                    ForEach(bucket.items) { item in
                        AgendaQueueRow(item: item, store: store)
                        if item.id != bucket.items.last?.id {
                            Divider().overlay(AppTheme.stroke.opacity(0.65))
                        }
                    }
                }
            }
        }
    }
}

private struct AgendaQueueRow: View {
    var item: AgendaItem
    @ObservedObject var store: AppStore

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: symbol(for: item.kind))
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(tone(for: item.kind))
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tone(for: item.kind).opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 9) {
                    Text(item.title)
                        .font(AppTypography.body(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.text)
                    StatusPill(text: label(for: item.kind), tone: AppTheme.secondaryText)
                }

                Text(relativeLabel(for: item.date))
                    .font(AppTypography.body(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)

                HStack(spacing: 12) {
                    Label(AppFormatting.fullDateFormatter.string(from: AppFormatting.date(fromISO: item.date) ?? Date()), systemImage: "calendar")
                    Text(item.subtitle)
                    if let amount = item.amount {
                        Text(AppFormatting.currency(amount))
                            .foregroundStyle(AppTheme.text)
                    }
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            VStack(spacing: 10) {
                PrimaryGlassButton(title: primaryAction(for: item.kind), systemImage: nil) {
                    if item.kind == .boleto,
                       item.id.hasPrefix("boleto-") {
                        let boletoID = String(item.id.dropFirst("boleto-".count))
                        store.dispatch(.boletoUpdateStatus(id: boletoID, status: .pago))
                    }
                }
                SecondaryGlassButton(title: "Ir para board", systemImage: nil) {}
            }
            .frame(width: 128)
        }
        .padding(.vertical, 15)
    }

    private func symbol(for kind: AgendaItemKind) -> String {
        switch kind {
        case .tarefa: "checklist"
        case .boleto: "creditcard"
        case .prazoProcessual: "briefcase"
        case .honorario: "banknote"
        }
    }

    private func label(for kind: AgendaItemKind) -> String {
        switch kind {
        case .tarefa: "Tarefa"
        case .boleto: "Conta"
        case .prazoProcessual: "Prazo"
        case .honorario: "Honorário"
        }
    }

    private func primaryAction(for kind: AgendaItemKind) -> String {
        switch kind {
        case .tarefa: "Abrir tarefas"
        case .boleto: "Marcar pago"
        case .prazoProcessual: "Abrir processo"
        case .honorario: "Abrir honorários"
        }
    }

    private func tone(for kind: AgendaItemKind) -> Color {
        switch kind {
        case .tarefa: AppTheme.accent
        case .boleto: AppTheme.success
        case .prazoProcessual: AppTheme.warning
        case .honorario: AppTheme.gold
        }
    }

    private func relativeLabel(for iso: String) -> String {
        guard let date = AppFormatting.date(fromISO: iso) else { return iso }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Hoje" }
        if date < calendar.startOfDay(for: Date()) { return "Hoje" }
        return "Próximos 7 dias"
    }
}

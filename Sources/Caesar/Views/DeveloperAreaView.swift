import CaesarCore
import SwiftUI

struct DeveloperAreaView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case producao = "Produção"
        case caixa = "Caixa"
        case sketchbook = "Sketchbook"
        case novidades = "Novidades"
        var id: String { rawValue }
    }

    @ObservedObject var store: AppStore
    @State private var tab: Tab = .dashboard

    init(store: AppStore, initialTab: Tab = .dashboard) {
        self.store = store
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        ModuleScroll {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(eyebrow: "System", title: "Área do developer")

                Picker("Developer", selection: $tab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 520)

                switch tab {
                case .dashboard:
                    dashboard
                case .producao:
                    producao
                case .caixa:
                    caixa
                case .sketchbook:
                    sketchbook
                case .novidades:
                    novidades
                }
            }
        }
    }

    private var dashboard: some View {
        let finance = AppSelectors.developerFinance(for: store.state)
        return VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                MetricCard(title: "Projetos", value: "\(store.state.developer.projects.count)", subtitle: "Em carteira")
                MetricCard(title: "Pendente", value: AppFormatting.currency(finance.pending), subtitle: "Caixa developer", tone: AppTheme.warning)
                MetricCard(title: "Recebido", value: AppFormatting.currency(finance.paid), subtitle: "Realizado", tone: AppTheme.success)
                MetricCard(title: "Ideias", value: "\(store.state.developer.ideas.count)", subtitle: "Sketchbook")
            }
            novidades
        }
    }

    private var producao: some View {
        CaesarPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(eyebrow: "Pipeline", title: "Produção") {
                    PrimaryGlassButton(title: "Novo projeto", systemImage: "plus") {
                        store.dispatch(.developerProjectAdd(DeveloperProject(name: "Novo projeto", client: "Cliente", status: .discovery, nextStep: "Definir escopo")))
                    }
                }

                ForEach(store.state.developer.projects) { project in
                    RowShell {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.name)
                                .font(AppTypography.body(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.text)
                            Text("\(project.client) • \(project.nextStep)")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        StatusPill(text: project.status.rawValue)
                        MiniBar(value: Double(project.progress), maxValue: 100, tone: AppTheme.success)
                            .frame(width: 90)
                    }
                }
            }
        }
    }

    private var caixa: some View {
        CaesarPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(eyebrow: "Receivables", title: "Caixa") {
                    PrimaryGlassButton(title: "Nova cobrança", systemImage: "plus") {
                        store.dispatch(.developerReceivableAdd(DeveloperReceivableDraft(client: "Cliente", description: "Nova cobrança", dueDate: AppFormatting.isoDate(Date()), value: 0)))
                    }
                }

                ForEach(store.state.developer.receivables.sorted { $0.dueDate < $1.dueDate }) { receivable in
                    RowShell {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(receivable.description)
                                .font(AppTypography.body(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.text)
                            Text("\(receivable.client) • \(receivable.installmentLabel)")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        Text(AppFormatting.currency(receivable.value))
                            .font(AppTypography.body(size: 13, weight: .medium).monospacedDigit())
                            .foregroundStyle(AppTheme.text)
                        StatusPill(text: receivable.status.label, tone: receivable.status == .paid ? AppTheme.success : AppTheme.warning)
                        Button {
                            store.dispatch(.developerReceivableUpdateStatus(id: receivable.id, status: receivable.status == .paid ? .pending : .paid))
                        } label: {
                            Image(systemName: receivable.status == .paid ? "arrow.uturn.backward.circle" : "checkmark.circle")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var sketchbook: some View {
        CaesarPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(eyebrow: "Ideas", title: "Sketchbook") {
                    PrimaryGlassButton(title: "Nova ideia", systemImage: "plus") {
                        store.dispatch(.developerIdeaAdd(DeveloperIdea(title: "Nova ideia", body: "Descrever oportunidade.")))
                    }
                }

                ForEach(store.state.developer.ideas) { idea in
                    RowShell {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(idea.title)
                                .font(AppTypography.body(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.text)
                            Text(idea.body)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        ForEach(idea.tags.prefix(2), id: \.self) { tag in
                            StatusPill(text: tag)
                        }
                    }
                }
            }
        }
    }

    private var novidades: some View {
        CaesarPanel(padding: 22) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(eyebrow: "Changelog", title: "Novidades")

                ForEach(store.state.developer.updates) { update in
                    RowShell {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(update.title)
                                .font(AppTypography.body(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.text)
                            Text(update.body)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        StatusPill(text: AppFormatting.shortDate(update.date))
                    }
                }
            }
        }
    }
}

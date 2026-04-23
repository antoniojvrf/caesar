import CaesarCore
import SwiftUI

struct TarefasKanbanView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        ModuleScroll {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(eyebrow: "Operations", title: "Kanban") {
                    PrimaryGlassButton(title: "Nova tarefa", systemImage: "plus") {
                        store.dispatch(.taskAdd(columnID: "hoje", draft: TaskDraft(title: "Nova tarefa", priority: .media, tag: "Geral", dueDate: AppFormatting.isoDate(Date()))))
                    }
                }

                HStack(alignment: .top, spacing: 16) {
                    ForEach(AppState.taskColumnOrder, id: \.self) { columnID in
                        CaesarPanel(padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(store.state.tarefas[columnID]?.name ?? columnID)
                                        .font(AppTypography.sectionTitle)
                                        .foregroundStyle(AppTheme.text)
                                    Spacer()
                                    StatusPill(text: "\(store.state.tasks(in: columnID).count)", tone: AppTheme.accent, filled: true)
                                }

                                ForEach(store.state.tasks(in: columnID)) { task in
                                    RowShell {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(task.title)
                                                .font(AppTypography.body(size: 13, weight: .semibold))
                                                .foregroundStyle(AppTheme.text)
                                            Text([task.tag, task.goal].filter { !$0.isEmpty }.joined(separator: " • "))
                                                .font(AppTypography.caption)
                                                .foregroundStyle(AppTheme.secondaryText)
                                            if !task.dueDate.isEmpty {
                                                Text(AppFormatting.shortDate(task.dueDate))
                                                    .font(AppTypography.body(size: 10, weight: .regular))
                                                    .foregroundStyle(AppTheme.mutedText)
                                            }
                                        }
                                        Spacer()
                                        StatusPill(text: task.priority.label, tone: tone(for: task.priority))
                                        Menu {
                                            Button("Mover para Hoje") { move(task, from: columnID, to: "hoje") }
                                            Button("Mover para Semana") { move(task, from: columnID, to: "semana") }
                                            Button("Mover para Próximas") { move(task, from: columnID, to: "proximas") }
                                            Divider()
                                            Button("Excluir", role: .destructive) { store.dispatch(.taskDelete(columnID: columnID, taskID: task.id)) }
                                        } label: {
                                            Image(systemName: "ellipsis.circle")
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundStyle(AppTheme.secondaryText)
                                        }
                                        .menuStyle(.button)
                                        .buttonStyle(.plain)
                                    }
                                }

                                if store.state.tasks(in: columnID).isEmpty {
                                    EmptyModuleState(
                                        title: "Coluna vazia",
                                        subtitle: "Crie ou mova tarefas para cá.",
                                        systemImage: "square.dashed"
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func move(_ task: TaskItem, from: String, to: String) {
        store.dispatch(.taskMove(fromColumnID: from, taskID: task.id, toColumnID: to))
    }

    private func tone(for priority: TaskPriority) -> Color {
        switch priority {
        case .alta: AppTheme.danger
        case .media: AppTheme.warning
        case .baixa: AppTheme.secondaryText
        }
    }
}

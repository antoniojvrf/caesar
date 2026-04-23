import CaesarCore
import SwiftUI

struct CategoriasView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        ModuleScroll {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(eyebrow: "Operations", title: "Taxonomia") {
                    PrimaryGlassButton(title: "Nova categoria", systemImage: "plus") {
                        store.dispatch(.categoriaAdd(CategoryDraft(name: "Nova categoria", color: "#737373")))
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                    ForEach(store.state.categorias) { category in
                        CaesarPanel(padding: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color(hex: category.color))
                                        .frame(width: 12, height: 12)
                                    Text(category.name)
                                        .font(AppTypography.sectionTitle)
                                        .foregroundStyle(AppTheme.text)
                                    Spacer()
                                    if category.recurring {
                                        StatusPill(text: "Recorrente", tone: AppTheme.gold)
                                    }
                                }

                                let accountCount = store.state.boletos.filter { $0.categoriaId == category.id }.count
                                let taskCount = store.state.allTasks.filter { $0.categoriaId == category.id || $0.tag == category.name }.count
                                Text("\(accountCount) contas • \(taskCount) tarefas relacionadas")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppTheme.secondaryText)

                                InlineActionButton("Excluir", systemImage: "trash", role: .destructive) {
                                    store.dispatch(.categoriaDelete(id: category.id))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

import CaesarCore
import SwiftUI

struct MetasDashboardView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        ModuleScroll {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(eyebrow: "Finance", title: "Metas") {
                    PrimaryGlassButton(title: "Nova meta", systemImage: "plus") {
                        store.dispatch(.metaAdd(GoalDraft(title: "Nova meta", type: .financeira, current: 0, target: 10_000, deadline: "Dez 2026")))
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(store.state.metas) { goal in
                        CaesarPanel(padding: 22) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(goal.type.label.uppercased())
                                            .font(AppTypography.eyebrow)
                                            .tracking(1.4)
                                            .foregroundStyle(AppTheme.mutedText)
                                        Text(goal.title)
                                            .font(AppTypography.sectionTitle)
                                            .foregroundStyle(AppTheme.text)
                                    }
                                    Spacer()
                                    StatusPill(text: "\(store.state.goalProgress(for: goal))%", tone: AppTheme.success, filled: true)
                                }

                                MiniBar(value: Double(store.state.goalProgress(for: goal)), maxValue: 100, tone: AppTheme.success)

                                if let target = goal.target {
                                    Text("\(AppFormatting.currency(store.state.goalCurrentValue(for: goal))) de \(AppFormatting.currency(target))")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(goal.milestones) { milestone in
                                        Button {
                                            store.dispatch(.metaMilestoneToggle(metaID: goal.id, milestoneID: milestone.id))
                                        } label: {
                                            HStack(spacing: 8) {
                                                Image(systemName: milestone.done ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 13, weight: .regular))
                                                Text(milestone.label)
                                                    .font(AppTypography.body(size: 12, weight: .regular))
                                                Spacer()
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundStyle(milestone.done ? AppTheme.success : AppTheme.secondaryText)
                                    }
                                }

                                HStack(spacing: 8) {
                                    SecondaryGlassButton(title: "Editar valor", systemImage: "slider.horizontal.3") {
                                        store.dispatch(.metaUpdate(id: goal.id, patch: GoalPatch(current: (goal.current ?? 0) + 500)))
                                    }
                                    InlineActionButton("Excluir", systemImage: "trash", role: .destructive) {
                                        store.dispatch(.metaDelete(id: goal.id))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

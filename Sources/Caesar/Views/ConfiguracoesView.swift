import CaesarCore
import SwiftUI

struct ConfiguracoesView: View {
    @ObservedObject var store: AppStore

    private var useDemoOnNextLaunch: Binding<Bool> {
        Binding(
            get: { store.nextLaunchProfile == .demo },
            set: { enabled in
                store.setNextLaunchProfile(enabled ? .demo : .real)
            }
        )
    }

    var body: some View {
        ModuleScroll {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(eyebrow: "", title: "Workspace local")

                CaesarPanel(padding: 22) {
                    VStack(alignment: .leading, spacing: 14) {
                        RowShell {
                            Label("Perfil atual", systemImage: "externaldrive")
                                .font(AppTypography.body(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.text)
                            Spacer()
                            StatusPill(text: store.session.profile.label, tone: AppTheme.accent)
                        }

                        RowShell {
                            VStack(alignment: .leading, spacing: 5) {
                                Label("Usar dados demo na próxima abertura", systemImage: "switch.2")
                                    .font(AppTypography.body(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.text)
                                Text("Quando marcado, o Caesar inicia com workspace-demo.json; quando desmarcado, inicia com workspace-v1.json.")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Spacer(minLength: 24)
                            Toggle("", isOn: useDemoOnNextLaunch)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }

                        RowShell {
                            Label("Próxima abertura", systemImage: "arrow.clockwise")
                                .font(AppTypography.body(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.text)
                            Spacer()
                            StatusPill(text: store.nextLaunchProfile.label, tone: store.nextLaunchProfile == .demo ? AppTheme.warning : AppTheme.success)
                        }

                        RowShell {
                            Label("Persistência", systemImage: store.canPersist ? "checkmark.seal" : "exclamationmark.triangle")
                                .font(AppTypography.body(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.text)
                            Spacer()
                            StatusPill(text: store.canPersist ? "Ativa" : "Bloqueada", tone: store.canPersist ? AppTheme.success : AppTheme.danger)
                        }

                        if let error = store.session.lastError {
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.danger)
                        }
                    }
                }
            }
        }
    }
}

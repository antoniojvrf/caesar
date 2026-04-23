import CaesarCore
import SwiftUI

enum AppRoute: String, CaseIterable, Identifiable, Hashable {
    case agenda
    case dashboard
    case tarefas
    case metas
    case financas
    case categorias
    case contatos
    case processos
    case honorarios
    case exito
    case developerDashboard
    case developerProducao
    case developerCaixa
    case developerSketchbook
    case developerNovidades
    case configuracoes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .agenda: "Agenda"
        case .dashboard: "Dashboard"
        case .tarefas: "Tarefas"
        case .metas: "Metas"
        case .financas: "Finanças"
        case .categorias: "Categorias"
        case .contatos: "Contatos"
        case .processos: "Processos"
        case .honorarios: "Honorários a Receber"
        case .exito: "Previstos em Êxito"
        case .developerDashboard: "Dashboard"
        case .developerProducao: "Produção"
        case .developerCaixa: "Caixa"
        case .developerSketchbook: "Sketchbook"
        case .developerNovidades: "Novidades"
        case .configuracoes: "Configurações"
        }
    }

    var pageTitle: String {
        switch self {
        case .developerDashboard, .developerProducao, .developerCaixa, .developerSketchbook, .developerNovidades:
            return "Área do Developer"
        default:
            return title
        }
    }

    var subtitle: String {
        switch self {
        case .dashboard: "Resumo consolidado do workspace pessoal e jurídico neste Mac."
        case .agenda: "O que está atrasado, vence hoje ou pede atenção nos próximos 7 dias."
        case .tarefas: "Kanban pessoal e operacional."
        case .metas: "Objetivos, marcos e vínculos financeiros."
        case .financas: "Entradas e saídas pessoais, recorrências, histórico e análise mensal."
        case .categorias: "Taxonomia compartilhada entre tarefas e contas pessoais."
        case .contatos: "Pessoas, empresas e vínculos úteis para a operação jurídica."
        case .processos: "Controle jurídico com prazos, andamentos e contexto."
        case .honorarios: "Contratual, parcelas e recebimentos."
        case .exito: "Pipeline de êxito com projeção comercial e priorização por probabilidade."
        case .developerDashboard: "Produção, caixa, sketchbook e novidades do workspace developer."
        case .developerProducao: "Projetos em carteira e próximos passos."
        case .developerCaixa: "Cobranças, parcelas e recebíveis de desenvolvimento."
        case .developerSketchbook: "Ideias e oportunidades para evoluir produtos."
        case .developerNovidades: "Registro do que mudou no sistema."
        case .configuracoes: "Preferências locais deste Mac."
        }
    }

    var symbol: String {
        switch self {
        case .agenda: "calendar"
        case .dashboard: "square.grid.2x2"
        case .tarefas: "checklist"
        case .metas: "target"
        case .financas: "chart.line.uptrend.xyaxis"
        case .categorias: "tag"
        case .contatos: "person.2"
        case .processos: "briefcase"
        case .honorarios: "banknote"
        case .exito: "trophy"
        case .developerDashboard: "square.grid.2x2"
        case .developerProducao: "cube"
        case .developerCaixa: "banknote"
        case .developerSketchbook: "square.and.pencil"
        case .developerNovidades: "newspaper"
        case .configuracoes: "gearshape"
        }
    }

    var developerTab: DeveloperAreaView.Tab? {
        switch self {
        case .developerDashboard: .dashboard
        case .developerProducao: .producao
        case .developerCaixa: .caixa
        case .developerSketchbook: .sketchbook
        case .developerNovidades: .novidades
        default: nil
        }
    }
}

struct RootView: View {
    @StateObject private var store: AppStore
    @State private var route: AppRoute = .agenda

    init(store: AppStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        Group {
            if store.session.isAuthenticated {
                WorkspaceShell(store: store, route: $route)
            } else {
                LoginView(store: store)
            }
        }
        .background(AppTheme.background)
        .overlay(alignment: .top) {
            WindowZoomTapZone()
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .padding(.leading, 140)
        }
    }
}

// MARK: - Login

private struct LoginView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var store: AppStore
    @State private var didEnter = false
    @State private var markBreathes = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                loginMark
                    .opacity(didEnter ? 1 : 0)
                    .scaleEffect(didEnter ? 1 : 0.92)
                    .offset(y: didEnter ? 0 : 14)

                loginCopy
                    .opacity(didEnter ? 1 : 0)
                    .offset(y: didEnter ? 0 : 10)

                unlockControls
                    .opacity(didEnter ? 1 : 0)
                    .offset(y: didEnter ? 0 : 8)
            }
            .padding(40)
        }
        .onAppear {
            playIntro()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            playIntro()
        }
    }

    private var loginMark: some View {
        Image("AppMark", bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: 146, height: 146)
            .scaleEffect(markBreathes ? 1.018 : 1.0)
            .shadow(color: AppTheme.shadowLift.opacity(0.95), radius: 24, x: 0, y: 16)
            .shadow(color: AppTheme.accent.opacity(markBreathes ? 0.10 : 0.04), radius: 34, x: 0, y: 10)
    }

    private var loginCopy: some View {
        VStack(spacing: 9) {
            Text(AppBrand.name)
                .font(AppTypography.brandTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.text, AppPalette.graphite, AppTheme.text.opacity(0.84)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .tracking(0.8)
                .shadow(color: Color.white.opacity(0.72), radius: 0, x: 0, y: 1)
                .frame(maxWidth: 440)
                .fixedSize(horizontal: false, vertical: true)

            Text(AppBrand.tagline)
                .font(AppTypography.brandSubtitle)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: 720)
        }
        .frame(maxWidth: .infinity)
    }

    private var unlockControls: some View {
        VStack(spacing: 13) {
            PrimaryGlassButton(title: "Desbloquear", systemImage: "lock.open") {
                Task { await store.unlock(reason: "Desbloquear o Caesar") }
            }
            .keyboardShortcut(.return, modifiers: [])

            HStack(spacing: 6) {
                Image(systemName: "return")
                    .font(.system(size: 11, weight: .semibold))
                Text("Pressione Return")
                    .font(AppTypography.caption)
            }
            .foregroundStyle(AppTheme.mutedText)

            if let error = store.session.lastError {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.danger)
            }
        }
    }

    private func playIntro() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            didEnter = false
            markBreathes = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.smooth(duration: 0.72)) {
                didEnter = true
            }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                markBreathes = true
            }
        }
    }
}

// MARK: - Workspace shell

private struct WorkspaceShell: View {
    @ObservedObject var store: AppStore
    @Binding var route: AppRoute
    @State private var displayMode: DisplayMode = .light
    @Namespace private var navNamespace

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 228)

            VStack(spacing: 0) {
                HeaderBar(route: route, store: store, displayMode: $displayMode)
                content
                    .id(route)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 8)),
                        removal: .opacity
                    ))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)
        }
        .animation(AppMotion.route, value: route)
        .background(AppTheme.background)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Image(systemName: "sidebar.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.horizontal, 18)
            .padding(.top, 54)
            .padding(.bottom, 22)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    navSection(title: "Pessoal", routes: [.agenda, .dashboard, .tarefas, .metas, .financas, .categorias])
                    navSection(title: "Painel do Advogado", routes: [.contatos, .processos, .honorarios, .exito])
                    navSection(title: "Área do Developer", routes: [.developerDashboard, .developerProducao, .developerCaixa, .developerSketchbook, .developerNovidades])
                    navSection(title: "Sistema", routes: [.configuracoes])
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppTheme.sidebarStroke)
                .frame(width: 1)
        }
    }

    @ViewBuilder
    private func navSection(title: String, routes: [AppRoute]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(AppTypography.body(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.mutedText)
                .padding(.horizontal, 4)
                .padding(.bottom, 3)

            ForEach(routes) { item in
                NavRow(item: item, isSelected: route == item, namespace: navNamespace) {
                    withAnimation(AppMotion.route) { route = item }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .dashboard:
            DashboardView(store: store)
        case .agenda:
            AgendaView(store: store)
        case .tarefas:
            TarefasKanbanView(store: store)
        case .metas:
            MetasDashboardView(store: store)
        case .financas:
            FinancasView(store: store)
        case .categorias:
            CategoriasView(store: store)
        case .contatos:
            ContatosView(store: store)
        case .processos:
            ProcessosView(store: store)
        case .honorarios:
            HonorariosView(store: store)
        case .exito:
            ExitoView(store: store)
        case .developerDashboard, .developerProducao, .developerCaixa, .developerSketchbook, .developerNovidades:
            DeveloperAreaView(store: store, initialTab: route.developerTab ?? .dashboard)
        case .configuracoes:
            ConfiguracoesView(store: store)
        }
    }
}

// MARK: - Sidebar row

private struct NavRow: View {
    var item: AppRoute
    var isSelected: Bool
    var namespace: Namespace.ID
    var action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 18)
                    .foregroundStyle(isSelected ? Color.white : AppTheme.text)

                Text(item.title)
                    .font(AppTypography.body(size: 14, weight: .bold))
                    .foregroundStyle(isSelected ? Color.white : AppTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(AppTheme.accent)
                            .matchedGeometryEffect(id: "nav.bg", in: namespace)
                    } else if isHovered {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.white.opacity(0.62))
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AppMotion.selection) { isHovered = hovering }
        }
    }
}

// MARK: - Header bar

private enum DisplayMode: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        case .system: "desktopcomputer"
        }
    }
}

private struct HeaderBar: View {
    var route: AppRoute
    @ObservedObject var store: AppStore
    @Binding var displayMode: DisplayMode

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text(route.pageTitle)
                    .font(AppTypography.pageTitle)
                    .foregroundStyle(AppTheme.text)
                Text(route.subtitle)
                    .font(AppTypography.body(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer(minLength: 20)

            HStack(spacing: 16) {
                Picker("Aparência", selection: $displayMode) {
                    ForEach(DisplayMode.allCases) { mode in
                        Image(systemName: mode.symbol).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 148)

                SecondaryGlassButton(title: "Bloquear", systemImage: nil) {}
            }
        }
        .padding(.leading, 40)
        .padding(.trailing, 40)
        .padding(.top, 86)
        .padding(.bottom, 28)
        .background(AppTheme.background)
    }
}

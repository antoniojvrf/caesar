import CaesarCore
import Foundation
import Testing

@Suite("CaesarCore")
struct CaesarCoreTests {
    @Test
    func taskMovePreservesTaskPayload() {
        var state = AppState.makeEmpty()
        AppReducer.reduce(&state, .taskAdd(columnID: "hoje", draft: TaskDraft(title: "Protocolar petição", priority: .alta, tag: "Processos")))
        let task = state.tasks(in: "hoje").first

        #expect(task?.title == "Protocolar petição")

        AppReducer.reduce(&state, .taskMove(fromColumnID: "hoje", taskID: task?.id ?? "", toColumnID: "semana"))

        #expect(state.tasks(in: "hoje").isEmpty)
        #expect(state.tasks(in: "semana").first?.title == "Protocolar petição")
        #expect(state.tasks(in: "semana").first?.priority == .alta)
    }

    @Test
    func filePersistenceMapsProfilesToSeparateWorkspaceFiles() throws {
        let root = try makeTemporaryDirectory()
        let persistence = FilePersistence(rootDirectory: root)

        #expect(persistence.workspaceURL(for: .real).lastPathComponent == "workspace-v1.json")
        #expect(persistence.workspaceURL(for: .demo).lastPathComponent == "workspace-demo.json")

        var real = AppState.makeEmpty()
        AppReducer.reduce(&real, .categoriaAdd(CategoryDraft(name: "Real")))
        try persistence.save(real, profile: .real)

        var demo = AppState.makeDemo()
        AppReducer.reduce(&demo, .categoriaAdd(CategoryDraft(name: "Demo extra")))
        try persistence.save(demo, profile: .demo)

        #expect(try persistence.load(profile: .real).categorias.contains { $0.name == "Real" })
        #expect(try persistence.load(profile: .demo).categorias.contains { $0.name == "Demo extra" })
    }

    @Test
    func filePersistenceMigratesLegacyWorkspaceIntoCaesarDirectory() throws {
        let root = try makeTemporaryDirectory()
        let legacy = try makeTemporaryDirectory()
        let legacyURL = legacy.appendingPathComponent("workspace-v1.json")
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)

        let legacyState = AppState.makeDemo()
        let data = try JSONEncoder().encode(PersistedWorkspace(profile: .real, state: legacyState))
        try data.write(to: legacyURL)

        let persistence = FilePersistence(rootDirectory: root, legacyRootDirectory: legacy)
        let loaded = try persistence.load(profile: .real)

        #expect(loaded.processos.count == legacyState.processos.count)
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("workspace-v1.json").path))
    }

    @Test
    func existingEmptyRealWorkspaceStaysEmpty() throws {
        let root = try makeTemporaryDirectory()
        let persistence = FilePersistence(rootDirectory: root)
        var emptyReal = AppState.makeEmpty()
        AppReducer.reduce(&emptyReal, .categoriaAdd(CategoryDraft(name: "Custas")))
        try persistence.save(emptyReal, profile: .real)

        let loaded = try persistence.load(profile: .real)
        let reloaded = try persistence.load(profile: .real)

        #expect(loaded.categorias.contains { $0.name == "Custas" })
        #expect(loaded.processos.isEmpty)
        #expect(loaded.honorarios.isEmpty)
        #expect(reloaded.processos.isEmpty)
        #expect(reloaded.honorarios.isEmpty)
    }

    @Test
    func existingEmptyDemoWorkspaceBootstrapsLegalExamplesOnce() throws {
        let root = try makeTemporaryDirectory()
        let persistence = FilePersistence(rootDirectory: root)
        try persistence.save(AppState.makeEmpty(), profile: .demo)

        let loaded = try persistence.load(profile: .demo)
        let reloaded = try persistence.load(profile: .demo)

        #expect(loaded.processos.count == 2)
        #expect(loaded.honorarios.count == 3)
        #expect(loaded.contatos.count == 2)
        #expect(reloaded.processos.count == 2)
        #expect(reloaded.honorarios.count == 3)
    }

    @Test
    @MainActor
    func nextLaunchProfilePreferenceDoesNotMutateCurrentWorkspace() throws {
        let root = try makeTemporaryDirectory()
        let persistence = FilePersistence(rootDirectory: root)
        let preferences = InMemoryWorkspacePreferences(nextLaunchProfile: .real)
        let store = AppStore(persistence: persistence, preferences: preferences)

        store.load()
        store.dispatch(.categoriaAdd(CategoryDraft(name: "Real ativo")))
        store.setNextLaunchProfile(.demo)

        #expect(store.session.profile == .real)
        #expect(store.nextLaunchProfile == .demo)
        #expect(try persistence.load(profile: .real).categorias.contains { $0.name == "Real ativo" })
        #expect(try persistence.load(profile: .demo).categorias.contains { $0.name == "Real ativo" } == false)
    }

    @Test
    @MainActor
    func storeBootsFromPreferredWorkspaceProfile() throws {
        let root = try makeTemporaryDirectory()
        let persistence = FilePersistence(rootDirectory: root)
        let preferences = InMemoryWorkspacePreferences(nextLaunchProfile: .demo)
        let store = AppStore(persistence: persistence, preferences: preferences)

        store.load()

        #expect(store.session.profile == .demo)
        #expect(store.nextLaunchProfile == .demo)
        #expect(FileManager.default.fileExists(atPath: persistence.workspaceURL(for: .demo).path))
        #expect(FileManager.default.fileExists(atPath: persistence.workspaceURL(for: .real).path) == false)
    }

    @Test
    func legacyReactStateDecodesWithNativeDefaults() throws {
        let json = """
        {
          "tarefas": {
            "hoje": { "name": "Hoje", "tasks": [
              { "id": "t1", "title": "Revisar contrato", "priority": "alta", "tag": "Processos", "goal": "", "dueDate": "2026-04-22", "notes": "", "checklist": [{ "text": "Ler inicial", "done": true }], "attachments": [{ "name": "peticao.pdf", "size": "42 KB" }] }
            ] },
            "semana": { "name": "Esta semana", "tasks": [] },
            "proximas": { "name": "Próximas", "tasks": [] }
          },
          "metas": [{ "id": "m1", "title": "Reserva", "type": "financeira", "progress": 10, "current": 1000, "target": 10000, "deadline": "Dez 2026", "milestones": [{ "label": "R$ 1.000", "done": true }] }],
          "categorias": [{ "id": "c1", "name": "Internet", "color": "#525252", "recurring": true }],
          "boletos": [{ "id": "b1", "categoriaId": "c1", "desc": "Mensalidade", "dueDate": "2026-04-22", "value": 129.9, "status": "pendente" }],
          "incomes": [{ "id": "i1", "desc": "Salário", "type": "fixa", "value": 9500 }],
          "monthlyFlow": [],
          "processos": [{ "id": "p1", "numero": "1001234-56.2025.8.26.0100", "cliente": "Silva", "area": "Cível", "fase": "Inicial", "proxAto": "2026-04-30", "proxAtoDesc": "Contestação", "valorCausa": 85000, "exitoPercentual": 15, "exitoProbabilidade": "média", "exitoPrazo": "Dez/2026" }],
          "honorarios": [{ "id": "h1", "processoId": "p1", "cliente": "Silva", "processo": "1001234-56", "tipo": "Entrada", "venc": "2026-04-20", "valor": 6500, "status": "pendente" }]
        }
        """

        let state = try JSONDecoder().decode(AppState.self, from: Data(json.utf8))

        #expect(state.tasks(in: "hoje").first?.checklist.first?.done == true)
        #expect(state.processos.first?.prazos.first?.title == "Contestação")
        #expect(state.processos.first?.exitoChancePercentual == 50)
        #expect(state.processos.first?.exitoBaseCalculo == .valorCausa)
        #expect(state.developer.projects.isEmpty == false)
        #expect(state.monthlyFlow.isEmpty == false)
    }

    @Test
    func processoFichaCanBeCreatedUpdatedAndLinkedToHonorarios() {
        var state = AppState.makeEmpty()
        let draft = ProcessoDraft(
            numero: "0809999-11.2026.8.14.0301",
            tituloAcao: "Ação de Indenização por Danos Morais",
            cliente: "Maria Cliente",
            autores: ["Maria Cliente"],
            parteContraria: "Banco Teste S.A.",
            reus: ["Banco Teste S.A."],
            tipoCaso: .judicial,
            area: "Cível",
            fase: "Inicial",
            orgaoJulgador: "1ª Vara Cível de Belém",
            comarca: "Belém/PA",
            proxAto: "2026-05-10",
            proxAtoDesc: "Réplica",
            valorCausa: 40_000,
            exitoPercentual: 20,
            exitoChancePercentual: 70,
            exitoProbabilidade: .alta,
            exitoPrazo: "Ago/2026",
            exitoBaseCalculo: .proveitoEconomico,
            exitoProveitoEconomicoEstimado: 25_000,
            resumo: "Falha bancária com bloqueio indevido.",
            resumoInicial: "Inicial narra defeito de serviço e dano moral.",
            tesePrincipal: "Responsabilidade objetiva do banco.",
            pedidos: ["Danos morais", "Custas e honorários"],
            riscos: "Discussão sobre regularidade do bloqueio.",
            estrategia: "Organizar protocolos em ordem cronológica.",
            resultadoEsperado: "Acordo indenizatório."
        )

        AppReducer.reduce(&state, .processoAdd(draft), referenceDate: AppFormatting.date(fromISO: "2026-04-23") ?? Date())
        let processoID = state.processos.first?.id ?? ""

        #expect(state.processos.first?.tituloAcao == "Ação de Indenização por Danos Morais")
        #expect(state.processos.first?.prazos.first?.title == "Réplica")
        #expect(state.processos.first?.exitoValorHonorariosEstimado == 5_000)
        #expect(state.processos.first?.exitoValorPonderado == 3_500)

        AppReducer.reduce(&state, .processoUpdate(id: processoID, patch: ProcessoPatch(fase: "Contestação", pedidos: ["Danos morais", "Tutela de urgência"])), referenceDate: AppFormatting.date(fromISO: "2026-04-24") ?? Date())
        AppReducer.reduce(&state, .honorarioAdd(HonorarioDraft(processoId: processoID, cliente: "Maria Cliente", processo: "0809999-11", tipo: "Entrada", venc: "2026-05-01", valor: 2_000)))

        #expect(state.processos.first?.fase == "Contestação")
        #expect(state.processos.first?.pedidos.contains("Tutela de urgência") == true)
        #expect(state.honorarios.filter { $0.processoId == processoID }.reduce(0) { $0 + $1.valor } == 2_000)
    }

    @Test
    func honorarioRequiresExistingProcessAndStoresReceiptMetadata() {
        var state = AppState.makeEmpty()
        AppReducer.reduce(&state, .honorarioAdd(HonorarioDraft(processoId: "inexistente", cliente: "Cliente", processo: "000", tipo: "Inválido", venc: "2026-05-01", valor: 1_000)))
        #expect(state.honorarios.isEmpty)

        AppReducer.reduce(&state, .processoAdd(ProcessoDraft(numero: "0801111-22.2026.8.14.0301", tituloAcao: "Cobrança contratual", cliente: "Cliente Teste", tipoCaso: .judicial, area: "Cível", fase: "Inicial")))
        let processoID = state.processos.first?.id ?? ""

        AppReducer.reduce(&state, .honorarioAdd(HonorarioDraft(processoId: processoID, cliente: "", processo: "", tipo: "Entrada contratual", venc: "2026-05-01", valor: 1_200)))

        let honorarioID = state.honorarios.first?.id ?? ""
        #expect(state.honorarios.first?.cliente == "Cliente Teste")
        #expect(state.honorarios.first?.processo.isEmpty == false)

        AppReducer.reduce(&state, .honorarioUpdateStatus(id: honorarioID, status: .pago, receivedAt: "2026-05-02", method: .pix, receiptNote: "Pago na assinatura do acordo."))

        #expect(state.honorarios.first?.status == .pago)
        #expect(state.honorarios.first?.dataRecebimento == "2026-05-02")
        #expect(state.honorarios.first?.recebimentoMetodo == .pix)
        #expect(state.honorarios.first?.recebimentoObservacao == "Pago na assinatura do acordo.")
    }

    @Test
    func legacyProcessRepresentationBackfillsFromAuthorsOrClient() {
        let processo = ProcessoItem(
            numero: "",
            tituloAcao: "Caso extrajudicial",
            cliente: "Cliente Base",
            autores: ["Cliente Autor"],
            parteContraria: "Parte Contrária",
            reus: ["Parte Contrária"],
            parteRepresentada: "",
            poloRepresentado: .autor,
            tipoCaso: .extrajudicial,
            area: "Contratos",
            fase: "Negociação"
        )
        let normalized = AppState.normalized(AppState(tarefas: AppState.defaultTaskColumns(), processos: [processo]))

        #expect(normalized.processos.first?.parteRepresentada == "Cliente Autor")
    }

    @Test
    func processoPrazoAndAndamentoCanBeEditedAndDeleted() {
        var state = AppState.makeEmpty()
        AppReducer.reduce(&state, .processoAdd(ProcessoDraft(numero: "", tituloAcao: "Caso extrajudicial", cliente: "Cliente", tipoCaso: .extrajudicial, area: "Contratos", fase: "Negociação")))
        let processoID = state.processos.first?.id ?? ""

        let prazo = ProcessoPrazo(title: "Enviar minuta", date: "2026-05-03", type: .acordo)
        let andamento = ProcessoAndamento(date: "2026-04-23", time: "09:30", title: "Reunião", summary: "Cliente validou a estratégia.", type: .acordo)
        AppReducer.reduce(&state, .processoPrazoAdd(processoID: processoID, prazo: prazo))
        AppReducer.reduce(&state, .processoAndamentoAdd(processoID: processoID, andamento: andamento))

        AppReducer.reduce(&state, .processoPrazoUpdate(processoID: processoID, prazoID: prazo.id, prazo: ProcessoPrazo(id: prazo.id, title: "Enviar minuta revisada", date: "2026-05-04", type: .acordo)))
        AppReducer.reduce(&state, .processoAndamentoUpdate(processoID: processoID, andamentoID: andamento.id, andamento: ProcessoAndamento(id: andamento.id, date: "2026-04-24", title: "Contraproposta", summary: "Parte contrária pediu parcelamento.", type: .acordo)))

        #expect(state.processos.first?.prazos.first?.title == "Enviar minuta revisada")
        #expect(state.processos.first?.andamentos.first?.title == "Contraproposta")

        AppReducer.reduce(&state, .processoPrazoDelete(processoID: processoID, prazoID: prazo.id))
        AppReducer.reduce(&state, .processoAndamentoDelete(processoID: processoID, andamentoID: andamento.id))

        #expect(state.processos.first?.prazos.isEmpty == true)
        #expect(state.processos.first?.andamentos.isEmpty == true)
    }

    @Test
    func exitoSelectorUsesChosenBaseAndNumericChance() {
        var state = AppState.makeEmpty()
        AppReducer.reduce(
            &state,
            .processoAdd(
                ProcessoDraft(
                    numero: "0802222-33.2026.8.14.0301",
                    tituloAcao: "Cumprimento de sentença",
                    cliente: "Cliente Êxito",
                    tipoCaso: .judicial,
                    area: "Cível",
                    fase: "Execução",
                    valorCausa: 10_000,
                    exitoPercentual: 15,
                    exitoChancePercentual: 40,
                    exitoProbabilidade: .media,
                    exitoPrazo: "Out/2026",
                    exitoBaseCalculo: .valorAcordo,
                    exitoValorAcordoEstimado: 80_000
                )
            )
        )

        let item = AppSelectors.exitoCases(for: state).first

        #expect(item?.baseCalculo == .valorAcordo)
        #expect(item?.valorBrutoEstimado == 80_000)
        #expect(item?.valorEstimado == 12_000)
        #expect(item?.valorPonderado == 4_800)
        #expect(item?.chancePercentual == 40)
    }

    @Test
    func personalExpensesAndIncomesAffectFinanceSelectors() {
        var state = AppState.makeEmpty()
        AppReducer.reduce(&state, .categoriaAdd(CategoryDraft(name: "Custas")))
        let categoryID = state.categorias.first?.id ?? ""
        AppReducer.reduce(&state, .processoAdd(ProcessoDraft(numero: "0807000-11.2026.8.14.0301", tituloAcao: "Execução", cliente: "Cliente Financeiro", tipoCaso: .judicial, area: "Cível", fase: "Inicial")))
        let processoID = state.processos.first?.id ?? ""
        AppReducer.reduce(&state, .boletoAdd(BoletoDraft(categoriaId: categoryID, desc: "Custas", dueDate: "2026-04-22", value: 500)), referenceDate: AppFormatting.date(fromISO: "2026-04-23") ?? Date())
        AppReducer.reduce(&state, .incomeAdd(IncomeDraft(desc: "Salário", type: .fixa, value: 3_000, startDate: "2026-04-05")), referenceDate: AppFormatting.date(fromISO: "2026-04-23") ?? Date())
        AppReducer.reduce(&state, .honorarioAdd(HonorarioDraft(processoId: processoID, cliente: "Cliente", processo: "000", tipo: "Entrada", venc: "2026-04-22", valor: 1_500)), referenceDate: AppFormatting.date(fromISO: "2026-04-23") ?? Date())

        let summary = AppSelectors.financasSummary(for: state, referenceDate: AppFormatting.date(fromISO: "2026-04-23") ?? Date())

        #expect(summary.saidasProjetadas == 500)
        #expect(summary.entradasFixas == 3_000)
        #expect(summary.saldoFinal == 2_500)
    }

    @Test
    func fixedExpensePaymentCreatesHistoryAndAdvancesNextDueDate() {
        var state = AppState.makeEmpty()
        AppReducer.reduce(&state, .categoriaAdd(CategoryDraft(name: "Internet")))
        let categoryID = state.categorias.first?.id ?? ""
        AppReducer.reduce(&state, .boletoAdd(BoletoDraft(categoriaId: categoryID, desc: "Internet", dueDate: "2026-04-10", value: 120, recurrence: .fixa)), referenceDate: AppFormatting.date(fromISO: "2026-04-05") ?? Date())
        let accountID = state.boletos.first?.id ?? ""

        AppReducer.reduce(&state, .boletoUpdateStatus(id: accountID, status: .pago), referenceDate: AppFormatting.date(fromISO: "2026-04-10") ?? Date())

        #expect(state.boletos.contains { $0.status == .pago && $0.desc == "Internet" })
        #expect(state.boletos.contains { $0.status == .pendente && $0.recurrence == .fixa && $0.dueDate == "2026-05-10" })
    }

    @Test
    func variableIncomeCanBeSplitIntoMonthlyReceivables() {
        var state = AppState.makeEmpty()

        AppReducer.reduce(&state, .incomeAdd(IncomeDraft(desc: "Parcelado pessoal", type: .variavel, value: 700, startDate: "2026-04-15", durationMonths: 3)), referenceDate: AppFormatting.date(fromISO: "2026-04-01") ?? Date())

        #expect(state.incomes.count == 3)
        #expect(state.incomes.map(\.startDate) == ["2026-04-15", "2026-05-15", "2026-06-15"])
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("caesar-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

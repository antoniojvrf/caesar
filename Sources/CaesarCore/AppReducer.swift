import Foundation

public enum AppReducer {
    public static func reduce(_ state: AppState, _ action: WorkspaceAction, referenceDate: Date = Date()) -> AppState {
        var next = state
        reduce(&next, action, referenceDate: referenceDate)
        return next
    }

    public static func reduce(_ state: inout AppState, _ action: WorkspaceAction, referenceDate: Date = Date()) {
        switch action {
        case .workspaceReset:
            state = AppState.makeEmpty(referenceDate: referenceDate)

        case .workspaceLoadDemo:
            state = AppState.makeDemo(referenceDate: referenceDate)

        case let .workspaceReplace(replacement):
            state = AppState.normalized(replacement)

        case let .taskAdd(columnID, draft):
            guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { break }
            ensureColumn(columnID, in: &state)
            let task = TaskItem(
                title: draft.title,
                priority: draft.priority,
                tag: draft.tag.isEmpty ? "Geral" : draft.tag,
                goal: draft.goal,
                categoriaId: draft.categoriaId,
                dueDate: AppDateValidation.normalizedISODate(draft.dueDate) ?? draft.dueDate,
                notes: draft.notes,
                createdAt: AppFormatting.isoDate(referenceDate),
                updatedAt: AppFormatting.isoDate(referenceDate)
            )
            state.tarefas[columnID]?.tasks.append(task)

        case let .taskUpdate(columnID, taskID, patch):
            guard var column = state.tarefas[columnID],
                  let index = column.tasks.firstIndex(where: { $0.id == taskID }) else { break }
            if let title = patch.title { column.tasks[index].title = title }
            if let priority = patch.priority { column.tasks[index].priority = priority }
            if let tag = patch.tag { column.tasks[index].tag = tag }
            if let goal = patch.goal { column.tasks[index].goal = goal }
            if let categoriaId = patch.categoriaId { column.tasks[index].categoriaId = categoriaId }
            if let dueDate = patch.dueDate { column.tasks[index].dueDate = AppDateValidation.normalizedISODate(dueDate) ?? dueDate }
            if let notes = patch.notes { column.tasks[index].notes = notes }
            if let checklist = patch.checklist { column.tasks[index].checklist = checklist }
            if let attachments = patch.attachments { column.tasks[index].attachments = attachments }
            column.tasks[index].updatedAt = AppFormatting.isoDate(referenceDate)
            state.tarefas[columnID] = column

        case let .taskMove(fromColumnID, taskID, toColumnID):
            guard fromColumnID != toColumnID,
                  var from = state.tarefas[fromColumnID],
                  let taskIndex = from.tasks.firstIndex(where: { $0.id == taskID }) else { break }
            ensureColumn(toColumnID, in: &state)
            let task = from.tasks.remove(at: taskIndex)
            state.tarefas[fromColumnID] = from
            state.tarefas[toColumnID]?.tasks.append(task)

        case let .taskDelete(columnID, taskID):
            state.tarefas[columnID]?.tasks.removeAll { $0.id == taskID }

        case let .metaAdd(draft):
            guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { break }
            let progress = progress(current: draft.current, target: draft.target, milestones: draft.milestones)
            state.metas.append(GoalItem(title: draft.title, type: draft.type, progress: progress, current: draft.current, target: draft.target, deadline: draft.deadline, milestones: draft.milestones))

        case let .metaUpdate(id, patch):
            guard let index = state.metas.firstIndex(where: { $0.id == id }) else { break }
            if let title = patch.title { state.metas[index].title = title }
            if let type = patch.type { state.metas[index].type = type }
            if let current = patch.current { state.metas[index].current = current }
            if let target = patch.target { state.metas[index].target = target }
            if let deadline = patch.deadline { state.metas[index].deadline = deadline }
            if let milestones = patch.milestones { state.metas[index].milestones = milestones }
            if let associatedIncomeIDs = patch.associatedIncomeIDs { state.metas[index].associatedIncomeIDs = associatedIncomeIDs }
            if let associatedHonorarioIDs = patch.associatedHonorarioIDs { state.metas[index].associatedHonorarioIDs = associatedHonorarioIDs }
            if let notes = patch.notes { state.metas[index].notes = notes }
            state.metas[index].progress = state.goalProgress(for: state.metas[index])

        case let .metaDelete(id):
            state.metas.removeAll { $0.id == id }

        case let .metaMilestoneToggle(metaID, milestoneID):
            guard let metaIndex = state.metas.firstIndex(where: { $0.id == metaID }),
                  let milestoneIndex = state.metas[metaIndex].milestones.firstIndex(where: { $0.id == milestoneID }) else { break }
            state.metas[metaIndex].milestones[milestoneIndex].done.toggle()
            state.metas[metaIndex].progress = state.goalProgress(for: state.metas[metaIndex])

        case let .categoriaAdd(draft):
            let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { break }
            let exists = state.categorias.contains { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
            guard !exists else { break }
            state.categorias.append(CategoryItem(name: name, color: draft.color, recurring: draft.recurring))

        case let .categoriaUpdate(id, draft):
            guard let index = state.categorias.firstIndex(where: { $0.id == id }) else { break }
            state.categorias[index].name = draft.name
            state.categorias[index].color = draft.color
            state.categorias[index].recurring = draft.recurring

        case let .categoriaDelete(id):
            state.categorias.removeAll { $0.id == id }
            state.boletos.removeAll { $0.categoriaId == id }
            for columnID in Array(state.tarefas.keys) {
                guard var column = state.tarefas[columnID] else { continue }
                let tasks = column.tasks.map { task in
                    var copy = task
                    if copy.categoriaId == id { copy.categoriaId = nil }
                    return copy
                }
                column.tasks = tasks
                state.tarefas[columnID] = column
            }
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .boletoAdd(draft):
            state.boletos.append(BoletoItem(categoriaId: draft.categoriaId, desc: draft.desc, dueDate: AppDateValidation.normalizedISODate(draft.dueDate) ?? draft.dueDate, value: draft.value, status: draft.status, recurrence: draft.recurrence, monthlyAdjustments: draft.monthlyAdjustments, barcode: draft.barcode, notes: draft.notes))
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .boletoUpdate(id, draft):
            guard let index = state.boletos.firstIndex(where: { $0.id == id }) else { break }
            state.boletos[index].categoriaId = draft.categoriaId
            state.boletos[index].desc = draft.desc
            state.boletos[index].dueDate = AppDateValidation.normalizedISODate(draft.dueDate) ?? draft.dueDate
            state.boletos[index].value = draft.value
            state.boletos[index].status = draft.status
            state.boletos[index].recurrence = draft.recurrence
            state.boletos[index].monthlyAdjustments = draft.monthlyAdjustments
            state.boletos[index].barcode = draft.barcode
            state.boletos[index].notes = draft.notes
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .boletoUpdateStatus(id, status):
            guard let index = state.boletos.firstIndex(where: { $0.id == id }) else { break }
            if status == .pago {
                if state.boletos[index].recurrence == .fixa && state.boletos[index].status != .pago {
                    var paidCopy = state.boletos[index]
                    paidCopy.id = UUID().uuidString
                    paidCopy.status = .pago
                    paidCopy.paidAt = AppFormatting.isoDate(referenceDate)
                    paidCopy.recurrence = .variavel
                    state.boletos.append(paidCopy)
                    state.boletos[index].dueDate = AppFormatting.addingMonths(1, toISODate: state.boletos[index].dueDate)
                    state.boletos[index].status = .pendente
                    state.boletos[index].paidAt = nil
                } else {
                    state.boletos[index].status = .pago
                    state.boletos[index].paidAt = AppFormatting.isoDate(referenceDate)
                }
            } else {
                state.boletos[index].status = status == .recorrente ? .pendente : status
                state.boletos[index].paidAt = nil
            }
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .boletoAddAdjustment(id, adjustment):
            guard let index = state.boletos.firstIndex(where: { $0.id == id }),
                  let month = AppDateValidation.normalizedMonthKey(adjustment.month) else { break }
            state.boletos[index].monthlyAdjustments.removeAll { $0.month == month }
            state.boletos[index].monthlyAdjustments.append(FinanceMonthlyAdjustment(month: month, value: adjustment.value))
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .boletoDelete(id):
            state.boletos.removeAll { $0.id == id }
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .incomeAdd(draft):
            if draft.type == .variavel, (draft.durationMonths ?? 1) > 1 {
                let start = AppDateValidation.normalizedISODate(draft.startDate) ?? AppFormatting.isoDate(referenceDate)
                let duration = max(1, draft.durationMonths ?? 1)
                for offset in 0..<duration {
                    let dueDate = AppFormatting.addingMonths(offset, toISODate: start)
                    state.incomes.append(IncomeItem(desc: "\(draft.desc) \(offset + 1)/\(duration)", type: .variavel, value: draft.value, startDate: dueDate, durationMonths: 1, monthlyAdjustments: draft.monthlyAdjustments, notes: draft.notes))
                }
            } else {
                state.incomes.append(IncomeItem(desc: draft.desc, type: draft.type, value: draft.value, startDate: AppDateValidation.normalizedISODate(draft.startDate), durationMonths: draft.durationMonths, monthlyAdjustments: draft.monthlyAdjustments, notes: draft.notes))
            }
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .incomeUpdate(id, draft):
            guard let index = state.incomes.firstIndex(where: { $0.id == id }) else { break }
            state.incomes[index] = IncomeItem(id: id, desc: draft.desc, type: draft.type, value: draft.value, startDate: AppDateValidation.normalizedISODate(draft.startDate), durationMonths: draft.durationMonths, status: state.incomes[index].status, receivedAt: state.incomes[index].receivedAt, monthlyAdjustments: draft.monthlyAdjustments, notes: draft.notes)
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .incomeUpdateStatus(id, status):
            guard let index = state.incomes.firstIndex(where: { $0.id == id }) else { break }
            if status == .recebido {
                if state.incomes[index].type == .fixa && state.incomes[index].status != .recebido {
                    var receivedCopy = state.incomes[index]
                    receivedCopy.id = UUID().uuidString
                    receivedCopy.type = .variavel
                    receivedCopy.durationMonths = 1
                    receivedCopy.status = .recebido
                    receivedCopy.receivedAt = AppFormatting.isoDate(referenceDate)
                    state.incomes.append(receivedCopy)
                    let currentStart = state.incomes[index].startDate ?? AppFormatting.isoDate(referenceDate)
                    state.incomes[index].startDate = AppFormatting.addingMonths(1, toISODate: currentStart)
                    state.incomes[index].status = .pendente
                    state.incomes[index].receivedAt = nil
                } else {
                    state.incomes[index].status = .recebido
                    state.incomes[index].receivedAt = AppFormatting.isoDate(referenceDate)
                }
            } else {
                state.incomes[index].status = .pendente
                state.incomes[index].receivedAt = nil
            }
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .incomeAddAdjustment(id, adjustment):
            guard let index = state.incomes.firstIndex(where: { $0.id == id }),
                  let month = AppDateValidation.normalizedMonthKey(adjustment.month) else { break }
            state.incomes[index].monthlyAdjustments.removeAll { $0.month == month }
            state.incomes[index].monthlyAdjustments.append(FinanceMonthlyAdjustment(month: month, value: adjustment.value))
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .incomeDelete(id):
            state.incomes.removeAll { $0.id == id }
            for index in state.metas.indices {
                state.metas[index].associatedIncomeIDs.removeAll { $0 == id }
            }
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .processoAdd(draft):
            let processo = ProcessoItem(
                numero: draft.numero,
                tituloAcao: draft.tituloAcao,
                cliente: draft.cliente,
                autores: draft.autores,
                parteContraria: draft.parteContraria,
                reus: draft.reus,
                parteRepresentada: draft.parteRepresentada,
                poloRepresentado: draft.poloRepresentado,
                tipoCaso: draft.tipoCaso,
                area: draft.area,
                fase: draft.fase,
                status: draft.status,
                prioridade: draft.prioridade,
                orgaoJulgador: draft.orgaoJulgador,
                comarca: draft.comarca,
                vara: draft.vara,
                tribunal: draft.tribunal,
                dataDistribuicao: AppDateValidation.normalizedISODate(draft.dataDistribuicao) ?? draft.dataDistribuicao,
                proxAto: AppDateValidation.normalizedISODate(draft.proxAto) ?? draft.proxAto,
                proxAtoDesc: draft.proxAtoDesc,
                valorCausa: draft.valorCausa,
                exitoPercentual: draft.exitoPercentual,
                exitoChancePercentual: draft.exitoChancePercentual,
                exitoProbabilidade: draft.exitoProbabilidade,
                exitoPrazo: draft.exitoPrazo,
                exitoBaseCalculo: draft.exitoBaseCalculo,
                exitoValorCondenacaoEstimado: draft.exitoValorCondenacaoEstimado,
                exitoProveitoEconomicoEstimado: draft.exitoProveitoEconomicoEstimado,
                exitoValorAcordoEstimado: draft.exitoValorAcordoEstimado,
                exitoBasePersonalizadaRotulo: draft.exitoBasePersonalizadaRotulo,
                exitoBasePersonalizadaValor: draft.exitoBasePersonalizadaValor,
                resumo: draft.resumo,
                resumoInicial: draft.resumoInicial,
                tesePrincipal: draft.tesePrincipal,
                pedidos: draft.pedidos,
                riscos: draft.riscos,
                estrategia: draft.estrategia,
                resultadoEsperado: draft.resultadoEsperado,
                observacoes: draft.observacoes,
                prazos: draft.proxAto.isEmpty ? [] : [ProcessoPrazo(title: draft.proxAtoDesc.isEmpty ? "Próximo ato" : draft.proxAtoDesc, date: AppDateValidation.normalizedISODate(draft.proxAto) ?? draft.proxAto)]
            )
            state.processos.append(processo)

        case let .processoUpdate(id, patch):
            guard let index = state.processos.firstIndex(where: { $0.id == id }) else { break }
            if let numero = patch.numero { state.processos[index].numero = numero }
            if let tituloAcao = patch.tituloAcao { state.processos[index].tituloAcao = tituloAcao }
            if let cliente = patch.cliente { state.processos[index].cliente = cliente }
            if let autores = patch.autores { state.processos[index].autores = autores }
            if let parteContraria = patch.parteContraria { state.processos[index].parteContraria = parteContraria }
            if let reus = patch.reus { state.processos[index].reus = reus }
            if let parteRepresentada = patch.parteRepresentada { state.processos[index].parteRepresentada = parteRepresentada }
            if let poloRepresentado = patch.poloRepresentado { state.processos[index].poloRepresentado = poloRepresentado }
            if let tipoCaso = patch.tipoCaso { state.processos[index].tipoCaso = tipoCaso }
            if let area = patch.area { state.processos[index].area = area }
            if let fase = patch.fase { state.processos[index].fase = fase }
            if let status = patch.status { state.processos[index].status = status }
            if let prioridade = patch.prioridade { state.processos[index].prioridade = prioridade }
            if let orgaoJulgador = patch.orgaoJulgador { state.processos[index].orgaoJulgador = orgaoJulgador }
            if let comarca = patch.comarca { state.processos[index].comarca = comarca }
            if let vara = patch.vara { state.processos[index].vara = vara }
            if let tribunal = patch.tribunal { state.processos[index].tribunal = tribunal }
            if let dataDistribuicao = patch.dataDistribuicao { state.processos[index].dataDistribuicao = AppDateValidation.normalizedISODate(dataDistribuicao) ?? dataDistribuicao }
            if let proxAto = patch.proxAto { state.processos[index].proxAto = AppDateValidation.normalizedISODate(proxAto) ?? proxAto }
            if let proxAtoDesc = patch.proxAtoDesc { state.processos[index].proxAtoDesc = proxAtoDesc }
            if let valorCausa = patch.valorCausa { state.processos[index].valorCausa = valorCausa }
            if let exitoPercentual = patch.exitoPercentual { state.processos[index].exitoPercentual = exitoPercentual }
            if let exitoChancePercentual = patch.exitoChancePercentual { state.processos[index].exitoChancePercentual = exitoChancePercentual }
            if let exitoProbabilidade = patch.exitoProbabilidade { state.processos[index].exitoProbabilidade = exitoProbabilidade }
            if let exitoPrazo = patch.exitoPrazo { state.processos[index].exitoPrazo = exitoPrazo }
            if let exitoBaseCalculo = patch.exitoBaseCalculo { state.processos[index].exitoBaseCalculo = exitoBaseCalculo }
            if let exitoValorCondenacaoEstimado = patch.exitoValorCondenacaoEstimado { state.processos[index].exitoValorCondenacaoEstimado = exitoValorCondenacaoEstimado }
            if let exitoProveitoEconomicoEstimado = patch.exitoProveitoEconomicoEstimado { state.processos[index].exitoProveitoEconomicoEstimado = exitoProveitoEconomicoEstimado }
            if let exitoValorAcordoEstimado = patch.exitoValorAcordoEstimado { state.processos[index].exitoValorAcordoEstimado = exitoValorAcordoEstimado }
            if let exitoBasePersonalizadaRotulo = patch.exitoBasePersonalizadaRotulo { state.processos[index].exitoBasePersonalizadaRotulo = exitoBasePersonalizadaRotulo }
            if let exitoBasePersonalizadaValor = patch.exitoBasePersonalizadaValor { state.processos[index].exitoBasePersonalizadaValor = exitoBasePersonalizadaValor }
            if let resumo = patch.resumo { state.processos[index].resumo = resumo }
            if let resumoInicial = patch.resumoInicial { state.processos[index].resumoInicial = resumoInicial }
            if let tesePrincipal = patch.tesePrincipal { state.processos[index].tesePrincipal = tesePrincipal }
            if let pedidos = patch.pedidos { state.processos[index].pedidos = pedidos }
            if let riscos = patch.riscos { state.processos[index].riscos = riscos }
            if let estrategia = patch.estrategia { state.processos[index].estrategia = estrategia }
            if let resultadoEsperado = patch.resultadoEsperado { state.processos[index].resultadoEsperado = resultadoEsperado }
            if let observacoes = patch.observacoes { state.processos[index].observacoes = observacoes }
            state.processos[index].updatedAt = AppFormatting.isoDate(referenceDate)

        case let .processoDelete(id):
            state.processos.removeAll { $0.id == id }
            state.honorarios.removeAll { $0.processoId == id }
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .processoPrazoAdd(processoID, prazo):
            guard let index = state.processos.firstIndex(where: { $0.id == processoID }) else { break }
            state.processos[index].prazos.append(prazo)
            state.processos[index].updatedAt = AppFormatting.isoDate(referenceDate)

        case let .processoPrazoUpdate(processoID, prazoID, prazo):
            guard let processoIndex = state.processos.firstIndex(where: { $0.id == processoID }),
                  let prazoIndex = state.processos[processoIndex].prazos.firstIndex(where: { $0.id == prazoID }) else { break }
            state.processos[processoIndex].prazos[prazoIndex] = prazo
            state.processos[processoIndex].updatedAt = AppFormatting.isoDate(referenceDate)

        case let .processoPrazoDelete(processoID, prazoID):
            guard let index = state.processos.firstIndex(where: { $0.id == processoID }) else { break }
            state.processos[index].prazos.removeAll { $0.id == prazoID }
            state.processos[index].updatedAt = AppFormatting.isoDate(referenceDate)

        case let .processoAndamentoAdd(processoID, andamento):
            guard let index = state.processos.firstIndex(where: { $0.id == processoID }) else { break }
            state.processos[index].andamentos.insert(andamento, at: 0)
            state.processos[index].updatedAt = AppFormatting.isoDate(referenceDate)

        case let .processoAndamentoUpdate(processoID, andamentoID, andamento):
            guard let processoIndex = state.processos.firstIndex(where: { $0.id == processoID }),
                  let andamentoIndex = state.processos[processoIndex].andamentos.firstIndex(where: { $0.id == andamentoID }) else { break }
            state.processos[processoIndex].andamentos[andamentoIndex] = andamento
            state.processos[processoIndex].updatedAt = AppFormatting.isoDate(referenceDate)

        case let .processoAndamentoDelete(processoID, andamentoID):
            guard let index = state.processos.firstIndex(where: { $0.id == processoID }) else { break }
            state.processos[index].andamentos.removeAll { $0.id == andamentoID }
            state.processos[index].updatedAt = AppFormatting.isoDate(referenceDate)

        case let .contatoAdd(draft):
            state.contatos.append(ContatoItem(name: draft.name, entityType: draft.entityType, role: draft.role, document: draft.document, email: draft.email, phone: draft.phone, address: draft.address, notes: draft.notes))

        case let .contatoDelete(id):
            state.contatos.removeAll { $0.id == id }
            state.processos = state.processos.map { processo in
                var copy = processo
                copy.contatos.removeAll { $0.contatoId == id }
                return copy
            }

        case let .honorarioAdd(draft):
            guard let processo = state.processo(for: draft.processoId),
                  let honorario = normalizedHonorarioItem(from: draft, existingID: nil, processo: processo) else { break }
            state.honorarios.append(honorario)
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .honorarioUpdate(id, patch):
            guard let index = state.honorarios.firstIndex(where: { $0.id == id }) else { break }
            let current = state.honorarios[index]
            let processoId = patch.processoId ?? current.processoId
            guard let processo = state.processo(for: processoId) else { break }
            let mergedDraft = HonorarioDraft(
                processoId: processoId,
                cliente: patch.cliente ?? current.cliente,
                processo: patch.processo ?? current.processo,
                tipo: patch.tipo ?? current.tipo,
                venc: patch.venc ?? current.venc,
                valor: patch.valor ?? current.valor,
                launchType: patch.launchType ?? current.launchType,
                parcelaIndice: patch.parcelaIndice ?? current.parcelaIndice,
                parcelaTotal: patch.parcelaTotal ?? current.parcelaTotal,
                status: patch.status ?? current.status,
                dataRecebimento: patch.dataRecebimento ?? current.dataRecebimento,
                recebimentoMetodo: patch.recebimentoMetodo ?? current.recebimentoMetodo,
                recebimentoObservacao: patch.recebimentoObservacao ?? current.recebimentoObservacao,
                notes: patch.notes ?? current.notes
            )
            guard let updated = normalizedHonorarioItem(from: mergedDraft, existingID: current.id, processo: processo) else { break }
            state.honorarios[index] = updated
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .honorarioUpdateStatus(id, status, receivedAt, method, receiptNote):
            guard let index = state.honorarios.firstIndex(where: { $0.id == id }) else { break }
            if status == .pago {
                guard let normalizedDate = AppDateValidation.normalizedISODate(receivedAt ?? ""),
                      let method else { break }
                state.honorarios[index].status = .pago
                state.honorarios[index].dataRecebimento = normalizedDate
                state.honorarios[index].recebimentoMetodo = method
                state.honorarios[index].recebimentoObservacao = sanitizedReceiptNote(receiptNote)
            } else {
                state.honorarios[index].status = status
                state.honorarios[index].dataRecebimento = nil
                state.honorarios[index].recebimentoMetodo = nil
                state.honorarios[index].recebimentoObservacao = ""
            }
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .honorarioDelete(id):
            state.honorarios.removeAll { $0.id == id }
            for index in state.metas.indices {
                state.metas[index].associatedHonorarioIDs.removeAll { $0 == id }
            }
            state.recalculateMonthlyFlow(referenceDate: referenceDate)

        case let .developerProjectAdd(project):
            state.developer.projects.append(project)

        case let .developerReceivableAdd(draft):
            state.developer.receivables.append(DeveloperReceivable(projectId: draft.projectId, client: draft.client, description: draft.description, dueDate: AppDateValidation.normalizedISODate(draft.dueDate) ?? draft.dueDate, value: draft.value, status: draft.status, installmentLabel: draft.installmentLabel, notes: draft.notes))

        case let .developerReceivableUpdateStatus(id, status):
            guard let index = state.developer.receivables.firstIndex(where: { $0.id == id }) else { break }
            state.developer.receivables[index].status = status

        case let .developerReceivableDelete(id):
            state.developer.receivables.removeAll { $0.id == id }

        case let .developerIdeaAdd(idea):
            state.developer.ideas.insert(idea, at: 0)

        case let .developerNoteUpdate(notes):
            state.developer.notes = notes
        }

        state.updatedAt = AppFormatting.isoDate(referenceDate)
        state = AppState.normalized(state)
    }

    private static func ensureColumn(_ id: String, in state: inout AppState) {
        guard state.tarefas[id] == nil else { return }
        let name: String
        switch id {
        case "hoje": name = "Hoje"
        case "semana": name = "Esta semana"
        case "proximas": name = "Próximas"
        default: name = id.capitalized
        }
        state.tarefas[id] = TaskColumn(name: name)
    }

    private static func progress(current: Double?, target: Double?, milestones: [GoalMilestone]) -> Int {
        if let current, let target, target > 0 {
            return min(100, max(0, Int((current / target * 100).rounded())))
        }
        guard !milestones.isEmpty else { return 0 }
        return Int((Double(milestones.filter(\.done).count) / Double(milestones.count) * 100).rounded())
    }

    private static func normalizedHonorarioItem(from draft: HonorarioDraft, existingID: String?, processo: ProcessoItem) -> HonorarioItem? {
        let descricao = draft.tipo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !descricao.isEmpty else { return nil }
        guard let venc = AppDateValidation.normalizedISODate(draft.venc), draft.valor >= 0 else { return nil }
        let processoRef = processo.numero.isEmpty ? processo.tipoCaso.label : String(processo.numero.prefix(14))
        let receiptNote = sanitizedReceiptNote(draft.recebimentoObservacao)

        let status: HonorarioStatus
        let recebimentoData: String?
        let recebimentoMetodo: HonorarioReceiptMethod?
        if draft.status == .pago {
            guard let normalizedReceiptDate = AppDateValidation.normalizedISODate(draft.dataRecebimento ?? ""),
                  let method = draft.recebimentoMetodo else { return nil }
            status = .pago
            recebimentoData = normalizedReceiptDate
            recebimentoMetodo = method
        } else {
            status = draft.status
            recebimentoData = nil
            recebimentoMetodo = nil
        }

        return HonorarioItem(
            id: existingID ?? UUID().uuidString,
            processoId: processo.id,
            cliente: processo.cliente,
            processo: processoRef,
            tipo: descricao,
            venc: venc,
            valor: draft.valor,
            launchType: draft.launchType,
            parcelaIndice: draft.parcelaIndice,
            parcelaTotal: draft.parcelaTotal,
            status: status,
            dataRecebimento: recebimentoData,
            recebimentoMetodo: recebimentoMetodo,
            recebimentoObservacao: status == .pago ? receiptNote : "",
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private static func sanitizedReceiptNote(_ note: String?) -> String {
        String((note ?? "").trimmingCharacters(in: .whitespacesAndNewlines).prefix(200))
    }
}

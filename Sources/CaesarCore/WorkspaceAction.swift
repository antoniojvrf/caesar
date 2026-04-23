import Foundation

public enum WorkspaceAction: Equatable {
    case workspaceReset
    case workspaceLoadDemo
    case workspaceReplace(AppState)

    case taskAdd(columnID: String, draft: TaskDraft)
    case taskUpdate(columnID: String, taskID: String, patch: TaskPatch)
    case taskMove(fromColumnID: String, taskID: String, toColumnID: String)
    case taskDelete(columnID: String, taskID: String)

    case metaAdd(GoalDraft)
    case metaUpdate(id: String, patch: GoalPatch)
    case metaDelete(id: String)
    case metaMilestoneToggle(metaID: String, milestoneID: String)

    case categoriaAdd(CategoryDraft)
    case categoriaUpdate(id: String, draft: CategoryDraft)
    case categoriaDelete(id: String)

    case boletoAdd(BoletoDraft)
    case boletoUpdate(id: String, draft: BoletoDraft)
    case boletoUpdateStatus(id: String, status: BoletoStatus)
    case boletoAddAdjustment(id: String, adjustment: FinanceMonthlyAdjustment)
    case boletoDelete(id: String)

    case incomeAdd(IncomeDraft)
    case incomeUpdate(id: String, draft: IncomeDraft)
    case incomeUpdateStatus(id: String, status: IncomeStatus)
    case incomeAddAdjustment(id: String, adjustment: FinanceMonthlyAdjustment)
    case incomeDelete(id: String)

    case processoAdd(ProcessoDraft)
    case processoUpdate(id: String, patch: ProcessoPatch)
    case processoDelete(id: String)
    case processoPrazoAdd(processoID: String, prazo: ProcessoPrazo)
    case processoPrazoUpdate(processoID: String, prazoID: String, prazo: ProcessoPrazo)
    case processoPrazoDelete(processoID: String, prazoID: String)
    case processoAndamentoAdd(processoID: String, andamento: ProcessoAndamento)
    case processoAndamentoUpdate(processoID: String, andamentoID: String, andamento: ProcessoAndamento)
    case processoAndamentoDelete(processoID: String, andamentoID: String)

    case contatoAdd(ContatoDraft)
    case contatoDelete(id: String)

    case honorarioAdd(HonorarioDraft)
    case honorarioUpdate(id: String, patch: HonorarioPatch)
    case honorarioUpdateStatus(id: String, status: HonorarioStatus, receivedAt: String?, method: HonorarioReceiptMethod?, receiptNote: String?)
    case honorarioDelete(id: String)

    case developerProjectAdd(DeveloperProject)
    case developerReceivableAdd(DeveloperReceivableDraft)
    case developerReceivableUpdateStatus(id: String, status: DeveloperReceivableStatus)
    case developerReceivableDelete(id: String)
    case developerIdeaAdd(DeveloperIdea)
    case developerNoteUpdate(String)
}

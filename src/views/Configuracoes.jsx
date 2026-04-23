import { useMemo } from 'react'
import { Card } from '../components/Card.jsx'
import { Folder, Bell, Download, Keyboard, Database, RotateCcw, FlaskConical } from 'lucide-react'
import { useAppState } from '../store/AppContext.jsx'

export default function Configuracoes() {
  const { state, dispatch } = useAppState()

  const totals = useMemo(() => {
    const totalTarefas = Object.values(state.tarefas).reduce((sum, col) => sum + col.tasks.length, 0)
    return {
      totalTarefas,
      metas: state.metas.length,
      categorias: state.categorias.length,
      boletos: state.boletos.length,
      entradas: state.incomes.length,
      processos: state.processos.length,
      honorarios: state.honorarios.length,
    }
  }, [state])

  const hasUserData = Object.values(totals).some((value) => value > 0)

  function resetWorkspace() {
    const confirmed = window.confirm(
      'Isso vai limpar todo o workspace atual e deixar o app pronto para receber dados reais. Deseja continuar?'
    )
    if (!confirmed) return
    dispatch({ type: 'WORKSPACE_RESET' })
  }

  function loadDemo() {
    const confirmed = window.confirm(
      'Isso vai substituir o workspace atual pelos dados de demonstração. Deseja continuar?'
    )
    if (!confirmed) return
    dispatch({ type: 'WORKSPACE_LOAD_DEMO' })
  }

  return (
    <div className="space-y-4 max-w-3xl">
      <Card className="p-5">
        <div className="flex items-start gap-3">
          <Database className="text-brand-blue" size={20} />
          <div className="flex-1">
            <div className="font-semibold">Workspace atual</div>
            <div className="text-sm text-neutral-500 mt-0.5">
              Ambiente persistido localmente. Você pode zerar tudo para começar com dados reais ou recarregar o modo demo.
            </div>
            <div className="mt-4 grid grid-cols-4 gap-2">
              <StatChip label="Tarefas" value={totals.totalTarefas} />
              <StatChip label="Metas" value={totals.metas} />
              <StatChip label="Boletos" value={totals.boletos} />
              <StatChip label="Processos" value={totals.processos} />
            </div>
            <div className="mt-4 flex flex-wrap items-center gap-2">
              <button
                onClick={resetWorkspace}
                className="text-xs px-3 py-1.5 bg-brand-red text-white rounded-lg flex items-center gap-1.5"
              >
                <RotateCcw size={13} />
                Limpar workspace
              </button>
              <button
                onClick={loadDemo}
                className="text-xs px-3 py-1.5 border border-neutral-200 dark:border-neutral-700 rounded-lg flex items-center gap-1.5"
              >
                <FlaskConical size={13} />
                Carregar dados demo
              </button>
              <span className="text-xs text-neutral-500">
                {hasUserData ? 'Há dados carregados no app.' : 'Workspace limpo e pronto para uso real.'}
              </span>
            </div>
          </div>
        </div>
      </Card>

      <Card className="p-5">
        <div className="flex items-start gap-3">
          <Folder className="text-brand-blue" size={20} />
          <div className="flex-1">
            <div className="font-semibold">Pasta monitorada</div>
            <div className="text-sm text-neutral-500 mt-0.5">
              Boletos PDF salvos aqui serão importados automaticamente.
            </div>
            <div className="mt-3 flex items-center gap-2">
              <code className="text-xs px-2 py-1.5 bg-neutral-100 dark:bg-neutral-800 rounded flex-1">
                ~/Documents/MyLife/Boletos
              </code>
              <button className="text-xs px-3 py-1.5 border border-neutral-200 dark:border-neutral-700 rounded-lg">
                Alterar
              </button>
            </div>
          </div>
        </div>
      </Card>

      <Card className="p-5">
        <div className="flex items-start gap-3">
          <Bell className="text-brand-amber" size={20} />
          <div className="flex-1">
            <div className="font-semibold">Notificações</div>
            <div className="text-sm text-neutral-500 mt-0.5">
              Alerta X dias antes do vencimento de cada boleto.
            </div>
            <div className="mt-3 flex items-center gap-2">
              <input
                type="number"
                defaultValue={3}
                className="w-16 px-2 py-1.5 text-sm border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent"
              />
              <span className="text-sm text-neutral-500">dias de antecedência</span>
            </div>
          </div>
        </div>
      </Card>

      <Card className="p-5">
        <div className="flex items-start gap-3">
          <Keyboard className="text-brand-green" size={20} />
          <div className="flex-1">
            <div className="font-semibold">Atalhos globais</div>
            <div className="text-sm text-neutral-500 mt-0.5">
              Adicione registros mesmo com o app em segundo plano.
            </div>
            <div className="mt-3 space-y-2 text-sm">
              <Row label="Nova tarefa" kbd="⌘ ⇧ T" />
              <Row label="Novo boleto" kbd="⌘ ⇧ B" />
              <Row label="Abrir MyLife" kbd="⌘ ⇧ M" />
            </div>
          </div>
        </div>
      </Card>

      <Card className="p-5">
        <div className="flex items-start gap-3">
          <Download className="text-brand-blue" size={20} />
          <div className="flex-1">
            <div className="font-semibold">Backup & Exportação</div>
            <div className="text-sm text-neutral-500 mt-0.5">
              Exporte todos os dados e anexos em um único arquivo ZIP.
            </div>
            <div className="mt-3 flex items-center gap-2">
              <button className="text-xs px-3 py-1.5 bg-brand-blue text-white rounded-lg">
                Exportar agora
              </button>
              <button className="text-xs px-3 py-1.5 border border-neutral-200 dark:border-neutral-700 rounded-lg">
                Restaurar de backup
              </button>
            </div>
          </div>
        </div>
      </Card>
    </div>
  )
}

function Row({ label, kbd }) {
  return (
    <div className="flex items-center justify-between">
      <span>{label}</span>
      <kbd className="text-xs px-2 py-0.5 bg-neutral-100 dark:bg-neutral-800 rounded font-mono">{kbd}</kbd>
    </div>
  )
}

function StatChip({ label, value }) {
  return (
    <div className="rounded-lg border border-neutral-200 dark:border-neutral-800 px-3 py-2">
      <div className="text-[11px] uppercase tracking-wide text-neutral-500">{label}</div>
      <div className="text-lg font-semibold">{value}</div>
    </div>
  )
}

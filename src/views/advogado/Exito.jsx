import { Card, StatCard } from '../../components/Card.jsx'
import { formatBRL } from './_shared.jsx'
import { useAppState } from '../../store/AppContext.jsx'
import { getExitoCases } from '../../store/selectors.js'

export default function Exito() {
  const { state } = useAppState()
  const exitoCases = getExitoCases(state)

  const total = exitoCases.reduce((s, c) => s + c.valorEstimado, 0)
  const ponderado = exitoCases.reduce((s, c) => {
    const w = c.probabilidade === 'alta' ? 0.75 : c.probabilidade === 'média' ? 0.5 : 0.25
    return s + c.valorEstimado * w
  }, 0)
  const maior = exitoCases.reduce((max, c) => c.valorEstimado > max.valor ? { valor: c.valorEstimado, nome: c.caso } : max, { valor: 0, nome: '—' })

  const probColor = {
    alta: 'bg-brand-green/10 text-brand-green',
    média: 'bg-brand-amber/10 text-brand-amber',
    baixa: 'bg-brand-red/10 text-brand-red',
  }

  return (
    <div className="space-y-4 max-w-6xl">
      <div className="grid grid-cols-3 gap-4">
        <StatCard label="Total previsto (bruto)" value={formatBRL(total)} hint={`${exitoCases.length} casos com cláusula de êxito`} accent="amber" />
        <StatCard label="Ponderado por probabilidade" value={formatBRL(ponderado)} hint="Estimativa realista" accent="blue" />
        <StatCard label="Maior caso" value={formatBRL(maior.valor)} hint={maior.nome} accent="green" />
      </div>

      <div className="grid grid-cols-2 gap-3">
        {exitoCases.map((c) => (
          <Card key={c.id} className="p-4">
            <div className="flex items-start justify-between">
              <div>
                <div className="font-semibold">{c.caso}</div>
                <div className="text-xs text-neutral-500 mt-0.5">{c.area} · previsão {c.prazoEstimado}</div>
              </div>
              <span className={`text-[10px] uppercase px-2 py-0.5 rounded-full font-semibold ${probColor[c.probabilidade]}`}>
                {c.probabilidade}
              </span>
            </div>

            <div className="mt-4 flex items-end justify-between">
              <div>
                <div className="text-[11px] uppercase tracking-wide text-neutral-400">Êxito previsto</div>
                <div className="text-2xl font-semibold text-brand-green mt-0.5">{formatBRL(c.valorEstimado)}</div>
              </div>
              <div className="text-right text-xs text-neutral-500">
                <div>{c.percentual}% sobre</div>
                <div className="font-medium text-neutral-700 dark:text-neutral-200">{formatBRL(c.causaBase)}</div>
              </div>
            </div>

            <div className="mt-3 h-1.5 rounded-full bg-neutral-100 dark:bg-neutral-800 overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-brand-blue to-brand-green"
                style={{ width: `${c.probabilidade === 'alta' ? 75 : c.probabilidade === 'média' ? 50 : 25}%` }}
              />
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}

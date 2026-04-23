import { useState } from 'react'
import { Card } from '../../components/Card.jsx'
import { AlertTriangle, Activity, HelpCircle, Gavel, Calendar, CalendarClock, CheckSquare, ScanLine, BookOpen, TrendingUp, Target, Clock, Award, Paperclip } from 'lucide-react'
import { useAppState } from '../../store/AppContext.jsx'
import { getIndicadoresData, getProcessosMovimentacao, formatBRL, formatDateBR } from '../../store/selectors.js'

const TABS = [
  { id: 'geral', label: 'Visão Geral' },
  { id: 'estrategica', label: 'Gestão Estratégica' },
  { id: 'pessoais', label: 'Indicadores Pessoais' },
]

export default function Indicadores() {
  const [tab, setTab] = useState('geral')

  return (
    <div className="space-y-5 max-w-6xl">
      <div>
        <h2 className="text-xl font-semibold tracking-tight">Indicadores de Performance</h2>
        <p className="text-sm text-neutral-500 mt-0.5">Termômetro de urgência e produtividade do seu escritório.</p>
      </div>

      <div className="flex items-center gap-1 border-b border-neutral-200 dark:border-neutral-800">
        {TABS.map(({ id, label }) => (
          <button
            key={id}
            onClick={() => setTab(id)}
            className={`px-4 py-2.5 text-sm border-b-2 -mb-px transition ${
              tab === id
                ? 'border-brand-blue text-brand-blue font-medium'
                : 'border-transparent text-neutral-500 hover:text-neutral-800 dark:hover:text-neutral-200'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === 'geral' && <VisaoGeral />}
      {tab === 'estrategica' && <GestaoEstrategica />}
      {tab === 'pessoais' && <IndicadoresPessoais />}
    </div>
  )
}

function Tooltip({ text }) {
  return (
    <span className="group relative inline-flex">
      <HelpCircle size={13} className="text-neutral-400 hover:text-neutral-600 cursor-help" />
      <span className="absolute left-5 top-0 z-10 hidden group-hover:block w-64 p-2 text-[11px] leading-snug bg-neutral-900 text-neutral-100 rounded-md shadow-lg">
        {text}
      </span>
    </span>
  )
}

function BlockHeader({ title, tooltip, description }) {
  return (
    <div className="mb-3">
      <div className="flex items-center gap-1.5">
        <h3 className="font-semibold">{title}</h3>
        <Tooltip text={tooltip} />
      </div>
      {description && <p className="text-xs text-neutral-500 mt-0.5">{description}</p>}
    </div>
  )
}

function DelayMetric({ label, value, Icon }) {
  const alert = value > 0
  return (
    <div className="p-4 rounded-lg border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-neutral-900/40">
      <div className="flex items-center gap-2 text-xs uppercase tracking-wide text-neutral-500">
        <Icon size={13} />
        {label}
      </div>
      <div className={`mt-2 text-3xl font-semibold ${alert ? 'text-brand-red' : 'text-neutral-400'}`}>{value}</div>
    </div>
  )
}

function VisaoGeral() {
  const { state } = useAppState()
  const { tarefasAtrasadas, prazosAtrasados, anexosTarefas, agendaProcessual } = getIndicadoresData(state)
  const [periodo, setPeriodo] = useState('30d')
  const [objeto, setObjeto] = useState('todos')

  const movimentacao = getProcessosMovimentacao(state, periodo, objeto)
  const processosComExito = state.processos.filter((processo) => processo.exitoPercentual > 0).length

  return (
    <div className="space-y-5">
      <Card className="p-5">
        <BlockHeader
          title="Atividades atrasadas do escritório"
          tooltip="Pendências que ultrapassaram o prazo fatal ou a data agendada. Números maiores que zero indicam urgência."
          description="Monitoramento de pendências que ultrapassaram o prazo fatal ou a data agendada."
        />
        <div className="grid grid-cols-4 gap-3">
          <DelayMetric label="Prazos" value={prazosAtrasados} Icon={AlertTriangle} />
          <DelayMetric label="Audiências" value={0} Icon={Gavel} />
          <DelayMetric label="Eventos" value={0} Icon={Calendar} />
          <DelayMetric label="Tarefas" value={tarefasAtrasadas} Icon={CheckSquare} />
        </div>
      </Card>

      <Card className="p-5">
        <BlockHeader
          title="Movimentação de processos e casos do escritório"
          tooltip="Volume de interações e andamentos detectados no sistema de tribunais."
          description="Volume de interações e andamentos detectados no sistema de tribunais."
        />
        <div className="flex flex-wrap items-center gap-3 mb-5">
          <Select value={periodo} onChange={setPeriodo} options={[
            { v: '7d', l: 'Últimos 7 dias' },
            { v: '30d', l: 'Últimos 30 dias' },
            { v: 'mes', l: 'Mês atual' },
            { v: 'ano', l: 'Ano corrente' },
          ]} />
          <Select value={objeto} onChange={setObjeto} options={[
            { v: 'todos', l: 'Toda a carteira' },
            { v: 'com_exito', l: 'Somente com êxito' },
            { v: 'sem_exito', l: 'Sem êxito' },
          ]} />
        </div>
        <div className="grid grid-cols-2 gap-4">
          <MovCell label="Com movimentação" value={movimentacao.comMovimentacao} Icon={Activity} tone="positive" hint="processos com ato no período" />
          <MovCell label="Sem movimentação" value={movimentacao.semMovimentacao} Icon={Clock} tone="warning" hint={`${movimentacao.total} processos na seleção`} />
        </div>
      </Card>

      <Card className="p-5">
        <BlockHeader
          title="Base operacional"
          tooltip="Indicadores sobre a massa de dados já cadastrada no app, sem depender de integrações externas."
          description="Resumo do que já está documentado e estruturado no sistema."
        />
        <div className="grid grid-cols-3 gap-3">
          <AutomationCell label="Arquivos anexados" value={anexosTarefas} hint="Anexos nas tarefas do fluxo" Icon={Paperclip} />
          <AutomationCell label="Processos com êxito" value={processosComExito} hint="Casos alimentando previsão" Icon={ScanLine} />
          <AutomationCell label="Próximos atos" value={agendaProcessual.length} hint="Agenda jurídica futura" Icon={BookOpen} />
        </div>
      </Card>
    </div>
  )
}

function MovCell({ label, value, Icon, tone, hint }) {
  const toneClass = tone === 'positive' ? 'text-brand-green' : 'text-brand-amber'
  return (
    <div className="p-4 rounded-lg border border-neutral-200 dark:border-neutral-800">
      <div className="flex items-center gap-2 text-xs uppercase tracking-wide text-neutral-500">
        <Icon size={13} />
        {label}
      </div>
      <div className={`mt-2 text-3xl font-semibold ${toneClass}`}>{value}</div>
      <div className="text-xs text-neutral-500 mt-1">{hint}</div>
    </div>
  )
}

function AutomationCell({ label, value, hint, Icon }) {
  return (
    <div className="p-4 rounded-lg border border-neutral-200 dark:border-neutral-800 flex items-center gap-4">
      <div className="w-10 h-10 rounded-lg bg-brand-blue/10 text-brand-blue flex items-center justify-center">
        <Icon size={18} />
      </div>
      <div>
        <div className="text-xs uppercase tracking-wide text-neutral-500">{label}</div>
        <div className="text-2xl font-semibold text-brand-blue">{value}</div>
        <div className="text-xs text-neutral-500">{hint}</div>
      </div>
    </div>
  )
}

function Select({ value, onChange, options }) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="text-sm px-3 py-1.5 rounded-md border border-neutral-200 dark:border-neutral-700 bg-white dark:bg-neutral-900 text-neutral-700 dark:text-neutral-200 focus:outline-none focus:ring-2 focus:ring-brand-blue/30"
    >
      {options.map((o) => <option key={o.v} value={o.v}>{o.l}</option>)}
    </select>
  )
}

function GestaoEstrategica() {
  const { state } = useAppState()
  const { porArea, taxaExitoMedia, ticketMedio, progressoMetasFinanceiras } = getIndicadoresData(state)

  return (
    <div className="space-y-5">
      <Card className="p-5">
        <BlockHeader
          title="Produtividade por área"
          tooltip="Distribuição de casos ativos, êxito previsto e rentabilidade por área de atuação."
          description="Foco em produtividade, êxito e rentabilidade."
        />
        <div className="overflow-hidden rounded-lg border border-neutral-200 dark:border-neutral-800">
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 dark:bg-neutral-800/40 text-xs uppercase tracking-wide text-neutral-500">
              <tr>
                <th className="text-left px-4 py-2.5">Área</th>
                <th className="text-right px-4 py-2.5">Casos ativos</th>
                <th className="text-right px-4 py-2.5">Êxito previsto</th>
                <th className="text-left px-4 py-2.5 w-56">Rentabilidade</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100 dark:divide-neutral-800">
              {porArea.map((a) => (
                <tr key={a.area}>
                  <td className="px-4 py-3 font-medium">{a.area}</td>
                  <td className="px-4 py-3 text-right">{a.ativos}</td>
                  <td className="px-4 py-3 text-right font-semibold">{formatBRL(a.exitoPrevisto)}</td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <div className="flex-1 h-1.5 rounded-full bg-neutral-100 dark:bg-neutral-800 overflow-hidden">
                        <div className="h-full bg-gradient-to-r from-brand-blue to-brand-green" style={{ width: `${a.rentabilidade}%` }} />
                      </div>
                      <span className="text-xs font-medium text-neutral-600 dark:text-neutral-300 w-9 text-right">{a.rentabilidade}%</span>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      <div className="grid grid-cols-3 gap-4">
        <Kpi label="Taxa de êxito média" value={`${taxaExitoMedia}%`} Icon={Award} tone="green" hint="ponderada pela probabilidade" />
        <Kpi label="Ticket médio" value={formatBRL(ticketMedio)} Icon={TrendingUp} tone="blue" />
        <Kpi label="Metas financeiras" value={`${progressoMetasFinanceiras}%`} Icon={Target} tone="amber" hint="progresso médio cadastrado" />
      </div>
    </div>
  )
}

function Kpi({ label, value, Icon, tone, hint }) {
  const tones = { green: 'text-brand-green', blue: 'text-brand-blue', amber: 'text-brand-amber' }
  return (
    <Card className="p-4 flex items-center gap-4">
      <div className="w-10 h-10 rounded-lg bg-neutral-100 dark:bg-neutral-800 flex items-center justify-center">
        <Icon size={18} className={tones[tone]} />
      </div>
      <div>
        <div className="text-xs uppercase tracking-wide text-neutral-500">{label}</div>
        <div className={`text-xl font-semibold ${tones[tone]}`}>{value}</div>
        {hint && <div className="text-xs text-neutral-500">{hint}</div>}
      </div>
    </Card>
  )
}

function IndicadoresPessoais() {
  const { state } = useAppState()
  const { hon, totalExito, audienciasMes, peticoesMes, agendaProcessual } = getIndicadoresData(state)

  return (
    <div className="space-y-5">
      <div className="grid grid-cols-4 gap-4">
        <Kpi label="Processos ativos" value={String(state.processos.length)} Icon={Gavel} tone="blue" />
        <Kpi label="Audiências no mês" value={String(audienciasMes)} Icon={CalendarClock} tone="amber" />
        <Kpi label="Atos no mês" value={String(peticoesMes)} Icon={Activity} tone="green" />
        <Kpi label="Agenda futura" value={String(agendaProcessual.length)} Icon={Clock} tone="blue" hint="próximos atos cadastrados" />
      </div>

      <Card className="p-5">
        <BlockHeader
          title="Próximos atos processuais"
          tooltip="Linha de frente da sua agenda jurídica, baseada no cadastro atual de processos."
          description="Agenda derivada dos próximos atos cadastrados."
        />
        <ul className="space-y-2 text-sm">
          {agendaProcessual.length === 0 ? (
            <li className="text-neutral-500">Nenhum próximo ato cadastrado.</li>
          ) : (
            agendaProcessual.map((processo) => (
              <li key={processo.id} className="flex items-center gap-3 py-1.5 border-b border-neutral-100 dark:border-neutral-800 last:border-0">
                <span className="text-xs font-mono text-neutral-500 w-14">{formatDateBR(processo.proxAto)}</span>
                <span className="flex-1 font-medium">{processo.proxAtoDesc}</span>
                <span className="text-xs text-neutral-500">{processo.cliente}</span>
              </li>
            ))
          )}
        </ul>
      </Card>

      <Card className="p-5">
        <BlockHeader
          title="Metas individuais"
          tooltip="Progresso de metas no trimestre."
          description="Trimestre atual."
        />
        <div className="space-y-3">
          {[
            { label: 'Faturamento de honorários', atual: hon.recebido, meta: hon.total, tone: 'green' },
            { label: 'Êxito previsto ponderado', atual: totalExito * 0.6, meta: totalExito, tone: 'blue' },
            { label: 'Processos ativos', atual: state.processos.length, meta: 12, tone: 'amber', unit: '' },
          ].map((m) => {
            const pct = m.meta > 0 ? Math.min(100, Math.round((m.atual / m.meta) * 100)) : 0
            const fmt = (v) => m.unit === '' ? v : formatBRL(v)
            return (
              <div key={m.label}>
                <div className="flex items-center justify-between text-sm">
                  <span className="font-medium">{m.label}</span>
                  <span className="text-xs text-neutral-500">
                    {fmt(Math.round(m.atual))} / {fmt(Math.round(m.meta))} · <span className="font-semibold text-neutral-700 dark:text-neutral-200">{pct}%</span>
                  </span>
                </div>
                <div className="mt-1.5 h-1.5 rounded-full bg-neutral-100 dark:bg-neutral-800 overflow-hidden">
                  <div
                    className={`h-full ${m.tone === 'green' ? 'bg-brand-green' : m.tone === 'blue' ? 'bg-brand-blue' : 'bg-brand-amber'}`}
                    style={{ width: `${pct}%` }}
                  />
                </div>
              </div>
            )
          })}
        </div>
      </Card>
    </div>
  )
}

export function formatBRL(value) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value)
}

export function formatDateBR(iso) {
  if (!iso) return ''
  const [, m, d] = iso.split('-')
  return `${d}/${m}`
}

export function getFinancasSummary(state) {
  const now = new Date()
  const currentMonthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`

  const entradasFixas = state.incomes
    .filter(i => i.type === 'fixa')
    .reduce((s, i) => s + i.value, 0)

  const entradasVariaveis = state.incomes
    .filter(i => i.type === 'variável')
    .reduce((s, i) => {
      if (!i.startDate) return s + i.value
      const start = new Date(i.startDate + 'T00:00:00')
      const diffMonths = (now.getFullYear() - start.getFullYear()) * 12 + (now.getMonth() - start.getMonth())
      if (diffMonths >= 0 && diffMonths < (i.durationMonths || 1)) {
        return s + i.value
      }
      return s
    }, 0)

  const today = new Date()
  const honorariosNoMes = state.honorarios
    .filter(h => {
      const d = new Date(h.venc + 'T00:00:00')
      return d.getMonth() === today.getMonth() && d.getFullYear() === today.getFullYear()
    })

  const honorariosPagos = honorariosNoMes
    .filter(h => h.status === 'pago')
    .reduce((s, h) => s + h.valor, 0)

  const honorariosPendentes = honorariosNoMes
    .filter(h => h.status === 'pendente')
    .reduce((s, h) => s + h.valor, 0)

  const saidasProjetadas = state.boletos
    .filter(b => {
      const d = new Date(b.dueDate + 'T00:00:00')
      return b.status !== 'pago' && d.getMonth() === today.getMonth() && d.getFullYear() === today.getFullYear()
    })
    .reduce((s, b) => s + b.value, 0)

  const totalEntradas = entradasFixas + entradasVariaveis + honorariosPagos + honorariosPendentes

  return {
    entradasFixas,
    entradasVariaveis: entradasVariaveis + honorariosPagos + honorariosPendentes,
    saidasProjetadas,
    saldoFinal: totalEntradas - saidasProjetadas,
  }
}


export function getBoletosByCategoria(state) {
  return state.categorias
    .map(cat => {
      const catBoletos = state.boletos.filter(b => b.categoriaId === cat.id)
      const nextPending = catBoletos
        .filter(b => b.status !== 'pago')
        .sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate))[0]
      return { ...cat, count: catBoletos.length, nextBoleto: nextPending }
    })
    .filter(c => c.count > 0)
}

export function getExitoCases(state) {
  return state.processos
    .filter(p => p.exitoPercentual > 0)
    .map(p => ({
      id: p.id,
      caso: p.cliente,
      area: p.area,
      percentual: p.exitoPercentual,
      causaBase: p.valorCausa,
      probabilidade: p.exitoProbabilidade,
      prazoEstimado: p.exitoPrazo,
      valorEstimado: (p.valorCausa * p.exitoPercentual) / 100,
    }))
}

export function getHonorariosSummary(state) {
  const total = state.honorarios.reduce((s, h) => s + h.valor, 0)
  const pendente = state.honorarios.filter(h => h.status === 'pendente').reduce((s, h) => s + h.valor, 0)
  const recebido = state.honorarios.filter(h => h.status === 'pago').reduce((s, h) => s + h.valor, 0)
  return { total, pendente, recebido }
}

export function getDashboardStats(state) {
  const today = new Date().toISOString().split('T')[0]
  const in7Days = new Date()
  in7Days.setDate(in7Days.getDate() + 7)
  const in7DaysStr = in7Days.toISOString().split('T')[0]

  const allTasks = Object.values(state.tarefas).flatMap(col => col.tasks)
  const tasksDueToday = allTasks.filter(t => t.dueDate && t.dueDate <= today)

  const boletosDue = state.boletos
    .filter(b => b.status !== 'pago' && b.dueDate <= in7DaysStr)
    .sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate))

  const proximosAtos = [...state.processos]
    .filter(p => p.proxAto >= today)
    .sort((a, b) => new Date(a.proxAto) - new Date(b.proxAto))
    .slice(0, 3)

  const financas = getFinancasSummary(state)

  return { tasksDueToday, boletosDue, proximosAtos, financas, metasAtivas: state.metas.length }
}

export function getIndicadoresData(state) {
  const today = new Date().toISOString().split('T')[0]
  const now = new Date()
  const currentMonth = now.getMonth()
  const currentYear = now.getFullYear()

  const allTasks = Object.values(state.tarefas).flatMap(col => col.tasks)
  const tarefasAtrasadas = allTasks.filter(t => t.dueDate && t.dueDate < today).length
  const prazosAtrasados = state.processos.filter(p => p.proxAto < today).length
  const anexosTarefas = allTasks.reduce((sum, task) => sum + task.attachments.length, 0)

  const processosMes = state.processos.filter(p => {
    const date = new Date(p.proxAto)
    return date.getMonth() === currentMonth && date.getFullYear() === currentYear
  })

  const audienciasMes = processosMes.filter(p =>
    p.proxAtoDesc?.toLowerCase().includes('audi')
  ).length

  const peticoesMes = processosMes.filter(p =>
    !p.proxAtoDesc?.toLowerCase().includes('audi')
  ).length

  const agendaProcessual = [...state.processos]
    .filter(p => p.proxAto >= today)
    .sort((a, b) => new Date(a.proxAto) - new Date(b.proxAto))
    .slice(0, 5)

  const porArea = Object.entries(
    state.processos.reduce((acc, p) => {
      if (!acc[p.area]) acc[p.area] = { ativos: 0, exitoPrevisto: 0 }
      acc[p.area].ativos++
      acc[p.area].exitoPrevisto += (p.valorCausa * p.exitoPercentual) / 100
      return acc
    }, {})
  ).map(([area, d]) => ({ area, ativos: d.ativos, exitoPrevisto: d.exitoPrevisto, rentabilidade: 65 }))
    .sort((a, b) => b.exitoPrevisto - a.exitoPrevisto)

  const hon = getHonorariosSummary(state)
  const exitoCases = getExitoCases(state)
  const totalExito = exitoCases.reduce((s, c) => s + c.valorEstimado, 0)
  const totalExitoPonderado = exitoCases.reduce((s, c) => {
    const weight = c.probabilidade === 'alta' ? 0.75 : c.probabilidade === 'média' ? 0.5 : 0.25
    return s + (c.valorEstimado * weight)
  }, 0)
  const taxaExitoMedia = totalExito > 0 ? Math.round((totalExitoPonderado / totalExito) * 100) : 0
  const ticketMedio = state.processos.length > 0
    ? state.processos.reduce((s, p) => s + p.valorCausa, 0) / state.processos.length
    : 0
  const metasFinanceiras = state.metas.filter(meta => meta.type === 'financeira')
  const progressoMetasFinanceiras = metasFinanceiras.length > 0
    ? Math.round(metasFinanceiras.reduce((sum, meta) => sum + meta.progress, 0) / metasFinanceiras.length)
    : 0

  return {
    tarefasAtrasadas,
    prazosAtrasados,
    porArea,
    hon,
    totalExito,
    anexosTarefas,
    audienciasMes,
    peticoesMes,
    agendaProcessual,
    taxaExitoMedia,
    ticketMedio,
    progressoMetasFinanceiras,
  }
}

export function getProcessosMovimentacao(state, periodo = '30d', filtro = 'todos') {
  const today = new Date()
  const start = new Date(today)

  if (periodo === '7d') start.setDate(today.getDate() - 7)
  if (periodo === '30d') start.setDate(today.getDate() - 30)
  if (periodo === 'mes') start.setDate(1)
  if (periodo === 'ano') {
    start.setMonth(0)
    start.setDate(1)
  }

  const processos = state.processos.filter((processo) => {
    if (filtro === 'com_exito') return processo.exitoPercentual > 0
    if (filtro === 'sem_exito') return processo.exitoPercentual <= 0
    return true
  })

  const comMovimentacao = processos.filter((processo) => {
    const date = new Date(processo.proxAto)
    return date >= start && date <= today
  }).length

  return {
    comMovimentacao,
    semMovimentacao: Math.max(0, processos.length - comMovimentacao),
    total: processos.length,
  }
}

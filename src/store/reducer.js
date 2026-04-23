import { createDemoState, createEmptyState } from './initialState.js'

function recalculateFlow(state) {
  const newFlow = state.monthlyFlow.map(m => ({ ...m, in: 0, out: 0 }))

  // Process Incomes
  state.incomes.forEach(inc => {
    newFlow.forEach(month => {
      if (inc.type === 'fixa') {
        month.in += inc.value
      } else if (inc.type === 'variável') {
        const start = new Date(inc.startDate + 'T00:00:00')
        const monthDate = new Date(month.month + '-01T00:00:00')

        const diffMonths = (monthDate.getFullYear() - start.getFullYear()) * 12 + (monthDate.getMonth() - start.getMonth())
        if (diffMonths >= 0 && diffMonths < (inc.durationMonths || 1)) {
          month.in += inc.value
        }
      }
    })
  })

  // Process Boletos
  state.boletos.forEach(bol => {
    newFlow.forEach(month => {
      const bolDate = new Date(bol.dueDate + 'T00:00:00')
      const bolMonthStr = `${bolDate.getFullYear()}-${String(bolDate.getMonth() + 1).padStart(2, '0')}`

      if (bol.status === 'recorrente') {
        const monthDate = new Date(month.month + '-01T00:00:00')
        const bolStartMonth = new Date(bolDate.getFullYear(), bolDate.getMonth(), 1)
        if (monthDate >= bolStartMonth) {
          month.out += bol.value
        }
      } else if ((bol.status === 'pendente' || bol.status === 'pago') && bolMonthStr === month.month) {
        month.out += bol.value
      }
    })
  })

  // Process Honorarios
  state.honorarios.forEach(hon => {
    newFlow.forEach(month => {
      const honDate = new Date(hon.venc + 'T00:00:00')
      const honMonthStr = `${honDate.getFullYear()}-${String(honDate.getMonth() + 1).padStart(2, '0')}`
      if (honMonthStr === month.month) {
        month.in += hon.valor
      }
    })
  })

  return { ...state, monthlyFlow: newFlow }
}


export function reducer(state, action) {
  switch (action.type) {

    case 'WORKSPACE_RESET':
      return createEmptyState()

    case 'WORKSPACE_LOAD_DEMO':
      return createDemoState()

    case 'TAREFAS_UPDATE':
      return { ...state, tarefas: action.payload }

    case 'TAREFA_ADD': {
      const {
        colId,
        title,
        priority = 'média',
        tag = 'Geral',
        goal = '',
        dueDate = '',
        notes = '',
      } = action.payload
      const col = state.tarefas[colId]
      if (!col) return state
      const task = {
        id: crypto.randomUUID(),
        title,
        priority,
        tag,
        goal,
        dueDate,
        notes,
        checklist: [],
        attachments: [],
      }
      return {
        ...state,
        tarefas: {
          ...state.tarefas,
          [colId]: { ...col, tasks: [...col.tasks, task] },
        },
      }
    }

    case 'TAREFA_UPDATE': {
      const { colId, taskId, patch } = action.payload
      const col = state.tarefas[colId]
      return {
        ...state,
        tarefas: {
          ...state.tarefas,
          [colId]: { ...col, tasks: col.tasks.map(t => t.id === taskId ? { ...t, ...patch } : t) },
        },
      }
    }

    case 'TAREFA_MOVE': {
      const { fromCol, taskId, toCol } = action.payload
      if (fromCol === toCol) return state
      const from = state.tarefas[fromCol]
      const to = state.tarefas[toCol]
      const task = from.tasks.find(t => t.id === taskId)
      if (!task) return state
      return {
        ...state,
        tarefas: {
          ...state.tarefas,
          [fromCol]: { ...from, tasks: from.tasks.filter(t => t.id !== taskId) },
          [toCol]: { ...to, tasks: [...to.tasks, task] },
        },
      }
    }

    case 'META_UPDATE': {
      const { id, patch } = action.payload
      return { ...state, metas: state.metas.map(m => m.id === id ? { ...m, ...patch } : m) }
    }

    case 'META_ADD': {
      const {
        title,
        type = 'pessoal',
        current = null,
        target = null,
        deadline = '',
        milestones = [],
      } = action.payload
      const normalizedCurrent = current === '' || current == null ? null : Number(current)
      const normalizedTarget = target === '' || target == null ? null : Number(target)
      const progress = normalizedCurrent != null && normalizedTarget
        ? Math.max(0, Math.min(100, Math.round((normalizedCurrent / normalizedTarget) * 100)))
        : 0

      return {
        ...state,
        metas: [
          ...state.metas,
          {
            id: crypto.randomUUID(),
            title,
            type,
            progress,
            current: normalizedCurrent,
            target: normalizedTarget,
            deadline,
            milestones,
          },
        ],
      }
    }

    case 'META_MILESTONE_TOGGLE': {
      const { metaId, index } = action.payload
      return {
        ...state,
        metas: state.metas.map(m => {
          if (m.id !== metaId) return m
          const milestones = m.milestones.map((ms, i) => i === index ? { ...ms, done: !ms.done } : ms)
          const doneCt = milestones.filter(ms => ms.done).length
          const progress = Math.round((doneCt / milestones.length) * 100)
          return { ...m, milestones, progress }
        }),
      }
    }

    case 'BOLETO_UPDATE_STATUS': {
      const { id, status } = action.payload
      return recalculateFlow({ ...state, boletos: state.boletos.map(b => b.id === id ? { ...b, status } : b) })
    }

    case 'BOLETO_ADD':
      return recalculateFlow({ ...state, boletos: [...state.boletos, { id: crypto.randomUUID(), ...action.payload }] })

    case 'CATEGORIA_ADD':
      return { ...state, categorias: [...state.categorias, { id: crypto.randomUUID(), ...action.payload }] }

    case 'INCOME_ADD':
      return recalculateFlow({ ...state, incomes: [...state.incomes, { id: crypto.randomUUID(), ...action.payload }] })

    case 'INCOME_UPDATE': {
      const { id, patch } = action.payload
      return recalculateFlow({ ...state, incomes: state.incomes.map(i => i.id === id ? { ...i, ...patch } : i) })
    }

    case 'INCOME_DELETE':
      return recalculateFlow({ ...state, incomes: state.incomes.filter(i => i.id !== action.payload) })


    case 'MONTHLY_UPDATE': {
      const { month, patch } = action.payload
      return {
        ...state,
        monthlyFlow: state.monthlyFlow.map(m => m.month === month ? { ...m, ...patch } : m),
      }
    }

    case 'PROCESSO_ADD':
      return { ...state, processos: [...state.processos, { id: crypto.randomUUID(), ...action.payload }] }

    case 'PROCESSO_UPDATE': {
      const { id, patch } = action.payload
      return { ...state, processos: state.processos.map(p => p.id === id ? { ...p, ...patch } : p) }
    }

    case 'HONORARIO_UPDATE_STATUS': {
      const { id, status } = action.payload
      return recalculateFlow({ ...state, honorarios: state.honorarios.map(h => h.id === id ? { ...h, status } : h) })
    }

    case 'HONORARIO_ADD':
      return recalculateFlow({ ...state, honorarios: [...state.honorarios, { id: crypto.randomUUID(), ...action.payload }] })

    default:
      return state
  }
}


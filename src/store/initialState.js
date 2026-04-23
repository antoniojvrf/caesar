function getTwelveMonths(count = 12, pastCount = 2) {
  const formatter = new Intl.DateTimeFormat('pt-BR', { month: 'short' })
  const today = new Date()
  const months = []

  for (let offset = -pastCount; offset < count - pastCount; offset += 1) {
    const date = new Date(today.getFullYear(), today.getMonth() + offset, 1)
    const label = formatter.format(date).replace('.', '')
    months.push({
      month: `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`,
      label: label.charAt(0).toUpperCase() + label.slice(1),
      in: 0,
      out: 0,
    })
  }

  return months
}

export function createEmptyState() {
  return {
    tarefas: {
      hoje: { name: 'Hoje', tasks: [] },
      semana: { name: 'Esta semana', tasks: [] },
      proximas: { name: 'Próximas', tasks: [] },
    },
    metas: [],
    categorias: [],
    boletos: [],
    incomes: [],
    monthlyFlow: getTwelveMonths(),
    processos: [],
    honorarios: [],
  }
}



export function createDemoState() {
  return {
    tarefas: {
      hoje: {
        name: 'Hoje',
        tasks: [
          {
            id: 't1', title: 'Revisar investimentos', priority: 'alta', tag: 'Finanças',
            goal: 'Reserva de emergência — 6 meses', dueDate: '2026-04-17',
            notes: 'Verificar rentabilidade do CDB e rebalancear carteira.',
            checklist: [
              { text: 'Abrir home broker', done: true },
              { text: 'Conferir alocação', done: false },
              { text: 'Rebalancear se necessário', done: false },
            ],
            attachments: [{ name: 'extrato-abril.pdf', size: '284 KB' }],
          },
          {
            id: 't2', title: 'Ligar para seguradora', priority: 'média', tag: 'Carro',
            dueDate: '2026-04-17', notes: '', checklist: [], attachments: [],
          },
        ],
      },
      semana: {
        name: 'Esta semana',
        tasks: [
          {
            id: 't3', title: 'Agendar check-up médico', priority: 'alta', tag: 'Saúde',
            goal: 'Saúde em dia', dueDate: '2026-04-22',
            notes: 'Clínica São Luiz, convênio ativo.',
            checklist: [
              { text: 'Ligar para marcar', done: false },
              { text: 'Separar carteirinha', done: false },
            ],
            attachments: [],
          },
          {
            id: 't4', title: 'Organizar documentos IR', priority: 'média', tag: 'Finanças',
            dueDate: '2026-04-25', notes: '', checklist: [], attachments: [],
          },
          {
            id: 't5', title: 'Renovar CNH', priority: 'baixa', tag: 'Documentos',
            dueDate: '2026-04-30', notes: '', checklist: [], attachments: [],
          },
        ],
      },
      proximas: {
        name: 'Próximas',
        tasks: [
          {
            id: 't6', title: 'Pesquisar cursos de inglês', priority: 'baixa', tag: 'Estudo',
            goal: 'Fluência em inglês', dueDate: '', notes: '', checklist: [], attachments: [],
          },
          {
            id: 't7', title: 'Planejar férias de julho', priority: 'baixa', tag: 'Pessoal',
            dueDate: '', notes: '', checklist: [], attachments: [],
          },
        ],
      },
    },

    metas: [
      {
        id: 'm1', title: 'Reserva de emergência — 6 meses', type: 'financeira',
        progress: 58, current: 17400, target: 30000, deadline: 'Dez 2026',
        milestones: [
          { label: 'R$ 10.000', done: true },
          { label: 'R$ 20.000', done: false },
          { label: 'R$ 30.000', done: false },
        ],
      },
      {
        id: 'm2', title: 'Quitar financiamento do carro', type: 'financeira',
        progress: 34, current: 8200, target: 24000, deadline: 'Jun 2027',
        milestones: [
          { label: '25%', done: true },
          { label: '50%', done: false },
          { label: '75%', done: false },
          { label: 'Quitado', done: false },
        ],
      },
      {
        id: 'm3', title: 'Saúde em dia', type: 'pessoal',
        progress: 70, current: null, target: null, deadline: 'Contínuo',
        milestones: [
          { label: 'Check-up anual', done: true },
          { label: '3x academia/semana', done: true },
          { label: 'Dentista', done: false },
        ],
      },
      {
        id: 'm4', title: 'Fluência em inglês', type: 'pessoal',
        progress: 25, current: null, target: null, deadline: 'Dez 2026',
        milestones: [
          { label: 'Definir escola', done: true },
          { label: 'Completar A2', done: false },
          { label: 'Completar B1', done: false },
          { label: 'Completar B2', done: false },
        ],
      },
    ],

    categorias: [
      { id: 'c1', name: 'Seguro do Carro', color: '#2563EB', recurring: false },
      { id: 'c2', name: 'Internet', color: '#10B981', recurring: true },
      { id: 'c3', name: 'Academia', color: '#F59E0B', recurring: true },
      { id: 'c4', name: 'Cartão Nubank', color: '#EF4444', recurring: false },
      { id: 'c5', name: 'IPTU', color: '#8B5CF6', recurring: false },
      { id: 'c6', name: 'Condomínio', color: '#14B8A6', recurring: true },
      { id: 'c7', name: 'Energia', color: '#F97316', recurring: true },
      { id: 'c8', name: 'Água', color: '#06B6D4', recurring: true },
    ],

    boletos: [
      { id: 'b1', categoriaId: 'c1', desc: 'Parcela 04/12', dueDate: '2026-04-20', value: 348.90, status: 'pendente' },
      { id: 'b2', categoriaId: 'c2', desc: 'Mensalidade abril', dueDate: '2026-04-22', value: 129.90, status: 'pendente' },
      { id: 'b3', categoriaId: 'c6', desc: 'Taxa abril', dueDate: '2026-04-05', value: 780.00, status: 'pago' },
      { id: 'b4', categoriaId: 'c3', desc: 'Mensalidade abril', dueDate: '2026-04-25', value: 99.90, status: 'recorrente' },
      { id: 'b5', categoriaId: 'c4', desc: 'Fatura abril', dueDate: '2026-04-28', value: 2140.50, status: 'pendente' },
    ],

    incomes: [
      { id: 'i1', desc: 'Salário CLT', type: 'fixa', value: 9500 },
      { id: 'i2', desc: 'Freelance Projeto X', type: 'variável', value: 2400 },
      { id: 'i3', desc: 'Dividendos', type: 'variável', value: 500 },
    ],

    monthlyFlow: [
      { month: '2025-11', label: 'Nov', in: 11800, out: 4200 },
      { month: '2025-12', label: 'Dez', in: 14200, out: 6100 },
      { month: '2026-01', label: 'Jan', in: 11500, out: 3800 },
      { month: '2026-02', label: 'Fev', in: 12100, out: 4500 },
      { month: '2026-03', label: 'Mar', in: 12400, out: 4900 },
      { month: '2026-04', label: 'Abr', in: 12400, out: 3219 },
    ],

    processos: [
      {
        id: 'p1', numero: '1001234-56.2025.8.26.0100', cliente: 'Silva & Cia Ltda',
        area: 'Cível', fase: 'Instrução', proxAto: '2026-04-22', proxAtoDesc: 'Audiência',
        valorCausa: 85000, exitoPercentual: 15, exitoProbabilidade: 'média', exitoPrazo: 'Dez/2026',
      },
      {
        id: 'p2', numero: '2004567-89.2024.5.02.0011', cliente: 'João Pereira',
        area: 'Trabalhista', fase: 'Recursal', proxAto: '2026-05-05', proxAtoDesc: 'Contrarrazões',
        valorCausa: 42000, exitoPercentual: 30, exitoProbabilidade: 'alta', exitoPrazo: 'Jul/2026',
      },
      {
        id: 'p3', numero: '0501234-11.2025.8.26.0053', cliente: 'Maria Souza',
        area: 'Família', fase: 'Inicial', proxAto: '2026-04-28', proxAtoDesc: 'Contestação',
        valorCausa: 12000, exitoPercentual: 20, exitoProbabilidade: 'alta', exitoPrazo: 'Ago/2026',
      },
      {
        id: 'p4', numero: '3002345-67.2023.4.03.6100', cliente: 'Tech Solutions SA',
        area: 'Tributário', fase: 'Execução', proxAto: '2026-05-15', proxAtoDesc: 'Manifestação',
        valorCausa: 210000, exitoPercentual: 20, exitoProbabilidade: 'alta', exitoPrazo: 'Set/2026',
      },
      {
        id: 'p5', numero: '0403456-22.2025.8.26.0010', cliente: 'Ana Costa',
        area: 'Consumidor', fase: 'Sentença', proxAto: '2026-05-03', proxAtoDesc: 'Apelação',
        valorCausa: 8500, exitoPercentual: 30, exitoProbabilidade: 'baixa', exitoPrazo: 'Nov/2026',
      },
      {
        id: 'p6', numero: '0701122-33.2024.8.26.0100', cliente: 'Ricardo Alves',
        area: 'Indenizatória', fase: 'Instrução', proxAto: '2026-05-20', proxAtoDesc: 'Perícia',
        valorCausa: 120000, exitoPercentual: 25, exitoProbabilidade: 'média', exitoPrazo: 'Out/2026',
      },
      {
        id: 'p7', numero: '0902345-44.2025.8.26.0053', cliente: 'Beta Comércio ME',
        area: 'Cível', fase: 'Recursal', proxAto: '2026-06-01', proxAtoDesc: 'Sustentação oral',
        valorCausa: 95000, exitoPercentual: 20, exitoProbabilidade: 'média', exitoPrazo: 'Jan/2027',
      },
      {
        id: 'p8', numero: '1203456-77.2025.8.26.0100', cliente: 'Carla Mendes',
        area: 'Previdenciário', fase: 'Inicial', proxAto: '2026-04-30', proxAtoDesc: 'Citação',
        valorCausa: 45000, exitoPercentual: 30, exitoProbabilidade: 'alta', exitoPrazo: 'Jun/2026',
      },
    ],

    honorarios: [
      { id: 'h1', processoId: 'p1', cliente: 'Silva & Cia Ltda', processo: '1001234-56', tipo: 'Parcela 03/06', venc: '2026-04-20', valor: 6500, status: 'pendente' },
      { id: 'h2', processoId: 'p2', cliente: 'João Pereira', processo: '2004567-89', tipo: 'Honorário contratual', venc: '2026-04-10', valor: 4200, status: 'pago' },
      { id: 'h3', processoId: 'p4', cliente: 'Tech Solutions SA', processo: '3002345-67', tipo: 'Parcela 08/12', venc: '2026-04-25', valor: 18500, status: 'pendente' },
      { id: 'h4', processoId: 'p3', cliente: 'Maria Souza', processo: '0501234-11', tipo: 'Entrada', venc: '2026-04-15', valor: 3600, status: 'pago' },
      { id: 'h5', processoId: 'p5', cliente: 'Ana Costa', processo: '0403456-22', tipo: 'Parcela 02/04', venc: '2026-04-28', valor: 2100, status: 'pendente' },
      { id: 'h6', processoId: 'p1', cliente: 'Silva & Cia Ltda', processo: '1001234-56', tipo: 'Custas reembolso', venc: '2026-05-05', valor: 1800, status: 'pendente' },
      { id: 'h7', processoId: 'p6', cliente: 'Ricardo Alves', processo: '0701122-33', tipo: 'Parcela única', venc: '2026-05-12', valor: 9500, status: 'pendente' },
    ],
  }
}

export const initialState = createEmptyState()

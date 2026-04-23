import { useRef, useState } from 'react'
import {
  AlertCircle,
  CalendarDays,
  CheckCircle2,
  FileSearch,
  FileText,
  LoaderCircle,
  Paperclip,
  Repeat,
  Upload,
} from 'lucide-react'
import { Card } from '../components/Card.jsx'
import Modal from '../components/Modal.jsx'
import { useAppState } from '../store/AppContext.jsx'
import { formatBRL, formatDateBR, getBoletosByCategoria } from '../store/selectors.js'

export default function Boletos() {
  const { state, dispatch } = useAppState()
  const [isCreating, setIsCreating] = useState(false)
  const [isImporting, setIsImporting] = useState(false)
  const [importDraft, setImportDraft] = useState(null)
  const [importError, setImportError] = useState('')
  const fileInputRef = useRef(null)
  const categorias = getBoletosByCategoria(state)
  const catMap = Object.fromEntries(state.categorias.map((c) => [c.id, c]))
  const canCreateBoleto = state.categorias.length > 0

  function toggleStatus(id, current) {
    const next = current === 'pago' ? 'pendente' : 'pago'
    dispatch({ type: 'BOLETO_UPDATE_STATUS', payload: { id, status: next } })
  }

  function openFilePicker() {
    fileInputRef.current?.click()
  }

  async function handleFileSelection(event) {
    const file = event.target.files?.[0]
    event.target.value = ''
    if (!file) return

    setImportError('')
    setIsImporting(true)

    try {
      const { importBoletoFromPdf } = await import('../utils/boletoImport.js')
      const draft = await importBoletoFromPdf(file, state.categorias)
      setImportDraft(draft)
    } catch (error) {
      setImportError(error.message || 'Falha ao importar este PDF.')
    } finally {
      setIsImporting(false)
    }
  }

  function saveImportedBoleto(payload) {
    dispatch({ type: 'BOLETO_ADD', payload })
    setImportDraft(null)
  }

  return (
    <div className="space-y-6 max-w-6xl">
      <input
        ref={fileInputRef}
        type="file"
        accept="application/pdf"
        className="hidden"
        onChange={handleFileSelection}
      />

      <Card className="p-6 border-dashed border-2 border-brand-blue/30 bg-brand-blue/5">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-brand-blue/15 text-brand-blue flex items-center justify-center">
            {isImporting ? <LoaderCircle size={22} className="animate-spin" /> : <Upload size={22} />}
          </div>
          <div className="flex-1">
            <div className="font-semibold">Importar boleto em PDF</div>
            <div className="text-sm text-neutral-500 mt-0.5">
              Extraimos texto do PDF, preenchemos os campos e voce revisa antes de salvar.
            </div>
            {importError && (
              <div className="mt-3 flex items-start gap-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
                <AlertCircle size={16} className="mt-0.5 shrink-0" />
                <span>{importError}</span>
              </div>
            )}
          </div>
          <button
            onClick={openFilePicker}
            disabled={isImporting}
            className="px-4 py-2 text-sm font-medium bg-brand-blue text-white rounded-lg hover:bg-blue-700 disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {isImporting ? 'Lendo PDF...' : 'Selecionar PDF'}
          </button>
        </div>
      </Card>

      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="font-semibold">Categorias</h2>
          <button
            onClick={() => canCreateBoleto && setIsCreating(true)}
            disabled={!canCreateBoleto}
            className="text-xs text-brand-blue hover:underline disabled:text-neutral-400 disabled:no-underline"
          >
            + Novo boleto
          </button>
        </div>
        <div className="grid grid-cols-3 gap-4">
          {categorias.map((c) => (
            <Card key={c.id} className="p-4 hover:border-brand-blue/40 transition cursor-pointer">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div
                    className="w-9 h-9 rounded-lg flex items-center justify-center"
                    style={{ background: `${c.color}25` }}
                  >
                    <FileText size={16} className="text-neutral-700 dark:text-neutral-200" />
                  </div>
                  <div>
                    <div className="font-medium">{c.name}</div>
                    <div className="text-xs text-neutral-500">{c.count} boletos</div>
                  </div>
                </div>
                {c.recurring && <Repeat size={14} className="text-brand-green" title="Pagamento recorrente" />}
              </div>
              {c.nextBoleto && (
                <div className="mt-3 flex items-center gap-1.5 text-xs text-neutral-600 dark:text-neutral-300">
                  <CalendarDays size={12} />
                  <span>
                    Proximo: {formatBRL(c.nextBoleto.value)} · {formatDateBR(c.nextBoleto.dueDate)}
                  </span>
                </div>
              )}
            </Card>
          ))}
        </div>
      </div>

      <div>
        <h2 className="font-semibold mb-3">Boletos do mes</h2>
        <Card className="overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 dark:bg-neutral-800/40 text-xs uppercase tracking-wide text-neutral-500">
              <tr>
                <th className="text-left px-4 py-3">Categoria</th>
                <th className="text-left px-4 py-3">Descricao</th>
                <th className="text-left px-4 py-3">Vencimento</th>
                <th className="text-right px-4 py-3">Valor</th>
                <th className="text-center px-4 py-3">Status</th>
                <th className="text-center px-4 py-3">PDF</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100 dark:divide-neutral-800">
              {state.boletos.map((b) => (
                <tr key={b.id} className="hover:bg-neutral-50 dark:hover:bg-neutral-800/40">
                  <td className="px-4 py-3">{catMap[b.categoriaId]?.name ?? '—'}</td>
                  <td className="px-4 py-3 text-neutral-600 dark:text-neutral-300">
                    <div>{b.desc}</div>
                    {b.beneficiario && b.beneficiario !== b.desc && (
                      <div className="text-xs text-neutral-400 mt-0.5">{b.beneficiario}</div>
                    )}
                  </td>
                  <td className="px-4 py-3">{formatDateBR(b.dueDate)}</td>
                  <td className="px-4 py-3 text-right font-medium">{formatBRL(b.value)}</td>
                  <td className="px-4 py-3 text-center">
                    <button onClick={() => toggleStatus(b.id, b.status)}>
                      <StatusPill status={b.status} />
                    </button>
                  </td>
                  <td className="px-4 py-3 text-center">
                    <Paperclip
                      size={14}
                      className={`inline ${b.sourceFileName ? 'text-brand-blue' : 'text-neutral-400'}`}
                      title={b.sourceFileName || 'Sem arquivo importado'}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
        {!canCreateBoleto && (
          <p className="text-xs text-neutral-500 mt-2">
            Cadastre ao menos uma categoria antes de lancar o primeiro boleto.
          </p>
        )}
      </div>

      {isCreating && (
        <NewBoletoModal
          categorias={state.categorias}
          onClose={() => setIsCreating(false)}
          onCreate={(payload) => {
            dispatch({ type: 'BOLETO_ADD', payload })
            setIsCreating(false)
          }}
        />
      )}

      {importDraft && (
        <ImportBoletoModal
          categorias={state.categorias}
          draft={importDraft}
          onClose={() => setImportDraft(null)}
          onConfirm={saveImportedBoleto}
        />
      )}
    </div>
  )
}

function NewBoletoModal({ categorias, onClose, onCreate }) {
  const [form, setForm] = useState({
    categoriaId: categorias[0]?.id ?? '',
    desc: '',
    dueDate: '',
    value: '',
    status: 'pendente',
  })

  function update(key, value) {
    setForm((current) => ({ ...current, [key]: value }))
  }

  function submit(event) {
    event.preventDefault()
    if (!form.categoriaId || !form.desc.trim() || !form.dueDate || !form.value) return
    onCreate({
      ...form,
      desc: form.desc.trim(),
      value: Number(form.value),
    })
  }

  return (
    <Modal title="Novo boleto" subtitle="Cadastre um compromisso financeiro real." onClose={onClose}>
      <form onSubmit={submit} className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Categoria</span>
            <select
              value={form.categoriaId}
              onChange={(event) => update('categoriaId', event.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            >
              {categorias.map((categoria) => (
                <option key={categoria.id} value={categoria.id}>
                  {categoria.name}
                </option>
              ))}
            </select>
          </label>

          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Status</span>
            <select
              value={form.status}
              onChange={(event) => update('status', event.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            >
              <option value="pendente">Pendente</option>
              <option value="recorrente">Recorrente</option>
              <option value="pago">Pago</option>
            </select>
          </label>
        </div>

        <label className="block">
          <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Descricao</span>
          <input
            value={form.desc}
            onChange={(event) => update('desc', event.target.value)}
            placeholder="Ex.: Fatura cartao corporativo"
            className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
          />
        </label>

        <div className="grid grid-cols-2 gap-4">
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Vencimento</span>
            <input
              type="date"
              value={form.dueDate}
              onChange={(event) => update('dueDate', event.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>

          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Valor</span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={form.value}
              onChange={(event) => update('value', event.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
        </div>

        <div className="flex items-center justify-end gap-2 pt-2">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 text-sm border border-neutral-200 dark:border-neutral-700 rounded-lg"
          >
            Cancelar
          </button>
          <button
            type="submit"
            className="px-4 py-2 text-sm font-medium bg-brand-blue text-white rounded-lg hover:bg-blue-700"
          >
            Salvar boleto
          </button>
        </div>
      </form>
    </Modal>
  )
}

function ImportBoletoModal({ categorias, draft, onClose, onConfirm }) {
  const [form, setForm] = useState({
    categoriaId: draft.categoriaId || categorias[0]?.id || '',
    desc: draft.desc || '',
    dueDate: draft.dueDate || '',
    value: draft.value === '' ? '' : String(draft.value),
    status: draft.status || 'pendente',
  })

  const hasCategories = categorias.length > 0

  function update(key, value) {
    setForm((current) => ({ ...current, [key]: value }))
  }

  function submit(event) {
    event.preventDefault()
    if (!hasCategories) return
    if (!form.categoriaId || !form.desc.trim() || !form.dueDate || !form.value) return

    onConfirm({
      ...draft,
      ...form,
      desc: form.desc.trim(),
      value: Number(form.value),
    })
  }

  return (
    <Modal
      title="Revisar importacao"
      subtitle="Conferimos o PDF e preenchemos os campos abaixo para voce validar."
      onClose={onClose}
      maxWidth="max-w-3xl"
    >
      <div className="space-y-5">
        <div className="grid grid-cols-3 gap-3">
          <InfoCard
            icon={<FileSearch size={16} />}
            label="Arquivo"
            value={draft.sourceFileName}
            hint={draft.extractionMethod === 'pdf-text' ? 'Texto extraido do PDF' : 'Importacao manual'}
          />
          <InfoCard
            icon={<CheckCircle2 size={16} />}
            label="Confianca"
            value={`${Math.round((draft.ocrConfidence ?? 0) * 100)}%`}
            hint="Maior quando linha digitavel, valor e vencimento sao encontrados"
          />
          <InfoCard
            icon={<CalendarDays size={16} />}
            label="Valor identificado"
            value={
              typeof draft.value === 'number' && !Number.isNaN(draft.value)
                ? formatBRL(draft.value)
                : 'Nao identificado'
            }
            hint={draft.dueDate ? `Vence em ${formatDateBR(draft.dueDate)}` : 'Vencimento nao encontrado'}
          />
        </div>

        {draft.importWarnings.length > 0 && (
          <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            <div className="font-medium">Campos para revisar com atencao</div>
            <ul className="mt-2 space-y-1">
              {draft.importWarnings.map((warning) => (
                <li key={warning}>- {warning}</li>
              ))}
            </ul>
          </div>
        )}

        {!hasCategories && (
          <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            Cadastre pelo menos uma categoria antes de salvar um boleto importado.
          </div>
        )}

        <form onSubmit={submit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <label className="block">
              <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Categoria</span>
              <select
                value={form.categoriaId}
                onChange={(event) => update('categoriaId', event.target.value)}
                disabled={!hasCategories}
                className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue disabled:opacity-60"
              >
                {categorias.map((categoria) => (
                  <option key={categoria.id} value={categoria.id}>
                    {categoria.name}
                  </option>
                ))}
              </select>
            </label>

            <label className="block">
              <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Status</span>
              <select
                value={form.status}
                onChange={(event) => update('status', event.target.value)}
                className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
              >
                <option value="pendente">Pendente</option>
                <option value="recorrente">Recorrente</option>
                <option value="pago">Pago</option>
              </select>
            </label>
          </div>

          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Descricao</span>
            <input
              value={form.desc}
              onChange={(event) => update('desc', event.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>

          <div className="grid grid-cols-2 gap-4">
            <label className="block">
              <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Vencimento</span>
              <input
                type="date"
                value={form.dueDate}
                onChange={(event) => update('dueDate', event.target.value)}
                className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
              />
            </label>

            <label className="block">
              <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Valor</span>
              <input
                type="number"
                min="0"
                step="0.01"
                value={form.value}
                onChange={(event) => update('value', event.target.value)}
                className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
              />
            </label>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <ReadonlyField label="Beneficiario" value={draft.beneficiario || 'Nao identificado'} />
            <ReadonlyField
              label="Linha digitavel"
              value={draft.linhaDigitavel || 'Nao encontrada'}
              mono
            />
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm border border-neutral-200 dark:border-neutral-700 rounded-lg"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={!hasCategories}
              className="px-4 py-2 text-sm font-medium bg-brand-blue text-white rounded-lg hover:bg-blue-700 disabled:opacity-60 disabled:cursor-not-allowed"
            >
              Salvar boleto
            </button>
          </div>
        </form>
      </div>
    </Modal>
  )
}

function InfoCard({ icon, label, value, hint }) {
  return (
    <div className="rounded-xl border border-neutral-200 dark:border-neutral-800 px-4 py-3">
      <div className="flex items-center gap-2 text-xs uppercase tracking-wide text-neutral-500">
        {icon}
        <span>{label}</span>
      </div>
      <div className="mt-2 font-semibold text-sm">{value}</div>
      <div className="mt-1 text-xs text-neutral-500">{hint}</div>
    </div>
  )
}

function ReadonlyField({ label, value, mono = false }) {
  return (
    <div className="rounded-xl border border-neutral-200 dark:border-neutral-800 px-3 py-2">
      <div className="text-xs font-semibold uppercase tracking-wide text-neutral-500">{label}</div>
      <div className={`mt-1 text-sm break-all ${mono ? 'font-mono' : ''}`}>{value}</div>
    </div>
  )
}

function StatusPill({ status }) {
  const map = {
    pago: 'bg-brand-green/10 text-brand-green',
    pendente: 'bg-brand-amber/10 text-brand-amber',
    recorrente: 'bg-brand-blue/10 text-brand-blue',
    vencido: 'bg-brand-red/10 text-brand-red',
  }

  return (
    <span
      className={`text-[10px] uppercase font-semibold px-2 py-0.5 rounded-full cursor-pointer hover:opacity-80 ${map[status] ?? map.pendente}`}
    >
      {status}
    </span>
  )
}

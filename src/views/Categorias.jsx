import { useState } from 'react'
import { Card } from '../components/Card.jsx'
import Modal from '../components/Modal.jsx'
import { useAppState } from '../store/AppContext.jsx'

export default function Categorias() {
  const { state, dispatch } = useAppState()
  const [isCreating, setIsCreating] = useState(false)
  const boletoCountById = state.boletos.reduce((acc, b) => {
    acc[b.categoriaId] = (acc[b.categoriaId] || 0) + 1
    return acc
  }, {})

  return (
    <div className="max-w-4xl">
      <Card className="overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-neutral-50 dark:bg-neutral-800/40 text-xs uppercase tracking-wide text-neutral-500">
            <tr>
              <th className="text-left px-4 py-3">Categoria</th>
              <th className="text-center px-4 py-3">Tipo</th>
              <th className="text-right px-4 py-3">Boletos</th>
              <th className="text-right px-4 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-neutral-100 dark:divide-neutral-800">
            {state.categorias.map((c) => (
              <tr key={c.id} className="hover:bg-neutral-50 dark:hover:bg-neutral-800/40">
                <td className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    <span className="w-3 h-3 rounded-full" style={{ background: c.color }} />
                    <span className="font-medium">{c.name}</span>
                  </div>
                </td>
                <td className="px-4 py-3 text-center">
                  {c.recurring ? (
                    <span className="text-[10px] uppercase px-2 py-0.5 rounded-full bg-brand-green/10 text-brand-green font-semibold">
                      Recorrente
                    </span>
                  ) : (
                    <span className="text-[10px] uppercase px-2 py-0.5 rounded-full bg-neutral-100 dark:bg-neutral-800 text-neutral-500 font-semibold">
                      Avulsa
                    </span>
                  )}
                </td>
                <td className="px-4 py-3 text-right">{boletoCountById[c.id] ?? 0}</td>
                <td className="px-4 py-3 text-right">
                  <button className="text-xs text-brand-blue hover:underline">Abrir</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
      <button onClick={() => setIsCreating(true)} className="mt-4 text-sm text-brand-blue hover:underline">+ Nova categoria</button>

      {isCreating && (
        <NewCategoriaModal
          onClose={() => setIsCreating(false)}
          onCreate={(payload) => {
            dispatch({ type: 'CATEGORIA_ADD', payload })
            setIsCreating(false)
          }}
        />
      )}
    </div>
  )
}

function NewCategoriaModal({ onClose, onCreate }) {
  const [form, setForm] = useState({
    name: '',
    color: '#2563EB',
    recurring: false,
  })

  function submit(e) {
    e.preventDefault()
    if (!form.name.trim()) return
    onCreate({ ...form, name: form.name.trim() })
  }

  return (
    <Modal title="Nova categoria" subtitle="Cadastre uma categoria para organizar seus boletos." onClose={onClose}>
      <form onSubmit={submit} className="space-y-4">
        <label className="block">
          <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Nome</span>
          <input
            value={form.name}
            onChange={(e) => setForm((current) => ({ ...current, name: e.target.value }))}
            placeholder="Ex.: ISS do escritório"
            className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
          />
        </label>

        <div className="grid grid-cols-2 gap-4">
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Cor</span>
            <input
              type="color"
              value={form.color}
              onChange={(e) => setForm((current) => ({ ...current, color: e.target.value }))}
              className="mt-1.5 h-11 w-full border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent"
            />
          </label>

          <label className="flex items-center gap-3 pt-7">
            <input
              type="checkbox"
              checked={form.recurring}
              onChange={(e) => setForm((current) => ({ ...current, recurring: e.target.checked }))}
              className="rounded border-neutral-300"
            />
            <span className="text-sm">Categoria recorrente</span>
          </label>
        </div>

        <div className="flex items-center justify-end gap-2 pt-2">
          <button type="button" onClick={onClose} className="px-4 py-2 text-sm border border-neutral-200 dark:border-neutral-700 rounded-lg">
            Cancelar
          </button>
          <button type="submit" className="px-4 py-2 text-sm font-medium bg-brand-blue text-white rounded-lg hover:bg-blue-700">
            Salvar categoria
          </button>
        </div>
      </form>
    </Modal>
  )
}

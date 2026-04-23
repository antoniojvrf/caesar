import { useState, useRef } from 'react'
import { Card } from '../components/Card.jsx'
import Modal from '../components/Modal.jsx'
import { CheckCircle2, Circle, Flag, Target, X, Paperclip, Calendar, ListChecks, StickyNote, Plus, Trash2, GripVertical } from 'lucide-react'
import { useAppState } from '../store/AppContext.jsx'

const prioColor = {
  alta: 'text-brand-red',
  média: 'text-brand-amber',
  baixa: 'text-neutral-400',
}

export default function Tarefas() {
  const { state, dispatch } = useAppState()
  const columns = state.tarefas
  const [activeTask, setActiveTask] = useState(null)
  const [isCreating, setIsCreating] = useState(false)
  const dragInfo = useRef(null)

  function openTask(colId, taskId) {
    setActiveTask({ colId, taskId })
  }

  function updateTask(colId, taskId, patch) {
    dispatch({ type: 'TAREFA_UPDATE', payload: { colId, taskId, patch } })
  }

  function handleDragStart(colId, taskId) {
    dragInfo.current = { colId, taskId }
  }

  function handleDragOver(e) {
    e.preventDefault()
  }

  function handleDrop(destCol) {
    const src = dragInfo.current
    if (!src || src.colId === destCol) return
    dispatch({ type: 'TAREFA_MOVE', payload: { fromCol: src.colId, taskId: src.taskId, toCol: destCol } })
    dragInfo.current = null
  }

  const active = activeTask ? columns[activeTask.colId]?.tasks.find((t) => t.id === activeTask.taskId) : null

  return (
    <div className="max-w-6xl">
      <div className="grid grid-cols-3 gap-4">
        {Object.entries(columns).map(([colId, col]) => (
          <Card
            key={colId}
            className="p-4 min-h-[400px]"
            onDragOver={handleDragOver}
            onDrop={() => handleDrop(colId)}
          >
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-semibold">{col.name}</h3>
              <span className="text-xs text-neutral-500">{col.tasks.length}</span>
            </div>
            <div className="space-y-2">
              {col.tasks.map((task) => (
                <div
                  key={task.id}
                  draggable
                  onDragStart={() => handleDragStart(colId, task.id)}
                  onClick={() => openTask(colId, task.id)}
                  className="p-3 rounded-lg border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-neutral-900 hover:border-brand-blue/40 transition group cursor-grab active:cursor-grabbing"
                >
                  <div className="flex items-start gap-2">
                    <GripVertical size={14} className="mt-0.5 text-neutral-300" />
                    <div className="flex-1">
                      <div className="text-sm font-medium">{task.title}</div>
                      <div className="mt-2 flex items-center gap-2 flex-wrap">
                        <span className="text-[10px] uppercase font-semibold px-1.5 py-0.5 rounded bg-neutral-100 dark:bg-neutral-800">
                          {task.tag}
                        </span>
                        <Flag size={11} className={prioColor[task.priority]} />
                        {task.goal && (
                          <span className="text-[10px] flex items-center gap-1 text-brand-green">
                            <Target size={10} /> {task.goal}
                          </span>
                        )}
                      </div>
                      <div className="mt-2 flex items-center gap-3 text-[11px] text-neutral-500">
                        {task.dueDate && (
                          <span className="flex items-center gap-1">
                            <Calendar size={11} /> {formatDate(task.dueDate)}
                          </span>
                        )}
                        {task.checklist.length > 0 && (
                          <span className="flex items-center gap-1">
                            <ListChecks size={11} />
                            {task.checklist.filter((c) => c.done).length}/{task.checklist.length}
                          </span>
                        )}
                        {task.attachments.length > 0 && (
                          <span className="flex items-center gap-1">
                            <Paperclip size={11} /> {task.attachments.length}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
              <button
                onClick={() => setIsCreating(true)}
                className="w-full text-xs text-neutral-400 hover:text-brand-blue py-2 border border-dashed border-neutral-200 dark:border-neutral-800 rounded-lg hover:border-brand-blue/40"
              >
                + Adicionar tarefa
              </button>
            </div>
          </Card>
        ))}
      </div>

      {isCreating && (
        <NewTaskModal
          columns={columns}
          onClose={() => setIsCreating(false)}
          onCreate={(payload) => {
            dispatch({ type: 'TAREFA_ADD', payload })
            setIsCreating(false)
          }}
        />
      )}

      {active && (
        <TaskModal
          task={active}
          onClose={() => setActiveTask(null)}
          onUpdate={(patch) => updateTask(activeTask.colId, activeTask.taskId, patch)}
        />
      )}
    </div>
  )
}

function NewTaskModal({ columns, onClose, onCreate }) {
  const [form, setForm] = useState({
    colId: Object.keys(columns)[0] ?? 'hoje',
    title: '',
    priority: 'média',
    tag: 'Geral',
    goal: '',
    dueDate: '',
    notes: '',
  })

  function update(key, value) {
    setForm((current) => ({ ...current, [key]: value }))
  }

  function submit(e) {
    e.preventDefault()
    if (!form.title.trim()) return
    onCreate({
      ...form,
      title: form.title.trim(),
      tag: form.tag.trim() || 'Geral',
      goal: form.goal.trim(),
      notes: form.notes.trim(),
    })
  }

  return (
    <Modal title="Nova tarefa" subtitle="Adicione uma tarefa real ao seu fluxo diário." onClose={onClose}>
      <form onSubmit={submit} className="space-y-4">
        <Field label="Título" icon={StickyNote}>
          <input
            value={form.title}
            onChange={(e) => update('title', e.target.value)}
            placeholder="Ex.: Protocolar petição de réplica"
            className="w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
          />
        </Field>

        <div className="grid grid-cols-2 gap-4">
          <Field label="Coluna" icon={ListChecks}>
            <select
              value={form.colId}
              onChange={(e) => update('colId', e.target.value)}
              className="w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            >
              {Object.entries(columns).map(([colId, col]) => (
                <option key={colId} value={colId}>{col.name}</option>
              ))}
            </select>
          </Field>
          <Field label="Prioridade" icon={Flag}>
            <select
              value={form.priority}
              onChange={(e) => update('priority', e.target.value)}
              className="w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            >
              <option value="alta">Alta</option>
              <option value="média">Média</option>
              <option value="baixa">Baixa</option>
            </select>
          </Field>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <Field label="Tag" icon={Target}>
            <input
              value={form.tag}
              onChange={(e) => update('tag', e.target.value)}
              placeholder="Ex.: Processo"
              className="w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </Field>
          <Field label="Prazo fatal" icon={Calendar}>
            <input
              type="date"
              value={form.dueDate}
              onChange={(e) => update('dueDate', e.target.value)}
              className="w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </Field>
        </div>

        <Field label="Vincular à meta" icon={Target}>
          <input
            value={form.goal}
            onChange={(e) => update('goal', e.target.value)}
            placeholder="Opcional"
            className="w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
          />
        </Field>

        <Field label="Observações" icon={StickyNote}>
          <textarea
            value={form.notes}
            onChange={(e) => update('notes', e.target.value)}
            rows={4}
            placeholder="Detalhes importantes para execução."
            className="w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue resize-none"
          />
        </Field>

        <div className="flex items-center justify-end gap-2 pt-2">
          <button type="button" onClick={onClose} className="px-4 py-2 text-sm border border-neutral-200 dark:border-neutral-700 rounded-lg">
            Cancelar
          </button>
          <button type="submit" className="px-4 py-2 text-sm font-medium bg-brand-blue text-white rounded-lg hover:bg-blue-700">
            Salvar tarefa
          </button>
        </div>
      </form>
    </Modal>
  )
}

function formatDate(iso) {
  if (!iso) return ''
  const [, m, d] = iso.split('-')
  return `${d}/${m}`
}

function TaskModal({ task, onClose, onUpdate }) {
  const [newCheckItem, setNewCheckItem] = useState('')
  const fileInputRef = useRef(null)

  function addChecklistItem() {
    if (!newCheckItem.trim()) return
    onUpdate({ checklist: [...task.checklist, { text: newCheckItem.trim(), done: false }] })
    setNewCheckItem('')
  }

  function toggleCheck(i) {
    const next = task.checklist.map((c, idx) => (idx === i ? { ...c, done: !c.done } : c))
    onUpdate({ checklist: next })
  }

  function removeCheck(i) {
    onUpdate({ checklist: task.checklist.filter((_, idx) => idx !== i) })
  }

  function addAttachment(e) {
    const files = Array.from(e.target.files || [])
    const mapped = files.map((f) => ({ name: f.name, size: formatSize(f.size) }))
    onUpdate({ attachments: [...task.attachments, ...mapped] })
  }

  function removeAttachment(i) {
    onUpdate({ attachments: task.attachments.filter((_, idx) => idx !== i) })
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-center justify-center p-6" onClick={onClose}>
      <div
        onClick={(e) => e.stopPropagation()}
        className="bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 rounded-2xl w-full max-w-2xl max-h-[85vh] overflow-hidden flex flex-col shadow-2xl"
      >
        <div className="px-6 py-4 border-b border-neutral-200 dark:border-neutral-800 flex items-center justify-between">
          <input
            value={task.title}
            onChange={(e) => onUpdate({ title: e.target.value })}
            className="text-lg font-semibold bg-transparent w-full focus:outline-none"
          />
          <button onClick={onClose} className="p-1 rounded hover:bg-neutral-100 dark:hover:bg-neutral-800">
            <X size={18} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto px-6 py-5 space-y-5">
          <div className="grid grid-cols-2 gap-4">
            <Field label="Prazo fatal" icon={Calendar}>
              <input
                type="date"
                value={task.dueDate}
                onChange={(e) => onUpdate({ dueDate: e.target.value })}
                className="w-full text-sm px-3 py-1.5 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
              />
            </Field>
            <Field label="Prioridade" icon={Flag}>
              <select
                value={task.priority}
                onChange={(e) => onUpdate({ priority: e.target.value })}
                className="w-full text-sm px-3 py-1.5 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
              >
                <option value="alta">Alta</option>
                <option value="média">Média</option>
                <option value="baixa">Baixa</option>
              </select>
            </Field>
          </div>

          <Field label="Observações" icon={StickyNote}>
            <textarea
              value={task.notes}
              onChange={(e) => onUpdate({ notes: e.target.value })}
              rows={3}
              placeholder="Notas livres sobre a tarefa..."
              className="w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue resize-none"
            />
          </Field>

          <Field label="Checklist" icon={ListChecks}>
            <div className="space-y-1.5">
              {task.checklist.map((c, i) => (
                <div key={i} className="flex items-center gap-2 group">
                  <button onClick={() => toggleCheck(i)}>
                    {c.done ? (
                      <CheckCircle2 size={16} className="text-brand-green" />
                    ) : (
                      <Circle size={16} className="text-neutral-300" />
                    )}
                  </button>
                  <span className={`text-sm flex-1 ${c.done ? 'line-through text-neutral-400' : ''}`}>{c.text}</span>
                  <button onClick={() => removeCheck(i)} className="opacity-0 group-hover:opacity-100">
                    <Trash2 size={13} className="text-neutral-400 hover:text-brand-red" />
                  </button>
                </div>
              ))}
              <div className="flex items-center gap-2 pt-1">
                <Plus size={14} className="text-neutral-400" />
                <input
                  value={newCheckItem}
                  onChange={(e) => setNewCheckItem(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && addChecklistItem()}
                  placeholder="Novo item"
                  className="flex-1 text-sm bg-transparent focus:outline-none placeholder:text-neutral-400"
                />
              </div>
            </div>
          </Field>

          <Field label="Anexos" icon={Paperclip}>
            <div className="space-y-1.5">
              {task.attachments.map((a, i) => (
                <div key={i} className="flex items-center justify-between px-3 py-2 rounded-lg bg-neutral-50 dark:bg-neutral-800/40 group">
                  <div className="flex items-center gap-2">
                    <Paperclip size={14} className="text-brand-blue" />
                    <span className="text-sm">{a.name}</span>
                    <span className="text-xs text-neutral-400">{a.size}</span>
                  </div>
                  <button onClick={() => removeAttachment(i)} className="opacity-0 group-hover:opacity-100">
                    <Trash2 size={13} className="text-neutral-400 hover:text-brand-red" />
                  </button>
                </div>
              ))}
              <input ref={fileInputRef} type="file" multiple className="hidden" onChange={addAttachment} />
              <button
                onClick={() => fileInputRef.current?.click()}
                className="w-full text-xs text-neutral-500 hover:text-brand-blue py-2 border border-dashed border-neutral-200 dark:border-neutral-700 rounded-lg hover:border-brand-blue/40"
              >
                + Adicionar anexo
              </button>
            </div>
          </Field>
        </div>
      </div>
    </div>
  )
}

function Field({ label, icon: Icon, children }) {
  return (
    <div>
      <div className="flex items-center gap-1.5 text-xs font-semibold text-neutral-500 uppercase tracking-wide mb-1.5">
        <Icon size={12} /> {label}
      </div>
      {children}
    </div>
  )
}

function formatSize(bytes) {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(0) + ' KB'
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
}

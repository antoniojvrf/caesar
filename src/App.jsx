import { useState } from 'react'
import { LockKeyhole, ShieldCheck } from 'lucide-react'
import Sidebar from './components/Sidebar.jsx'
import Topbar from './components/Topbar.jsx'
import Dashboard from './views/Dashboard.jsx'
import Boletos from './views/Boletos.jsx'
import Tarefas from './views/Tarefas.jsx'
import Metas from './views/Metas.jsx'
import Financas from './views/Financas.jsx'
import Categorias from './views/Categorias.jsx'
import Configuracoes from './views/Configuracoes.jsx'
import Processos from './views/advogado/Processos.jsx'
import Honorarios from './views/advogado/Honorarios.jsx'
import Exito from './views/advogado/Exito.jsx'
import Indicadores from './views/advogado/Indicadores.jsx'
import { useLocalStorage } from './hooks/useLocalStorage.js'

const AUTH_STORAGE_KEY = 'mylife_auth_v1'
const DEFAULT_CREDENTIALS = {
  username: 'admin',
  password: 'admin',
}

const VIEWS = {
  dashboard: { title: 'Dashboard', Component: Dashboard },
  boletos: { title: 'Boletos & Contas', Component: Boletos },
  tarefas: { title: 'Tarefas', Component: Tarefas },
  metas: { title: 'Metas', Component: Metas },
  financas: { title: 'Finanças', Component: Financas },
  categorias: { title: 'Categorias', Component: Categorias },
  adv_processos: { title: 'Processos', Component: Processos },
  adv_honorarios: { title: 'Honorários a Receber', Component: Honorarios },
  adv_exito: { title: 'Previstos em Êxito', Component: Exito },
  adv_indicadores: { title: 'Indicadores', Component: Indicadores },
  config: { title: 'Configurações', Component: Configuracoes },
}

function LoginScreen({ onLogin }) {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')

  function handleSubmit(event) {
    event.preventDefault()

    if (
      username === DEFAULT_CREDENTIALS.username &&
      password === DEFAULT_CREDENTIALS.password
    ) {
      setError('')
      onLogin(username)
      return
    }

    setError('Login ou senha incorretos. Use admin / admin.')
  }

  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(37,99,235,0.22),_transparent_42%),linear-gradient(135deg,#f8fafc_0%,#e2e8f0_45%,#dbeafe_100%)] text-neutral-900 flex items-center justify-center p-6">
      <div className="w-full max-w-5xl grid gap-6 lg:grid-cols-[1.1fr_420px]">
        <section className="hidden lg:flex flex-col justify-between rounded-[32px] bg-slate-950 text-white p-10 shadow-2xl shadow-blue-950/20 overflow-hidden relative">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,_rgba(34,197,94,0.28),_transparent_28%),radial-gradient(circle_at_bottom_left,_rgba(59,130,246,0.35),_transparent_34%)]" />
          <div className="relative space-y-6">
            <div className="inline-flex items-center gap-3 rounded-full border border-white/10 bg-white/5 px-4 py-2 text-sm text-white/80">
              <ShieldCheck size={16} />
              Acesso local protegido
            </div>
            <div className="space-y-4">
              <p className="text-sm uppercase tracking-[0.35em] text-blue-200/70">MyLife</p>
              <h1 className="text-4xl font-semibold tracking-tight leading-tight">
                Seu painel pessoal com autenticação local simples.
              </h1>
              <p className="max-w-xl text-base leading-7 text-slate-300">
                Esta etapa protege o acesso ao sistema neste dispositivo. Não existe criação de conta:
                o acesso é feito apenas com as credenciais locais configuradas.
              </p>
            </div>
          </div>

          <div className="relative grid gap-4 sm:grid-cols-2">
            <div className="rounded-2xl border border-white/10 bg-white/5 p-5 backdrop-blur">
              <p className="text-sm text-slate-300">Modo de acesso</p>
              <p className="mt-2 text-xl font-semibold">Local e persistente</p>
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/5 p-5 backdrop-blur">
              <p className="text-sm text-slate-300">Cadastro</p>
              <p className="mt-2 text-xl font-semibold">Desabilitado</p>
            </div>
          </div>
        </section>

        <section className="rounded-[32px] border border-white/60 bg-white/85 p-8 shadow-2xl shadow-slate-300/40 backdrop-blur xl:p-10">
          <div className="mb-8 flex items-center gap-4">
            <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-brand-blue to-brand-green text-white shadow-lg shadow-blue-500/30">
              <LockKeyhole size={24} />
            </div>
            <div>
              <p className="text-sm font-medium uppercase tracking-[0.25em] text-neutral-500">Entrar</p>
              <h2 className="text-2xl font-semibold tracking-tight text-neutral-950">Acesso ao sistema</h2>
            </div>
          </div>

          <form className="space-y-5" onSubmit={handleSubmit}>
            <label className="block space-y-2">
              <span className="text-sm font-medium text-neutral-700">Login</span>
              <input
                type="text"
                value={username}
                onChange={(event) => setUsername(event.target.value)}
                placeholder="Digite seu login"
                autoComplete="username"
                className="w-full rounded-2xl border border-neutral-200 bg-white px-4 py-3 text-neutral-900 outline-none transition focus:border-brand-blue focus:ring-4 focus:ring-blue-100"
              />
            </label>

            <label className="block space-y-2">
              <span className="text-sm font-medium text-neutral-700">Senha</span>
              <input
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                placeholder="Digite sua senha"
                autoComplete="current-password"
                className="w-full rounded-2xl border border-neutral-200 bg-white px-4 py-3 text-neutral-900 outline-none transition focus:border-brand-blue focus:ring-4 focus:ring-blue-100"
              />
            </label>

            {error ? (
              <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                {error}
              </div>
            ) : null}

            <button
              type="submit"
              className="w-full rounded-2xl bg-slate-950 px-4 py-3 text-sm font-semibold text-white transition hover:bg-slate-800"
            >
              Entrar
            </button>
          </form>

          <div className="mt-6 rounded-2xl border border-blue-100 bg-blue-50 px-4 py-4 text-sm text-blue-950">
            Credenciais locais ativas: <strong>login admin</strong> e <strong>senha admin</strong>.
          </div>
        </section>
      </div>
    </div>
  )
}

export default function App() {
  const [view, setView] = useState('tarefas')
  const [session, setSession] = useLocalStorage(AUTH_STORAGE_KEY, {
    isAuthenticated: false,
    username: '',
  })
  const { title, Component } = VIEWS[view]

  function handleLogin(username) {
    setSession({
      isAuthenticated: true,
      username,
    })
  }

  function handleLogout() {
    setSession({
      isAuthenticated: false,
      username: '',
    })
  }

  if (!session?.isAuthenticated) {
    return <LoginScreen onLogin={handleLogin} />
  }

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-neutral-50 dark:bg-neutral-950 text-neutral-900 dark:text-neutral-100">
      <Sidebar current={view} onChange={setView} />
      <div className="flex-1 flex flex-col overflow-hidden">
        <Topbar title={title} username={session.username} onLogout={handleLogout} />
        <main className="flex-1 overflow-y-auto p-8">
          <Component />
        </main>
      </div>
    </div>
  )
}

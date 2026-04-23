import { createContext, useContext, useReducer, useEffect } from 'react'
import { initialState, createEmptyState } from './initialState.js'
import { reducer } from './reducer.js'

const STORAGE_KEY = 'mylife_state_v2'

const AppContext = createContext(null)

function loadState() {
  try {
    const saved = localStorage.getItem(STORAGE_KEY)
    return saved ? JSON.parse(saved) : initialState
  } catch {
    return createEmptyState()
  }
}

export function AppProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, null, loadState)

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
    } catch (e) {
      console.warn('localStorage write error:', e)
    }
  }, [state])

  return (
    <AppContext.Provider value={{ state, dispatch }}>
      {children}
    </AppContext.Provider>
  )
}

export function useAppState() {
  const ctx = useContext(AppContext)
  if (!ctx) throw new Error('useAppState must be used inside AppProvider')
  return ctx
}

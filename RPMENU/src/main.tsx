import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import './index.css'
import App from './App.tsx'
import { initLegacyPwa } from './legacyPwa'
import { initStandaloneLaunchScreen } from './standaloneLaunch'

initLegacyPwa()
const finishStandaloneLaunch = initStandaloneLaunchScreen()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>,
)

window.setTimeout(() => {
  finishStandaloneLaunch()
}, 0)

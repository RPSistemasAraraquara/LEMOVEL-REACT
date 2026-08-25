import fs from 'node:fs/promises'
import path from 'node:path'
import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

function pwaVersionPlugin(buildId: string) {
  const publicDir = path.resolve(process.cwd(), 'public')

  const injectBuildId = (content: string) => content.replaceAll('__BUILD_ID__', buildId)

  const readTemplate = async (fileName: string) => {
    const templatePath = path.join(publicDir, fileName)
    return fs.readFile(templatePath, 'utf8')
  }

  return {
    name: 'rpmenu-pwa-version',
    configureServer(server: { middlewares: { use: (handler: (req: { url?: string }, res: { setHeader: (name: string, value: string) => void; end: (body: string) => void }, next: () => void) => void | Promise<void>) => void } }) {
      server.middlewares.use(async (req, res, next) => {
        const pathname = req.url?.split('?')[0] ?? ''
        if (pathname !== '/manifest.json' && pathname !== '/sw.js') {
          next()
          return
        }

        const fileName = pathname === '/manifest.json' ? 'manifest.json' : 'sw.js'
        const content = injectBuildId(await readTemplate(fileName))

        res.setHeader('Content-Type', pathname === '/manifest.json' ? 'application/manifest+json' : 'application/javascript')
        res.end(content)
      })
    },
    async writeBundle(options: { dir?: string }) {
      const outDir = options.dir ? path.resolve(options.dir) : path.resolve(process.cwd(), 'dist')
      const manifestContent = injectBuildId(await readTemplate('manifest.json'))
      const serviceWorkerContent = injectBuildId(await readTemplate('sw.js'))

      await fs.writeFile(path.join(outDir, 'manifest.json'), manifestContent, 'utf8')
      await fs.writeFile(path.join(outDir, 'sw.js'), serviceWorkerContent, 'utf8')
    },
  }
}

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const proxyTarget = env.RPMENU_PROXY_TARGET?.trim() || env.RPFOOD_PROXY_TARGET?.trim() || 'http://rpfoodteste.rpfood.com.br'
  const buildId = new Date().toISOString().replace(/[-:.TZ]/g, '').slice(0, 14)

  return {
    plugins: [react(), pwaVersionPlugin(buildId)],
    define: {
      __APP_BUILD_ID__: JSON.stringify(buildId),
    },
    server: {
      host: '0.0.0.0',
      proxy: {
        '/rpfood/v1': {
          target: proxyTarget,
          changeOrigin: true,
        },
        '/swagger': {
          target: proxyTarget,
          changeOrigin: true,
        },
      },
    },
  }
})

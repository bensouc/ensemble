const esbuild = require('esbuild')
const rails = require('esbuild-rails')

const watch = process.argv.includes('--watch')

const base = {
  bundle: true,
  sourcemap: true,
  outdir: 'app/assets/builds',
  publicPath: '/assets',
  plugins: [rails()],
  logLevel: 'info',
}

const configs = [
  // Chargé par les layouts en `type: "module"`.
  { ...base, entryPoints: { application: 'app/javascript/application.js' }, format: 'esm' },
  // `rails_admin` à la racine des builds : c'est là que rails_admin, en mode
  // `asset_source = :webpack`, va chercher son JS (et son CSS, bin/build-css).
  // Il le charge par une balise <script> CLASSIQUE, pas en module : en ESM, les
  // variables de haut niveau du bundle deviendraient des globales, et le
  // `var top = "top"` de Popper ne peut pas écraser `window.top` — ses menus
  // déroulants tombaient alors sur « placement.split is not a function ».
  { ...base, entryPoints: { rails_admin: 'app/javascript/packs/rails_admin.js' }, format: 'iife' },
  // Manipule a son propre point d'entrée : son JavaScript n'alourdit pas le
  // bundle des écoles qui ne s'en servent pas.
  { ...base, entryPoints: { manipule: 'app/javascript/manipule.js' }, format: 'esm' },
]

if (watch) {
  Promise.all(configs.map(config => esbuild.context(config))).then(contexts => {
    contexts.forEach(ctx => ctx.watch())
    console.log('Watching for changes...')
  }).catch(() => process.exit(1))
} else {
  Promise.all(configs.map(config => esbuild.build(config))).catch(() => process.exit(1))
}

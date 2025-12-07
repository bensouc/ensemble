const esbuild = require('esbuild')
const rails = require('esbuild-rails')

const watch = process.argv.includes('--watch')

const config = {
  entryPoints: ['app/javascript/application.js', 'app/javascript/packs/rails_admin.js'],
  bundle: true,
  sourcemap: true,
  format: 'esm',
  outdir: 'app/assets/builds',
  publicPath: '/assets',
  external: ['jquery-ui/ui/safe-active-element.js', 'jquery-ui/ui/ie.js'],
  plugins: [rails()],
  logLevel: 'info',
}

if (watch) {
  esbuild.context(config).then(ctx => {
    ctx.watch()
    console.log('Watching for changes...')
  }).catch(() => process.exit(1))
} else {
  esbuild.build(config).catch(() => process.exit(1))
}
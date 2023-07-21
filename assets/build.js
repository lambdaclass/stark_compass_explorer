const esbuild = require('esbuild');
const {wasmLoader} = require('esbuild-plugin-wasm');

const args = process.argv.slice(2)
const watch = args.includes('--watch')
const deploy = args.includes('--deploy')

const loader = {
  // Add loaders for images/fonts/etc, e.g. { '.svg': 'file' }
}

const plugins = [
  wasmLoader({mode:"embedded"})
]

let opts = {
  entryPoints: ['js/app.js'],
  outdir: '../priv/static/assets',
  bundle: true,
  target: 'chrome100',
  logLevel: 'info',
  format:'esm',
  loader,
  plugins
}

if (deploy) {
  opts = {
    ...opts,
    minify: true,
  };
}

if (watch) {
  opts = {
    ...opts,
    sourcemap: "inline",
  };
  esbuild
    .context(opts)
    .then((ctx) => {
      ctx.watch();
    })
    .catch((_error) => {
      process.exit(1);
    });
} else {
  esbuild.build(opts);
}

// Serves build/web and proxies /api to the backend, so the browser sees one origin (no CORS).
// Usage: node tools/serve_web.mjs [port]   (BACKEND_URL defaults to http://localhost:5000)
import { createServer, request } from 'node:http';
import { createReadStream, existsSync, statSync } from 'node:fs';
import { extname, join, normalize, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(fileURLToPath(new URL('../build/web', import.meta.url)));
const port = Number(process.argv[2] ?? 4300);
const backend = new URL(process.env.BACKEND_URL ?? 'http://localhost:5000');

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
};

function proxy(req, res) {
  const upstream = request(
    { host: backend.hostname, port: backend.port, path: req.url, method: req.method, headers: req.headers },
    (response) => {
      res.writeHead(response.statusCode ?? 502, response.headers);
      response.pipe(res);
    },
  );
  // Same answer the Nginx gateway gives when the backend is down.
  upstream.on('error', () => {
    res.writeHead(502, { 'content-type': 'application/problem+json' });
    res.end(JSON.stringify({ title: 'Bad Gateway', status: 502, detail: 'Backend unavailable' }));
  });
  req.pipe(upstream);
}

createServer((req, res) => {
  if (req.url?.startsWith('/api/')) return proxy(req, res);

  const path = normalize(decodeURIComponent((req.url ?? '/').split('?')[0]));
  let file = join(root, path);
  if (!file.startsWith(root)) {
    res.writeHead(403).end();
    return;
  }
  // Single-page app: unknown paths fall back to index.html.
  if (!existsSync(file) || statSync(file).isDirectory()) file = join(root, 'index.html');
  res.writeHead(200, { 'content-type': types[extname(file)] ?? 'application/octet-stream' });
  createReadStream(file).pipe(res);
}).listen(port, () => console.log(`http://localhost:${port}  (api -> ${backend.origin})`));

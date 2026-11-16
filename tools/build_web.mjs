// Usage: node tools/build_web.mjs
// Builds the web portal with the build setting read from ./.env (API_BASE_URL). The bookable
// services come from the API (GET /services), so no service list is read here.
import { readFileSync, writeFileSync, existsSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { tmpdir } from 'node:os';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const envPath = join(root, '.env');

function readEnv(path) {
  const values = {};
  for (const raw of readFileSync(path, 'utf8').split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith('#') || !line.includes('=')) continue;
    const index = line.indexOf('=');
    const key = line.slice(0, index).trim();
    let value = line.slice(index + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    values[key] = value;
  }
  return values;
}

if (!existsSync(envPath)) {
  console.error('Missing .env in the portal root. Create it with API_BASE_URL.');
  process.exit(1);
}

const env = readEnv(envPath);
const apiBaseUrl = (env.API_BASE_URL ?? '').replace(/\/+$/, '');
if (!apiBaseUrl) {
  console.error('API_BASE_URL is empty in .env; a build without it would run the demo mode.');
  process.exit(1);
}
if (!apiBaseUrl.endsWith('/api/v1')) {
  console.error('API_BASE_URL in .env must be the API root and end with /api/v1 (the REST routes live under it).');
  process.exit(1);
}

// Passed as a file so the build reads the value exactly, without shell quoting.
const defineFile = join(tmpdir(), `medilo-portal-defines-${process.pid}.json`);
writeFileSync(defineFile, JSON.stringify({ API_BASE_URL: apiBaseUrl }));
console.log('Building with: API_BASE_URL');

const result = spawnSync('flutter', ['build', 'web', `--dart-define-from-file=${defineFile}`], {
  cwd: root,
  stdio: 'inherit',
  shell: true,
});
rmSync(defineFile, { force: true });
process.exit(result.status ?? 1);

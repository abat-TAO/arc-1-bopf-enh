import { build } from 'esbuild';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

const directory = await mkdtemp(join(tmpdir(), 'bopf-tests-'));
try {
  const outfile = join(directory, 'tests.mjs');
  await build({ entryPoints: ['tests/index.test.ts'], bundle: true, platform: 'node', format: 'esm', target: 'node22', outfile });
  const result = spawnSync(process.execPath, ['--test', '--test-isolation=none', outfile], { stdio: 'inherit' });
  if (result.error) throw result.error;
  process.exitCode = result.status ?? 1;
} finally {
  await rm(directory, { recursive: true, force: true });
}

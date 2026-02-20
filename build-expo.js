#!/usr/bin/env node

const { spawnSync } = require('node:child_process');

function run(cmd, args) {
  const r = spawnSync(cmd, args, { stdio: 'inherit', shell: false });
  if (r.error) throw r.error;
  if (r.status !== 0) process.exit(r.status ?? 1);
}

// Prefer the locally installed TypeScript compiler.
// Using npx makes it work for both npm and yarn environments.
run('npx', ['-y', 'tsc', '--project', 'expo/tsconfig.json']);

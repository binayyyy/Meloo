import { mkdir, rm } from 'node:fs/promises';
import path from 'node:path';

const root = process.cwd();
const demoDir = path.join(root, '.tooling/demo');
const files = [
  'smart-event-local.sqlite',
  'smart-event-demo.sqlite',
  'demo-data.json',
];

await mkdir(demoDir, { recursive: true });

for (const file of files) {
  await rm(path.join(demoDir, file), { force: true });
}

console.log(`Reset demo artifacts in ${demoDir}`);

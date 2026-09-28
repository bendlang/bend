import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import test from 'node:test';
const project=path.resolve(import.meta.dirname,'../..');
const cli=path.join(project,'cli.mjs');
const run=args=>spawnSync(process.execPath,[cli,...args],{cwd:project,encoding:'utf8',timeout:120000});
test('public CLI defaults to main evaluation and retains explicit check-only',()=>{
  const source=path.join(import.meta.dirname,'typed-smoke/bool.bend');
  const evaluated=run([source]);assert.equal(evaluated.status,0,evaluated.stderr);assert.equal(evaluated.stdout,'On{}\n');
  const checked=run(['--check-only',source]);assert.equal(checked.status,0,checked.stderr);assert.equal(checked.stdout,'ALL PROOFS CHECK\nUse --verdict for mathematical validity.\n');
  const conflicted=run([source,'--check-only','--run']);assert.notEqual(conflicted.status,0);assert.equal(conflicted.stdout,'');
});
test('multiple output suffixes route to JS and native C without overwriting inputs',()=>{
  const directory=fs.mkdtempSync(path.join(os.tmpdir(),'bend-cli-test-'));
  try {
    const source=path.join(directory,'input.bend'),js=path.join(directory,'output.mjs'),c=path.join(directory,'output.c');
    fs.copyFileSync(path.join(import.meta.dirname,'typed-smoke/base-u32.bend'),source);
    const original=fs.readFileSync(source,'utf8');
    const emitted=run([source,'-o',js,'-o',c]);assert.equal(emitted.status,0,emitted.stderr);
    const executed=spawnSync(process.execPath,[js],{encoding:'utf8'});assert.equal(executed.status,0,executed.stderr);assert.equal(executed.stdout,'42\n');
    assert.match(fs.readFileSync(c,'utf8'),/#include/);
    const overwrite=run([source,'-o',source]);assert.notEqual(overwrite.status,0);assert.match(overwrite.stderr,/overwrite/);
    assert.equal(fs.readFileSync(source,'utf8'),original);
  } finally {fs.rmSync(directory,{recursive:true,force:true});}
});

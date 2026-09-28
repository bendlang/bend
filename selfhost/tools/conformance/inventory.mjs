import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import os from 'node:os';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';

export const PIN_MANIFEST = fileURLToPath(new URL('../../src/compiler.json',import.meta.url));
export const PIN = JSON.parse(fs.readFileSync(PIN_MANIFEST,'utf8')).upstream;
if(!/^[a-f0-9]{40}$/.test(PIN))throw Error('Invalid upstream pin in src/compiler.json');
export const tidy = text => text.replace(/[ \t]+$/gm, '').trim();
export const sha256 = text => crypto.createHash('sha256').update(text).digest('hex');
// File-backed capture also works under supervisors where synchronous pipe
// capture reports EPERM after a child exits. Never ignore a spawn error merely
// because the command happened to return status zero and some stdout.
function git(upstream,args) {
  const directory=fs.mkdtempSync(path.join(os.tmpdir(),'bend-inventory-git-'));
  const stdout=path.join(directory,'stdout'),stderr=path.join(directory,'stderr');
  const a=fs.openSync(stdout,'wx'),b=fs.openSync(stderr,'wx');
  try {
    const result=spawnSync('git',['-C',upstream,...args],{stdio:['ignore',a,b],timeout:30000});
    if(result.error||result.signal||result.status!==0)throw Error('Pinned upstream git verification failed: '+(result.error?.message??result.signal??'exit '+result.status)+' '+fs.readFileSync(stderr,'utf8'));
    return fs.readFileSync(stdout,'utf8');
  } finally {
    fs.closeSync(a);fs.closeSync(b);fs.rmSync(directory,{recursive:true,force:true});
  }
}
export function walk(dir) {
  return fs.readdirSync(dir, {withFileTypes:true}).sort((a,b)=>a.name.localeCompare(b.name)).flatMap(e =>
    e.isDirectory() ? walk(path.join(dir,e.name)) : [path.join(dir,e.name)]);
}
// Fixture negativity is the gate's observable outcome, not necessarily a type
// rejection: declaration-only unsafe/foreign books can validate, then fail trust.
export function expectation(text) {
  const expected=tidy(text);
  const failureKind=/^SOME PROOFS FAIL\nError: \d+ defs? (?:relies|rely) on unsafe or foreign code:/.test(expected)
    ?'proof-trust':/^SOME PROOFS FAIL(?:\n|$)/.test(expected)?'validation':/^Error:/.test(expected)?'error':null;
  return {expected,negative:failureKind!==null,failureKind};
}
export function describeFixture(file,id) {
    const source=fs.readFileSync(file,'utf8');
    const oracle=expectation(source.split('\n').filter(l=>l.startsWith('#|')).map(l=>l.slice(2)).join('\n'));
    const {expected,negative,failureKind}=oracle;
    const foreign=[...source.matchAll(/^\s*import\s+"([^"\n]+\.(c|js))"/gm)].map(m=>({path:m[1],backend:m[2]}));
    const imports=[...source.matchAll(/^import\s+(\S+)\s+as\s+(\S+)/gm)].map(m=>({path:m[1],alias:m[2]}));
    const base=/^import Base\s*$/m.test(source), main=/^(def|law) main(?:\(|:)/m.test(source);
    const backends=['js','c'].filter(l=>base&&(!foreign.length||foreign.some(f=>f.backend===l)));
    return {id,namespace:id.split('/')[0],file,sha256:sha256(source),bytes:Buffer.byteLength(source),expected,negative,failureKind,
      main,base,imports,foreign,backends,hasExpectation:source.split('\n').some(l=>l.startsWith('#|')),
      gpuCandidate:/!\(/.test(source.replace(/^\s*#.*$/gm,'')),
      tags:[negative?'negative':'positive',...(imports.length?['module-import']:[]),...(foreign.length?['foreign-effect']:[]),
        ...(/\bIO\./.test(source)?['io']:[]),...(/\{==\}|\blaw\b/.test(source)?['proof-or-law']:[]),
        ...(/\bfor\s+[+\-&]|(?:\(|,)\s*[+\-]\w+\s*:/.test(source)?['quantity']:[]),
        ...(/~/.test(source)?['comptime']:[])]};
}

export function inventory(upstream) {
  const revision=git(upstream,['rev-parse','HEAD']).trim();
  if(revision!==PIN) throw Error(`Expected pinned upstream ${PIN}, found ${revision}`);
  git(upstream,['diff','--quiet','HEAD','--','bend2','tests','gates/test.ts']);
  const root=path.join(upstream,'tests');
  const bendSources=walk(root).filter(f=>f.endsWith('.bend')).map(file=>{
    return describeFixture(file,path.relative(root,file).split(path.sep).join('/'));
  });
  // gates/test.ts discovers tests/<namespace>/*.bend. Nested Bend modules are
  // imported support inputs, not independent tests with invented empty oracles.
  const tests=bendSources.filter(t=>t.id.split('/').length===2);
  const supportSources=bendSources.filter(t=>t.id.split('/').length!==2).map(({id,file,sha256,bytes,hasExpectation})=>({id,file,sha256,bytes,hasExpectation}));
  for(const test of tests)if(!test.hasExpectation)throw Error('Gate fixture has no #| oracle: '+test.id);
  const sources=['bend2/bend.ts','bend2/comp.ts','bend2/main.ts','bend2/base.bend','bend2/safe.ts','bend2/bendtt.lean','gates/test.ts'].map(name=>{
    const source=fs.readFileSync(path.join(upstream,name),'utf8');
    return {file:name,sha256:sha256(source),lines:source.split('\n').length-1,
      functions:[...source.matchAll(/^(?:export\s+)?(?:async\s+)?function\s+(\w+)/gm)].map(m=>m[1]),
      exports:[...source.matchAll(/^export\s+(?:async\s+)?(?:function|const|type|class)\s+(\w+)/gm)].map(m=>m[1])};
  });
  const effects=walk(path.join(upstream,'bend2/effs')).map(f=>path.relative(upstream,f).split(path.sep).join('/'));
  const tested=new Set(tests.map(t=>t.file));
  const fixtures=walk(root).filter(f=>!tested.has(f)).map(f=>path.relative(root,f).split(path.sep).join('/'));
  const namespaces=Object.fromEntries([...new Set(tests.map(t=>t.namespace))].map(n=>{
    const ts=tests.filter(t=>t.namespace===n);
    return [n,{total:ts.length,positive:ts.filter(t=>!t.negative).length,negative:ts.filter(t=>t.negative).length,
      failureKinds:Object.fromEntries(['validation','proof-trust','error'].map(kind=>[kind,ts.filter(t=>t.failureKind===kind).length])),
      jsEligible:ts.filter(t=>!t.negative&&t.main&&t.backends.includes('js')).length,
      nativeEligible:ts.filter(t=>!t.negative&&t.main&&t.backends.includes('c')).length}];
  }));
  return {revision,sources,effects,fixtures,supportSources,bendSourceCount:bendSources.length,namespaces,total:tests.length,tests};
}

export function probes(test) {
  const rows=[{lane:'parse'}, {lane:'check'}];
  if(test.main) {
    rows.push({lane:'interpreter'});
    if(test.backends.includes('js')) rows.push({lane:'js'});
    if(test.backends.includes('c')) {
      rows.push({lane:'native'});
      if(!test.negative&&test.gpuCandidate) rows.push({lane:'metal'},{lane:'cuda'});
    }
  }
  return rows;
}

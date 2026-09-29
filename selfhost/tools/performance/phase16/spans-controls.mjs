// Metadata-only controls. Disposable exports expose unchanged checked workers.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {verifyAttempt, identity, verifyIdentity, validatedCache} from '../../development/workflow.mjs';
const [baseArg, candidateArg, outArg] = process.argv.slice(2);
const out = path.resolve(outArg); fs.mkdirSync(out);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-controls.mjs'));
const base = await verifyAttempt(path.resolve(baseArg)), candidate = await verifyAttempt(path.resolve(candidateArg));
const B = (await import(pathToFileURL(base.api.file))).default;
const original = fs.readFileSync(candidate.api.file, 'utf8');
const probes = {kt:5,kb:1,ke:1,norm_exact:2,subst:3};
const extension = '\nexport const spanControls={'+Object.entries(probes).map(([name,n])=>{
  assert.ok(original.includes(`function $${name}$(`), name);
  const args=Array.from({length:n},(_,i)=>`a${i}`).join(',');
  return `${name}:(${args})=>run_loop($${name}$(${args}))`;
}).join(',')+'};\n';
const view=path.join(out,'candidate-view.mjs'); fs.writeFileSync(view, original+extension, {flag:'wx'});
const module = await import(pathToFileURL(view)), C=module.default, X=module.spanControls;
const report={kind:'phase16-zero-origin-controls',complete:false,pass:false,inputs:[identity(import.meta.filename),identity(base.api.file),identity(candidate.api.file),identity(view)],
  view:{source:identity(candidate.api.file),extension,originalPrefixSha256:createHash('sha256').update(fs.readFileSync(view).subarray(0,Buffer.byteLength(original))).digest('hex')},rows:[],cache:{}};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n'); save();
const check=(label,fn)=>{try{fn();report.rows.push({label,pass:true});}catch(e){report.rows.push({label,pass:false,error:String(e.stack??e)});}save();};
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const term=(tag,id=0,kids=[],begin=0,end=0)=>({$:'KTerm',tag,name:'',id,quant:0,kids:list(kids),removed:list([]),originBegin:begin,originEnd:end});
function semantic(value, requireZero=false) {
  if(Array.isArray(value))return value.map(x=>semantic(x,requireZero));
  if(!value||typeof value!=='object')return value;
  if(requireZero&&value.$==='KTerm'){assert.equal(value.originBegin,0);assert.equal(value.originEnd,0);}
  return Object.fromEntries(Object.entries(value).filter(([k])=>!['originBegin','originEnd'].includes(k)).map(([k,v])=>[k,semantic(v,requireZero)]));
}
function census(value) {
  const pending=[value],seen=new WeakSet();let terms=0,nonzero=0,missingMetadata=0,objects=0;
  while(pending.length){const x=pending.pop();if(!x||typeof x!=='object'||seen.has(x))continue;seen.add(x);objects++;
    if(x.$==='KTerm'){terms++;if(x.originBegin===undefined&&x.originEnd===undefined)missingMetadata++;else if(x.originBegin!==0||x.originEnd!==0)nonzero++;}
    for(const v of Object.values(x))if(v&&typeof v==='object')pending.push(v);
  }return {terms,nonzero,missingMetadata,objects};
}
try {
  check('checked-worker-prefix-unchanged',()=>assert.equal(report.view.originalPrefixSha256,candidate.api.sha256));
  check('explicit-eight-field-abi',()=>assert.equal(C.compiler_span_abi(),3));
  check('canonical-generated-absence',()=>assert.deepEqual(X.kt('Qnt','',0,0,list([])),term('Qnt')));
  check('span-projections',()=>{assert.equal(X.kb(term('Qnt',0,[],11,17)),11);assert.equal(X.ke(term('Qnt',0,[],11,17)),17);});
  check('semantic-equality-ignores-ranges',()=>assert.equal(X.norm_exact(term('Qnt',0,[],11,17),term('Qnt',0,[],31,39)), true));
  check('substitution-preserves-parent-range',()=>{const t=term('Ctr',0,[term('Var',1,[],2,3)],11,17),r=X.subst(t,1,term('Qnt',0,[],31,39));assert.equal(r.originBegin,11);assert.equal(r.originEnd,17);assert.equal(r.kids.head.originBegin,31);assert.equal(r.kids.head.originEnd,39);});
  check('substitution-uses-replacement-range',()=>assert.deepEqual(X.subst(term('Var',1,[],2,3),1,term('Qnt',0,[],31,39)),term('Qnt',0,[],31,39)));
  const sources=[
    ['empty',''],['function','def id(x): x\n'],['literal','def main() -> U32:\n  12\n'],
    ['repeated','def f(x):\n  x(x)\n'],['constructor','type N is Data:\n  Z{}\n  S{x:N}\ndef v(): S{Z{}}\n'],
    ['unicode','# 😀\ndef main(): "𝒳\\n"\n'],['tabs','def main():\n\t!\n'],['eof','def main(): ('],
    ['proof','law eq:\n  {0 == 1 : U32}\ndef eq(): {==}\n'],['precedence','def main(): (!;)\ndef broken(\n']];
  for(const [label,source]of sources)check('parse-'+label,()=>assert.deepEqual(semantic(C.f_parse(source),true),B.f_parse(source)));
  const selected = m=>JSON.parse(fs.readFileSync(path.join(path.dirname(m.api.file),m.artifactKind==='derived-b1'?'../validation-001/selected/candidate.json':'validation-001/selected/candidate.json'))).results;
  check('all36-focused-observations-unchanged',()=>{
    const normalize=(rows,m)=>rows.map(x=>{
      const r=structuredClone(x.result);
      if(r.hostProvenance?.driverSha256!==undefined){
        assert.equal(r.hostProvenance.driverSha256,identity(path.join(m.snapshot.root,'tools/typed-driver.mjs')).sha256);
        delete r.hostProvenance.driverSha256;
      }
      const normalizePath=file=>{
        if(!file.startsWith(m.snapshot.root+'/'))return file;
        const rel=path.relative(m.snapshot.root,file);
        assert.equal(identity(path.join(base.snapshot.root,rel)).sha256,identity(path.join(candidate.snapshot.root,rel)).sha256);
        return 'SNAPSHOT/'+rel;
      };
      if(r.sourceFile)r.sourceFile=normalizePath(r.sourceFile);
      if(r.files)r.files=r.files.map(normalizePath);
      return{id:x.id,lane:x.lane,result:r};
    });
    const a=selected(base),b=selected(candidate);assert.equal(a.length,36);assert.equal(b.length,36);
    assert.deepEqual(normalize(b,candidate),normalize(a,base));
  });
  const caches={};
  for(const [name,m]of Object.entries({baseline:base,candidate})) {
    const file=validatedCache(path.join(m.snapshot.root,'build/typed/cache'),m.api.file,m.base.file).file;
    const bytes=fs.readFileSync(file),data=JSON.parse(bytes);caches[name]=data;
    report.inputs.push(identity(file));report.cache[name]={identity:identity(file),...census(data.book),bookJsonBytes:Buffer.byteLength(JSON.stringify(data.book))};
  }
  check('Base-cache-semantic-fields-unchanged',()=>assert.deepEqual(semantic(caches.candidate.book,true),caches.baseline.book));
  check('v5-helper-and-runtime-unchanged',()=>{for(const file of ['tools/development/equality.mjs','src/runtime.mjs'])assert.equal(identity(path.join(candidate.snapshot.root,file)).sha256,identity(path.join(base.snapshot.root,file)).sha256);});
  report.inputs.forEach(verifyIdentity);report.complete=true;report.pass=report.rows.every(x=>x.pass);save();assert.equal(report.pass,true);
}catch(e){report.error=String(e.stack??e);save();process.exitCode=1;}
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,failed:report.rows.filter(x=>!x.pass).map(x=>x.label),cache:report.cache}));

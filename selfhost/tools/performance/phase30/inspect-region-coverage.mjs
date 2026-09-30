#!/usr/bin/env node
// Checked acquisition and static source-shape inventory; never run workloads.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';
import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
import {verifyAttempt} from '../../development/workflow.mjs';
const root=path.resolve(import.meta.dirname,'../../../..');
const [outArg,attemptArg,selection]=process.argv.slice(2),out=path.resolve(outArg),attempt=path.resolve(attemptArg);
assert.ok(selection===undefined||selection==='raytrace-typed');
fs.mkdirSync(out,{recursive:false});
const id=file=>({file:fs.realpathSync(file),sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const m=await verifyAttempt(attempt);process.env.BEND_TYPED_API=m.api.file;process.env.BEND_TYPED_RUNTIME=m.runtime.file;process.env.BEND_BASE=m.base.file;
const D=await import(pathToFileURL(path.join(m.snapshot.root,'tools/typed-driver.mjs'))),api=await D.loadApi();
const array=xs=>{const out=[];for(;xs?.$==='Con';xs=xs.tail)out.push(xs.head);return out;};
const tag=t=>t?.$==='KLambda'?'Lam':t?.$==='KLiteral'?'Lit':t?.tag??'Absent';
const name=t=>t?.$==='KLiteral'?t.kind:t?.name??'';
const kids=t=>array(t?.kids),strip=t=>{for(let n=0;tag(t)==='Ann'&&n<1024;n++)t=kids(t)[0];return t;};
const type=t=>{t=strip(t);return ['Ref','ADT'].includes(tag(t))?name(t):tag(t);};
const signature=t=>{const params=[];for(let n=0;tag(strip(t))==='All'&&n<64;n++){t=strip(t);const k=kids(t);params.push(type(k[0]));t=k[1];}return {params,result:type(t)};};
const spine=t=>{const args=[];for(let n=0;tag(strip(t))==='App'&&n<128;n++){const k=kids(strip(t));args.unshift(k[1]);t=k[0];}t=strip(t);return {name:tag(t)==='Ref'?name(t):null,args};};
const unwrap=t=>{for(let n=0;tag(strip(t))==='Lam'&&n<64;n++)t=kids(strip(t))[0];return strip(t);};
const tail=t=>{t=unwrap(t);for(let n=0;tag(t)==='Let'&&n<128;n++)t=strip(kids(t).at(-1));return t;};
function shape(d){
 const sig=signature(d.typ),tags={},calls={},todo=[d.value];let nodes=0;
 while(todo.length&&nodes<100000){const t=todo.pop(),k=kids(t),g=tag(t);nodes++;tags[g]=(tags[g]??0)+1;if(g==='Ann'){todo.push(k[0]);continue;}if(g==='App'){const s=spine(t);if(s.name){calls[s.name]=(calls[s.name]??0)+1;todo.push(...s.args);continue;}}todo.push(...k);}
 const body=strip(d.value);let natCase=null;
 if(sig.params[0]==='Nat'&&tag(body)==='Mat'&&name(body)==='Zero'){
  const second=strip(kids(body)[1]);if(tag(second)==='Mat'&&name(second)==='Succ'){
   const succ=tail(kids(second)[0]),s=spine(succ);natCase={successorTailTag:tag(succ),successorTailName:s.name,exactSelfTail:s.name===d.name,zeroTailTag:tag(tail(kids(body)[0]))};
  }
 }
 const scalar=allowed=>sig.params.length>0&&[...sig.params,sig.result].every(x=>allowed.includes(x));
 return {name:d.name,...sig,arity:d.arity,head:tag(body),headName:name(body),nodes,tags,calls,natCase,signatureU32Bool:scalar(['U32','Bool']),signatureWithF32:scalar(['U32','Bool','F32']),signatureWithNat:scalar(['U32','Bool','Nat']),signatureAllScalars:scalar(['U32','Bool','Nat','F32'])};
}
const six=JSON.parse(fs.readFileSync(path.join(root,'selfhost/tools/performance/phase28/six-cases.json'))).cases;
const apps=JSON.parse(fs.readFileSync(path.join(root,'selfhost/tools/performance/phase28/application-cases.json'))).cases.filter(x=>x.mode==='library');
const cases=selection?[{id:'raytrace-typed',file:'selfhost/tools/performance/phase28/corpus/raytrace-typed.bend'}]:[...six.map(x=>({id:x.id,file:x.fixture.path})),...apps.map(x=>({id:x.id,file:x.source}))];assert.equal(cases.length,selection?1:10);
const report={kind:'phase30-scalar-region-coverage',complete:false,scope:(selection?'Previously documented Phase28 typed raytrace wrapper; original algorithm prefix retained.':'Ten initial Phase28 library fixtures.')+' Checked source acquisition and static sites only; no dynamic cost or speed inference.',inputs:[id(import.meta.filename),id(path.join(attempt,'attempt.json')),id(m.api.file),id(m.runtime.file),id(m.base.file)],cases:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
for(const c of cases){
 const source=path.join(root,c.file),input=id(source);let annotated=[];
 const wrapped={...api,j_library_selected(context,book){annotated=array(book).filter(d=>d?.$==='KDef'&&d.kind==='Def'&&!d.native);return api.j_library_selected(context,book);}};
 const start=performance.now(),result=await D.inspect(source,{mode:'library',api:wrapped});
 const row={id:c.id,input,acquisitionMs:performance.now()-start,status:result.status,checked:result.checked,phase:result.phase,diagnostic:result.diagnostic};
 if(result.status==='ok'){
  const file=path.join(out,c.id+'.mjs');fs.writeFileSync(file,result.code);row.output=id(file);
  row.definitions=annotated.map(shape);row.regions=[];
  for(const line of result.code.split('\n')){const m=/^G\[("(?:[^"\\]|\\.)*")\]=/.exec(line);if(!m)continue;const owner=JSON.parse(m[1]);if(line.includes('/* private scalar region */')){const guards=/const \$guards=\[([^\]]*)\]/.exec(line);row.regions.push({owner,guards:guards?JSON.parse('['+guards[1]+']'):null,bytes:Buffer.byteLength(line)});}}
  row.summary={definitions:row.definitions.length,regions:row.regions.length,u32BoolSignatures:row.definitions.filter(x=>x.signatureU32Bool).length,newF32Signatures:row.definitions.filter(x=>x.signatureWithF32&&!x.signatureU32Bool).length,newNatSignatures:row.definitions.filter(x=>x.signatureWithNat&&!x.signatureU32Bool).length,natZeroSucc:row.definitions.filter(x=>x.natCase).length,syntacticSelfTails:row.definitions.filter(x=>x.natCase?.exactSelfTail).length};
 }
 assert.deepEqual(id(source),input);report.cases.push(row);save();console.log(JSON.stringify({id:row.id,status:row.status,acquisitionMs:row.acquisitionMs,summary:row.summary}));
}
await verifyAttempt(attempt);for(const input of report.inputs)assert.deepEqual(id(input.file),input);
report.complete=true;save();fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));

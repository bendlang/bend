import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {makeFixtures,definition,term,list,fnv,ctr,nil} from './checker-fixtures.mjs';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const sha=b=>createHash('sha256').update(b).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file)),bytes:fs.statSync(file).size});
const manifest=JSON.parse(fs.readFileSync(path.join(dir,'derive.json')));
const inputs=[import.meta.filename,path.join(path.dirname(import.meta.filename),'checker-fixtures.mjs'),path.join(dir,'derive.json'),'design/phase32/checker-direct-calls.md',...Object.values(manifest.variants).map(v=>v.file)].map(identity);
const report={kind:'phase32-checker-direct-controls',complete:false,pass:false,inputs,node:process.version,scope:'Original public compiler plus private immutable helper copies; no timing or public admission',lookup:[],infer:[],boundaries:[],witnesses:[]};
for(const name of ['checker-controls.mjs','checker-fixtures.mjs'])fs.copyFileSync(path.join(path.dirname(import.meta.filename),name),path.join(out,'consumed-'+name));
try{
 const roles=Object.keys(manifest.variants);const modules=[];
 for(const role of roles){const v=manifest.variants[role];assert.equal(identity(v.file).sha256,v.sha256);modules.push(await import(pathToFileURL(v.file)))}
 if(roles.includes('captured')){
  let expectedSource=fs.readFileSync(manifest.variants.captured.file,'utf8');
  for(const [name,proof]of Object.entries(manifest.projections)){
   const before='const $Checker_'+name+'='+proof.code+';';
   const after='const $Checker_'+name+'=function(a){return a[0].a['+proof.field+'];};';
   assert.equal(expectedSource.split(before).length,2);expectedSource=expectedSource.replace(before,after);
  }
  assert.equal(expectedSource,fs.readFileSync(manifest.variants.fields.file,'utf8'));
  report.projectionOnlyPair={captured:manifest.variants.captured,fields:manifest.variants.fields,changedCallbacks:Object.keys(manifest.projections).length,allOtherBytesIdentical:true};
 }
 assert.equal(fnv('costarring'),fnv('liquid'));
 report.collision={names:['costarring','liquid'],hash:fnv('costarring')};
 for(let i=0;i<modules.length;i++){
  const m=modules[i],f=makeFixtures(m),before={book:JSON.stringify(f.book),cached:JSON.stringify(f.cached)};
  for(const [cache,book]of [['uncached',f.book],['cached',f.cached]])for(let j=0;j<f.queries.length;j++){
   const name=f.queries[j],expected=f.expected[j],publicValue=m.default.lookup(book,name),privateValue=m.checkerProbe.lookup(book,name);
   assert.deepEqual(publicValue,expected);assert.deepEqual(privateValue,expected);
   const found=f.definitions.find(d=>d.a[0]===name);
   if(found){assert.equal(publicValue,found);assert.equal(privateValue,found)}
   report.lookup.push({role:roles[i],cache,name,expected,publicValue,privateValue,foundIdentity:!!found});
  }
  assert.equal(JSON.stringify(f.book),before.book);assert.equal(JSON.stringify(f.cached),before.cached);
  for(const point of f.infer){
   const publicValue=m.default.infer_ref(...point.args),privateValue=m.checkerProbe.infer_ref(...point.args);
   assert.deepEqual(publicValue,point.expected,roles[i]+':'+point.name+':public');assert.deepEqual(privateValue,point.expected,roles[i]+':'+point.name+':private');
   assert.equal(publicValue.a[4],point.world);assert.equal(privateValue.a[4],point.world);
   report.infer.push({role:roles[i],name:point.name,expected:point.expected,publicValue,privateValue,worldIdentity:true});
  }
 }
 function observe(m,action){const saved=Object.fromEntries(Object.keys(m.G).map(k=>[k,Object.getOwnPropertyDescriptor(m.G,k)]));const events=[];
  try{const value=JSON.parse(JSON.stringify(action(m,events)));return {value,events:events.slice()}}catch(e){return {error:{name:e.name,message:e.message},events:events.slice()}}
  finally{for(const[k,v]of Object.entries(saved))Object.defineProperty(m.G,k,v)}}
 function boundary(name,action){const observed=modules.map(m=>observe(m,action));for(let i=1;i<observed.length;i++)assert.deepEqual(observed[0],observed[i],name+':'+roles[i]);report.boundaries.push({name,observed})}
 const wrap=(m,events,n)=>{const f=m.G[n];m.G[n]={...f,code(a){events.push(n);return Reflect.apply(f.code,this,[a])}}};
 for(const mode of ['normal','saved-partial','raw','constructed'])boundary(mode,(m,events)=>{
  const book=list([definition('x')]),f=m.G.lookup;
  if(mode==='normal'){wrap(m,events,'dn');return m.default.lookup(book,'x')}
  if(mode==='saved-partial'){const part=m.call(f,[book]);wrap(m,events,'lookup_cached');return m.call(part,['x'])}
  const v=mode==='raw'?Reflect.apply(f.code,null,[[book]]):Reflect.construct(f.code,[[book]]);
  wrap(m,events,'lookup_cached');return m.call({arity:0,code:()=>v,env:null,bound:[]},['x']);
 });
 for(const field of [0,1,2,6])boundary('field-getter:'+field,(m,events)=>{
  const d=definition('x'),a=d.a.slice();Object.defineProperty(a,field,{get(){events.push('field:'+field);return d.a[field]}});
  return m.default.lookup(list([{$:'KDef',a}]),'x');
 });
 boundary('getter-mutates-dn',(m,events)=>{
  const d=definition('x'),a=d.a.slice();let done=false;
  Object.defineProperty(a,1,{get(){events.push('kind');if(!done){done=true;m.G.dn={arity:1,env:null,bound:[],code(){events.push('changed-dn');return 'other'}}}return 'Def'}});
  const v=m.default.lookup(list([{$:'KDef',a}]),'x');assert.equal(v.a[1],'Absent');assert.ok(events.includes('changed-dn'));return v;
 });
 // Explicitly establish why private immutable results are not a public proof.
 const hostile=[];
 for(const m of modules){hostile.push(observe(m,(m,events)=>{
  const d=definition('x'),a=d.a.slice();let done=false;
  Object.defineProperty(a,1,{get(){events.push('kind');if(!done){done=true;m.G.dn={arity:1,env:null,bound:[],code(){events.push('changed-dn');return 'other'}}}return 'Def'}});
  return m.checkerProbe.lookup(list([{$:'KDef',a}]),'x');
 }))}
 assert.notDeepEqual(hostile[0],hostile[1]);report.witnesses.push({name:'unchecked-public-structured-capture-is-unsound',observed:hostile,expectedMismatch:true});
 // The slice observes every field, so direct reads require the immutable proof.
 const copyOrder=[];
 for(const m of modules){copyOrder.push(observe(m,(m,events)=>{
  const d=definition('x'),a=d.a.slice();let once=false;
  Object.defineProperty(a,2,{get(){events.push('unselected-field');if(!once){once=true;a[0]='other'}return 0}});
  return m.checkerProbe.lookup(list([{$:'KDef',a}]),'x');
 }))}
 if(roles.includes('fields')){assert.notDeepEqual(copyOrder[0],copyOrder[roles.indexOf('fields')]);report.witnesses.push({name:'slice-unselected-field-effect-refuses-public-field-read',roles,observed:copyOrder,expectedMismatch:true})}
 // Execute a deliberately wrong derivative to challenge the complete oracle.
 const directSource=fs.readFileSync(manifest.variants.direct.file,'utf8');
 const before='const $Checker_dn=function(a){return project("KDef",a[0]).slice()[0];};';
 const after='const $Checker_dn=function(a){return project("KDef",a[0]).slice()[1];};';
 assert.equal(directSource.split(before).length,2);
 const badPath=path.join(out,'wrong-field.mjs');fs.writeFileSync(badPath,directSource.replace(before,after),{flag:'wx'});
 const wrongModule=await import(pathToFileURL(badPath)),right=definition('x');
 const wrong=wrongModule.checkerProbe.lookup(list([right]),'x');
 assert.notDeepEqual(wrong,right);assert.equal(wrong.a[1],'Absent');
 report.witnesses.push({name:'wrong-projection-index-rejected',module:identity(badPath),expected:right,observed:wrong,expectedMismatch:true});
 for(const input of inputs)assert.deepEqual(identity(input.file),input);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,lookup:report.lookup.length,infer:report.infer.length,boundaries:report.boundaries.length,witnesses:report.witnesses.length,error:report.error}));

// Verify ordinary ABI/ownership behavior for the internal fresh-vector path.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';import {createHash} from 'node:crypto';
const [dir,output]=process.argv.slice(2);const out=path.resolve(output);fs.mkdirSync(out,{recursive:false});
const ident=file=>({file:path.resolve(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={complete:false,pass:false,scope:'Owned non-tail call prototypes; ABI and alias boundaries, no timing.',inputs:[ident(import.meta.filename)],observations:[]};
try{
 const all={};
 for(const side of ['unchanged','owned']){
  const file=path.join(dir,side+'.mjs');report.inputs.push(ident(file));
  const target=path.join(out,side+'.mjs');
  fs.writeFileSync(target,fs.readFileSync(file,'utf8')+'\nexport {fn,force,apply,jump};\nexport const invokeFresh='+(side==='owned'?'callOwned':'call')+';\n');
  const m=await import(pathToFileURL(target));const trace=[];
  const tests=[
   ['mutates-received',()=>m.invokeFresh(m.fn(2,a=>{a[0]=7;a.push(8);return a}),[1,2])],
   ['partial',()=>{const p=m.invokeFresh(m.fn(3,a=>{a[0]=99;return a}),[1]);return {result:m.invokeFresh(p,[2,3]),bound:p.bound}}],
   ['over',()=>m.invokeFresh(m.fn(1,a=>{a.push(99);return m.fn(1,b=>b[0])}),[1,2])],
   ['zero',()=>m.invokeFresh(m.fn(0,a=>{a.push(8);return 7}),[])],
   ['null',()=>m.invokeFresh(null,[1,2])],
   ['type',()=>m.invokeFresh({typeName:'X',typeArgs:['a']},[2])],
   ['env',()=>m.invokeFresh(m.fn(1,function(a){return this.x+a[0]},{x:13}),[2])],
   ['public-copy',()=>{const a=[1];const r=m.call(m.fn(1,x=>{x[0]=7;return x}),a);return {a,r}}],
   ['tail-reuse',()=>{const bounce=m.jump(m.fn(1,a=>{a[0]++;return a[0]}),[1]);return [m.force(bounce),m.force(bounce),bounce.args]}],
   ['error',()=>{const events=[];try{m.invokeFresh(m.fn(1,a=>{events.push('body');throw Error('sentinel')}),[(events.push('arg'),1),2]);}catch(e){return {events,error:e.message}}}],
  ];
  for(const [name,f]of tests)trace.push({name,value:f()});
  const events=[];let reads=0;
  const f={get code(){events.push('code'+(++reads));return a=>a[0]+a[1]},get bound(){events.push('bound');return []},get arity(){events.push('arity');return 2},get env(){events.push('env');return null}};
  trace.push({name:'metadata-getters',value:m.invokeFresh(f,[2,3]),events});
  all[side]=trace;
 }
 assert.deepEqual(all.owned,all.unchanged);report.observations=all;report.complete=true;report.pass=true;
 for(const row of report.inputs)assert.deepEqual(ident(row.file),row);
}catch(e){report.error=e.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({complete:report.complete,pass:report.pass,error:report.error}));

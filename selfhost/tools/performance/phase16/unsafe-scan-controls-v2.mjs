import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
const [attemptArg,outArg,mode='baseline']=process.argv.slice(2);
assert(['baseline','candidate'].includes(mode));
const out=path.resolve(outArg);fs.mkdirSync(out);
const m=await verifyAttempt(fs.realpathSync(attemptArg));
const source=fs.readFileSync(m.api.file,'utf8');
assert(source.includes('function $contains_self$('));assert(source.includes('function $self_pending$('));
const target=path.join(out,'instrumented-api.mjs');
fs.writeFileSync(target,source+`
let calls=0;
const originalContainsSelf=$contains_self$;
$contains_self$=function(...args){calls++;return originalContainsSelf(...args);};
export const scanControl=run_lib((d,t)=>run_loop($self_pending$(d,t)),2);
export const resetScan=()=>{calls=0;};
export const countScan=()=>calls;
`);
const api=await import(pathToFileURL(target));
const inputs=[import.meta.filename,m.api.file,process.execPath].map(identity);
const report={kind:'phase16-unsafe-recursion-scan-control',complete:false,pass:false,mode,inputs,rows:[],scope:'Copied private API instrumentation counts actual contains_self invocations. Results derive from checked compiler code; this view is not a release artifact or timing run.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const term=(tag,name='',kids=[])=>({$:'KTerm',tag,name,id:0,quant:1,kids:list(kids),removed:nil,originBegin:0,originEnd:0});
try{
 for(const unsafe of [false,true])for(const hasSelf of [false,true])for(const width of [0,64]){
  const body=term('Ctr','Container',[...Array.from({length:width},()=>term('Var','x')),term('Ref',hasSelf?'probe':'other')]);
  const d={$:'KDef',name:'probe',kind:'Def',arity:3,templates:1,typ:term('Typ'),value:body,ctors:nil,native:false,unsafe};
  api.resetScan();const result=api.scanControl(d,body),calls=api.countScan();
  const row={unsafe,hasSelf,width,result,calls};report.rows.push(row);save();
  assert.equal(result,!unsafe&&hasSelf?2:0);
  if(mode==='candidate'&&unsafe)assert.equal(calls,0);else assert(calls>0);
 }
 inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;save();
}catch(e){report.error=String(e.stack??e);save();process.exitCode=1;}
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows,error:report.error}));

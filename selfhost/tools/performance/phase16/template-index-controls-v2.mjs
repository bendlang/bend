import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
const [attemptArg,outArg,mode='baseline']=process.argv.slice(2);assert(['baseline','candidate'].includes(mode));
const out=path.resolve(outArg);fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const m=await verifyAttempt(path.resolve(attemptArg));
let source=fs.readFileSync(m.api.file,'utf8');
for(const name of ['$lookup_named$','$index_find$','$sp_initial$','$sp_needed$','$sp_templates$'])assert(source.includes('function '+name+'('),name);
const start=source.indexOf('function $lookup$('),end=source.indexOf('\n}\n',start)+3;
const worker=source.slice(start,end),point='$3 = ($String$eq$(($dn$(_d_0)), _name_0));';
assert.equal(worker.split(point).length,2,'Exact v5 fused lookup comparison required');
source=source.slice(0,start)+worker.replace(point,'namedCalls++; '+point)+source.slice(end);
const moduleFile=path.join(out,'instrumented-api.mjs');
fs.writeFileSync(moduleFile,source+`
let namedCalls=0,indexCalls=0;
const oldIndex=$index_find$;
$index_find$=function(...xs){indexCalls++;return oldIndex(...xs);};
export const membership=run_lib((book,term)=>{
  const st=run_loop($sp_initial$(book,0));
  const templates=run_loop($sp_templates$(st));
  namedCalls=0;indexCalls=0;
  return run_loop($sp_needed$(templates,term));
},2);
export const counts=()=>({namedCalls,indexCalls});
`);
const api=await import(pathToFileURL(moduleFile));
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const term=(tag,name='',kids=[])=>({$:'KTerm',tag,name,id:0,quant:1,kids:list(kids),removed:nil,originBegin:0,originEnd:0});
const definition=(name,templates)=>({$:'KDef',name,kind:'Def',arity:1,templates,typ:term('Typ'),value:term('Absent'),ctors:nil,native:false,unsafe:false});
const inputs=[import.meta.filename,m.api.file,process.execPath].map(identity);
const report={complete:false,pass:false,mode,inputs,rows:[],scope:'Actual fused lookup name comparisons and index entries during membership only; checked state setup excluded from counts, included in later process timing.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
  for(const size of [0,1,8,32,128]){
    const book=list([...Array.from({length:size},(_,i)=>definition('template'+i,1)),definition('ordinary',0)]);
    const cases=[['absent',term('Ref','missing'),false],['ordinary',term('Ref','ordinary'),false],['leaf',term('Typ'),false]];
    if(size)cases.push(['first',term('Ref','template0'),true],['last',term('Ref','template'+(size-1)),true],['nested',term('App','',[term('Ref','missing'),term('Ref','template'+(size-1))]),true]);
    for(const [label,t,expected]of cases){
      const result=api.membership(book,t),counts=api.counts();assert.equal(result,expected);
      if(mode==='candidate'){assert(counts.namedCalls<=(label==='nested'?2:1));if(label!=='leaf')assert(counts.indexCalls>0);}else if(size&&label!=='leaf')assert(counts.namedCalls>0);
      report.rows.push({size,label,result,...counts});save();
    }
  }
  inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;
}catch(e){report.error=String(e.stack??e);process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));

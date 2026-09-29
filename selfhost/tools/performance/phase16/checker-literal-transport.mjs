import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'../../../..');
const build=path.join(root,'selfhost/build/phase16/checker-literal-build-01');
const {verifyAttempt,identity,verifyIdentity}=await import(pathToFileURL(path.join(build,'snapshot/tools/development/workflow.mjs')));
const out=path.resolve(process.argv[2]);fs.mkdirSync(out);
const apiFile=path.join(build,'equality/api.mjs');
const inputs=[import.meta.filename,apiFile,path.join(build,'attempt.json'),path.join(root,'design/phase16/checker-compact-literals.md')].map(identity);
const report={kind:'phase16-literal-representation-controls',complete:false,inputs,rows:[]};
try {
 verifyAttempt(build);
 const api=(await import(pathToFileURL(apiFile))).default;
 const nil={$:'Nil'};const term=(tag,name='',id=0,kids=nil)=>({$:'KTerm',tag,name,id,quant:0,kids,removed:nil,originBegin:0,originEnd:0});
 const check=(name,actual,expected)=>{assert.deepEqual(actual,expected,name);report.rows.push({name,pass:true});};
 for(const [kind,number,text] of [['Nat',42,''],['U32',4294967295,''],['F32',2147483648,''],['String',0,'a\0😃']]){
  const raw=api.kl_make(kind,number,text),t=api.k_with_span(raw,7,17);
  check(kind+'/shape',t,{$:'KLiteral',kind,number,text,originBegin:7,originEnd:17});
  check(kind+'/projections',[api.tg(t),api.nm(t),api.ix(t),api.qt(t),api.ks(t),api.rm(t),api.kb(t),api.ke(t),api.kl_number(t),api.kl_text(t)],['Lit',kind,0,0,nil,nil,7,17,number,text]);
  for(const [name,value] of [['children',api.k_with_children(t,{$:'Con',head:term('Var','x',2),tail:nil})],['subst',api.subst(t,0,term('Ref','changed'))],['shift',api.sp_shift(t,99)],['path',api.f_path_term(t,'other')],['qualify',api.f_qual_term(t,nil,'ns',nil)],['alias',api.f_alias_term(t,nil,nil)],['existing-span',api.f_span_created(t,90,100)],['absent-pattern-span',api.f_pattern_value(t,0,0)]])check(kind+'/'+name,value,t);
  check(kind+'/new-span',api.f_span_created(raw,90,100),{...raw,originBegin:90,originEnd:100});
  check(kind+'/pattern-span',api.f_pattern_value(t,90,100),{...t,originBegin:90,originEnd:100});
 }
 inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;
} catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));

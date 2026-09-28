import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity,verifyIdentity,verifyAttempt} from '../../development/workflow.mjs';
import {moduleView} from '../phase13/rewriter-structure.mjs';
const [candidateArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);
const baseline=await verifyAttempt('selfhost/build/phase12/integrated-03'),candidate=await verifyAttempt(candidateArg);
const report={kind:'phase14-source-dispatch-static-and-focused-analysis',complete:false,inputs:[identity(import.meta.filename),identity(process.execPath),baseline.api,candidate.api],codegen:[],source:[],focused:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const cost=s=>({physical:s.split('\n').length-Number(s.endsWith('\n')),nonblank:s.split('\n').filter(x=>x.trim()).length,bytes:Buffer.byteLength(s),defs:(s.match(/^def /gm)||[]).length,laws:(s.match(/^law /gm)||[]).length});
try{
 for(const [name,m] of [['baseline',baseline],['candidate',candidate]]){
  const source=fs.readFileSync(m.api.file,'utf8'),view=moduleView(source),names=['norm_eval_node',...(name==='candidate'?['app','ann','let','ref','min','rwt'].map(n=>'norm_node_'+n):[])];
  let text='';for(const n of names){const fn=view.functions.get('$'+n+'$');assert.ok(fn);text+=source.slice(view.ts[fn.first].start,view.ts[fn.end].end)+'\n';}
  const file=path.join(out,name+'-selection.mjs');fs.writeFileSync(file,text);report.codegen.push({name,file:identity(file),functions:names,forLoop:text.includes('for ('),runTailSites:(text.match(/run_tail\(/g)||[]).length,arrowSites:(text.match(/=>/g)||[]).length,unitSites:(text.match(/\$: "Unit"/g)||[]).length});
  for(const relative of ['src/core/normalize.bend','tools/development/equality.mjs','tools/development/equality.test.mjs']){const file=path.join(m.snapshot.root,relative);report.inputs.push(identity(file));report.source.push({name,relative,...cost(fs.readFileSync(file,'utf8'))});}
 }
 const files=[path.join('selfhost/build/phase12/integrated-03/validation-001/selected/candidate.json'),path.join(candidateArg,'validation-001/selected/candidate.json')];files.forEach(f=>report.inputs.push(identity(f)));
 const [a,b]=files.map(f=>JSON.parse(fs.readFileSync(f)).results);assert.equal(a.length,b.length);
 for(let i=0;i<a.length;i++){assert.equal(a[i].id,b[i].id);const before={...a[i].result},after={...b[i].result};const exact=JSON.stringify(before)===JSON.stringify(after),paths={before:before.sourceFile??null,after:after.sourceFile??null};delete before.sourceFile;delete after.sourceFile;assert.deepEqual(after,before);report.focused.push({id:a[i].id,completeResultExact:exact,sourceFile:paths,allOtherFieldsExact:true});}
 report.inputs.forEach(verifyIdentity);report.complete=true;
}catch(e){report.error=e.stack;process.exitCode=1;}save();console.log(JSON.stringify({complete:report.complete,error:report.error}));

// Disposable counters at exact emitted call sites; not a candidate or timing.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';import {createHash} from 'node:crypto';
const [apiArg,outArg]=process.argv.slice(2),api=path.resolve(apiArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:path.resolve(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const input=identity(api);assert.equal(input.sha256,'ff876a357db2d44d3e1fbd37ab694a16d2fa0f47d60c9d500603e634c8c645f9');
let source=fs.readFileSync(api,'utf8');
const header='function $norm_ref$(_book_0, _t_0, _args_0, _d_0) {';
const pos=source.indexOf(header),end=source.indexOf('\nfunction ',pos+1);assert.ok(pos>=0&&end>pos);
const part=source.slice(pos,end),needle='return $norm_eval$(_book_0, ($dv$(_d_0)), _args_0, ($da$(_d_0)), ($norm_apply$(_t_0, _args_0)));';assert.equal(part.split(needle).length,2);
source=source.slice(0,pos)+part.replace(needle,'return $norm_eval$(_book_0, ($dv$(_d_0)), _args_0, ($da$(_d_0)), phase11Fallback(_t_0, _args_0));')+source.slice(end);
source+='\nlet phase11Calls=0, phase11Spine=0;\nfunction phase11Fallback(t,args){phase11Calls++;for(let x=args;x.$=== "Con";x=x.tail)phase11Spine++;return $norm_apply$(t,args);}\nexport function observe(book,t){phase11Calls=0;phase11Spine=0;const value=run_loop($wnf$(book,t));return{value,fallbackReconstructions:phase11Calls,spineArgumentsTraversed:phase11Spine};}\n';
const derived=path.join(out,'instrumented.mjs');fs.writeFileSync(derived,source);const K=await import(pathToFileURL(derived));
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const term=(tag,name='',id=0,kids=[])=>({$:'KTerm',tag,name,id,quant:0,kids:list(kids),removed:nil});
const rows=[];for(const arity of [0,1,4,16,64,256]){
 const result=term('Ctr','Result');let body=result;for(let i=arity;i>0;i--)body=term('Lam','x',i,[body]);
 const book=list([{$:'KDef',name:'f',kind:'Def',arity,templates:0,typ:term('Absent'),value:body,ctors:nil,native:false,unsafe:true}]);
 let inputTerm=term('Ref','f');for(let i=0;i<arity;i++)inputTerm=term('App','',0,[inputTerm,term('Ctr','Arg')]);
 const observation=K.observe(book,inputTerm);assert.deepEqual(observation.value,result);assert.equal(observation.fallbackReconstructions,1);assert.equal(observation.spineArgumentsTraversed,arity);
 const inputFile=path.join(out,'input-'+arity+'.json');fs.writeFileSync(inputFile,JSON.stringify({book,t:inputTerm})+'\n');rows.push({arity,input:identity(inputFile),observation});
}
assert.deepEqual(identity(api),input);const report={kind:'phase11-eager-reference-fallback-counts',scope:'Actual emitted normalizer with one exact call-site counter; finite raw terms, known terminating constant bodies; not a checked source fixture, B1 candidate, timing, or allocation measurement.',inputs:[identity(import.meta.filename),identity(process.execPath),input],instrumented:identity(derived),cpu:2,hook:{header,needle},rows,pass:true};fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({pass:true,rows:rows.map(({arity,observation})=>({arity,fallbackReconstructions:observation.fallbackReconstructions,spineArgumentsTraversed:observation.spineArgumentsTraversed}))}));

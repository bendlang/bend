// Complete independent numerical oracle and actual compiler admission inventory.
// Root runs with serial ExecutionGuard, explicit heap/RSS/deadline limits.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [baseArg,candidateArg,outArg]=process.argv.slice(2);
assert(baseArg&&candidateArg&&outArg,'usage: producer-fixture-controls.mjs BASELINE.mjs CANDIDATE.mjs NEW_OUT');
const files=[baseArg,candidateArg].map(x=>fs.realpathSync(x)),out=path.resolve(outArg);
assert(!fs.existsSync(out));fs.mkdirSync(out,{recursive:false});
const identity=p=>({path:fs.realpathSync(p),sha256:createHash('sha256').update(fs.readFileSync(p)).digest('hex')});
const report={kind:'phase36-producer-fixture-controls',complete:false,pass:false,inputs:[import.meta.filename,...files].map(identity),oracle:[],admission:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const modules=[];for(const p of files)modules.push(await import(pathToFileURL(p)));
const u=x=>x>>>0,mul=(x,y)=>Math.imul(x,y)>>>0;
// The model returns opcode arrays; evaluation uses a separately generated postfix.
function model(kind,d,s){if(d===0)return [0,kind==='gen'?(s<40?u(s^17):u(s+9)):u(s+9)];
 if(kind==='gen'){const left=model(kind,d-1,u(mul(s,3)+1)),right=model(kind,d-1,u(mul(s,5)+7));return s%2===0?[1,left,right]:[1,right,left];}
 if(kind==='dependent'){const left=model(kind,d-1,u(s+1)),right=model(kind,d-1,hashTree(left));return [1,left,right];}
 if(kind==='unary'){const child=model(kind,d-1,u(s+1));return [1,child,child];}
 const left=model(kind,d-1,u(s+3)),right=model(kind,d-1,u(s+5));return kind==='share'?[1,left,left]:[1,left,right];}
function hashTree(tree){const todo=[[tree,false]],values=[];while(todo.length){const [node,after]=todo.pop();if(node[0]===0){values.push(node[1]);continue;}
 if(!after){todo.push([node,true],[node[2],false],[node[1],false]);continue;}const b=values.pop(),a=values.pop();values.push(u(mul(a,31)+b));}assert.equal(values.length,1);return values[0];}
const names={gen:'producer_check',parallel:'producer_parallel',share:'producer_share',dependent:'producer_dependent',unary:'producer_unary'};
try{
 for(const [kind,name]of Object.entries(names))for(const depth of [0,1,2,4,7])for(const seed of [0,1,39,40,42,2147483648,4294967295]){
  const expected=hashTree(model(kind,depth,seed)),results=modules.map(m=>m.default[name](BigInt(depth),seed));
  report.current={name,kind,depth,seed,expected,results};for(const r of results)assert.equal(r,expected);report.oracle.push(report.current);delete report.current;
 }
 const candidate=fs.readFileSync(files[1],'utf8'),privateName=name=>'$R'+[...name].map(c=>'_'+c.charCodeAt(0)).join('');
 for(const [name,expected]of [['p.gen',true],['p.parallel',true],['p.share',true],['p.dependent',false],['p.unary',false]]){
  const signature='function '+privateName(name)+'(',at=candidate.indexOf(signature),tail=at<0?'':candidate.slice(at,at+signature.length+250);
  const admitted=tail.includes('/* private sum producer */');assert.equal(admitted,expected,'private producer admission '+name);
  report.admission.push({name,expected,admitted});
 }
 for(const x of report.inputs)assert.deepEqual(identity(x.path),x);
 report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,admission:report.admission.length,error:report.error}));

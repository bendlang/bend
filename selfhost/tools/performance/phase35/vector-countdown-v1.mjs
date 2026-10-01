#!/usr/bin/env node
// Exact checked03-output ablation: private vector-loop predecessor cannot escape.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const [input,output]=process.argv.slice(2);
assert(input&&output,'usage: node vector-countdown.mjs CHECKED03_MODULE NEW_OUTPUT');
assert(!fs.existsSync(output),'output exists');
const hash=s=>createHash('sha256').update(s).digest('hex');
const source=fs.readFileSync(input,'utf8');
const known={
 '8a23980636a1bd1db16d01f8fe806bb6532804c7c49b5b78045c071550524bdc':'local-pair',
 '97727c14d3f247bd54a23bcb91e0349b2f6edc58977bade51e4941f131e0a8cb':'local-fold'};
const fixture=known[hash(source)];assert(fixture,'input must be exact checked03 pair/fold output');
const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'],p={exports:{}};
new Function('module','exports',parserSource)(p,p.exports);assert.equal(p.exports.version,'8.16.0');
const parse=s=>p.exports.parse(s,{ecmaVersion:'latest',sourceType:'module'});
const tree=parse(source),changes=[],proofs=[];
function children(n){return Object.entries(n).flatMap(([k,v])=>k==='loc'?[]:Array.isArray(v)?v.filter(x=>x?.type):v?.type?[v]:[]);}
function visit(n,fn,exclusive=false,root=n){fn(n);if(exclusive&&n!==root&&['FunctionDeclaration','FunctionExpression','ArrowFunctionExpression'].includes(n.type))return;for(const c of children(n))visit(c,fn,exclusive,root);}
const id=(n,name)=>n?.type==='Identifier'&&n.name===name;
const one=n=>n?.type==='Literal'&&n.bigint==='1';
const zero=n=>n?.type==='Literal'&&n.bigint==='0';
visit(tree,node=>{
 if(node.type!=='FunctionDeclaration'||!/^\$R(?:_\d+)+$/.test(node.id?.name||''))return;
 if(!source.slice(node.start,node.end).includes('let $w0='))return;
 const all=[];visit(node.body,n=>all.push(n),true);
 const init=all.filter(n=>n.type==='VariableDeclarator'&&id(n.id,'$s0')&&n.init?.type==='BinaryExpression'&&n.init.operator==='-'&&id(n.init.left,'$p0')&&one(n.init.right));
 const pred=all.filter(n=>n.type==='VariableDeclarator'&&n.id?.type==='Identifier'&&/^x\d+$/.test(n.id.name)&&id(n.init,'$s0'));
 const next=all.filter(n=>n.type==='VariableDeclarator'&&id(n.id,'$n0'));
 if(init.length!==1||pred.length!==1||next.length!==1||!id(next[0].init,pred[0].id.name))return;
 const predRefs=all.filter(n=>id(n,pred[0].id.name));
 const n0Refs=all.filter(n=>id(n,'$n0'));
 const s0Refs=all.filter(n=>id(n,'$s0'));
 const stop=all.filter(n=>n.type==='BinaryExpression'&&n.operator==='==='&&id(n.left,'$n0')&&zero(n.right));
 const step=all.filter(n=>n.type==='AssignmentExpression'&&n.operator==='='&&id(n.left,'$s0')&&n.right?.type==='BinaryExpression'&&n.right.operator==='-'&&id(n.right.left,'$n0')&&one(n.right.right));
 // Decl + the single self-tail transfer; no source arithmetic, stores or return.
 if(predRefs.length!==2||n0Refs.length!==3||s0Refs.length!==3||stop.length!==1||step.length!==1)return;
 const initialZero=all.filter(n=>n.type==='BinaryExpression'&&n.operator==='==='&&id(n.left,'$p0')&&zero(n.right));
 assert.equal(initialZero.length,1,'original initial-zero branch retained');
 changes.push([init[0].init.start,init[0].init.end,'$vectorNumber($p0)-1'],
  [stop[0].right.start,stop[0].right.end,'0'],[step[0].right.right.start,step[0].right.right.end,'1']);
 proofs.push({name:node.id.name,originalBodySha256:hash(source.slice(node.start,node.end)),
  predecessor:pred[0].id.name,predecessorOccurrences:predRefs.length,
  nextOccurrences:n0Refs.length,currentOccurrences:s0Refs.length,
  invariant:'Predecessor occurs only as the recursive countdown argument; source cannot observe Number representation. Entry Nat ABI and initial-zero branch unchanged.'});
});
assert(proofs.length>0,'no proven vector-state countdown found');
assert(!source.includes('$vectorNumber'),'private capture name must be unused');
let result=source;
for(const [start,end,text]of changes.sort((a,b)=>b[0]-a[0]))result=result.slice(0,start)+text+result.slice(end);
result='const $vectorNumber=Number;\n'+result;
parse(result);fs.mkdirSync(path.dirname(output),{recursive:true});fs.writeFileSync(output,result,{flag:'wx'});
const receipt={kind:'phase35-private-number-countdown-prototype',checked:false,fixture,
 input:{file:path.resolve(input),sha256:hash(source)},output:{file:path.resolve(output),sha256:hash(result)},
 producer:{file:path.resolve(import.meta.filename),sha256:hash(fs.readFileSync(import.meta.filename))},
 parserSha256:hash(parserSource),node:process.version,loops:proofs,
 numberCapture:'Number is captured once at module initialization, so replacing the global after import does not add a callback at each loop entry. A future compiler rule needs the corresponding runtime capture/guard and host-hook controls.',
 scope:'Saved checked03 JavaScript mechanism experiment only. Valid private Nat inputs are bounded below 2^48 and exactly represented as Number; public ABI and generic fallback are unchanged.'};
if(fixture==='local-pair'){
 assert.equal(result.split('export default ').length,2);
 const wrapper=result.replace('export default ','const $Pair_exports = ')+'\nexport default {...$Pair_exports,bench:p=>$Pair_exports.pair(p)};\n';
 const wrapped=output+'.bench.mjs';fs.writeFileSync(wrapped,wrapper,{flag:'wx'});receipt.controlWrapper={file:path.resolve(wrapped),sha256:hash(wrapper)};
}
fs.writeFileSync(output+'.json',JSON.stringify(receipt,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({fixture,loops:proofs.map(p=>p.name),output,sha256:hash(result)}));

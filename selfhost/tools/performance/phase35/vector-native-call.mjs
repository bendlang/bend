#!/usr/bin/env node
// Exact saved-output ablation: remove redundant private Array.get/set adapters.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';
const [input,output]=process.argv.slice(2);assert(input&&output,'usage: vector-native-call.mjs NUMBER_MODULE NEW_OUTPUT');assert(!fs.existsSync(output));
const hash=s=>createHash('sha256').update(s).digest('hex'),source=fs.readFileSync(input,'utf8');
const known={'f94c6386a34156d0f48ee8e4009be7b16989001c7cca21498058298546549230':'local-pair','f78194cfab3935af50f39bd4f72a2263a20ced6c0d5519ae41b847098e1fd33c':'local-fold'};
const fixture=known[hash(source)];assert(fixture,'exact Number prototype pair/fold required');
const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'],p={exports:{}};new Function('module','exports',parserSource)(p,p.exports);assert.equal(p.exports.version,'8.16.0');
const parse=s=>p.exports.parse(s,{ecmaVersion:'latest',sourceType:'module'}),tree=parse(source),edits=[],sites=[];
function visit(n){if(!n||typeof n!=='object')return;
 if(n.type==='CallExpression'&&n.callee.type==='ArrowFunctionExpression'){
  const f=n.callee,b=f.body,native=b?.type==='CallExpression'&&b.callee.type==='Identifier'?b.callee.name:null;
  if(native==='arrayset'||native==='arrayget'){
   const params=native==='arrayset'?['_t','a','i','v']:['_t','a','i'];
   assert.deepEqual(f.params.map(x=>x.type==='Identifier'?x.name:null),params);
   assert.equal(f.async,false);assert.equal(f.expression,true);
   assert.deepEqual(b.arguments.map(x=>x.type==='Identifier'?x.name:null),params.slice(1));
   assert.equal(n.arguments.length,params.length);assert(n.arguments[0].type==='Literal'&&n.arguments[0].value===null,'erased argument must be inert null');
   edits.push([f.start,f.end,native],[n.arguments[0].start,n.arguments[1].start,'']);
   sites.push({native,start:n.start,sourceSha256:hash(source.slice(n.start,n.end)),erasedArgument:'null',argumentOrder:params.slice(1)});
  }
 }
 for(const v of Object.values(n)){if(Array.isArray(v))v.forEach(visit);else if(v&&typeof v==='object')visit(v);}
}
visit(tree);assert(sites.length>0);edits.sort((a,b)=>a[0]-b[0]);for(let i=1;i<edits.length;i++)assert(edits[i-1][1]<=edits[i][0]);
let result=source;for(const [a,b,text]of edits.reverse())result=result.slice(0,a)+text+result.slice(b);parse(result);
fs.mkdirSync(path.dirname(output),{recursive:true});fs.writeFileSync(output,result,{flag:'wx'});
const receipt={kind:'phase35-private-native-call-prototype',checked:false,fixture,input:{file:path.resolve(input),sha256:hash(source)},output:{file:path.resolve(output),sha256:hash(result)},producer:{file:import.meta.filename,sha256:hash(fs.readFileSync(import.meta.filename))},node:process.version,parserSha256:hash(parserSource),sites,
 scope:'Only exact private Array.get/set wrappers whose ignored first argument is literal null. Remaining source arguments retain byte-identical order and expressions. Runtime arrayget/arrayset, Number calls and Array.new are unchanged. Saved-output mechanism experiment, not compiler certification.'};
if(fixture==='local-pair'){
 assert.equal(result.split('export default ').length,2);const wrapper=result.replace('export default ','const $Pair_exports = ')+'\nexport default {...$Pair_exports,bench:p=>$Pair_exports.pair(p)};\n';const file=output+'.bench.mjs';fs.writeFileSync(file,wrapper,{flag:'wx'});receipt.controlWrapper={file:path.resolve(file),sha256:hash(wrapper)};
}
fs.writeFileSync(output+'.json',JSON.stringify(receipt,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({fixture,sites:sites.length,get:sites.filter(x=>x.native==='arrayget').length,set:sites.filter(x=>x.native==='arrayset').length,output,sha256:hash(result)}));

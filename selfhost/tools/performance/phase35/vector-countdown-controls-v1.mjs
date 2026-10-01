#!/usr/bin/env node
// Actual emitted counter arithmetic; bounded precision/host-hook witnesses.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [baseArg,candArg,outArg]=process.argv.slice(2),base=path.resolve(baseArg),cand=path.resolve(candArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const hash=s=>createHash('sha256').update(s).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const report={kind:'phase35-number-counter-controls',complete:false,pass:false,
 scope:'Actual emitted initializer/stop/decrement exercised for at most 32 transitions per near-maximum input; public pair/fold calls compare complete results and Number hooks. This does not run a huge countdown.',
 inputs:[import.meta.filename,base,cand].map(identity),loops:[],precision:[],hooks:[],negative:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
try {
 const source=fs.readFileSync(cand,'utf8'),parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
 const p={exports:{}};new Function('module','exports',parserSource)(p,p.exports);assert.equal(p.exports.version,'8.16.0');
 const ast=p.exports.parse(source,{ecmaVersion:'latest',sourceType:'module'}),take=n=>source.slice(n.start,n.end);
 const visit=(n,f)=>{if(!n||typeof n!=='object')return;f(n);for(const v of Object.values(n)){if(Array.isArray(v))v.forEach(x=>visit(x,f));else if(v&&typeof v==='object')visit(v,f);}};
 visit(ast,n=>{
  if(n.type!=='FunctionDeclaration'||!/^\$R(?:_\d+)+$/.test(n.id?.name||''))return;
  const nodes=[];visit(n.body,x=>nodes.push(x));
  const init=nodes.filter(x=>x.type==='VariableDeclarator'&&x.id.name==='$s0'&&x.init?.type==='BinaryExpression'&&x.init.left?.type==='CallExpression'&&['$vectorNumber','regionCounterNumber'].includes(x.init.left.callee.name));
  if(init.length===0)return;assert.equal(init.length,1);
  const stops=nodes.filter(x=>x.type==='BinaryExpression'&&x.operator==='==='&&x.left.name==='$n0'&&x.right.type==='Literal'&&x.right.value===0);
  const steps=nodes.filter(x=>x.type==='AssignmentExpression'&&x.left.name==='$s0'&&x.right.type==='BinaryExpression'&&x.right.operator==='-'&&x.right.left.name==='$n0'&&x.right.right.value===1);
  const zeros=nodes.filter(x=>x.type==='IfStatement'&&x.test.type==='BinaryExpression'&&x.test.left.name==='$p0'&&x.test.right.bigint==='0');
  assert.equal(stops.length,1);assert.equal(steps.length,1);assert.equal(zeros.length,1);assert(zeros[0].end<init[0].start);
  const capture=init[0].init.left.callee.name;
  assert(source.includes('const '+capture+'=Number;'),'module-initialization Number capture exists');
  report.loops.push({name:n.id.name,bodySha256:hash(take(n)),capture,initial:take(init[0].init),stop:take(stops[0]),step:take(steps[0].right),initialZeroPrecedesConversion:true});
 });
 assert(report.loops.length>0,'non-vacuous Number counter output');
 const OriginalNumber=Number;
 for(const row of report.loops){
  const init=new Function(row.capture,'$p0','return '+row.initial),stop=new Function('$n0','return '+row.stop),step=new Function('$n0','return '+row.step);
  for(const start of [1n,2n,3n,33n,257n,4294967295n,4294967296n,281474976710653n,281474976710654n,281474976710655n]){
   let actual=init(OriginalNumber,start),expected=start-1n,transitions=0;
   for(;transitions<32;transitions++) {assert.equal(BigInt(actual),expected);assert.equal(stop(actual),expected===0n);if(expected===0n)break;actual=step(actual);expected-=1n;}
   report.precision.push({loop:row.name,start:String(start),transitions,last:String(expected),actual});
  }
  let hookCalls=0;try{globalThis.Number=new Proxy(OriginalNumber,{apply(t,self,args){hookCalls++;return Reflect.apply(t,self,args)}});assert.equal(init(OriginalNumber,257n),256);assert.equal(hookCalls,0);Number(257n);assert.equal(hookCalls,1);}finally{globalThis.Number=OriginalNumber;}
  report.negative.push({kind:'live-global-conversion-adds-callback',capturedCalls:0,liveCalls:hookCalls});
 }
 const modules=[await import(pathToFileURL(base)),await import(pathToFileURL(cand))];
 const pair=Object.hasOwn(modules[0].G,'pair');const cases=pair?[[0],[17]]:[[0,17],[1,17],[257,17]];
 for(const args of cases)for(const mode of ['count','throw-first','getter']){
  const observations=[];
  for(const m of modules){
   let calls=0,gets=0;const trace=createHash('sha256'),descriptor=Object.getOwnPropertyDescriptor(globalThis,'Number');
   const hooked=new Proxy(OriginalNumber,{apply(t,self,a){calls++;trace.update(typeof a[0]+':'+String(a[0])+'\n');if(mode==='throw-first')throw Error('Number conversion sentinel');return Reflect.apply(t,self,a)}});
   try{
    if(mode==='getter')Object.defineProperty(globalThis,'Number',{configurable:true,get(){gets++;return hooked}});else globalThis.Number=hooked;
    let value,error;try{value=(pair?m.default.pair:m.default.bench)(...args);}catch(e){error=e.message;}
    observations.push({value,error,calls,gets,trace:trace.digest('hex')});
   }finally{Object.defineProperty(globalThis,'Number',descriptor);}
  }
  assert.deepEqual(observations[1],observations[0]);report.hooks.push({args,mode,observations});
 }
 for(const i of report.inputs)assert.deepEqual(identity(i.file),i);
 report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,loops:report.loops.length,precision:report.precision.length,hooks:report.hooks.length,error:report.error}));

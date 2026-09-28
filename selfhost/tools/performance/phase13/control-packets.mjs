// Independent convention controls, not a test of the implementer's rewriter.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';

const [attemptArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);
const attempt=await verifyAttempt(path.resolve(attemptArg));
assert.equal(attempt.api.sha256,'0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697');
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const source=fs.readFileSync(attempt.api.file,'utf8'),marker='// Program\n// =======\n';
assert.equal(source.split(marker).length,2);
const prefix=source.slice(0,source.indexOf(marker)+marker.length);
const report={kind:'phase13-explicit-capture-convention-controls',complete:false,pass:false,
  scope:'Handwritten original/candidate toy bodies under the exact released runtime. Demonstrates packet convention and required guards; does not validate an AST rewriter, B1, compiler-wide stack behavior, or performance.',
  inputs:[import.meta.filename,process.execPath,attempt.api.file,path.join(attemptArg,'attempt.json')].map(identity),rows:[],negativeWitnesses:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,(_key,value)=>value===undefined?{$controlUndefined:true}:value,2)+'\n');save();

const original=`
function $probe$(condition,effect,yes,no) {
  return run_tail(effect("condition",condition) ? ((unit)=>{effect("yes",unit.$);return yes;}) : ((unit)=>{effect("no",unit.$);return no;}), {$:"Unit"});
}
function $down$(n,acc) {
  return run_tail((n>0) ? ((unit)=>{return $down$(n-1,acc+1);}) : ((unit)=>{return acc;}), {$:"Unit"});
}
function $object$(record) {
  const jump=run_tail((unit)=>{return [record,record.value];}, {$:"Unit"});
  record.current=9;
  return jump;
}
function $nested$(x) {
  return run_tail((unit)=>{const local=(x)=>x;return (y)=>[local(y)+x,unit.$];}, {$:"Unit"});
}
function $unit$() {return run_tail((unit)=>unit, {$:"Unit"});}
function $zero$() {return run_tail((unit)=>17, {$:"Unit"});}
function $many$(a,b,c,d) {return run_tail((unit)=>[a,b,c,d,a===d], {$:"Unit"});}
function $tdz$() {const jump=run_tail((unit)=>x, {$:"Unit"});const x=17;return jump;}
function $mutated$(x) {const jump=run_tail((unit)=>x, {$:"Unit"});x=2;return jump;}
function $nestedWrite$(x) {const mutate=()=>{x=2;};const jump=run_tail((unit)=>x, {$:"Unit"});mutate();return jump;}
function $lexicalThis$() {return run_tail((unit)=>this.value, {$:"Unit"});}
function $lexicalArguments$(x) {return run_tail((unit)=>arguments[0], {$:"Unit"});}
`;

const candidate=`
function $yes$(unit,effect,yes) {effect("yes",unit.$);return yes;}
function $no$(unit,effect,no) {effect("no",unit.$);return no;}
function $probe$(condition,effect,yes,no) {
  return effect("condition",condition) ? {$:"$JMP",f:$yes$,x:[{$:"Unit"},effect,yes]} : {$:"$JMP",f:$no$,x:[{$:"Unit"},effect,no]};
}
function $downYes$(unit,n,acc) {return $down$(n-1,acc+1);}
function $downNo$(unit,acc) {return acc;}
function $down$(n,acc) {return n>0 ? {$:"$JMP",f:$downYes$,x:[{$:"Unit"},n,acc]} : {$:"$JMP",f:$downNo$,x:[{$:"Unit"},acc]};}
function $objectWorker$(unit,record) {return [record,record.value];}
function $object$(record) {const jump={$:"$JMP",f:$objectWorker$,x:[{$:"Unit"},record]};record.current=9;return jump;}
function $nestedWorker$(unit,x) {const local=(x)=>x;return (y)=>[local(y)+x,unit.$];}
function $nested$(x) {return {$:"$JMP",f:$nestedWorker$,x:[{$:"Unit"},x]};}
function $unitWorker$(unit) {return unit;}
function $unit$() {return {$:"$JMP",f:$unitWorker$,x:[{$:"Unit"}]};}
function $zeroWorker$(unit) {return 17;}
function $zero$() {return {$:"$JMP",f:$zeroWorker$,x:[{$:"Unit"}]};}
function $manyWorker$(unit,a,b,c,d) {return [a,b,c,d,a===d];}
function $many$(a,b,c,d) {return {$:"$JMP",f:$manyWorker$,x:[{$:"Unit"},a,b,c,d]};}
function $read$(unit,x) {return x;}
function $tdz$() {const jump={$:"$JMP",f:$read$,x:[{$:"Unit"},x]};const x=17;return jump;}
function $mutated$(x) {const jump={$:"$JMP",f:$read$,x:[{$:"Unit"},x]};x=2;return jump;}
function $nestedWrite$(x) {const mutate=()=>{x=2;};const jump={$:"$JMP",f:$read$,x:[{$:"Unit"},x]};mutate();return jump;}
function $thisWorker$(unit) {return this.value;}
function $lexicalThis$() {return {$:"$JMP",f:$thisWorker$,x:[{$:"Unit"}]};}
function $argumentsWorker$(unit) {return arguments[0];}
function $lexicalArguments$(x) {return {$:"$JMP",f:$argumentsWorker$,x:[{$:"Unit"}]};}
`;
const exports=`
export const api={
 probe:run_lib((condition,effect,yes,no)=>run_loop($probe$(condition,effect,yes,no)),4),
 down:(n,acc)=>run_loop($down$(n,acc)),object:record=>run_loop($object$(record)),
 nested:x=>run_loop($nested$(x)),unit:()=>run_loop($unit$()),zero:()=>run_loop($zero$()),
 many:(...args)=>run_loop($many$(...args)),tdz:()=>run_loop($tdz$()),
 mutated:x=>run_loop($mutated$(x)),nestedWrite:x=>run_loop($nestedWrite$(x)),
 lexicalThis:()=>run_loop($lexicalThis$.call({value:9})),lexicalArguments:x=>run_loop($lexicalArguments$(x))
};
`;
try {
 const modules=[];
 for(const [name,body] of [['original',original],['candidate',candidate]]){
  const file=path.join(out,name+'.mjs');fs.writeFileSync(file,prefix+body+exports);report.inputs.push(identity(file));modules.push((await import(pathToFileURL(file))).api);
 }
 const observe=fn=>{try{return {value:fn()};}catch(e){return {error:{name:e.name,message:e.message}};}};
 const same=(name,fn)=>{const results=modules.map(fn);assert.deepEqual(results[1],results[0],name);report.rows.push({name,results});save();};
 for(const condition of [false,true,0,1,'','x',null,undefined,{},[]])same('truthiness '+String(condition),api=>{const events=[];const value=api.probe(condition,(name,value)=>{events.push([name,value]);return value;},17,23);return {value,events};});
 for(const condition of [false,true])same('selected exception '+condition,api=>{const events=[];const result=observe(()=>api.probe(condition,(name,value)=>{events.push(name);if(name!=='condition')throw Error(name);return value;},17,23));return {result,events};});
 same('condition error before branches',api=>observe(()=>api.probe(true,()=>{throw Error('condition');},17,23)));
 same('partial public application',api=>api.probe(true)((_,value)=>value)(17)(23));
 same('extra public arguments',api=>api.probe(false,(_,value)=>value,17,23,'ignored'));
 same('returned function',api=>api.probe(true,(_,value)=>value,x=>x+1,x=>x+2)(40));
 same('returned raw jump is forced',api=>api.probe(true,(_,value)=>value,{$:'$JMP',f:x=>x+1,x:[40]},null));
 same('getters remain in demanded body and object aliases survive',api=>{const events=[],record={current:1,get value(){events.push('get');return this.current;}};const value=api.object(record);return {value:value[1],sameObject:value[0]===record,events};});
 same('nested shadow and escaped closure',api=>api.nested(17)(25));
 same('Unit remains fresh per dispatch',api=>{const a=api.unit(),b=api.unit();return {a,b,distinct:a!==b};});
 same('zero captures',api=>api.zero());
 same('many captures with same-object aliases',api=>{const a={value:1};return api.many(a,2,'three',a);});
 same('100000 tail steps',api=>api.down(100000,0));
 const negative=[['later const initialization','tdz',17],['mutated parameter','mutated',2],['nested captured write','nestedWrite',2],['lexical this','lexicalThis',9],['lexical arguments','lexicalArguments',7]];
 for(const [name,key,expected] of negative){const results=modules.map(api=>observe(()=>api[key](7)));assert.deepEqual(results[0],{value:expected});assert.notDeepEqual(results[1],results[0]);report.negativeWitnesses.push({name,results,requiredDisposition:'Refuse or leave original site unchanged; never lower this shape.'});save();}
 report.inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;report.inputsVerified=true;
}catch(e){report.error=e.stack;process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,positive:report.rows.length,negativeWitnesses:report.negativeWitnesses.length,error:report.error}));

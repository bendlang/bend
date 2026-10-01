// Version 2 fixes descriptor equality for NaN; version 1 is preserved unchanged.
// Uncertified saved-output experiment, not a compiler transformation.
// This producer only writes modules; root runs review, controls and timing.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const [inputArg,outArg]=process.argv.slice(2);
assert(inputArg&&outArg,'usage: sum-derive-v2.mjs FROZEN_SYMREG.mjs NEW_OUT');
const input=fs.realpathSync(inputArg),out=path.resolve(outArg);
assert(!fs.existsSync(out),'output must be new');
const hash=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({path:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const source=fs.readFileSync(input,'utf8');
assert.equal(hash(source),'551e61d6ccbeca827650038d31d93dc5866f59a11283bff9bc6a6ca59e05d875','frozen Phase33 symreg module required');
const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
const parserModule={exports:{}};new Function('module','exports',parserSource)(parserModule,parserModule.exports);
const acorn=parserModule.exports;assert.equal(acorn.version,'8.16.0');
const parse=s=>acorn.parse(s,{ecmaVersion:'latest',sourceType:'module'}),tree=parse(source);
const take=n=>source.slice(n.start,n.end);
const call=(n,name)=>n?.type==='CallExpression'&&n.callee.type==='Identifier'&&n.callee.name===name;
function walk(n,f){if(!n||typeof n!=='object')return;f(n);for(const v of Object.values(n)){
 if(Array.isArray(v))for(const x of v)walk(x,f);else if(v&&typeof v==='object')walk(v,f);
}}
const assignments=new Map();
for(const stmt of tree.body){const n=stmt.type==='ExpressionStatement'?stmt.expression:null;
 if(n?.type==='AssignmentExpression'&&n.left.type==='MemberExpression'&&n.left.object.name==='G'&&typeof n.left.property.value==='string'){
  assert(!assignments.has(n.left.property.value),'duplicate G assignment');assignments.set(n.left.property.value,n);
 }}
const assignment=assignments.get('cand');assert(assignment);
const capture=assignment.right;assert(call(capture,'scalarCapture'));assert.equal(capture.arguments[0].value,'cand');
const wrapper=capture.arguments[1];assert(call(wrapper,'fn'));assert.equal(wrapper.arguments[0].value,2);
const code=wrapper.arguments[1];assert.equal(code.type,'FunctionExpression');assert.equal(code.params.length,1);
const stmts=code.body.body;assert.equal(stmts.length,3);
const locals=stmts.slice(0,2).map((s,i)=>{assert.equal(s.type,'VariableDeclaration');assert.equal(s.declarations.length,1);
 const d=s.declarations[0];assert.equal(d.id.type,'Identifier');assert.equal(d.init.type,'MemberExpression');
 assert.equal(d.init.object.name,code.params[0].name);assert.equal(d.init.property.value,i);return d.id.name;
});assert.equal(stmts[2].type,'ReturnStatement');
const dependencies=new Set();function dependency(name){if(dependencies.has(name))return;dependencies.add(name);
 const d=assignments.get(name);assert(d,'unknown dependency '+name);
 walk(d.right,n=>{if(call(n,'get')&&n.arguments[0]?.name==='G'){assert.equal(typeof n.arguments[1]?.value,'string');dependency(n.arguments[1].value);}});
}
dependency('cand');const names=[...dependencies].sort();assert(names.length<=32);
const guard=`
// Scope: standard host intrinsics at module initialization. Reject changed
// descriptors/prototypes before any canonical-input or dependency guard call.
const $sumGet=Object.getOwnPropertyDescriptor,$sumKeys=Reflect.ownKeys,$sumProto=Object.getPrototypeOf,$sumHas=Object.hasOwn,$sumIs=Object.is;
const $sumIterator=$sumProto([][Symbol.iterator]()),$sumIteratorParent=$sumProto($sumIterator);
const $sumGlobalNames=['Object','Reflect','Math','Number','BigInt','Array','Boolean','String','Symbol'];
const $sumGlobalDescriptors=[];
for(let i=0;i<$sumGlobalNames.length;i++)$sumGlobalDescriptors[i]=$sumGet(globalThis,$sumGlobalNames[i]);
const $sumObjects=[Object,Reflect,Math,Number,BigInt,Array,Object.prototype,Array.prototype,Function.prototype,Boolean.prototype,Number.prototype,BigInt.prototype,String.prototype,$sumIterator,$sumIteratorParent];
const $sumObjectSnapshots=[];
for(let i=0;i<$sumObjects.length;i++){const obj=$sumObjects[i],keys=$sumKeys(obj),descriptors=[];
 for(let j=0;j<keys.length;j++)descriptors[j]=$sumGet(obj,keys[j]);
 $sumObjectSnapshots[i]={obj,keys,descriptors,proto:$sumProto(obj)};
}
function $sumSameDescriptor(a,b){if(!a||!b)return a===b;if(a.enumerable!==b.enumerable||a.configurable!==b.configurable)return false;
 const value=$sumHas(a,'value');return value===$sumHas(b,'value')&&(value?$sumIs(a.value,b.value)&&a.writable===b.writable:a.get===b.get&&a.set===b.set);
}
function $sumHostGuard(){
 for(let i=0;i<$sumGlobalNames.length;i++)if(!$sumSameDescriptor($sumGlobalDescriptors[i],$sumGet(globalThis,$sumGlobalNames[i])))return false;
 for(let i=0;i<$sumObjectSnapshots.length;i++){const row=$sumObjectSnapshots[i];if($sumProto(row.obj)!==row.proto)return false;
  const keys=$sumKeys(row.obj);if(keys.length!==row.keys.length)return false;
  for(let j=0;j<row.keys.length;j++)if(!$sumSameDescriptor(row.descriptors[j],$sumGet(row.obj,row.keys[j])))return false;
 }return true;
}
const $sumNames=${JSON.stringify(names)};
for(let i=0;i<$sumNames.length;i++)scalarCapture($sumNames[i],G[$sumNames[i]]);
// Retain the existing tree layout. Only a locally produced depth-five Expr is
// passed here; public eval still accepts every original generic input.
function $sumEval(e,x){switch(e.$){case 'Var':return x;case 'Lit':return e.a[0];
 case 'Add':return ($sumEval(e.a[0],x)+$sumEval(e.a[1],x))>>>0;
 case 'Sub':return ($sumEval(e.a[0],x)-$sumEval(e.a[1],x))>>>0;
 case 'Mul':return Math.imul($sumEval(e.a[0],x),$sumEval(e.a[1],x))>>>0;
 case 'Xor':return ($sumEval(e.a[0],x)^$sumEval(e.a[1],x))>>>0;
 default:throw Error('private Expr proof failed');}}
function $sumSize(e){switch(e.$){case 'Var':case 'Lit':return 1;
 case 'Add':case 'Sub':case 'Mul':case 'Xor':return (1+(($sumSize(e.a[0])+$sumSize(e.a[1]))>>>0))>>>0;
 default:throw Error('private Expr proof failed');}}
// Separate diagnostic point; the original full bench export is untouched.
export function sumCandidatePoint(count,seed,pts=16n){let sum=0;for(let i=0;i<count;i++){
 const r=call(get(G,'cand'),[(seed+i)>>>0,pts]);assertSumRecord(r);sum=(sum+r.a[0]+r.a[1]+r.a[2])>>>0;
 }return sum;}
function assertSumRecord(r){if(r?.$!=='Sel'||r.a.length!==3)throw Error('expected complete Sel');}
`;
function make(variant){
 const seed=locals[0],pts=locals[1],prefix=stmts.slice(0,2).map(take).join('');
 const fallback=take(stmts[2]);
 const evalExpr=variant==='sums'?'$sumEval($tree,$xx)':'callOwned(callOwned(get(G,"eval"),[$tree]),[$xx])';
 const sizeExpr=variant==='sums'?'$sumSize($tree)':'callOwned(get(G,"esize"),[$tree])';
 const fast=variant==='baseline'?'':`if($entered&&$sumHostGuard()&&typeof ${seed}==="number"&&Number.isInteger(${seed})&&${seed}>=0&&${seed}<=4294967295&&typeof ${pts}==="bigint"&&${pts}>=0n&&${pts}<=281474976710655n&&localGuard($sumNames)){/* private sum ${variant} prototype */
 const $tree=callOwned(callOwned(get(G,"gen"),[5n]),[callOwned(get(G,"prng"),[${seed}])]);
 let $j=${pts},$acc=0;while($j!==0n){const $p=$j-1n,$xx=Number($p&0xffffffffn);const $v=${evalExpr};
  const $target=(Math.imul($xx,$xx)+((Math.imul(3,$xx)+7)>>>0))>>>0;
  const $next=($acc+callOwned(get(G,"adiff"),[$v,$target]))>>>0;$j=$p;$acc=$next;
 }
 const $f=($acc+Math.imul(${sizeExpr},8))>>>0;
 return build("Sel",[()=>$f,()=>${seed},()=>(($f^Math.imul(${seed},2654435761))>>>0)]);
 }`;
 // All three timing variants use the same exact-entry registration wrapper.
 // The untouched original is also saved for independent ABI controls.
 const replacement=`exactCode(function(a,$entered){${prefix}${fast}${fallback}})`;
 return source.slice(0,code.start)+replacement+source.slice(code.end)+guard;
}
fs.mkdirSync(out,{recursive:false});
const report={kind:'phase35-private-sum-prototype',complete:false,checked:false,certified:false,node:process.version,
 producer:identity(import.meta.filename),parent:identity(input),parserSha256:hash(parserSource),dependencies:names,modules:[],
 scope:'Fixture-specific cand callback. Generic gen and tagged tree records retained. Original public eval unchanged. Baseline/loop/sums share exact-entry registration; original module saved separately for ABI controls. Host guard is conservative and not certified. No semantic controls or timing run by producer.'};
for(const variant of ['original','baseline','loop','sums']){const text=variant==='original'?source:make(variant);parse(text);
 const file=path.join(out,variant+'.mjs');fs.writeFileSync(file,text,{flag:'wx'});report.modules.push({variant,...identity(file),bytes:Buffer.byteLength(text)});}
assert.deepEqual(identity(input),report.parent);report.complete=true;
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-derive.mjs'));
fs.writeFileSync(path.join(out,'derive.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:true,certified:false,dependencies:names,modules:report.modules}));

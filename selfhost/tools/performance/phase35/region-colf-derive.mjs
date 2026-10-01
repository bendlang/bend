// Frozen saved-output partial-region discriminator. Not a compiler rule.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const [inputArg,outArg]=process.argv.slice(2);
assert(inputArg&&outArg,'usage: region-colf-derive.mjs FROZEN_RAYTRACE.mjs NEW_OUT');
const input=fs.realpathSync(inputArg),out=path.resolve(outArg);
assert(!fs.existsSync(out),'output must be new');
const hash=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({path:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const source=fs.readFileSync(input,'utf8');
assert.equal(hash(source),'3d1bc9a29878c1c079fdafcad3e6733037194323edc9a099efd940d811b3b367');
const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
const parserModule={exports:{}};new Function('module','exports',parserSource)(parserModule,parserModule.exports);
const acorn=parserModule.exports;assert.equal(acorn.version,'8.16.0');
const parse=s=>acorn.parse(s,{ecmaVersion:'latest',sourceType:'module'}),tree=parse(source);
const take=n=>source.slice(n.start,n.end);
const call=(n,name)=>n?.type==='CallExpression'&&n.callee.type==='Identifier'&&n.callee.name===name;
function walk(n,f){if(!n||typeof n!=='object')return;f(n);for(const v of Object.values(n)){
 if(Array.isArray(v)){for(const x of v)walk(x,f);}else if(v&&typeof v==='object')walk(v,f);
}}
const assignments=new Map();
for(const stmt of tree.body){const n=stmt.type==='ExpressionStatement'?stmt.expression:null;
 if(n?.type==='AssignmentExpression'&&n.left.type==='MemberExpression'&&n.left.object.name==='G'&&typeof n.left.property.value==='string'){
  assert(!assignments.has(n.left.property.value),'duplicate G assignment');assignments.set(n.left.property.value,n);
 }}
const dependencies=new Set(),nativeDependencies=new Set();
function dependency(name){if(dependencies.has(name))return;dependencies.add(name);const d=assignments.get(name);
 if(!d){assert.equal(name,'F32.to_u32','unreviewed native dependency');nativeDependencies.add(name);return;}
 walk(d.right,n=>{if(call(n,'get')&&n.arguments[0]?.name==='G'){
  assert.equal(typeof n.arguments[1]?.value,'string');dependency(n.arguments[1].value);}});
}
dependency('colf');const names=[...dependencies].sort();assert(names.length<=128);
const arrow=n=>{assert.equal(n.type,'ArrowFunctionExpression');assert.equal(n.params.length,0);return n.body;};
const nat=assignments.get('colf').right;
assert(call(nat,'matcher'));assert.equal(nat.arguments[0].value,'Zero');
const succ=arrow(nat.arguments[2]);assert(call(succ,'matcher1'));assert.equal(succ.arguments[0].value,'Succ');
const prefixes=[arrow(nat.arguments[1]),arrow(succ.arguments[1])];
const plans=prefixes.map((prefix,index)=>{
 assert(call(prefix,'fn'));assert.equal(prefix.arguments[0].value,5+index);
 const code=prefix.arguments[1];assert.equal(code.type,'FunctionExpression');assert.equal(code.params.length,1);
 const statements=code.body.body;assert.equal(statements.length,6+index);
 const locals=statements.slice(0,-1).map((s,i)=>{assert.equal(s.type,'VariableDeclaration');assert.equal(s.declarations.length,1);
  const d=s.declarations[0];assert.equal(d.id.type,'Identifier');assert.equal(d.init.type,'MemberExpression');
  assert.equal(d.init.object.name,code.params[0].name);assert.equal(d.init.property.value,i);return d.id.name;});
 assert.equal(statements.at(-1).type,'ReturnStatement');
 return {code,locals,prefix:statements.slice(0,-1).map(take).join(''),fallback:take(statements.at(-1)),successor:!!index};
});
const host=`
// Conservative experimental proof boundary: standard intrinsics at import.
// Check all descriptors before input validation or guards which iterate arrays.
const $colGet=Object.getOwnPropertyDescriptor,$colKeys=Reflect.ownKeys,$colProto=Object.getPrototypeOf,$colHas=Object.hasOwn,$colIs=Object.is;
const $colIterator=$colProto([][Symbol.iterator]()),$colIteratorParent=$colProto($colIterator);
const $colGlobalNames=['Object','Reflect','Math','Number','BigInt','Array','Boolean','String','Symbol'];
const $colGlobalDescriptors=[];
for(let i=0;i<$colGlobalNames.length;i++)$colGlobalDescriptors[i]=$colGet(globalThis,$colGlobalNames[i]);
const $colObjects=[Object,Reflect,Math,Number,BigInt,Array,Object.prototype,Array.prototype,Function.prototype,Boolean.prototype,Number.prototype,BigInt.prototype,String.prototype,$colIterator,$colIteratorParent];
const $colObjectSnapshots=[];
for(let i=0;i<$colObjects.length;i++){const obj=$colObjects[i],keys=$colKeys(obj),descriptors=[];
 for(let j=0;j<keys.length;j++)descriptors[j]=$colGet(obj,keys[j]);
 $colObjectSnapshots[i]={obj,keys,descriptors,proto:$colProto(obj)};
}
function $colSameDescriptor(a,b){if(!a||!b)return a===b;if(a.enumerable!==b.enumerable||a.configurable!==b.configurable)return false;
 const value=$colHas(a,'value');return value===$colHas(b,'value')&&(value?$colIs(a.value,b.value)&&a.writable===b.writable:a.get===b.get&&a.set===b.set);
}
function $colHostGuard(){
 for(let i=0;i<$colGlobalNames.length;i++)if(!$colSameDescriptor($colGlobalDescriptors[i],$colGet(globalThis,$colGlobalNames[i])))return false;
 for(let i=0;i<$colObjectSnapshots.length;i++){const row=$colObjectSnapshots[i];if($colProto(row.obj)!==row.proto)return false;
  const keys=$colKeys(row.obj);if(keys.length!==row.keys.length)return false;
  for(let j=0;j<row.keys.length;j++)if(!$colSameDescriptor(row.descriptors[j],$colGet(row.obj,row.keys[j])))return false;
 }return true;
}
const $colNames=${JSON.stringify(names)};
for(let i=0;i<$colNames.length;i++)scalarCapture($colNames[i],G[$colNames[i]]);
let $colEntries=0;
export function colfEntryCount(){return $colEntries;}
// Only this balanced traversal is direct. Active pixel calls remain generic.
// Both children keep their original evaluation order and U32 wrapping points.
function $colRun(n,x,y,w,hw,hh){if(n===0n){const xx=(Math.imul(x,2654435761)>>>0)&16383;
 return xx<w?callOwned(get(G,'pixel'),[xx,y,hw,hh]):0;}
 const p=n-1n,left=$colRun(p,x,y,w,hw,hh);
 const next=(x+(p>=32n?0:(1<<Number(p))>>>0))>>>0;
 const right=$colRun(p,next,y,w,hw,hh);return (left+right)>>>0;
}
export function colfCandidatePoint(depth,seed,width=0){return call(get(G,'colf'),[BigInt(depth),seed>>>0,0,width>>>0,40,32]);}
`;
function make(variant){let text=source;
 for(const p of [...plans].sort((a,b)=>b.code.start-a.code.start)){
  const vars=p.successor?p.locals.slice(1):p.locals,[x,y,w,hw,hh]=vars;
  const depth=p.successor?`${p.locals[0]}+1n`:'0n';
  const canonical=vars.slice(0,3).map(v=>`typeof ${v}==='number'&&Number.isInteger(${v})&&${v}>=0&&${v}<=4294967295`).join('&&')+
   vars.slice(3).map(v=>`&&typeof ${v}==='number'&&(Math.fround(${v})===${v}||Number.isNaN(${v}))`).join('');
  const bound=p.successor?`&&typeof ${p.locals[0]}==='bigint'&&${p.locals[0]}>=0n&&${p.locals[0]}<24n`:'';
  const fast=variant==='partial'?`if($entered&&$colHostGuard()&&${canonical}${bound}&&localGuard($colNames)){/* private partial colf prototype */$colEntries++;return $colRun(${depth},${x},${y},${w},${hw},${hh});}`:'';
  const replacement=`exactCode(function(a,$entered){${p.prefix}${fast}${p.fallback}})`;
  text=text.slice(0,p.code.start)+replacement+text.slice(p.code.end);
 }
 return text+host;
}
fs.mkdirSync(out,{recursive:false});
const report={kind:'phase35-private-partial-colf-prototype',complete:false,checked:false,certified:false,node:process.version,
 producer:identity(import.meta.filename),parent:identity(input),parserSha256:hash(parserSource),dependencies:names,nativeDependencies:[...nativeDependencies],modules:[],
 scope:'Frozen colf only. Public Nat and fn5/fn6 stages retained, depths 0..24, canonical scalar inputs, whole reachable graph plus conservative host guard. Pixel stays generic. Original and common-wrapper baseline are separate. No controls or timings run by producer.'};
for(const variant of ['original','baseline','partial']){const text=variant==='original'?source:make(variant);parse(text);
 const file=path.join(out,variant+'.mjs');fs.writeFileSync(file,text,{flag:'wx'});report.modules.push({variant,...identity(file),bytes:Buffer.byteLength(text)});}
assert.deepEqual(identity(input),report.parent);report.complete=true;
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-derive.mjs'));
fs.writeFileSync(path.join(out,'derive.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:true,certified:false,dependencies:names,modules:report.modules}));

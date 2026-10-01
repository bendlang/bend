// Explicit saved-output nearest.t ablation; not a compiler transformation.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const [inputArg,outArg]=process.argv.slice(2);
assert(inputArg&&outArg,'usage: branch-derive.mjs BASELINE_RAYTRACE.mjs NEW_OUT');
const input=fs.realpathSync(inputArg),out=path.resolve(outArg);
assert(!fs.existsSync(out),'output must be new');
const hash=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({path:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const source=fs.readFileSync(input,'utf8');
assert.equal(hash(source),'3d1bc9a29878c1c079fdafcad3e6733037194323edc9a099efd940d811b3b367','frozen Phase33 raytrace module required');
const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
const parserModule={exports:{}};new Function('module','exports',parserSource)(parserModule,parserModule.exports);
const acorn=parserModule.exports;assert.equal(acorn.version,'8.16.0');
const parse=s=>acorn.parse(s,{ecmaVersion:'latest',sourceType:'module'}),tree=parse(source);
const take=n=>source.slice(n.start,n.end);
const call=(n,name)=>n?.type==='CallExpression'&&n.callee.type==='Identifier'&&n.callee.name===name;
function walk(n,f){if(!n||typeof n!=='object')return;f(n);for(const v of Object.values(n)){if(Array.isArray(v))for(const x of v)walk(x,f);else if(v&&typeof v==='object')walk(v,f);}}
const assignments=new Map();
for(const stmt of tree.body){const n=stmt.type==='ExpressionStatement'?stmt.expression:null;
 if(n?.type==='AssignmentExpression'&&n.left.type==='MemberExpression'&&n.left.object.name==='G'&&typeof n.left.property.value==='string'){
  assert(!assignments.has(n.left.property.value),'duplicate G assignment');assignments.set(n.left.property.value,n);
 }}
const arrow=n=>{assert.equal(n.type,'ArrowFunctionExpression');assert.equal(n.params.length,0);return n.body;};
const assignment=assignments.get('nearest.t');assert(assignment);
const nat=assignment.right;assert(call(nat,'matcher'));assert.equal(nat.arguments[0].value,'Zero');
const succ=arrow(nat.arguments[2]);assert(call(succ,'matcher1'));assert.equal(succ.arguments[0].value,'Succ');
const prefix=arrow(succ.arguments[1]);assert(call(prefix,'fn'));assert.equal(prefix.arguments[0].value,9);
const code=prefix.arguments[1];assert.equal(code.type,'FunctionExpression');assert.equal(code.params.length,1);
const statements=code.body.body;assert.equal(statements.length,10);
const locals=statements.slice(0,9).map((s,i)=>{assert.equal(s.type,'VariableDeclaration');assert.equal(s.declarations.length,1);
 const d=s.declarations[0];assert.equal(d.id.type,'Identifier');assert.equal(d.init.type,'MemberExpression');
 assert.equal(d.init.object.name,code.params[0].name);assert.equal(d.init.property.value,i);return d.id.name;});
assert.equal(statements[9].type,'ReturnStatement');const bool=statements[9].argument;
assert(call(bool,'matcher'));assert.equal(bool.arguments[0].value,'False');
const falseArm=arrow(bool.arguments[1]),trueMatch=arrow(bool.arguments[2]);
assert(call(trueMatch,'matcher1'));assert.equal(trueMatch.arguments[0].value,'True');
const trueArm=arrow(trueMatch.arguments[1]);
assert.equal(falseArm.type,'CallExpression');assert.equal(falseArm.arguments.length,1);
const intersection=falseArm.arguments[0];assert(call(intersection,'callOwned'));assert(call(intersection.arguments[0],'get'));
assert.equal(intersection.arguments[0].arguments[1].value,'isect5');assert.equal(take(trueArm.arguments[0]),take(intersection));
const deps=new Set();function dependency(name){if(deps.has(name))return;deps.add(name);const d=assignments.get(name);assert(d,'unknown dependency '+name);
 walk(d.right,n=>{if(call(n,'get')&&n.arguments[0]?.name==='G'){assert.equal(typeof n.arguments[1]?.value,'string');dependency(n.arguments[1].value);}});}
dependency('nearest.t');const names=[...deps].sort();assert(names.length<=32);
const replacements=[];walk(intersection,n=>{if(n.type==='Identifier'&&n.name===locals[0])replacements.push(n);});
let step=take(intersection);for(const n of replacements.sort((a,b)=>b.start-a.start))step=step.slice(0,n.start-intersection.start)+'$bn'+step.slice(n.end-intersection.start);
// Only the final Boolean callback changes. Destructure once, at the old stage,
// then reject hooks before guards which themselves iterate over arrays.
const inputs=locals.slice(1).map(n=>`(typeof ${n}==="number"&&(Math.fround(${n})===${n}||Number.isNaN(${n})))`).join('&&');
const fallback=`const $fields=fields("False",$bf);return $fields===null?jump(${take(trueMatch)},[$bf]):$fields.length?jump(${take(falseArm)},$fields):${take(falseArm)};`;
const replacement=`fn(1,exactCode(function(a,$entered){const [$bf]=a;if($entered&&typeof $bf==="boolean"&&typeof ${locals[0]}==="bigint"&&${locals[0]}>=0n&&${locals[0]}<281474976710655n&&$branchIntrinsicGuard()&&${inputs}&&$branchArrayGuard()&&localGuard($branchNames)){/* private Bool loop prototype */let $bn=${locals[0]},$bpt=${locals[7]},$bbt=${locals[8]},$blt=$bf;for(;;){const $best=$blt?$bpt:$bbt;const $t=${step};if($bn===0n)return $t<$best?$t:$best;$bn=$bn-1n;$bpt=$t;$bbt=$best;$blt=$t<$best;}}${fallback}},true))`;
const guard=`
const $branchNames=${JSON.stringify(names)};
const $branchNumericHooks=[[globalThis,"Math",Math],[globalThis,"Number",Number],[Math,"fround",Math.fround],[Math,"sqrt",Math.sqrt],[Number,"isNaN",Number.isNaN],[Number,"isInteger",Number.isInteger]];
function $branchIntrinsicGuard(){for(let i=0;i<$branchNumericHooks.length;i++){const p=$branchNumericHooks[i],d=Object.getOwnPropertyDescriptor(p[0],p[1]);if(!d||!Object.hasOwn(d,"value")||d.value!==p[2])return false;}return true;}
const $branchIteratorPrototype=Object.getPrototypeOf([][Symbol.iterator]());
const $branchIteratorParent=Object.getPrototypeOf($branchIteratorPrototype);
const $branchHookPairs=[[Array.prototype,Symbol.iterator],[Array.prototype,"concat"],[Array.prototype,"slice"],[Array.prototype,"every"],[Array.prototype,"constructor"],[Array.prototype,Symbol.isConcatSpreadable],[Object.prototype,Symbol.isConcatSpreadable],[Array,Symbol.species],[$branchIteratorPrototype,"next"],[$branchIteratorPrototype,"return"],[$branchIteratorParent,"return"],[Object.prototype,"return"]];
const $branchHookDescriptors=[];
for(let i=0;i<$branchHookPairs.length;i++)$branchHookDescriptors[i]=Object.getOwnPropertyDescriptor($branchHookPairs[i][0],$branchHookPairs[i][1]);
function $branchArrayGuard(){
 if(Object.getPrototypeOf(Array.prototype)!==Object.prototype||Object.getPrototypeOf($branchIteratorPrototype)!==$branchIteratorParent||Object.getPrototypeOf($branchIteratorParent)!==Object.prototype)return false;
 for(let i=0;i<$branchHookPairs.length;i++){const p=$branchHookPairs[i],old=$branchHookDescriptors[i],d=Object.getOwnPropertyDescriptor(p[0],p[1]);
  if(!old){if(d)return false;continue;}if(!d||d.enumerable!==old.enumerable||d.configurable!==old.configurable)return false;
  const value=Object.hasOwn(old,"value");if(value!==Object.hasOwn(d,"value"))return false;
  if(value){if(d.value!==old.value||d.writable!==old.writable)return false;}else if(d.get!==old.get||d.set!==old.set)return false;
 }return true;
}
for(let i=0;i<$branchNames.length;i++)scalarCapture($branchNames[i],G[$branchNames[i]]);
const $branchBench=(count,seed)=>{let sum=0;for(let k=0;k<count;k++){const ox=((seed+k)%5)-2;const v=call(get(G,"nearest.t"),[9n,ox,0,0,0,0,1,1000000000,1000000000,false]);sum=(sum+floatBits(v))>>>0;}return sum;};
export default {...$branchOriginalExports,raytraceBench:$branchOriginalExports.bench,bench:$branchBench};
`;
const wrap=text=>{assert.equal(text.split('export default ').length,2);return text.replace('export default ','const $branchOriginalExports = ')+guard;};
fs.mkdirSync(out,{recursive:false});
const report={kind:'phase35-final-bool-loop-prototype',complete:false,checked:false,node:process.version,producer:identity(import.meta.filename),parent:identity(input),parserSha256:hash(parserSource),dependencies:names,
 scope:'Only nearest.t final successor Boolean matcher callback changes. Generic isect5/selectors and all outer public stages remain. Stable host intrinsics at module initialization are assumed. Array protocol hooks and helper mutations after import force fallback.',modules:[]};
for(const variant of ['baseline','branch']){const text=wrap(variant==='baseline'?source:source.slice(0,bool.start)+replacement+source.slice(bool.end));parse(text);
 const file=path.join(out,variant+'.mjs');fs.writeFileSync(file,text,{flag:'wx'});report.modules.push({variant,...identity(file),bytes:Buffer.byteLength(text)});}
assert.deepEqual(identity(input),report.parent);report.complete=true;
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-derive.mjs'));
fs.writeFileSync(path.join(out,'derive.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:true,dependencies:names,modules:report.modules}));

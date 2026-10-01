// Saved-output mechanism screen only. This is not a compiler or checked emission.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const [inputArg,outArg]=process.argv.slice(2);
assert.ok(inputArg&&outArg,'usage: region-selector-derive.mjs BASELINE_RAYTRACE.mjs NEW_OUT');
const input=fs.realpathSync(inputArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const hash=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({path:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const source=fs.readFileSync(input,'utf8');
assert.equal(hash(source),'3d1bc9a29878c1c079fdafcad3e6733037194323edc9a099efd940d811b3b367','Only the preserved Phase34 raytrace parent is admitted by this scene-specific mechanism producer');
const nativeSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
const acornModule={exports:{}};
new Function('exports','module',nativeSource)(acornModule.exports,acornModule);
const acorn=acornModule.exports;
assert.equal(acorn.version,'8.16.0');
const tree=acorn.parse(source,{ecmaVersion:'latest',sourceType:'module'});
const take=node=>source.slice(node.start,node.end);
const call=(node,name)=>node?.type==='CallExpression'&&node.callee.type==='Identifier'&&node.callee.name===name;
const arrow=node=>{assert.equal(node.type,'ArrowFunctionExpression');assert.equal(node.params.length,0);return node.body;};
const names=['sx','sy','sz','sr','skr'];
const rewrites=[];
for(const name of names){
 const assignments=tree.body.map(n=>n.type==='ExpressionStatement'?n.expression:null).filter(n=>n?.type==='AssignmentExpression'&&n.left.type==='MemberExpression'&&n.left.object.name==='G'&&n.left.property.value===name);
 assert.equal(assignments.length,1,'one source selector '+name);const assignment=assignments[0];
 let node=assignment.right,depth=0;const cases=[];
 assert.ok(call(node,'matcher')&&node.arguments[0].value==='Zero');
 const zero=take(arrow(node.arguments[1])),otherwise=take(arrow(node.arguments[2]));
 while(call(node,'matcher')){
  assert.equal(node.arguments.length,3);assert.equal(node.arguments[0].value,'Zero');
  cases.push(`case ${depth}n:return ${take(arrow(node.arguments[1]))};`);
  const next=arrow(node.arguments[2]);
  assert.ok(call(next,'matcher1'));assert.equal(next.arguments[0].value,'Succ');assert.equal(next.arguments.length,2);
  node=arrow(next.arguments[1]);depth++;assert.ok(depth<=64);
 }
 assert.ok(call(node,'fn'));assert.equal(node.arguments[0].value,1);
 const callback=node.arguments[1];assert.equal(callback.type,'FunctionExpression');assert.equal(callback.params.length,1);
 const statements=callback.body.body;assert.equal(statements.length,2);
 const binding=statements[0];assert.equal(binding.type,'VariableDeclaration');assert.equal(binding.declarations.length,1);
 const declaration=binding.declarations[0];assert.equal(declaration.id.type,'Identifier');
 assert.equal(declaration.init.type,'MemberExpression');assert.equal(declaration.init.object.name,callback.params[0].name);assert.equal(declaration.init.property.value,0);
 assert.equal(statements[1].type,'ReturnStatement');
 const fallback=`const $fields=fields("Zero",$n);return $fields===null?jump(${otherwise},[$n]):$fields.length?jump(${zero},$fields):${zero};`;
 const table=`switch($n){${cases.join('')}default:{const ${declaration.id.name}=$n-${depth}n;${take(statements[1])}}}`;
 const replacement=guard=>`fn(1,exactCode(function(a,$entered){const [$n]=a;if(${guard?'$entered&&':''}typeof $n==="bigint"&&$n>=0n&&$n<=281474976710655n${guard?'&&scalarGuard([])':''}){${table}}${fallback}},true))`;
 rewrites.push({name,start:assignment.right.start,end:assignment.right.end,depth,guarded:replacement(true),unprotected:replacement(false)});
}
// Existing public bench is renamed only in the screen wrapper. Original bench
// remains available as raytraceBench for an unchanged original-program control.
const suffix=`\nconst $phase35Bench=(count,seed)=>{let sum=0;const names=${JSON.stringify(names)};for(let k=0;k<count;k++){const n=BigInt((seed+k)%9);for(const name of names)sum=(sum+floatBits(call(get(G,name),[n])))>>>0;}return sum;};\nexport default {...$phase35OriginalExports,raytraceBench:$phase35OriginalExports.bench,bench:$phase35Bench};\n`;
const wrap=text=>{assert.equal(text.split('export default ').length,2);return text.replace('export default ','const $phase35OriginalExports = ')+suffix;};
const report={kind:'phase35-saved-output-nat-selectors',complete:false,producer:identity(import.meta.filename),parent:identity(input),node:process.version,parser:{version:acorn.version,sha256:hash(nativeSource)},scope:'Only five raytrace selector descriptor expressions changed. Selected leaf expressions and live fl calls remain exact source slices. The unprotected variant is an upper-bound mechanism screen, not eligible for promotion.',selectors:rewrites.map(({name,depth})=>({name,depth})),modules:[]};
for(const variant of ['baseline','guarded','unprotected']){
 let text=source;
 if(variant!=='baseline')for(const row of [...rewrites].sort((a,b)=>b.start-a.start))text=text.slice(0,row.start)+row[variant]+text.slice(row.end);
 text=wrap(text);acorn.parse(text,{ecmaVersion:'latest',sourceType:'module'});
 const file=path.join(out,variant+'.mjs');fs.writeFileSync(file,text,{flag:'wx'});report.modules.push({variant,...identity(file),bytes:Buffer.byteLength(text)});
}
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-derive.mjs'));
assert.deepEqual(identity(input),report.parent);report.complete=true;
fs.writeFileSync(path.join(out,'derive.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:true,selectors:report.selectors,modules:report.modules}));

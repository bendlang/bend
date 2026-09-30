// P30-030 immutable registration audit and two isolated runtime derivatives.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';
const [sourceArg,outArg]=process.argv.slice(2),sourceFile=fs.realpathSync(sourceArg),out=path.resolve(outArg);
const ident=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const sha=x=>createHash('sha256').update(x).digest('hex');
const root=path.resolve(import.meta.dirname,'../../../..'),design=path.join(root,'design/phase30/registration-free-exact-dispatch.md');
const receiptFile=sourceFile+'.json',receipt=JSON.parse(fs.readFileSync(receiptFile));
assert.equal(receipt.complete,true);assert.equal(receipt.observation.checked,true);assert.equal(receipt.output.sha256,ident(sourceFile).sha256);
assert.equal(path.basename(path.dirname(receipt.attempt.file)),'attempt-16');
const inputs=[import.meta.filename,design,sourceFile,receiptFile,...['attempt','input','api','runtime','base','driver'].map(k=>receipt[k].file)].map(ident);
for(const key of ['attempt','input','api','runtime','base','driver'])assert.equal(ident(receipt[key].file).sha256,receipt[key].sha256);
const source=fs.readFileSync(sourceFile,'utf8'),runtime=fs.readFileSync(receipt.runtime.file,'utf8');assert.ok(source.startsWith(runtime));
const parserName='internal/deps/acorn/acorn/dist/acorn',parserSource=process.binding('natives')[parserName],parserModule={exports:{}};
assert.equal(typeof parserSource,'string');new Function('exports','module',parserSource)(parserModule.exports,parserModule);const acorn=parserModule.exports;assert.equal(acorn.version,'8.16.0');
const ast=acorn.parse(source,{ecmaVersion:'latest',sourceType:'module'}),top=name=>{const xs=ast.body.filter(n=>n.type==='FunctionDeclaration'&&n.id.name===name);assert.equal(xs.length,1);return xs[0]};
const register=top('exactCode'),invoke=top('invokeExact');assert.ok(register.end<runtime.length&&invoke.end<runtime.length);
const registryDecl=ast.body.flatMap(n=>n.type==='VariableDeclaration'?n.declarations:[]).filter(n=>n.id.type==='Identifier'&&n.id.name==='exactCodes');assert.equal(registryDecl.length,1);
assert.equal(source.slice(registryDecl[0].start,registryDecl[0].end),'exactCodes=new WeakSet()');
const audit={registrationCalls:[],quotedRegistrationStrings:[],registryUses:[]};
const stack=[{node:ast,parent:null,key:null}];
while(stack.length){const {node:n,parent,key}=stack.pop();
 assert.notEqual(n.type,'WithStatement');
 if((n.type==='CallExpression'||n.type==='NewExpression')&&n.callee.type==='Identifier')assert.ok(!['eval','Function'].includes(n.callee.name),'Dynamic lexical execution is outside proof');
 if(n.type==='Identifier'&&n.name==='hasExactCodes')assert.fail('Flag name already bound or referenced');
 if(n.type==='Identifier'&&n.name==='exactCode'&&n!==register.id){
  assert.equal(parent?.type,'CallExpression','Registration helper escapes or is shadowed');assert.equal(key,'callee');assert.equal(parent.optional,false);
  audit.registrationCalls.push({start:parent.start,end:parent.end,line:source.slice(0,parent.start).split('\n').length});
 }
 if(n.type==='Identifier'&&n.name==='exactCodes'&&n!==registryDecl[0].id){
  assert.equal(parent?.type,'MemberExpression');assert.equal(key,'object');assert.equal(parent.computed,false);
  const owner=parent.property.name==='add'?register:parent.property.name==='has'?invoke:null;assert.ok(owner&&n.start>owner.start&&n.end<owner.end,'Unexpected private registry use');
  audit.registryUses.push({method:parent.property.name,start:n.start});
 }
 if(n.type==='Literal'&&typeof n.value==='string'&&n.value.includes('exactCode('))audit.quotedRegistrationStrings.push({start:n.start,value:n.value});
 for(const [k,v]of Object.entries(n))if(v&&typeof v.type==='string')stack.push({node:v,parent:n,key:k});else if(Array.isArray(v))for(const x of v)if(x&&typeof x.type==='string')stack.push({node:x,parent:n,key:k});
}
assert.deepEqual(audit.registryUses.map(x=>x.method).sort(),['add','has']);audit.registrationFree=audit.registrationCalls.length===0;
function edit(original,replacement){const at=source.indexOf(original);assert.ok(at>=0);assert.equal(source.indexOf(original,at+1),-1);return {start:at,end:at+original.length,original,replacement}}
const variants={flag:[edit('let exactEntry=null;','let exactEntry=null,hasExactCodes=false;'),edit('  exactCodes.add(code);','  exactCodes.add(code);\n  hasExactCodes=true;'),edit('  if(!exactCodes.has(code)||','  if(!hasExactCodes||!exactCodes.has(code)||')]};
if(audit.registrationFree)variants.direct=[{start:invoke.start,end:invoke.end,original:source.slice(invoke.start,invoke.end),replacement:'function invokeExact(f,all){const code=f.code;return code.call(f.env,all);}'}];
fs.mkdirSync(out,{recursive:false});const report={kind:'phase30-registration-dispatch-derivation',complete:false,inputs,audit,parser:{version:acorn.version,sha256:sha(parserSource),node:ident(process.execPath)},variants:{}};
fs.writeFileSync(path.join(out,'baseline.mjs'),source,{flag:'wx'});report.baseline=ident(path.join(out,'baseline.mjs'));
fs.writeFileSync(path.join(out,'baseline-runtime.mjs'),runtime,{flag:'wx'});report.baselineRuntime=ident(path.join(out,'baseline-runtime.mjs'));
for(const [name,unordered]of Object.entries(variants)){
 const edits=unordered.sort((a,b)=>a.start-b.start);assert.ok(edits.every((e,i)=>e.end<=runtime.length&&(i===0||edits[i-1].end<=e.start)));
 let changed=source;for(const e of [...edits].reverse()){assert.equal(changed.slice(e.start,e.end),e.original);changed=changed.slice(0,e.start)+e.replacement+changed.slice(e.end)}
 let shift=0;const adjusted=edits.map(e=>{const at=e.start+shift;shift+=e.replacement.length-e.original.length;return {...e,at}});let restored=changed;
 for(const e of adjusted.reverse()){assert.equal(restored.slice(e.at,e.at+e.replacement.length),e.replacement);restored=restored.slice(0,e.at)+e.original+restored.slice(e.at+e.replacement.length)}
 assert.equal(restored,source);assert.equal(changed.slice(runtime.length+shift),source.slice(runtime.length));acorn.parse(changed,{ecmaVersion:'latest',sourceType:'module'});
 const file=path.join(out,name+'.mjs'),runtimeFile=path.join(out,name+'-runtime.mjs');fs.writeFileSync(file,changed,{flag:'wx'});fs.writeFileSync(runtimeFile,changed.slice(0,runtime.length+shift),{flag:'wx'});report.variants[name]={output:ident(file),runtime:ident(runtimeFile),edits,inverseExact:true,generatedSuffixExact:true};
}
for(const [from,to]of [[import.meta.filename,'consumed-derive.mjs'],[receiptFile,'checked-emission.json'],[design,'design.md']])fs.copyFileSync(from,path.join(out,to),fs.constants.COPYFILE_EXCL);
fs.writeFileSync(path.join(out,'parser-acorn.js'),parserSource,{flag:'wx'});for(const x of inputs)assert.deepEqual(ident(x.file),x);report.complete=true;
fs.writeFileSync(path.join(out,'derive.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:true,out,registrationFree:audit.registrationFree,registrationCalls:audit.registrationCalls.length,quotedRegistrationStrings:audit.quotedRegistrationStrings.length}));

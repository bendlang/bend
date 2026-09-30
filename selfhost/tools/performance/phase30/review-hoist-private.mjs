// AST-audited sharing of exact closed private helper declarations; no program execution.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';
const [sourceArg,outArg]=process.argv.slice(2),sourceFile=fs.realpathSync(sourceArg),out=path.resolve(outArg);
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const sha=x=>createHash('sha256').update(x).digest('hex');
const parserName='internal/deps/acorn/acorn/dist/acorn',parserSource=process.binding('natives')[parserName];
assert.equal(typeof parserSource,'string');const parserModule={exports:{}};
new Function('exports','module',parserSource)(parserModule.exports,parserModule);const acorn=parserModule.exports;assert.equal(acorn.version,'8.16.0');
const root=path.resolve(import.meta.dirname,'../../../..'),design=path.join(root,'design/phase30/hoisted-private-helpers.md');
const receiptFile=sourceFile+'.json',receipt=JSON.parse(fs.readFileSync(receiptFile));assert.equal(receipt.complete,true);assert.equal(receipt.observation.checked,true);
assert.equal(receipt.output.sha256,identity(sourceFile).sha256);assert.equal(path.basename(path.dirname(receipt.attempt.file)),'attempt-12');
for(const key of ['attempt','input','api','runtime','base','driver'])assert.equal(identity(receipt[key].file).sha256,receipt[key].sha256);
fs.mkdirSync(out,{recursive:false});
const source=fs.readFileSync(sourceFile,'utf8'),ast=acorn.parse(source,{ecmaVersion:'latest',sourceType:'module'});
const privateName=name=>/^\$R(?:_\d+)+$/.test(name),functions=new Set(['FunctionDeclaration','FunctionExpression','ArrowFunctionExpression']);
function children(node){return Object.entries(node).flatMap(([key,value])=>value&&typeof value.type==='string'?[{node:value,key}]:Array.isArray(value)?value.filter(x=>x&&typeof x.type==='string').map(node=>({node,key})):[])}
function visit(node,action,parent=null,key=null,ancestors=[]){action(node,parent,key,ancestors);for(const child of children(node))visit(child.node,action,node,child.key,[...ancestors,node])}
const declarations=[];visit(ast,node=>{if(node.type==='FunctionDeclaration'&&privateName(node.id.name))declarations.push(node)});
assert.ok(declarations.length);const originals=new Map(),allNames=new Set(declarations.map(d=>d.id.name));
for(const d of declarations){assert.ok(d.params.every(p=>p.type==='Identifier'));const text=source.slice(d.start,d.end),old=originals.get(d.id.name);if(old)assert.equal(text,old.text,'Nonidentical private copies: '+d.id.name);else originals.set(d.id.name,{node:d,text});}
const allowed=new Set(['Math','Number','BigInt']);
const lookup=(scopes,name)=>scopes.some(scope=>scope.has(name));
function bind(scope,pattern){assert.equal(pattern.type,'Identifier','Unsupported binding');assert.ok(!scope.has(pattern.name),'Duplicate lexical binding '+pattern.name);scope.add(pattern.name)}
function auditFunction(fn,outer=[],free=new Set()){
 assert.ok(!fn.async&&!fn.generator);const locals=new Set();if(fn.id)locals.add(fn.id.name);
 for(const p of fn.params)bind(locals,p);
 expression(fn.body,[locals,...outer],free);return free;
}
function expression(n,scopes,free){
 if(!n)return;
 const each=xs=>{for(const x of xs)expression(x,scopes,free)};
 switch(n.type){
 case 'Identifier':
  assert.ok(!['this','arguments','eval','super'].includes(n.name));
  if(!lookup(scopes,n.name)){assert.ok(allowed.has(n.name)||allNames.has(n.name),'Unproved free identifier '+n.name);free.add(n.name)}return;
 case 'Literal':case 'EmptyStatement':case 'BreakStatement':case 'ContinueStatement':return;
 case 'BlockStatement':{
  const local=new Set();for(const s of n.body)if(s.type==='VariableDeclaration'){assert.ok(['let','const'].includes(s.kind));for(const d of s.declarations)bind(local,d.id)}
  for(const s of n.body)expression(s,[local,...scopes],free);return;
 }
 case 'VariableDeclaration':assert.ok(['let','const'].includes(n.kind));for(const d of n.declarations){assert.equal(d.id.type,'Identifier');expression(d.init,scopes,free)}return;
 case 'FunctionExpression':case 'ArrowFunctionExpression':auditFunction(n,scopes,free);return;
 case 'FunctionDeclaration':throw Error('Unexpected nested named function');
 case 'ExpressionStatement':case 'ReturnStatement':case 'ThrowStatement':expression(n.expression??n.argument,scopes,free);return;
 case 'IfStatement':each([n.test,n.consequent,n.alternate]);return;
 case 'ConditionalExpression':each([n.test,n.consequent,n.alternate]);return;
 case 'BinaryExpression':case 'LogicalExpression':case 'AssignmentExpression':each([n.left,n.right]);return;
 case 'UnaryExpression':case 'UpdateExpression':expression(n.argument,scopes,free);return;
 case 'SequenceExpression':each(n.expressions);return;
 case 'ArrayExpression':each(n.elements);return;
 case 'MemberExpression':assert.equal(n.optional,false);expression(n.object,scopes,free);if(n.computed)expression(n.property,scopes,free);return;
 case 'CallExpression':assert.equal(n.optional,false);each([n.callee,...n.arguments]);return;
 case 'ObjectExpression':for(const p of n.properties){assert.equal(p.type,'Property');assert.equal(p.kind,'init');assert.equal(p.method,false);if(p.computed)expression(p.key,scopes,free);expression(p.value,scopes,free)}return;
 case 'ForStatement':{
  const local=new Set();if(n.init?.type==='VariableDeclaration'){assert.ok(['let','const'].includes(n.init.kind));for(const d of n.init.declarations)bind(local,d.id)}
  for(const x of [n.init,n.test,n.update,n.body])expression(x,[local,...scopes],free);return;
 }
 case 'WhileStatement':case 'DoWhileStatement':each([n.test,n.body]);return;
 case 'LabeledStatement':expression(n.body,scopes,free);return;
 default:throw Error('Unreviewed helper AST '+n.type);
 }
}
const report={kind:'phase30-hoisted-private-helper-ablation',complete:false,compilerChanged:false,runtimeChanged:false,
 parser:{name:parserName,version:acorn.version,sha256:sha(parserSource),node:identity(process.execPath)},
 inputs:[import.meta.filename,design,sourceFile,receiptFile,...['attempt','input','api','runtime','base','driver'].map(k=>receipt[k].file)].map(identity),helpers:[],calls:[],edits:[]};
for(const [name,{node:d}]of originals)report.helpers.push({name,arity:d.params.length,copies:declarations.filter(x=>x.id.name===name).length,free:[...auditFunction(d)].sort()});
const declarationIds=new Set(declarations.map(d=>d.id));
visit(ast,(n,parent,key,ancestors)=>{
 if(n.type!=='Identifier'||!privateName(n.name)||declarationIds.has(n))return;
 assert.equal(parent?.type,'CallExpression','Private helper escapes: '+n.name);assert.equal(key,'callee');assert.equal(parent.optional,false);
 const target=originals.get(n.name);assert.ok(target);assert.equal(parent.arguments.length,target.node.params.length);assert.ok(parent.arguments.every(a=>a.type!=='SpreadElement'));
 const owningHelper=ancestors.find(a=>declarations.includes(a));
 if(!owningHelper){
  // Actual private entries are the original exactCode callback. Merely being
  // nested in the eagerly invoked definition IIFE would not be sufficient.
  const callback=ancestors.find(a=>a.type==='FunctionExpression'&&a.params.length===2&&a.params[0].name==='a'&&a.params[1].name==='$entered');
  assert.ok(callback,'Private call outside deferred exact callback');
 }
 report.calls.push({name:n.name,at:n.start,owner:owningHelper?.id.name??'deferred-public-entry'});
});
const first=ast.body.find(n=>n.type==='ExpressionStatement'&&n.expression.type==='AssignmentExpression'&&n.expression.left.type==='MemberExpression'&&n.expression.left.object.name==='G');
assert.ok(first);assert.ok(declarations.every(d=>d.start>first.start));
const bundle=[...originals.values()].map(x=>x.text).join('\n')+'\n';
const edits=[{start:first.start,end:first.start,original:'',replacement:bundle},...declarations.map(d=>({start:d.start,end:d.end,original:source.slice(d.start,d.end),replacement:''}))].sort((a,b)=>a.start-b.start);
assert.ok(edits.every((e,i)=>i===0||edits[i-1].end<=e.start));let changed=source;
for(const e of [...edits].reverse()){assert.equal(changed.slice(e.start,e.end),e.original);changed=changed.slice(0,e.start)+e.replacement+changed.slice(e.end)}
let offset=0;const reversed=edits.map(e=>{const at=e.start+offset;offset+=e.replacement.length-e.original.length;return {...e,at}});let restored=changed;
for(const e of reversed.reverse()){assert.equal(restored.slice(e.at,e.at+e.replacement.length),e.replacement);restored=restored.slice(0,e.at)+e.original+restored.slice(e.at+e.replacement.length)}
assert.equal(restored,source);const resultAst=acorn.parse(changed,{ecmaVersion:'latest',sourceType:'module'});
const resultNames=resultAst.body.filter(n=>n.type==='FunctionDeclaration'&&privateName(n.id.name)).map(n=>n.id.name);assert.deepEqual(resultNames,[...originals.keys()]);
for(const [name,text]of [['baseline',source],['hoisted',changed]])fs.writeFileSync(path.join(out,name+'.mjs'),text,{flag:'wx'});
for(const [from,name]of [[import.meta.filename,'consumed-derive.mjs'],[design,'plan.md'],[receiptFile,'checked-emission.json']])fs.copyFileSync(from,path.join(out,name),fs.constants.COPYFILE_EXCL);
fs.writeFileSync(path.join(out,'parser-acorn.js'),parserSource,{flag:'wx'});
report.edits=edits;report.declarations=declarations.length;report.uniqueHelpers=originals.size;report.savedBytes=Buffer.byteLength(source)-Buffer.byteLength(changed);
report.outputs=Object.fromEntries(['baseline','hoisted'].map(name=>[name,identity(path.join(out,name+'.mjs'))]));
for(const item of report.inputs)assert.deepEqual(identity(item.file),item);report.complete=true;
fs.writeFileSync(path.join(out,'derive.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:true,out,declarations:report.declarations,uniqueHelpers:report.uniqueHelpers,savedBytes:report.savedBytes}));

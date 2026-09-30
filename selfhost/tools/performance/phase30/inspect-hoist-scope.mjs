// Independent lexical/global/entry audit of the frozen helper-hoist artifacts.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const [helperArg,wholeArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
const parserModule={exports:{}};new Function('exports','module',parserSource)(parserModule.exports,parserModule);
const parser=parserModule.exports;assert.equal(parser.version,'8.16.0');
const privateName=name=>/^\$R(?:_\d+)+$/.test(name),standard=new Set(['Math','Number','BigInt']);
function children(n){return Object.entries(n).flatMap(([key,value])=>value&&typeof value.type==='string'?[{node:value,key}]:Array.isArray(value)?value.filter(x=>x&&typeof x.type==='string').map(node=>({node,key})):[])}
function walk(n,action,ancestors=[]){action(n,ancestors);for(const child of children(n))walk(child.node,action,[...ancestors,{node:n,key:child.key}])}
function names(pattern){
 if(!pattern)return [];
 if(pattern.type==='Identifier')return [pattern.name];
 if(pattern.type==='RestElement')return names(pattern.argument);
 if(pattern.type==='AssignmentPattern')return names(pattern.left);
 if(pattern.type==='ArrayPattern')return pattern.elements.flatMap(names);
 if(pattern.type==='ObjectPattern')return pattern.properties.flatMap(p=>names(p.type==='RestElement'?p.argument:p.value));
 throw Error('Unknown binding pattern '+pattern.type);
}
const report={kind:'phase30-independent-hoist-scope-audit',complete:false,pass:false,
 scope:'Static AST facts on exact acquired modules: intrinsic names are not lexically shadowed, private names do not escape, public entries use exactCode, top-level hoist declarations have no collisions. No execution or timing claim.',
 inputs:[import.meta.filename,process.execPath].map(identity),parser:{version:parser.version,sha256:createHash('sha256').update(parserSource).digest('hex')},modules:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-audit.mjs'));
try{
 for(const [kind,dirArg]of [['helper',helperArg],['whole',wholeArg]]){
  const dir=path.resolve(dirArg),receiptFile=path.join(dir,'derive.json'),receipt=JSON.parse(fs.readFileSync(receiptFile));
  assert.equal(receipt.complete,true);report.inputs.push(identity(receiptFile));
  for(const side of ['baseline','hoisted']){
   const file=path.join(dir,side+'.mjs'),source=fs.readFileSync(file,'utf8'),id=identity(file);
   assert.deepEqual(id,receipt.outputs[side]);report.inputs.push(id);
   const ast=parser.parse(source,{sourceType:'module',ecmaVersion:'latest'}),declarations=[],globalBindings=[],entries=[];
   const binding=(node,label)=>{
    for(const name of names(node)){
     assert.ok(!standard.has(name),'Shadowed standard intrinsic: '+name);
     if(privateName(name))assert.equal(label,'private-function','Private lexical alias/shadow: '+name);
    }
   };
   walk(ast,(node,ancestors)=>{
    if(node.type==='VariableDeclarator')binding(node.id,'variable');
    if(['FunctionDeclaration','FunctionExpression','ArrowFunctionExpression'].includes(node.type)){
     if(node.id)binding(node.id,node.type==='FunctionDeclaration'&&privateName(node.id.name)?'private-function':'function');
     for(const p of node.params)binding(p,'parameter');
    }
    if(node.type==='ClassDeclaration'||node.type==='ClassExpression')binding(node.id,'class');
    if(node.type==='CatchClause'&&node.param)binding(node.param,'catch');
    if(node.type==='ImportDeclaration')for(const s of node.specifiers)binding(s.local,'import');
    if(node.type==='FunctionDeclaration'&&privateName(node.id.name))declarations.push(node);
    if(node.type!=='Identifier'||!privateName(node.name))return;
    const parent=ancestors.at(-1);
    if(parent?.node.type==='FunctionDeclaration'&&parent.key==='id')return;
    assert.equal(parent?.node.type,'CallExpression');assert.equal(parent.key,'callee');
    assert.ok(!ancestors.some(x=>['ExportNamedDeclaration','ExportDefaultDeclaration'].includes(x.node.type)),'Exported helper');
    const helper=ancestors.find(x=>x.node.type==='FunctionDeclaration'&&privateName(x.node.id.name));
    if(helper)return;
    const callbackIndex=ancestors.findIndex(x=>x.node.type==='FunctionExpression'&&x.node.params.length===2&&x.node.params[0].name==='a'&&x.node.params[1].name==='$entered');
    assert.ok(callbackIndex>0,'Missing exact callback');
    const call=ancestors[callbackIndex-1].node,callback=ancestors[callbackIndex].node;
    assert.equal(call.type,'CallExpression');assert.equal(call.callee.type,'Identifier');assert.equal(call.callee.name,'exactCode');
    assert.equal(call.arguments.length,1);assert.equal(call.arguments[0],callback);assert.equal(call.optional,false);
    entries.push({helper:node.name,callAt:node.start,callbackAt:callback.start,exactCodeAt:call.start});
   });
   for(const statement of ast.body){
    const node=statement.type==='ExportNamedDeclaration'?statement.declaration:statement;
    if(!node)continue;
    if(node.type==='FunctionDeclaration'||node.type==='ClassDeclaration')globalBindings.push(node.id.name);
    if(node.type==='VariableDeclaration')for(const d of node.declarations)globalBindings.push(...names(d.id));
   }
   assert.equal(globalBindings.length,new Set(globalBindings).size,'Top-level lexical collision');
   const topPrivate=globalBindings.filter(privateName);
   if(side==='baseline')assert.equal(topPrivate.length,0);
   else assert.deepEqual([...topPrivate].sort(),receipt.helpers.map(x=>x.name).sort());
   assert.ok(entries.length);
   report.modules.push({kind,side,module:id,declarations:declarations.length,topPrivate,exactEntryUses:entries,
    intrinsicShadowBindings:0,privateEscapes:0,topLevelCollisions:0});
  }
 }
 for(const item of report.inputs)assert.deepEqual(identity(item.file),item);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,modules:report.modules.length,error:report.error}));

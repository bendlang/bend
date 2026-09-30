// Static emitted-code inventory; no module execution and no timing evidence.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import{createHash}from'node:crypto';
const [cohortArg,deriverArg,outArg]=process.argv.slice(2),cohort=path.resolve(cohortArg),deriverFile=path.resolve(deriverArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const parserModule={exports:{}};new Function('exports','module',process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'])(parserModule.exports,parserModule);const acorn=parserModule.exports;
const source=fs.readFileSync(deriverFile,'utf8'),ast=acorn.parse(source,{ecmaVersion:'latest',sourceType:'module'}),functions=ast.body.filter(n=>n.type==='FunctionDeclaration').map(n=>source.slice(n.start,n.end)).join('\n');
const helpers=new Function('acorn','assert',functions+';return {inventory,unpack,children};')(acorn,assert);
const manifest=JSON.parse(fs.readFileSync(path.join(cohort,'derive.json'))),report={kind:'phase32-local-static-inventory',complete:false,inputs:[import.meta.filename,deriverFile,path.join(cohort,'derive.json')].map(identity),cases:{}};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-inventory.mjs'));
for(const [name,entry]of Object.entries(manifest.cases)){
 report.cases[name]={};for(const [role,file]of Object.entries(entry.variants)){
  assert.deepEqual(identity(file.file),file);report.inputs.push(file);const text=fs.readFileSync(file.file,'utf8'),inv=helpers.inventory(text),counts={workers:inv.workers.length,arrowCalls:0,fieldArrowCalls:0,returnFieldArrowCalls:0,variableDeclarations:0};
  for(const w of inv.workers){function walk(node){if(node.type==='CallExpression'&&node.callee.type==='ArrowFunctionExpression'){counts.arrowCalls++;if(helpers.unpack(text,node))counts.fieldArrowCalls++}if(node.type==='ReturnStatement'&&helpers.unpack(text,node.argument))counts.returnFieldArrowCalls++;if(node.type==='VariableDeclaration')counts.variableDeclarations++;for(const c of helpers.children(node))walk(c)}walk(w.node.body)}
  report.cases[name][role]={bytes:file.bytes,...counts};
 }
}
report.complete=true;fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify(report.cases));

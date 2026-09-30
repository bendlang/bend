// AST audit of every emitted private worker, including nested zero/IIFE exits.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';
const [moduleArg,outArg,mode='strict']=process.argv.slice(2),file=path.resolve(moduleArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
assert.ok(['strict','strict-no-force','strict-direct-read'].includes(mode));
const sha=x=>createHash('sha256').update(x).digest('hex'),identity=p=>({file:fs.realpathSync(p),sha256:sha(fs.readFileSync(p)),bytes:fs.statSync(p).size});
const source=fs.readFileSync(file,'utf8');assert.ok(Buffer.byteLength(source)<=32*1024*1024);
const parserName='internal/deps/acorn/acorn/dist/acorn',parserSource=process.binding('natives')[parserName],parserModule={exports:{}};
assert.equal(typeof parserSource,'string');new Function('exports','module',parserSource)(parserModule.exports,parserModule);const acorn=parserModule.exports;assert.equal(acorn.version,'8.16.0');
const report={kind:'phase31-private-strict-result-audit',complete:false,pass:false,mode,
  scope:'Exhaustive AST inventory of private worker declarations and forbidden scheduler/descriptor calls; complements the source-level closed-grammar proof. No execution or timing.',
  inputs:[import.meta.filename,file,process.execPath].map(identity),parser:{name:parserName,version:acorn.version,sha256:sha(parserSource)},workers:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review.mjs'));fs.writeFileSync(path.join(out,'parser-acorn.js'),parserSource,{flag:'wx'});
const forbidden=new Set(['build','jump','apply','call','callOwned','fn','matcher','matcher1']);
function children(node){const xs=[];for(const [key,value]of Object.entries(node)){if(key==='start'||key==='end')continue;if(value&&typeof value==='object'){if(Array.isArray(value)){for(const item of value)if(item&&typeof item.type==='string')xs.push(item)}else if(typeof value.type==='string')xs.push(value)}}return xs}
try{
  const ast=acorn.parse(source,{ecmaVersion:'latest',sourceType:'module'}),todo=[{node:ast,owner:null}];let visited=0;
  while(todo.length){const {node,owner:prior}=todo.pop();assert.ok(++visited<=5000000,'bounded AST walk');let owner=prior;
    if(node.type==='AssignmentExpression'&&node.left.type==='MemberExpression'&&node.left.object.type==='Identifier'&&node.left.object.name==='G'&&node.left.property.type==='Literal')owner=node.left.property.value;
    if(node.type==='FunctionDeclaration'&&/^\$R(?:_\d+)+$/.test(node.id.name)){
      const calls={},bad=[],returns=[],stack=[node.body];let nodes=0;
      while(stack.length){const x=stack.pop();assert.ok(++nodes<=1000000,'bounded worker walk');
        if(x.type==='CallExpression'&&x.callee.type==='Identifier'){const name=x.callee.name;calls[name]=(calls[name]??0)+1;if(forbidden.has(name))bad.push({name,start:x.start,end:x.end})}
        if(x.type==='ReturnStatement'){returns.push({start:x.start,type:x.argument?.type??null});assert.ok(x.argument,'private return must have a value');assert.ok(!['FunctionExpression','ArrowFunctionExpression'].includes(x.argument.type),'private result cannot be a function')}
        stack.push(...children(x));
      }
      assert.equal(bad.length,0,'private scheduler/descriptor path:'+node.id.name);
      if(mode!=='strict')assert.equal(calls.force??0,0,'private force remains:'+node.id.name);
      if(mode==='strict-direct-read')assert.equal(calls.project??0,0,'private generic projection remains:'+node.id.name);
      report.workers.push({owner,name:node.id.name,decoded:node.id.name.slice(3).split('_').map(Number).map(x=>String.fromCodePoint(x)).join(''),start:node.start,end:node.end,sha256:sha(source.slice(node.start,node.end)),parameters:node.params.length,returns,calls,nodes,bad});
    }
    for(const child of children(node))todo.push({node:child,owner});
  }
  assert.ok(report.workers.length,'at least one actual private worker');report.totalNodes=visited;
  report.totals={workers:report.workers.length,returns:report.workers.reduce((n,w)=>n+w.returns.length,0),force:report.workers.reduce((n,w)=>n+(w.calls.force??0),0),project:report.workers.reduce((n,w)=>n+(w.calls.project??0),0)};
  for(const input of report.inputs)assert.deepEqual(identity(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,totals:report.totals,error:report.error}));

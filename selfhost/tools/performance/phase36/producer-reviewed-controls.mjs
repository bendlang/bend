// Independent checked-emitter supplement: complete trees, alias identity, and
// actual private-entry/refusal witnesses. Diagnostic copies only; no timing.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [baselineArg,candidateArg,typescriptArg,outArg]=process.argv.slice(2);
assert(baselineArg&&candidateArg&&typescriptArg&&outArg,
  'usage: producer-reviewed-controls.mjs BASELINE.mjs CANDIDATE.mjs TYPESCRIPT.mjs NEW_OUT');
const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({path:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const files=[baselineArg,candidateArg,typescriptArg].map(f=>fs.realpathSync(f));
const report={kind:'phase36-independent-checked-producer-controls',complete:false,pass:false,
  inputs:[import.meta.filename,...files].map(identity),trees:[],aliases:[],entries:[],boundaries:[],structure:[],
  scope:'Actual checked private helper bodies are captured/instrumented in a diagnostic copy. Direct diagnostic calls use canonical inputs only; public entry/mutation tests separately establish admission. No timing or universal equivalence claim.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const targets=[['producer_check','p.gen','gen'],['producer_parallel','p.parallel','parallel'],['producer_share','p.share','share']];
const privateName=name=>'$R'+[...name].map(c=>'_'+c.codePointAt(0)).join('');
function walk(n,f){if(!n||typeof n!=='object')return;f(n);for(const v of Object.values(n)){
  if(Array.isArray(v)){for(const x of v)walk(x,f);}else if(v&&typeof v==='object')walk(v,f);
}}
const u=x=>x>>>0,mul=(x,y)=>Math.imul(x,y)>>>0;
function model(kind,depth,seed){
  if(depth===0)return [0,kind==='gen'?(seed<40?u(seed^17):u(seed+9)):u(seed+9)];
  if(kind==='gen'){
    const left=model(kind,depth-1,u(mul(seed,3)+1)),right=model(kind,depth-1,u(mul(seed,5)+7));
    return seed%2===0?[1,left,right]:[1,right,left];
  }
  const left=model(kind,depth-1,u(seed+3)),right=model(kind,depth-1,u(seed+5));
  return [1,left,kind==='share'?left:right];
}
function children(node){
  assert(node&&typeof node==='object');
  if(node.$==='PLeaf'){
    const value=Array.isArray(node.a)?node.a[0]:node.value;
    if(Array.isArray(node.a))assert.equal(node.a.length,1);
    assert(Number.isInteger(value)&&value>=0&&value<=4294967295);return [0,value];
  }
  assert.equal(node.$,'PNode');
  if(Array.isArray(node.a)){assert.equal(node.a.length,2);return [1,node.a[0],node.a[1]];}
  return [1,node.left,node.right];
}
function canonical(node){const v=children(node);return v[0]===0?v:[1,canonical(v[1]),canonical(v[2])];}
function digest(tree){return createHash('sha256').update(JSON.stringify(tree)).digest('hex');}
function treeHash(tree){const todo=[[tree,false]],values=[];while(todo.length){const [node,after]=todo.pop();
  if(node[0]===0){values.push(node[1]);continue;}
  if(!after){todo.push([node,true],[node[2],false],[node[1],false]);continue;}
  const b=values.pop(),a=values.pop();values.push(u(mul(a,31)+b));
}assert.equal(values.length,1);return values[0];}
function aliasCount(node){const todo=[node],seen=new Set();let count=0;while(todo.length){const x=todo.pop();
  if(seen.has(x))continue;seen.add(x);const row=children(x);if(row[0]===0)continue;
  assert.equal(row[1],row[2],'shared child must preserve object identity');count++;todo.push(row[1]);
}return {internalNodes:count,uniqueObjects:seen.size};}
function outcome(action){try{return {value:action()};}catch(error){return {error:{name:error.name,message:error.message}};}}
try{
  const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
  const parserModule={exports:{}};new Function('module','exports',parserSource)(parserModule,parserModule.exports);
  const acorn=parserModule.exports;assert.equal(acorn.version,'8.16.0');
  report.parser={version:acorn.version,sha256:createHash('sha256').update(parserSource).digest('hex')};
  const source=fs.readFileSync(files[1],'utf8'),tree=acorn.parse(source,{ecmaVersion:'latest',sourceType:'module'});
  const assignments=new Map();for(const s of tree.body){const n=s.type==='ExpressionStatement'?s.expression:null;
    if(n?.type==='AssignmentExpression'&&n.left.type==='MemberExpression'&&n.left.object.name==='G'&&typeof n.left.property.value==='string')
      assignments.set(n.left.property.value,n);
  }
  const insertions=[];
  for(const [root,name]of targets){
    const assignment=assignments.get(root);assert(assignment,'public root '+root);
    const declarations=[];walk(assignment,n=>{if(n.type==='FunctionDeclaration'&&n.id.name===privateName(name))declarations.push(n);});
    assert.equal(declarations.length,1,'one private producer in '+root);const d=declarations[0];
    const text=source.slice(d.start,d.end);assert(text.includes('/* private sum producer */'),'actual compiler marker '+name);
    let selfCalls=0,loops=0;walk(d.body,n=>{
      if(n.type==='CallExpression'&&n.callee.type==='Identifier'&&n.callee.name===d.id.name)selfCalls++;
      if(['ForStatement','WhileStatement','DoWhileStatement','ForOfStatement','ForInStatement'].includes(n.type))loops++;
    });
    assert.equal(selfCalls,0,'no emitted direct recursion '+name);assert(loops>=2,'explicit traversal and unwind loops '+name);
    insertions.push({at:d.body.start+1,text:'$phase36ProducerEntries['+JSON.stringify(name)+']++;'});
    insertions.push({at:d.end,text:'$phase36ProducerWorkers['+JSON.stringify(name)+']='+d.id.name+';'});
    report.structure.push({root,name,start:d.start,end:d.end,selfCalls,loops,sourceSha256:createHash('sha256').update(text).digest('hex')});
  }
  let diagnostic=source;for(const x of insertions.sort((a,b)=>b.at-a.at))diagnostic=diagnostic.slice(0,x.at)+x.text+diagnostic.slice(x.at);
  diagnostic='const $phase36ProducerWorkers=Object.create(null),$phase36ProducerEntries=Object.create(null);'+
    targets.map(([,name])=>'$phase36ProducerEntries['+JSON.stringify(name)+']=0;').join('')+'\n'+diagnostic+
    '\nexport function reviewedProducerTree(name,depth,seed){return $phase36ProducerWorkers[name](depth,seed);}\n'+
    'export function reviewedProducerEntries(name){return $phase36ProducerEntries[name];}\n';
  acorn.parse(diagnostic,{ecmaVersion:'latest',sourceType:'module'});
  const diagnosticFile=path.join(out,'candidate-diagnostic.mjs');fs.writeFileSync(diagnosticFile,diagnostic,{flag:'wx'});
  report.diagnostic={parent:identity(files[1]),output:identity(diagnosticFile),changes:'Counters at actual private entries, capture immediately after declarations, diagnostic-only globals and exports.'};
  const modules=[];for(const file of [files[0],diagnosticFile,files[2]])modules.push(await import(pathToFileURL(file)));
  const [baseline,candidate,typescript]=modules;
  for(const [root,name,kind]of targets){
    for(const depth of [0,1,2,5,8])for(const seed of [0,1,39,40,42,2147483648,4294967295]){
      const expected=model(kind,depth,seed),values=[baseline.default[name](BigInt(depth),seed),
        candidate.reviewedProducerTree(name,BigInt(depth),seed),typescript.default[name](depth,seed)];
      const expectedHash=digest(expected);for(const value of values)assert.deepEqual(canonical(value),expected,root+': complete tree');
      report.trees.push({root,name,kind,depth,seed,nodes:2**(depth+1)-1,sha256:expectedHash,roles:['baseline-public','candidate-private','typescript-public']});
      if(kind==='share'){
        const observations=values.map(aliasCount);for(const row of observations){assert.equal(row.internalNodes,depth);assert.equal(row.uniqueObjects,depth+1);}
        report.aliases.push({depth,seed,observations});
      }
    }
    // Depth twelve means 8,191 logical nodes, not an exponential OOM witness.
    const depth=12,seed=42,expected=model(kind,depth,seed),values=[baseline.default[name](BigInt(depth),seed),
      candidate.reviewedProducerTree(name,BigInt(depth),seed),typescript.default[name](depth,seed)];
    for(const value of values)assert.deepEqual(canonical(value),expected,root+': depth twelve');
    report.trees.push({root,name,kind,depth,seed,nodes:8191,sha256:digest(expected),roles:['baseline-public','candidate-private','typescript-public']});
    if(kind==='share')report.aliases.push({depth,seed,observations:values.map(aliasCount)});
    for(const [depth,seed]of [[0,42],[1,39],[4,4294967295]]){
      const expected=treeHash(model(kind,depth,seed)),before=candidate.reviewedProducerEntries(name);
      const results=[baseline.default[root](BigInt(depth),seed),candidate.default[root](BigInt(depth),seed),typescript.default[root](depth,seed)];
      for(const value of results)assert.equal(value,expected);const after=candidate.reviewedProducerEntries(name);
      assert.equal(after,before+1,root+': actual public fast entry');report.entries.push({root,name,depth,seed,expected,results,before,after});
    }
    for(const dependency of [name,'p.leaf','p.choose'])for(const mode of ['wrapper','code-getter','binding-getter']){
      function observe(m){const globalDescriptor=Object.getOwnPropertyDescriptor(m.G,dependency),f=globalDescriptor.value;
        const codeDescriptor=Object.getOwnPropertyDescriptor(f,'code'),code=codeDescriptor.value,events=[];
        const before=m===candidate?m.reviewedProducerEntries(name):null;
        try{
          if(mode==='wrapper')f.code=function(a){events.push('call:'+dependency);return Reflect.apply(code,this,[a]);};
          else if(mode==='code-getter')Object.defineProperty(f,'code',{configurable:true,get(){events.push('code:'+dependency);return code;}});
          else Object.defineProperty(m.G,dependency,{configurable:true,get(){events.push('get:'+dependency);return f;}});
          const result=outcome(()=>m.default[root](2n,42));
          assert(events.length>0,dependency+': active mutation witness');
          if(m===candidate)assert.equal(m.reviewedProducerEntries(name),before,'changed dependency refuses private producer');
          return {result,events};
        }finally{Object.defineProperty(f,'code',codeDescriptor);Object.defineProperty(m.G,dependency,globalDescriptor);}
      }
      const expected=observe(baseline),actual=observe(candidate);assert.deepEqual(actual,expected,root+': '+dependency+'/'+mode);
      report.boundaries.push({root,name,dependency,mode,expected,actual});
    }
  }
  for(const row of report.inputs)assert.deepEqual(identity(row.path),row);
  report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,trees:report.trees.length,aliases:report.aliases.length,
  entries:report.entries.length,boundaries:report.boundaries.length,error:report.error}));

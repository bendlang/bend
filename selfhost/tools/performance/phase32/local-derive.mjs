// Saved checked07 output experiments; production source and public ABI unchanged.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';

const root=path.resolve(import.meta.dirname,'../../../..');
const prior=path.join(root,'selfhost/build/phase31');
const out=path.resolve(process.argv[2]);fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex');
const identity=p=>({file:fs.realpathSync(p),sha256:sha(fs.readFileSync(p)),bytes:fs.statSync(p).size});
const save=(p,x)=>fs.writeFileSync(p,JSON.stringify(x,null,2)+'\n',{flag:'wx'});
const parserName='internal/deps/acorn/acorn/dist/acorn',parserSource=process.binding('natives')[parserName],parserModule={exports:{}};
new Function('exports','module',parserSource)(parserModule.exports,parserModule);
const acorn=parserModule.exports;assert.equal(acorn.version,'8.16.0');
const design=path.join(root,'design/phase32/local-generated-ladder.md');
const report={kind:'phase32-local-saved-output-derivation',complete:false,pass:false,
 inputs:[import.meta.filename,design,process.execPath].map(identity),
 parser:{name:parserName,version:acorn.version,sha256:sha(parserSource)},cases:{}};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-derive.mjs'));
fs.copyFileSync(design,path.join(out,'design.md'));
fs.writeFileSync(path.join(out,'parser-acorn.js'),parserSource,{flag:'wx'});

function children(node){const xs=[];for(const value of Object.values(node)){if(value&&typeof value==='object'){if(Array.isArray(value)){for(const item of value)if(item?.type)xs.push(item)}else if(value.type)xs.push(value)}}return xs}
function inventory(source){
 const ast=acorn.parse(source,{ecmaVersion:'latest',sourceType:'module'}),workers=[],calls=[];
 function walk(node,owner=null,worker=null){
  if(node.type==='AssignmentExpression'&&node.left.type==='MemberExpression'&&node.left.object.name==='G'&&node.left.property.type==='Literal')owner=node.left.property.value;
  if(node.type==='FunctionDeclaration'&&/^(\$R(?:_\d+)+|\$L32C_.+)$/.test(node.id.name)){worker={owner,node};workers.push(worker)}
  if(node.type==='CallExpression')calls.push({owner,worker,node});
  for(const child of children(node))walk(child,owner,worker);
 }
 walk(ast);return {ast,workers,calls};
}
function applyEdits(source,edits){
 edits.sort((a,b)=>a.start-b.start||a.end-b.end);
 let cursor=0,result='',inverse=[];
 for(const e of edits){assert.ok(e.start>=cursor,'overlapping edits');assert.equal(source.slice(e.start,e.end),e.before);
  result+=source.slice(cursor,e.start);const at=result.length;result+=e.after;
  inverse.push({start:at,end:result.length,before:e.after,after:e.before,kind:e.kind});cursor=e.end;
 }
 result+=source.slice(cursor);let undo=result;
 for(const e of [...inverse].reverse()){assert.equal(undo.slice(e.start,e.end),e.before);undo=undo.slice(0,e.start)+e.after+undo.slice(e.end)}
 assert.equal(undo,source);acorn.parse(result,{ecmaVersion:'latest',sourceType:'module'});
 return {source:result,edits,inverse,exactInverse:true};
}
function unpack(source,node){
 if(node?.type!=='CallExpression'||node.callee.type!=='ArrowFunctionExpression'||node.callee.body.type==='BlockStatement')return null;
 const arrow=node.callee;if(!arrow.params.length||arrow.params.length!==node.arguments.length||!arrow.params.every(p=>p.type==='Identifier'))return null;
 let vector=null;
 for(let i=0;i<node.arguments.length;i++){
  const a=node.arguments[i];if(a.type!=='MemberExpression'||!a.computed||a.property.type!=='Literal'||a.property.value!==i)return null;
  const v=a.object;if(!(v.type==='Identifier'||(v.type==='MemberExpression'&&!v.computed&&v.object.type==='Identifier'&&v.property.name==='a')))return null;
  const text=source.slice(v.start,v.end);if(vector!==null&&text!==vector)return null;vector=text;
 }
 return {arrow,vector,params:arrow.params.map(p=>p.name),body:source.slice(arrow.body.start,arrow.body.end)};
}
function statements(source){
 const edits=[],selected=[];let serial=0;
 for(const w of inventory(source).workers){
  function visit(node){
   if(node.type==='ReturnStatement'){
    const u=unpack(source,node.argument);
    if(u){const fresh='$L32_s'+serial++;assert.ok(!source.includes(fresh));
     const bindings=u.params.map((p,i)=>'const '+p+'='+fresh+'['+i+'];').join('');
     const after='{const '+fresh+'='+u.vector+';{'+bindings+'return '+u.body+';}}';
     edits.push({start:node.start,end:node.end,before:source.slice(node.start,node.end),after,kind:'return-field-statements'});
     selected.push({owner:w.owner,worker:w.node.id.name,params:u.params,vector:u.vector});return;
    }
   }
   for(const child of children(node))visit(child);
  }
  visit(w.node.body);
 }
 assert.ok(edits.length,'at least one return unpack opportunity');
 return {...applyEdits(source,edits),selected};
}
function nativeGet(node){
 if(node?.type!=='CallExpression'||node.callee.type!=='ArrowFunctionExpression'||node.arguments.length!==3)return null;
 const a=node.callee;if(a.params.length!==3||!a.params.every(p=>p.type==='Identifier'))return null;
 const body=a.body;if(body.type!=='CallExpression'||body.callee.name!=='arrayget'||body.arguments.length!==2)return null;
 if(body.arguments[0].name!==a.params[1].name||body.arguments[1].name!==a.params[2].name)return null;
 if(node.arguments[0].type!=='Literal'||node.arguments[0].value!==null)return null;
 return {handle:node.arguments[1],index:node.arguments[2]};
}
function fusion(source){
 assert.ok(!source.includes('$L32'),'fresh generated namespace');
 const inv=inventory(source),consumers=new Map(),edits=[],selected=[];
 for(const w of inv.workers){
  const f=w.node;if(!f.params.length||!f.params.every(p=>p.type==='Identifier')||f.body.body.length!==1||f.body.body[0].type!=='ReturnStatement')continue;
  const u=unpack(source,f.body.body[0].argument),last=f.params.at(-1).name;
  if(!u||u.vector!==last||u.params.length!==2)continue;
  let refs=0;function count(node){if(node.type==='Identifier'&&node.name===last)refs++;for(const c of children(node))count(c)}count(f.body);
  if(refs!==2)continue;
  const prefix=f.params.slice(0,-1).map(p=>p.name);assert.ok(u.params.every(p=>!prefix.includes(p)));
  consumers.set(w.owner+'\0'+f.id.name,{...w,u,prefix,clone:'$L32C_'+f.id.name.slice(3),bridge:'$L32B_'+f.id.name.slice(3),sites:[]});
 }
 for(const c of inv.calls){
  const n=c.node;if(n.callee.type!=='Identifier')continue;
  const target=consumers.get(c.owner+'\0'+n.callee.name);if(!target||n.arguments.length!==target.node.params.length)continue;
  const get=nativeGet(n.arguments.at(-1));if(!get)continue;
  const args=n.arguments.slice(0,-1).concat([get.handle,get.index]).map(a=>source.slice(a.start,a.end));
  edits.push({start:n.start,end:n.end,before:source.slice(n.start,n.end),after:target.bridge+'('+args.join(',')+')',kind:'get-consumer-call'});
  target.sites.push({start:n.start,owner:c.owner,worker:c.worker?.node.id.name??null});
 }
 for(const c of consumers.values())if(c.sites.length){
  const f=c.node,args=c.prefix.concat(c.u.params),bridgeArgs=c.prefix.concat(['$L32_h','$L32_i']);
  const clone='function '+c.clone+'('+args.join(',')+'){return '+c.u.body+';}';
  const bridge='function '+c.bridge+'('+bridgeArgs.join(',')+'){return '+c.clone+'('+c.prefix.concat(['$L32_h','$L32_read($L32_h,$L32_i)']).join(',')+');}';
  edits.push({start:f.start,end:f.start,before:'',after:clone+bridge,kind:'private-consumer-clone'});
  selected.push({owner:c.owner,consumer:f.id.name,clone:c.clone,bridge:c.bridge,sites:c.sites});
 }
 assert.ok(selected.length,'at least one canonical producer/consumer opportunity');
 edits.push({start:source.length,end:source.length,before:'',after:'\nfunction $L32_read(a,i){const xs=arraydata(a);return xs[Number(i)%xs.length]}\n',kind:'scalar-read-helper'});
 return {...applyEdits(source,edits),selected};
}

try{
 const sources={pair:{baseline:path.join(prior,'local-data-pair-actual07-01/actual.mjs'),typescript:path.join(prior,'local-data-pair-02/typescript.mjs'),receipt:path.join(prior,'local-data-actual07-source-01/candidate.mjs.json')},
  fold:{baseline:path.join(prior,'local-data-actual07-source-01/fold.mjs'),typescript:path.join(prior,'local-data-fold-source-02/upstream.mjs'),receipt:path.join(prior,'local-data-actual07-source-01/fold.mjs.json')}};
 for(const [name,input] of Object.entries(sources)){
  const receipt=JSON.parse(fs.readFileSync(input.receipt));assert.ok(receipt.complete&&receipt.observation.checked);
  const original=path.join(prior,'local-data-actual07-source-01',name==='pair'?'candidate.mjs':'fold.mjs');assert.equal(identity(original).sha256,receipt.output.sha256);
  if(name==='pair'){
   const cohort=path.join(prior,'local-data-pair-actual07-01/derive.json'),d=JSON.parse(fs.readFileSync(cohort));assert.deepEqual(identity(input.baseline),d.variants.actual);report.inputs.push(identity(cohort));
  }
  report.inputs.push(...[input.baseline,input.typescript,input.receipt,original].map(identity));
  const dir=path.join(out,name);fs.mkdirSync(dir);
  const base=fs.readFileSync(input.baseline,'utf8'),s=statements(base),f=fusion(base),both=statements(f.source);
  const variants={baseline:base,statements:s.source,fusion:f.source,combined:both.source,typescript:fs.readFileSync(input.typescript,'utf8')},ids={};
  for(const [variant,text] of Object.entries(variants)){const file=path.join(dir,variant+'.mjs');fs.writeFileSync(file,text,{flag:'wx'});ids[variant]=identity(file)}
  save(path.join(dir,'derive.json'),{complete:true,variants:ids});
  if(name==='pair')fs.copyFileSync(path.join(prior,'local-data-pair-02/points.json'),path.join(dir,'points.json'));
  report.cases[name]={inputs:input,variants:ids,statements:{...s,source:undefined},fusion:{...f,source:undefined},combined:{...both,source:undefined}};
 }
 for(const i of report.inputs)assert.deepEqual(identity(i.file),i);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
save(path.join(out,'derive.json'),report);
console.log(JSON.stringify({complete:report.complete,pass:report.pass,cases:Object.fromEntries(Object.entries(report.cases).map(([k,v])=>[k,{statements:v.statements.selected.length,fusedConsumers:v.fusion.selected.length,fusedSites:v.fusion.selected.reduce((a,x)=>a+x.sites.length,0),combinedStatements:v.combined.selected.length,bytes:Object.fromEntries(Object.entries(v.variants).map(([n,i])=>[n,i.bytes]))}])),error:report.error}));

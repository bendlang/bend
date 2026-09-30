// Disposable generated-JS experiment. Never imported by the compiler/runtime.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';

const parserName='internal/deps/acorn/acorn/dist/acorn';
const parserSource=process.binding('natives')[parserName],parserModule={exports:{}};
assert.equal(typeof parserSource,'string');
new Function('exports','module',parserSource)(parserModule.exports,parserModule);
const acorn=parserModule.exports;
assert.equal(acorn.version,'8.16.0');
const parse=source=>acorn.parse(source,{ecmaVersion:'latest',sourceType:'module'});
const sha=value=>createHash('sha256').update(value).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file)),bytes:fs.statSync(file).size});
const children=node=>Object.values(node).flatMap(value=>value&&typeof value.type==='string'?[value]:Array.isArray(value)?value.filter(x=>x&&typeof x.type==='string'):[]);
function visit(node,action){action(node);for(const child of children(node))visit(child,action)}
const namedParameter=p=>p.type==='Identifier'&&/^x\d+$/.test(p.name);

function tailLet(node){
  if(node?.type!=='CallExpression'||node.optional||node.callee.type!=='ArrowFunctionExpression')return false;
  const fn=node.callee;
  if(fn.async||fn.generator||!fn.expression||fn.body.type==='BlockStatement'||!fn.params.length)return false;
  if(!fn.params.every(namedParameter)||new Set(fn.params.map(p=>p.name)).size!==fn.params.length)return false;
  if(fn.params.length!==node.arguments.length||node.arguments.some(a=>a.type==='SpreadElement'))return false;
  // Bend bindings are immutable. Refuse even a conservatively shadowed write;
  // substituting const for a mutable JavaScript parameter would be unsound.
  const names=new Set(fn.params.map(p=>p.name));let writes=false;
  const containsName=pattern=>{let found=false;visit(pattern,n=>{if(n.type==='Identifier'&&names.has(n.name))found=true});return found};
  visit(fn.body,n=>{
    if(n.type==='AssignmentExpression'&&containsName(n.left))writes=true;
    if(n.type==='UpdateExpression'&&containsName(n.argument))writes=true;
    if((n.type==='ForInStatement'||n.type==='ForOfStatement')&&containsName(n.left))writes=true;
  });
  return !writes;
}

export function derive(source,prefix=''){
  assert.ok(source.startsWith(prefix),'Runtime prefix differs');
  assert.ok(Buffer.byteLength(source)<4*1024*1024,'Experiment source bound');
  let current=source,serial=0,total=0;const rounds=[];
  const names=new Set();visit(parse(source),n=>{if(n.type==='Identifier')names.add(n.name)});
  const fresh=()=>{let name;do{name='$tailLet'+serial++}while(names.has(name));names.add(name);return name};
  for(let round=0;round<32;round++){
    const ast=parse(current),candidates=[];
    visit(ast,n=>{
      if(n.start<prefix.length)return;
      assert.notEqual(n.type,'WithStatement','Dynamic scope is not admitted');
      assert.ok(!(n.type==='CallExpression'&&n.callee.type==='Identifier'&&n.callee.name==='eval'),'Direct eval is not admitted');
      if(n.type==='ReturnStatement'&&tailLet(n.argument))candidates.push(n);
    });
    if(!candidates.length)break;
    assert.ok(round<31,'Rewrite round bound');
    // A nested function may itself return a Let. Change its innermost return
    // first, then reparse before considering the enclosing source slice.
    const selected=candidates.filter(n=>!candidates.some(m=>m!==n&&m.start>n.start&&m.end<=n.end)).sort((a,b)=>a.start-b.start);
    const lower=node=>{
      if(!tailLet(node))return 'return ('+current.slice(node.start,node.end)+');';
      const fn=node.callee,temps=fn.params.map(fresh);total++;assert.ok(total<=4096,'Rewrite count bound');
      const values=node.arguments.map((arg,i)=>'const '+temps[i]+'=(0,('+current.slice(arg.start,arg.end)+'));').join('');
      const bindings=fn.params.map((param,i)=>'const '+param.name+'='+temps[i]+';').join('');
      return '{'+values+'{'+bindings+lower(fn.body)+'}}';
    };
    const edits=selected.map(n=>({start:n.start,end:n.end,original:current.slice(n.start,n.end),replacement:lower(n.argument)}));
    assert.ok(edits.every((e,i)=>!i||edits[i-1].end<=e.start));
    const before=sha(current);let delta=0;
    for(const e of edits){e.resultStart=e.start+delta;delta+=e.replacement.length-e.original.length}
    for(const e of [...edits].reverse())current=current.slice(0,e.start)+e.replacement+current.slice(e.end);
    assert.ok(current.startsWith(prefix));parse(current);
    rounds.push({before,after:sha(current),edits});
  }
  let restored=current;
  for(const round of [...rounds].reverse()){
    assert.equal(sha(restored),round.after);
    for(const e of [...round.edits].reverse()){
      assert.equal(restored.slice(e.resultStart,e.resultStart+e.replacement.length),e.replacement);
      restored=restored.slice(0,e.resultStart)+e.original+restored.slice(e.resultStart+e.replacement.length);
    }
    assert.equal(sha(restored),round.before);
  }
  assert.equal(restored,source);
  return {source:current,evidence:{rounds,tailLets:total,returns:rounds.reduce((n,r)=>n+r.edits.length,0),reconstructedOriginal:true,runtimePrefixBytes:Buffer.byteLength(prefix),runtimePrefixSha256:sha(prefix)}};
}

if(process.argv[1]&&pathToFileURL(path.resolve(process.argv[1])).href===import.meta.url){
  const [sourceArg,outArg]=process.argv.slice(2),sourceFile=fs.realpathSync(sourceArg),out=path.resolve(outArg);
  const receiptFile=sourceFile+'.json',receipt=JSON.parse(fs.readFileSync(receiptFile));
  assert.equal(receipt.complete,true);assert.equal(receipt.observation.checked,true);
  assert.equal(path.basename(path.dirname(receipt.attempt.file)),'attempt-13');
  assert.equal(identity(sourceFile).sha256,receipt.output.sha256);
  for(const k of ['attempt','input','api','runtime','base','driver'])assert.equal(identity(receipt[k].file).sha256,receipt[k].sha256);
  const root=path.resolve(import.meta.dirname,'../../../..'),design=path.join(root,'design/phase30/general-tail-let-statements.md');
  const supplement=path.join(root,'design/phase30/general-tail-let-independent-controls.md');
  const inputs=[import.meta.filename,design,supplement,sourceFile,receiptFile,...['attempt','input','api','runtime','base','driver'].map(k=>receipt[k].file)].map(identity);
  const source=fs.readFileSync(sourceFile,'utf8'),prefix=fs.readFileSync(receipt.runtime.file,'utf8');
  fs.mkdirSync(out,{recursive:false});
  const report={kind:'phase30-general-tail-let-ablation',complete:false,compilerChanged:false,runtimeChanged:false,inputs,
    parser:{name:parserName,version:acorn.version,sha256:sha(parserSource),node:identity(process.execPath)}};
  try{
    const result=derive(source,prefix);Object.assign(report,result.evidence);assert.ok(report.tailLets>0);
    for(const [name,text]of [['baseline',source],['candidate',result.source]])fs.writeFileSync(path.join(out,name+'.mjs'),text,{flag:'wx'});
    fs.writeFileSync(path.join(out,'parser-acorn.js'),parserSource,{flag:'wx'});
    for(const [file,name]of [[import.meta.filename,'consumed-derive.mjs'],[design,'plan.md'],[supplement,'independent-plan.md'],[receiptFile,'checked-emission.json']])fs.copyFileSync(file,path.join(out,name),fs.constants.COPYFILE_EXCL);
    report.outputs=Object.fromEntries(['baseline','candidate'].map(k=>[k,identity(path.join(out,k+'.mjs'))]));
    for(const input of inputs)assert.deepEqual(identity(input.file),input);
    report.complete=true;
  }catch(error){report.error=error.stack;process.exitCode=1}
  fs.writeFileSync(path.join(out,'derive.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
  console.log(JSON.stringify({complete:report.complete,out,tailLets:report.tailLets,returns:report.returns,rounds:report.rounds?.length}));
}

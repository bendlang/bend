// Supplemental actual-emission controls; root alone executes under bounded runner.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [baseArg,candidateArg,tsArg,outArg]=process.argv.slice(2);
assert(baseArg&&candidateArg&&tsArg&&outArg,'usage: producer-selector-controls.mjs BASELINE.mjs CANDIDATE.mjs TYPESCRIPT.mjs NEW_OUT');
const files=[baseArg,candidateArg,tsArg].map(x=>fs.realpathSync(x)),out=path.resolve(outArg);assert(!fs.existsSync(out));fs.mkdirSync(out,{recursive:false});
const identity=p=>({path:fs.realpathSync(p),sha256:createHash('sha256').update(fs.readFileSync(p)).digest('hex')});
const report={kind:'phase36-producer-selector-controls',complete:false,pass:false,inputs:[import.meta.filename,...files].map(identity),oracle:[],admission:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
const parserModule={exports:{}};new Function('module','exports',parserSource)(parserModule,parserModule.exports);
assert.equal(parserModule.exports.version,'8.16.0');const parse=s=>parserModule.exports.parse(s,{ecmaVersion:'latest',sourceType:'module'});
const privateName=n=>'$R'+[...n].map(c=>'_'+c.charCodeAt(0)).join('');
const u=x=>x>>>0,mul=(a,b)=>Math.imul(a,b)>>>0;
function leaf(seed){const c=seed%3;if(c===0)return [0,seed===0?u(seed^17):u(seed+9)];const s=u(seed+c-1);return [0,seed<40?u(s+9):u(s^17)];}
function node(code,l,r,s){return code===0?(s<40?[1,r,l]:[1,l,r]):code===1?[1,r,l]:code===2?[1,l,l]:[0,u(s+code-3)];}
function model(d,s,refused=false){if(d===0)return refused?[0,u(s+1)]:leaf(s);const l=model(d-1,refused?u(s+1):u(mul(s,3)+1),refused),r=model(d-1,refused?u(s+3):u(mul(s,5)+7),refused);return node(s%6,l,r,s);}
function hashTree(t){const todo=[[t,false]],stack=[];while(todo.length){const [n,done]=todo.pop();if(n[0]===0){stack.push(n[1]);continue;}if(!done){todo.push([n,true],[n[2],false],[n[1],false]);continue;}const b=stack.pop(),a=stack.pop();stack.push(u(mul(a,31)+b));}assert.equal(stack.length,1);return stack[0];}
function canonical(t){assert(t&&typeof t==='object');if(t.$==='SelectLeaf'){if(Array.isArray(t.a)){assert.equal(t.a.length,1);return [0,t.a[0]];}return [0,t.value];}assert.equal(t.$,'SelectNode');if(Array.isArray(t.a)){assert.equal(t.a.length,2);return [1,canonical(t.a[0]),canonical(t.a[1])];}return [1,canonical(t.left),canonical(t.right)];}
function assignment(tree,name){const rows=tree.body.filter(s=>s.type==='ExpressionStatement'&&s.expression.type==='AssignmentExpression'&&s.expression.left.type==='MemberExpression'&&s.expression.left.object.name==='G'&&s.expression.left.property.value===name);assert.equal(rows.length,1,name);return rows[0];}
try{
 const text=fs.readFileSync(files[1],'utf8'),tree=parse(text),stmt=assignment(tree,'selector_check'),capture=stmt.expression.right;
 assert.equal(capture.callee.name,'scalarCapture');const iife=capture.arguments[1];assert.equal(iife.type,'CallExpression');assert.equal(iife.callee.body.type,'BlockStatement');
 const body=iife.callee.body.body,functions=new Map(body.filter(x=>x.type==='FunctionDeclaration').map(x=>[x.id.name,x]));
 const expected=['s.gen','s.node','s.last','s.bool_first','s.bool_last','s.bool_children'];
 for(const name of expected){const d=functions.get(privateName(name));assert(d,'direct selector helper '+name);const source=text.slice(d.start,d.end);assert(!source.includes('callOwned('),'no generic selector dispatch in '+name);report.admission.push({name,direct:true,bytes:source.length,sha256:createHash('sha256').update(source).digest('hex')});}
 const gen=functions.get(privateName('s.gen'));assert(text.slice(gen.start,gen.end).includes('/* private sum producer */'));
 const finish=body.at(-1);assert.equal(finish.type,'ReturnStatement');
 const insertions=[
  {at:stmt.start,text:'let $selectorEntries=0,$selectorCapture,$selectorGuard;\n'},
  {at:gen.body.start+1,text:'++$selectorEntries;'},
  {at:finish.start,text:`$selectorCapture=${privateName('s.gen')};$selectorGuard=()=>regionHostGuard()&&localGuard($guards);`},
 ];
 let diagnostic=text;for(const e of insertions.sort((a,b)=>b.at-a.at))diagnostic=diagnostic.slice(0,e.at)+e.text+diagnostic.slice(e.at);
 diagnostic+=`\nexport function selectorEntryCount(){return $selectorEntries;}
 export function selectorTreePoint(d,s){if(typeof d==='bigint'&&d>=0n&&d<=281474976710655n&&typeof s==='number'&&Number.isInteger(s)&&s>=0&&s<=4294967295&&$selectorGuard())return $selectorCapture(d,s);return call(get(G,'s.gen'),[d,s]);}\n`;
 parse(diagnostic);const diagnosticFile=path.join(out,'candidate-diagnostic.mjs');fs.writeFileSync(diagnosticFile,diagnostic,{flag:'wx'});
 report.diagnostic={parent:identity(files[1]),output:identity(diagnosticFile),insertions,scope:'Expose/instrument the actual admitted private helper only. Canonical diagnostic entry retains its actual closure guards. No alternative producer body is introduced and no diagnostic artifact is timed.'};
 const baseline=await import(pathToFileURL(files[0])),candidate=await import(pathToFileURL(diagnosticFile)),typescript=await import(pathToFileURL(files[2]));
 const mods=[baseline,candidate,typescript];
 const call=(m,name,args)=>{const actual=m===typescript?args.map(x=>typeof x==='bigint'?Number(x):x):args;return m.default?m.default[name](...actual):m[name](...actual);};
 for(const depth of [0,1,2,4,7])for(const seed of [0,1,2,3,4,5,6,38,39,40,41,42,2147483648,4294967293,4294967294,4294967295]){
  for(const refused of [false,true]){const name=refused?'selector_refused':'selector_check',expected=hashTree(model(depth,seed,refused)),values=mods.map(m=>call(m,name,[BigInt(depth),seed]));for(const x of values)assert.equal(x,expected);
   report.oracle.push({kind:'hash',name,depth,seed,expected,values});}
  const expected=model(depth,seed),values=[canonical(call(baseline,'s.gen',[BigInt(depth),seed])),canonical(candidate.selectorTreePoint(BigInt(depth),seed)),canonical(call(typescript,'s.gen',[BigInt(depth),seed]))];
  for(const x of values)assert.deepEqual(x,expected);report.oracle.push({kind:'complete-tree',depth,seed,expected,values});
 }
 for(const seed of [0,2,42]){const depth=12,expected=model(depth,seed),value=candidate.selectorTreePoint(BigInt(depth),seed);assert.deepEqual(canonical(value),expected);report.oracle.push({kind:'depth12-complete-tree',depth,seed,hash:hashTree(expected)});}
 const shared=candidate.selectorTreePoint(1n,2);assert.equal(shared.$,'SelectNode');assert.equal(shared.a[0],shared.a[1]);report.admission.push({kind:'shared-child-identity',pass:true});
 let entries=candidate.selectorEntryCount();candidate.default.selector_check(3n,42);assert.equal(candidate.selectorEntryCount(),entries+1);report.admission.push({kind:'actual-root-entry',pass:true});
 for(const name of ['s.gen','s.node','s.last','s.bool_first','s.bool_last','s.bool_children']){
  function observe(m){const f=m.G[name],old=f.code;let calls=0;f.code=function(a){calls++;return Reflect.apply(old,this,[a]);};try{return {value:m.default.selector_check(3n,0),calls};}finally{f.code=old;}}
  // Depth3/seed0 executes all selectors: leaf seeds27/117 reach bool_first,13/37 reach bool_last; internal seed0 reaches bool_children.
  const a=observe(baseline);assert(a.calls>0,'active mutation witness '+name);entries=candidate.selectorEntryCount();const b=observe(candidate);assert.deepEqual(b,a);assert.equal(candidate.selectorEntryCount(),entries);report.boundaries.push({kind:'mutated-dependency-refusal',name,expected:a,actual:b});
 }
 const outside=text.slice(assignment(tree,'selector_outside').start,assignment(tree,'selector_outside').end);
 assert(!outside.includes('function '+privateName('s.make')+'('),'sum constructor must refuse outside producer context');assert(outside.includes('get(G,"s.make")'),'outside constructor retains generic residual');
 const refused=text.slice(assignment(tree,'selector_refused').start,assignment(tree,'selector_refused').end);
 assert(!refused.includes('function '+privateName('s.nonprimitive')+'('),'helper expression in delayed field must refuse direct constructor');assert(refused.includes('get(G,"s.nonprimitive")'));
 report.admission.push({kind:'outside-context-refusal',pass:true},{kind:'nonprimitive-field-refusal',pass:true});
 for(const seed of [0,1,4294967295])for(const m of mods)assert.equal(call(m,'selector_outside',[seed]),seed);
 for(const entry of report.inputs)assert.deepEqual(identity(entry.path),entry);report.complete=report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,admission:report.admission.length,boundaries:report.boundaries.length,error:report.error}));

// Structural correspondence for the checked generic-bridge -> matcher1 cleanup.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';
const [oldArg,newArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const ident=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const root=path.resolve(import.meta.dirname,'../../../..'),design=path.join(root,'design/phase30/retire-arm-prebinding.md');
const parserName='internal/deps/acorn/acorn/dist/acorn',parserSource=process.binding('natives')[parserName],parserModule={exports:{}};
assert.equal(typeof parserSource,'string');new Function('exports','module',parserSource)(parserModule.exports,parserModule);const acorn=parserModule.exports;assert.equal(acorn.version,'8.16.0');
const parse=s=>acorn.parse(s,{ecmaVersion:'latest',sourceType:'module'});
const report={kind:'phase30-checked-prebinding-retirement-structure',complete:false,pass:false,inputs:[import.meta.filename,design].map(ident),sites:[],
 parser:{name:parserName,version:acorn.version,sha256:createHash('sha256').update(parserSource).digest('hex'),node:ident(process.execPath)},
 scope:'Checked same-source emissions. Exactly one generic runtime bridge removed; only recognized generated matcher1p sites become matcher1 plus literal fn. Every other AST field must agree.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-audit.mjs'));fs.copyFileSync(design,path.join(out,'plan.md'));fs.writeFileSync(path.join(out,'parser-acorn.js'),parserSource,{flag:'wx'});
function clean(x){if(Array.isArray(x))return x.map(clean);if(!x||typeof x!=='object')return x;return Object.fromEntries(Object.entries(x).filter(([k])=>!['start','end','loc','raw'].includes(k)).map(([k,v])=>[k,clean(v)]));}
function load(file){file=fs.realpathSync(file);const receiptFile=file+'.json',r=JSON.parse(fs.readFileSync(receiptFile));assert.equal(r.complete,true);assert.equal(r.observation.checked,true);assert.equal(r.observation.status,'ok');assert.equal(ident(file).sha256,r.output.sha256);
 for(const key of ['attempt','input','api','runtime','base','driver'])assert.equal(ident(r[key].file).sha256,r[key].sha256,key);
 report.inputs.push(...[file,receiptFile,...['attempt','input','api','runtime','base','driver'].map(k=>r[k].file)].map(ident));const source=fs.readFileSync(file,'utf8'),runtime=fs.readFileSync(r.runtime.file,'utf8');assert.ok(source.startsWith(runtime+'\n'));return {file,r,source,runtime,generated:source.slice(runtime.length)};}
const id=name=>({type:'Identifier',name}),call=(name,args)=>({type:'CallExpression',callee:id(name),arguments:args,optional:false});
function rewrite(node){if(!node||typeof node!=='object')return node;if(Array.isArray(node))return node.map(rewrite);
 const next=Object.fromEntries(Object.entries(node).map(([k,v])=>[k,rewrite(v)]));
 if(next.type!=='CallExpression'||next.callee.type!=='Identifier'||next.callee.name!=='matcher1p')return next;
 assert.equal(next.optional,false);assert.equal(next.arguments.length,4);const [tag,count,total,factory]=next.arguments;
 assert.equal(tag.type,'Literal');assert.equal(typeof tag.value,'string');for(const n of [count,total]){assert.equal(n.type,'Literal');assert.ok(Number.isInteger(n.value));}assert.ok(count.value>0&&count.value<total.value);
 assert.equal(factory.type,'ArrowFunctionExpression');assert.deepEqual(factory.params,[]);assert.equal(factory.async,false);assert.equal(factory.expression,true);let body=factory.body,kind;
 if(body.type==='SequenceExpression'){assert.equal(body.expressions.length,2);assert.equal(body.expressions[0].type,'Literal');assert.equal(body.expressions[0].value,0);body=body.expressions[1];kind='literal-arm';
  assert.equal(body.type,'FunctionExpression');assert.equal(body.id,null);assert.equal(body.async,false);assert.equal(body.generator,false);assert.deepEqual(body.params,[id('a')]);
 }else{kind='registered-nat';assert.equal(tag.value,'Succ');assert.equal(count.value,1);assert.equal(body.type,'CallExpression');assert.deepEqual(body.callee,id('exactCode'));assert.equal(body.optional,false);assert.equal(body.arguments.length,1);
  const fn=body.arguments[0];assert.equal(fn.type,'FunctionExpression');assert.equal(fn.id,null);assert.equal(fn.async,false);assert.equal(fn.generator,false);assert.deepEqual(fn.params,[id('a'),id('$entered')]);}
 report.sites.push({tag:tag.value,count:count.value,total:total.value,kind});
 return call('matcher1',[tag,{...factory,body:call('fn',[total,body])}]);
}
try{
 const before=load(oldArg),after=load(newArg);assert.equal(before.r.input.sha256,after.r.input.sha256,'Same fixture source required');assert.equal(before.r.base.sha256,after.r.base.sha256,'Same Base required');assert.notEqual(before.r.attempt.sha256,after.r.attempt.sha256);
 const oldRuntime=clean(parse(before.runtime)),newRuntime=clean(parse(after.runtime));const bridges=oldRuntime.body.filter(x=>x.type==='FunctionDeclaration'&&x.id.name==='matcher1p');assert.equal(bridges.length,1);
 const expected=clean(parse('function matcher1p(name,count,arity,make){return fn(1,([x])=>{const p=project(name,x),n=p.length,c=make();return n?jump(fn(arity,c),p):fn(arity,c);})}')).body[0];
 assert.deepEqual(bridges[0],expected,'Baseline must be the proved generic bridge, not eager prebinding');oldRuntime.body=oldRuntime.body.filter(x=>x!==bridges[0]);assert.deepEqual(newRuntime,oldRuntime,'Only runtime bridge deletion is permitted');
 const generatedAst=side=>{const full=parse(side.source);assert.ok(full.body.every(n=>n.end<=side.runtime.length||n.start>=side.runtime.length),'Top-level node crosses runtime boundary');return {...full,body:full.body.filter(n=>n.start>=side.runtime.length)};};
 const original=clean(generatedAst(before)),candidate=clean(generatedAst(after)),expectedProgram=rewrite(original);assert.ok(report.sites.length,'At least one actual retirement site is required');assert.deepEqual(candidate,expectedProgram,'Unrelated generated AST changed');
 let surviving=0;function scan(x){if(!x||typeof x!=='object')return;if(x.type==='Identifier'&&x.name==='matcher1p')surviving++;for(const v of Object.values(x))if(Array.isArray(v))v.forEach(scan);else scan(v);}scan(candidate);assert.equal(surviving,0);
 report.literalArms=report.sites.filter(x=>x.kind==='literal-arm').length;report.registeredNatWrappers=report.sites.filter(x=>x.kind==='registered-nat').length;report.runtimeBridgeRemoved=true;report.unrelatedGeneratedAstEqual=true;
 for(const input of report.inputs)assert.deepEqual(ident(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,sites:report.sites.length,literalArms:report.literalArms,registeredNatWrappers:report.registeredNatWrappers,error:report.error}));

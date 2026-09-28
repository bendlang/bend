// Run with EQUALITY_TEST_API pointing at a genuine checked B1 API.
import nodeTest from 'node:test';
import {createHash} from 'node:crypto';
const planned=[],completed=[],failures=[];
const test=(name,fn)=>{planned.push(name);return nodeTest(name,async t=>{try{await fn(t);completed.push(name);}catch(error){failures.push({name,error:String(error.stack??error)});throw error;}});};
test.after=nodeTest.after;
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {transformEquality,deriveEquality,verifyEqualityDerivation} from './equality.mjs';

const input=process.env.EQUALITY_TEST_API;
assert.ok(input,'Set EQUALITY_TEST_API to a genuine checked B1 API');
const source=fs.readFileSync(input,'utf8'),temp=fs.mkdtempSync(path.join(os.tmpdir(),'bend-equality-tests-'));
const candidate=transformEquality(source);
const legacy=candidate.stats.version===1;
const declaration=name=>new RegExp('^function '+name.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')+'\\([^\\n]*\\) \\{','m');
const expose='\nexport const equality=(a,b)=>run_loop($String$eq$(a,b));\nexport const staged=run_lib($String$eq$,2);\n';
const modules=[];
for(const [name,body]of [['original',source],['derived',candidate.source]]) {
  const file=path.join(temp,name+'.mjs');fs.writeFileSync(file,body+expose);modules.push(await import(pathToFileURL(file)));
}
const observe=(module,a,b)=>{try{return {ok:true,value:module.equality(a,b)}}catch(e){return {ok:false,error:typeof e==='string'?e:{name:e.name,message:e.message}}}};

test('reviewed equality insertion and optional current-profile choice lowering',()=>{
  assert.equal(candidate.stats.replacements,1);assert.equal(Object.keys(candidate.stats.bodyHashes).length,11);
  const scalar=candidate.stats.version>=4?transformEquality(source,3):candidate;
  const at=source.search(declaration('$String$eq$')),open=source.indexOf('\n',at)+1,added=scalar.source.length-source.length;
  assert.equal(scalar.source.slice(0,open),source.slice(0,open));assert.equal(scalar.source.slice(open+added),source.slice(open));
  assert.ok(scalar.source.length>source.length);assert.equal(candidate.stats.exports.length,new Set(candidate.stats.exports).size);
  if(candidate.stats.version>=4){assert.ok(candidate.stats.choices.sites>0);assert.equal((candidate.stats.tailChoices??candidate.stats.choices).outputSha256,createHash('sha256').update(candidate.source).digest('hex'));}
  assert.throws(()=>transformEquality(candidate.source),/Unsupported equality dependency/);
});
test('explicit versions retain historical equality bytes and reject cross-emitter profiles',()=>{
  for(const version of [0,6,'2'])assert.throws(()=>transformEquality(source,version),/Unsupported generated runtime/);
  if(legacy){assert.deepEqual(transformEquality(source,1),candidate);for(const version of [2,3,4,5])assert.throws(()=>transformEquality(source,version),/Unsupported generated runtime/);}
  else{
    const historical=transformEquality(source,2),v3=transformEquality(source,3);
    const oldGuard='  if (typeof _a_0 === "string" && typeof _b_0 === "string" && _a_0.isWellFormed() && _b_0.isWellFormed()) return _a_0 === _b_0;\n';
    const newGuard='  if (typeof _a_0 === "string" && typeof _b_0 === "string") return _a_0 === _b_0;\n';
    assert.equal(historical.source.split(oldGuard).length,2);assert.equal(historical.source.replace(oldGuard,newGuard),v3.source);assert.deepEqual({...historical.stats,version:3},v3.stats);
    assert.equal(candidate.stats.version,5);assert.deepEqual(transformEquality(source,5),candidate);const v4=transformEquality(source,4),{choices,...baseStats}=v4.stats;assert.deepEqual({...baseStats,version:3},v3.stats);assert.ok(choices.sites>0);assert.equal(candidate.stats.choices.protectedBodies.length,3);assert.ok(candidate.stats.tailChoices.sites>0);assert.ok(candidate.stats.tailChoices.deferredGeneratedCalls>0);
    assert.throws(()=>transformEquality(source,1),/Unsupported generated runtime/);
  }
});
test('version4 rejects member callees, rebinding, destructuring and protected nesting',()=>{
  if(legacy)return;
  const rejected=[
    'function $probe$() { return obj.$kc$(true, run_clo((u)=>1), run_clo((u)=>2)); }',
    'function $probe$() { return obj?.$f_choose$(true, run_clo((u)=>1), run_clo((u)=>2)); }',
    'function $probe$() { const {$kc$} = obj; return 0; }',
    'function $probe$() { let [run_clo] = values; return 0; }',
    'function $probe$() { ({x:$kc$} = obj); return 0; }',
    'function $probe$() { ($f_choose$) = replacement; return 0; }',
    'function $probe$() { function run_tail(a,b) { return 0; } return 0; }',
    'function $probe$() { function $kc$(a,b,c) { return 0; } return 0; }',
    'function $probe$($kc$) { return 0; }',
    'function $probe$() { return (({x:run_tail})=>1)(obj); }',
    'function $probe$() { return $kc$.call(null,true,()=>1,()=>2); }',
    'function $probe$() { return new $kc$(true,run_clo((u)=>1),run_clo((u)=>2)); }',
    'function $kc$(a,b,c) { return 0; }'
  ];
  for(const probe of rejected)assert.throws(()=>transformEquality(source.replace('export default {',()=>probe+'\nexport default {'),4),undefined,probe);
  const probe='function $probe$(_c_0,_y_0,_n_0) { return $kc$(_c_0,_y_0,_n_0); }';
  const kept=transformEquality(source.replace('export default {',()=>probe+'\nexport default {'));
  assert.ok(kept.source.includes(probe));assert.equal(kept.stats.choices.skipped.length,candidate.stats.choices.skipped.length+1);
});
test('reject changed equality dependency and runtime',()=>{
  assert.throws(()=>transformEquality(source.replace(declaration('$Char$cmp$'),match=>match+'\n  void 0;')),/Unsupported equality dependency/);
  assert.throws(()=>transformEquality(source.replace('function char_new(code) {','function char_new(code) {\n void 0;')),/Unsupported generated runtime/);
});
test('reject duplicate, nested and rebound protected function bindings',()=>{
  const body=source.match(/function \$String\$eq\$\([^)]*\) \{\n[^\n]*\n\}/)[0];
  assert.throws(()=>transformEquality(source.replace('export default {',body+'\nexport default {')),/duplicate/);
  assert.throws(()=>transformEquality(source.replace('export default {','function $probe$() {\n'+body+'\n}\nexport default {')),/Nested equality binding/);
  assert.throws(()=>transformEquality(source.replace('export default {','function $probe$() {\n $String$eq$ = null;\n}\nexport default {')),/Rebound/);
  assert.throws(()=>transformEquality(source+'\n$String$eq$ = null;'),/Unexpected top-level/);
});
test('quoted declaration text cannot masquerade as a binding',()=>{
  const text='function $String$eq$(a_0, b_0) {\n return false;\n}';
  const decoy=source.replace('export default {','function $probe$() {\n return '+JSON.stringify(text)+';\n}\nexport default {');
  assert.equal(transformEquality(decoy).stats.replacements,1);
  assert.throws(()=>transformEquality(source.replace('function $String$eq$(', 'function $notEquality$(')),/Unsupported equality dependency/);
});
test('reject protected function and arrow parameter bindings, including destructuring',()=>{
  for(const body of [
    'function $probe$($String$eq$) { return 1; }',
    'function $probe$() { return function($String$cmp$) { return 1; }; }',
    'function $probe$() { return ($String$eq$) => 1; }',
    'function $probe$() { return ({x: $String$eq$}) => 1; }',
    'function $probe$() { return $String$eq$ => 1; }'
  ])assert.throws(()=>transformEquality(source.replace('export default {',body+'\nexport default {')),/Shadowed equality parameter/);
});
test('current public marshalling and arity are exact reviewed syntax',()=>{
  if(legacy)return;
  for(const [before,after]of [
    ['return r; }, 1)', 'return null; }, 1)'],
    ['$f_parse$((a0))', '$f_parse$((String(a0)))'],
    ['return r; }, 1)', 'return r; }, 2)'],
    ['(a0); return r;', '(a0); $String$eq$ = null; return r;']
  ])assert.throws(()=>transformEquality(source.replace(before,after)),/Unsupported export marshalling/);
});

test('Unicode, malformed UTF-16 and non-string values preserve exact observations',()=>{
  const values=['','a','b','abc','abd','a\0b','\0','é','e\u0301','λ','中','🙂','𝄞','\ud800','\udc00','a\ud800','b\ud800','\ud800a','\udc00a','\ud800\ud800','\udc00\ud800','🙂\ud800',null,undefined,0,1,true,false,{},new String('abc')];
  for(let i=0;i<values.length;i++)for(let j=0;j<values.length;j++)assert.deepEqual(observe(modules[1],values[i],values[j]),observe(modules[0],values[i],values[j]),`${i},${j}`);
  for(const n of [128,512,2048])for(const tail of ['','x','🙂'])assert.deepEqual(observe(modules[1],'ab'.repeat(n),'ab'.repeat(n)+tail),observe(modules[0],'ab'.repeat(n),'ab'.repeat(n)+tail));
});
test('malformed suffixes retain early mismatch/exhaustion and demanded-error order',()=>{
  for(const [a,b,expected]of [['x\ud800','y\ud800',false],['','\ud800',false],['\ud800','',false],['x\ud800','x\ud800',legacy?'bend: 55296 is not a Unicode scalar value':true],['\ud800','\udc00',legacy?'bend: 55296 is not a Unicode scalar value':false]]) {
    for(const module of modules){const result=observe(module,a,b);assert.equal(typeof expected==='boolean'?result.value:result.error,expected);}
  }
});
test('fallback objects and staged arguments preserve observed demand',()=>{
  function run(module) {
    const events=[];
    const a={codePointAt(i){events.push('left codepoint');throw Error('left error');}},b={codePointAt(i){events.push('right codepoint');throw Error('right error');}};
    return {result:observe(module,a,b),events};
  }
  assert.deepEqual(run(modules[1]),run(modules[0]));assert.deepEqual(run(modules[1]).events,['left codepoint']);
  for(const module of modules) {
    const events=[],arg=(name,value)=>(events.push(name),value);
    const partial=module.staged(arg('left','abc'));assert.deepEqual(events,['left']);
    assert.equal(partial(arg('right','abc')),true);assert.deepEqual(events,['left','right']);
    assert.equal(module.staged('a','a','ignored'),true);
  }
});
test('actual public compiler exports retain zero arity, currying and extra arguments',()=>{
  const observeApi=module=>{
    const api=module.default,events=[],arg=(name,value)=>(events.push(name),value);
    const partial=api.f_path_join(arg('left','folder/'));
    assert.deepEqual(events,['left']);
    const joined=partial(arg('right','file'));
    assert.deepEqual(events,['left','right']);assert.equal(joined,'folder/file');
    const parsed=api.f_parse('def main() -> U32:\n  0\n'),before=JSON.stringify(parsed);
    const checked=api.check_book(parsed.book);
    assert.equal(JSON.stringify(parsed),before,'Public checker mutated parsed data');
    return {abi:api.compiler_check_result_abi(),joined,extra:api.f_path_join('folder/','file','ignored'),checked,parsed};
  };
  assert.deepEqual(observeApi(modules[1]),observeApi(modules[0]));
});

test('version5 guards generated callees and lexical control dependencies',()=>{
  if(legacy)return;
  for(const probe of [
    'function $probe$() { const $lookup$=null; return 0; }',
    'function $probe$($lookup$) { return 0; }',
    'function $probe$({x:$lookup$}) { return 0; }',
    'function $probe$() { return obj.$lookup$(null, "x"); }',
    'function $probe$() { return this; }',
    'function $probe$() { return arguments; }',
    'function $probe$() { return new.target; }',
    'function $probe$() { try { return 0; } finally {} }',
    'function $probe$() { function $inner$() { return 0; } return 0; }'
  ])assert.throws(()=>transformEquality(source.replace('export default {',()=>probe+'\nexport default {'),5),undefined,probe);
});
test('version5 leaf guards preserve non-tail boundaries, Unit captures, effects and arity',async()=>{
  if(legacy)return;
  const probe=`
function $phase12_leaf$(_a,_b,_effect) { const _done=_effect("callee"); return _a+_b; }
function $phase12_order$(_b,_effect) { return $kc$(_effect("condition",_b),run_clo((_u)=>{return $phase12_leaf$(_effect("first",3),_effect("second",4),_effect);}),run_clo((_u)=>{const _done=_effect("other");return 0;})); }
function $phase12_down$(_n,_a) { return $kc$(_n>0,run_clo((_u)=>{return $phase12_down$(_n-1,_a+1);}),run_clo((_u)=>{return _a;})); }
function $phase12_keep$(_n) { return $nt_choose$(_n>0,run_clo((_u)=>{return (_v)=>{return _u.$+":"+_n+":"+_v;};}),run_clo((_u)=>{return (_v)=>{return _u.$+":zero";};})); }
function $phase12_nested$(_n) { return $kc$(_n>0,run_clo((_u)=>{return $phase12_down$($phase12_down$(_n,0),0);}),run_clo((_u)=>{return 0;})); }
function $phase12_nonterminal$(_n,_f) { return $kc$(_n>0,run_clo((_u)=>{return _f(_n)+1;}),run_clo((_u)=>{return 0;})); }
function $phase12_optional$(_n,_f) { return $kc$(_n>0,run_clo((_u)=>{return $phase12_down$(_f?.(_n),0);}),run_clo((_u)=>{return 0;})); }
function $phase12_unit$(_b) { return $kc$(_b,run_clo((_u)=>{return _u;}),run_clo((_v)=>{return _v;})); }
`;
  const augmented=source.replace('export default {',()=>probe+'\nexport default {'),lowered=transformEquality(augmented,5).source;
  const body=name=>{const start=lowered.indexOf('function $phase12_'+name+'$'),end=lowered.indexOf('\nfunction ',start+1),exportAt=lowered.indexOf('\nexport default',start+1);assert.ok(start>=0);return lowered.slice(start,end<0?exportAt:Math.min(end,exportAt));};
  for(const name of ['order','nested','nonterminal','optional'])assert.ok(body(name).includes('return run_tail('),'Non-tail boundary retained: '+name);
  for(const name of ['down','keep','unit'])assert.ok(!body(name).includes('return run_tail('),'Leaf transformed: '+name);
  assert.ok(body('down').includes('f: $phase12_down$, x: ['));assert.ok(body('keep').includes('const _u = {$: "Unit"}'));assert.ok(body('unit').includes('const _v = {$: "Unit"}'));
  const expose='\nexport const p12order=run_lib((b,e)=>run_loop($phase12_order$(b,e)),2);\nexport const p12down=(n,a)=>run_loop($phase12_down$(n,a));\nexport const p12keep=n=>run_loop($phase12_keep$(n));\nexport const p12unit=b=>run_loop($phase12_unit$(b));\nexport const p12nested=n=>run_loop($phase12_nested$(n));\nexport const p12nonterminal=(n,f)=>run_loop($phase12_nonterminal$(n,f));\n';
  const images=[];for(const [name,text]of [['before',augmented],['after',lowered]]){const file=path.join(temp,'phase12-leaf-'+name+'.mjs');fs.writeFileSync(file,text+expose);images.push(await import(pathToFileURL(file)));}
  const observation=m=>{const rows=[];for(const stop of ['none','condition','first','second','callee','other'])for(const condition of [false,true]){const log=[];let result;try{result={value:m.p12order(condition)((name,value)=>{log.push(name);if(name===stop)throw Error(name);return value;},'extra')};}catch(e){result={error:e.name+': '+e.message};}rows.push({condition,stop,log,result});}return{rows,deep:m.p12down(100000,0),capture:m.p12keep(7)('x'),zero:m.p12keep(0)('x'),unit:[m.p12unit(true),m.p12unit(false)],nested:m.p12nested(17),nonterminal:m.p12nonterminal(4,n=>n*2)};};
  assert.deepEqual(observation(images[1]),observation(images[0]));
});

test('fresh derivation has distinct honest lineage, replays and rejects drift',async()=>{
  const report=process.env.EQUALITY_TEST_BOOTSTRAP;
  assert.ok(report,'Set EQUALITY_TEST_BOOTSTRAP to the matching normal bootstrap report');
  const output=path.join(temp,'successful'),result=await deriveEquality({api:input,bootstrapReport:report,outputDirectory:output});
  assert.equal(result.metadata.newBootstrap,false);assert.equal(result.metadata.complete,true);
  assert.equal(fs.existsSync(result.api+'.bootstrap.json'),false);assert.equal(verifyEqualityDerivation(result.report).api,result.api);
  await assert.rejects(()=>deriveEquality({api:input,bootstrapReport:report,outputDirectory:output}),/EEXIST/);
  fs.appendFileSync(result.api,'\n');assert.throws(()=>verifyEqualityDerivation(result.report),/Changed input/);
});
test('incomplete/bootstrap identity mismatch retains explicit refusal report',async()=>{
  const report=JSON.parse(fs.readFileSync(process.env.EQUALITY_TEST_BOOTSTRAP,'utf8'));
  for(const [name,mutate]of [['incomplete',r=>r.provenance.verifiedAfterBuild=false],['wrong-api',r=>r.apiSha256='0'.repeat(64)],['wrong-stage',r=>r.stage='selfhost'],['wrong-pin',r=>r.revision='0'.repeat(40)],['wrong-base',r=>r.baseSha256='0'.repeat(64)],['wrong-recipe',r=>r.provenance.inputs.find(x=>x.role==='host-tool'&&x.file.endsWith('/stage0-library.mjs')).sha256='0'.repeat(64)],['wrong-source',r=>r.sourceSha256='0'.repeat(64)]]) {
    const changed=structuredClone(report);mutate(changed);const file=path.join(temp,name+'.json');fs.writeFileSync(file,JSON.stringify(changed));const output=path.join(temp,name);
    await assert.rejects(()=>deriveEquality({api:input,bootstrapReport:file,outputDirectory:output}));
    const failure=JSON.parse(fs.readFileSync(path.join(output,'api.mjs.derivation.json'),'utf8'));assert.equal(failure.complete,false);assert.equal(typeof failure.error,'string');
    assert.equal(fs.existsSync(path.join(output,'api.mjs')),false);
  }
});

test.after(()=>{
  if(process.env.EQUALITY_TEST_REPORT){
    const identity=file=>({file:String(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
    fs.writeFileSync(process.env.EQUALITY_TEST_REPORT,JSON.stringify({pass:completed.length===planned.length,planned,completed,failures,transform:candidate.stats,api:identity(input),bootstrap:identity(process.env.EQUALITY_TEST_BOOTSTRAP),tool:identity(new URL('./equality.mjs',import.meta.url)),test:identity(new URL(import.meta.url)),node:process.version,legacyNewExportTestApplicable:!legacy},null,2)+'\n',{flag:'wx'});
  }
  fs.rmSync(temp,{recursive:true,force:true});
});

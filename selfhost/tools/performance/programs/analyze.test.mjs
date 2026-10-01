#!/usr/bin/env node
// Serial, tiny AST controls; analyzed inputs are never imported or executed.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {analyze,analyzeEntry} from './analyze.mjs';

const root=fs.mkdtempSync(path.join(os.tmpdir(),'bend-program-analysis-'));
const sha=data=>createHash('sha256').update(data).digest('hex');
let tests=0;
function test(label,fn) {fn();tests++;console.log(`ok ${tests} ${label}`);}
const put=(name,source)=>{const file=path.join(root,name);fs.writeFileSync(file,source);return file;};
const bend=put('fixture.bend','def foo.bar(x: U32) -> U32:\n  x\ndef empty() -> U32:\n  0\n');
const runtime='const G=Object.create(null);\nfunction fn(n,f){return f;}\n';
const runtimePath=put('runtime.mjs',runtime);
const selfhost=put('selfhost.mjs',runtime+'G["foo.bar"]=fn(1,function(a){const x=1n; return callOwned(get(G,"empty"),[a[0]]);});\nexport default {};\n');
const upstream=put('upstream.mjs','function run_lib(f){return f;}\n// Program\n// =======\nfunction $foo$bar$(x){return TAB_0[x];}\nconst TAB_0=[0,1,2];\nexport default {"foo.bar":run_lib((x)=>$foo$bar$(x))};\n');
const entry=(module=selfhost,extra={})=>({id:'fixture',role:'baseline',path:module,sourcePath:bend,family:'selfhost',...extra});
try {
  test('AST counts real calls and BigInt literals; no module execution',()=>{
    const file=put('never-execute.mjs',runtime+'throw new Error("must never run");\nG["foo.bar"]=fn(1,function(a){const s="callOwned(x, [])";/* callOwned() */return callOwned(get(G,"empty"),[1n]);});\n');
    const result=analyzeEntry(entry(file,{runtimePath})).report;
    assert.equal(result.metrics.bigIntLiterals,1);
    assert.equal(result.callTargets.find(r=>r.name==='callOwned').sites,1);
    assert.equal(result.definitions.find(r=>r.name==='foo.bar').units.length,1);
  });
  test('exact runtime prefix and partitioned byte counts',()=>{
    const result=analyzeEntry(entry(selfhost,{runtimePath})).report;
    assert.equal(result.boundary.confidence,'exact');
    assert.equal(result.sections.runtimePrefix.bytes,Buffer.byteLength(runtime));
    assert.equal(Object.values(result.sections).reduce((a,s)=>a+s.bytes,0),result.bytes);
  });
  test('inferred selfhost prefix is explicit when runtime is unavailable',()=>{
    const result=analyzeEntry(entry()).report;
    assert.equal(result.boundary.confidence,'inferred');
    assert.equal(result.sections.program.metrics.bigIntLiterals,1);
  });
  test('runtime mismatch fails instead of inventing exact boundary',()=>{
    assert.throws(()=>analyzeEntry(entry(selfhost,{runtimePath:put('wrong-runtime.mjs','const notRuntime=1;')})),/runtime does not exactly prefix/);
  });
  test('upstream export maps dotted Bend names; shared tables remain visible',()=>{
    const result=analyzeEntry(entry(upstream,{role:'typescript',family:'upstream'})).report;
    const fn=result.functions.find(f=>f.name==='$foo$bar$');
    assert.deepEqual(fn.bendNames,['foo.bar']);assert.equal(fn.mapping.confidence,'syntax');
    assert.equal(result.sharedArrayTables[0].elements,3);
    assert.equal(result.sharedArrayTables[0].users[0].bendNames[0],'foo.bar');
    assert.equal(result.sections.program.metrics.arrayLiteralSites,1);
  });
  test('marker text inside string does not become a runtime boundary',()=>{
    const file=put('fake-marker.mjs','const fake="// Program\\n// =======\\n"; function x(){}');
    assert.equal(analyzeEntry(entry(file,{family:'upstream'})).report.boundary.confidence,'unknown');
  });
  test('exclusive function counts exclude nested bodies but retain function sites',()=>{
    const file=put('nested.mjs',runtime+'G["foo.bar"]=fn(1,function(a){return ()=>{inner();inner();};});');
    const result=analyzeEntry(entry(file)).report;
    const outer=result.functions.find(f=>f.name==='fn:argument1');
    assert.equal(outer.metricsExclusive.calls,0);assert.equal(outer.metricsExclusive.arrowFunctions,1);
    assert.equal(result.functions.find(f=>f.kind==='ArrowFunctionExpression').metricsExclusive.calls,2);
  });
  test('encoded private-region helpers map back to their Bend name',()=>{
    const file=put('private.mjs',runtime+'G["foo.bar"]=(()=>{function $R_102_111_111_46_98_97_114$get(x){return x;}return fn(1,(a)=>a[0]);})();');
    const fn=analyzeEntry(entry(file)).report.functions.find(f=>f.name.startsWith('$R_'));
    assert.deepEqual(fn.bendNames,['foo.bar']);assert.equal(fn.mapping.confidence,'convention');
  });
  test('normalized tokens ignore formatting/comments; raw source stays escaped in HTML',()=>{
    const first=put('normal-one.mjs',runtime+'G["foo.bar"]=fn(1,function(a){return "</pre><script>alert(1)</script>";});');
    const second=put('normal-two.mjs',runtime+'G [ "foo.bar" ] = fn(1, function(a) { /* trivia */ return "</pre><script>alert(1)</script>"; } );');
    const out=path.join(root,'normal-report');
    const report=analyze({entries:[entry(first),entry(second,{role:'candidate'})]},out);
    assert.equal(report.comparisons[0].definitions.find(d=>d.name==='foo.bar').normalizedEqual,true);
    const html=fs.readFileSync(path.join(out,'comparison.html'),'utf8');
    assert.ok(!html.includes('<script>'));assert.ok(html.includes('&lt;script&gt;'));
    assert.equal(report.comparisons[0].definitions.find(d=>d.name==='empty').normalizedEqual,null);
    assert.ok(fs.readFileSync(path.join(out,'fixture-baseline.tokens.txt'),'utf8').includes('string\t'));
  });
  test('changed identifiers produce different normalized tokens',()=>{
    const second=put('different.mjs',runtime+'G["foo.bar"]=fn(1,function(z){const x=1n; return callOwned(get(G,"empty"),[z[0]]);});');
    const report=analyze({entries:[entry(),entry(second,{role:'candidate'})]},path.join(root,'different-report'));
    assert.equal(report.comparisons[0].definitions[0].normalizedEqual,false);
  });
  test('input and source hash mismatches reject analysis',()=>{
    assert.throws(()=>analyzeEntry(entry(selfhost,{sha256:'0'.repeat(64)})),/Module hash differs/);
    assert.throws(()=>analyzeEntry(entry(selfhost,{sourceSha256:'0'.repeat(64)})),/Bend source hash differs/);
    assert.equal(analyzeEntry(entry(selfhost,{sha256:sha(fs.readFileSync(selfhost))})).report.sha256,sha(fs.readFileSync(selfhost)));
  });
  test('parse errors leave an incomplete receipt',()=>{
    const bad=put('bad.mjs','function {');const out=path.join(root,'parse-failure');
    assert.throws(()=>analyze({entries:[entry(bad)]},out));
    const report=JSON.parse(fs.readFileSync(path.join(out,'report.json')));
    assert.equal(report.complete,false);assert.ok(report.error.includes('SyntaxError'));
  });
  test('cross-source comparison fails with incomplete receipt',()=>{
    const other=put('other.bend','def foo.bar(x: U32) -> U32:\n  U32.inc(x)\n');
    const out=path.join(root,'mismatch');
    assert.throws(()=>analyze({entries:[entry(),entry(upstream,{role:'typescript',family:'upstream',sourcePath:other})]},out),/Comparison sources differ/);
    assert.equal(JSON.parse(fs.readFileSync(path.join(out,'report.json'))).complete,false);
  });
  test('output directories and duplicate roles are never overwritten',()=>{
    const existing=path.join(root,'existing');fs.mkdirSync(existing);put('existing/sentinel','keep');
    assert.throws(()=>analyze({entries:[entry()]},existing),/EEXIST/);assert.equal(fs.readFileSync(path.join(existing,'sentinel'),'utf8'),'keep');
    assert.throws(()=>analyze({entries:[entry(),entry()]},path.join(root,'duplicate')),/Duplicate case\/role/);
  });
  test('UTF-8 validity and safe artifact names are enforced',()=>{
    const bad=put('bytes.mjs',Buffer.from([255]));assert.throws(()=>analyzeEntry(entry(bad)),/canonical UTF-8/);
    assert.throws(()=>analyze({entries:[entry(selfhost,{id:'../escape'})]},path.join(root,'path-failure')));
  });
  console.log(JSON.stringify({complete:true,tests}));
} finally {fs.rmSync(root,{recursive:true,force:true});}

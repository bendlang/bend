// Emit a checked library with either unchanged compiler. No execution timing here.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [variant,inputArgument,outputArgument] = process.argv.slice(2);
assert.ok(['upstream','selfhost'].includes(variant));
const input=fs.realpathSync(inputArgument), output=path.resolve(outputArgument);
const root=path.resolve(import.meta.dirname,'../../..');
const sha=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
const report={kind:'phase25-checked-library-emission',variant,input:{file:input,sha256:sha(input)},complete:false,started:new Date().toISOString()};
const begin=performance.now();
try {
  let code;
  if(variant==='upstream') {
    const upstream=path.join(root,'.bootstrap/upstream-phase23/bend2');
    const B=await import(pathToFileURL(path.join(upstream,'bend.ts')));
    const C=await import(pathToFileURL(path.join(upstream,'comp.ts')));
    const book=B.book_nil(); await B.book_load(book,input,'',new Map()); B.book_valid(book);
    assert.equal(book.hols,0); report.checked=true;
    // Match the candidate's ordinary library roots, not a private bench-only API.
    code=C.js_lib(book,true);
  } else {
    process.env.BEND_TYPED_API=path.join(root,'dist/typed-api.mjs');
    process.env.BEND_TYPED_RUNTIME=path.join(root,'src/runtime.mjs');
    process.env.BEND_BASE=path.join(root,'dist/base.bend');
    const D=await import(pathToFileURL(path.join(root,'tools/typed-driver.mjs')));
    const result=await D.inspect(input,{mode:'library'});
    ({code,...report.observation}=result);
    assert.equal(result.status,'ok');assert.equal(result.checked,true);
    report.checked=true;
  }
  fs.writeFileSync(output,code,{flag:'wx'});
  report.output={file:output,sha256:sha(output),bytes:Buffer.byteLength(code)};
  assert.equal(sha(input),report.input.sha256); report.complete=true;
} catch(error) {
  report.error=error?.$==='Err'?String(error):error.stack??String(error);
  process.exitCode=1;
} finally {
  report.elapsedMs=performance.now()-begin;
  report.timingScope='Descriptive emission acquisition only; not a controlled compiler-throughput measurement.';
  fs.writeFileSync(output+'.json',JSON.stringify(report,null,2)+'\n',{flag:'wx'});
  console.log(JSON.stringify(report));
}

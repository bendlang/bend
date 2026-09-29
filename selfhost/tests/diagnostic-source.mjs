// Differential tests only: production diagnostic modules never import upstream.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const {default:D}=await import(process.env.BEND_DIAGNOSTIC_API||'../build/diagnostic/api.mjs');
const U=await import(pathToFileURL(path.join(process.env.BEND_UPSTREAM||path.resolve(import.meta.dirname,'../../upstream-bend'),'bend2/bend.ts')));
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const prefix='type Flag is Data:\n  On{}\n  Off{}\n\n';
const cases=[
 ['undefined reference',prefix+'def main() -> Flag:\n  absent\n',true],
 ['undefined reference with context',prefix+'def use(x: Flag) -> Flag:\n  absent\n',true],
 ['wrong constructor family',prefix+'type Other is Data:\n  Other{}\n\ndef main() -> Flag:\n  Other{}\n',true],
 ['unknown constructor',prefix+'def main() -> Flag:\n  Never{}\n',true],
 ['constructor field arity',prefix+'type Box is Data:\n  Mk{value: Flag}\n\ndef main() -> Box:\n  Mk{}\n',true],
 ['decreasing-call diagnostic',prefix+'def loop(x: Flag) -> Flag:\n  loop(x)\n',true],
 ['dependent context mismatch',prefix+'def wrong(x: Flag) -> Type:\n  x\n',true],
 ['affine diagnostic',prefix+'type Pair is Data:\n  Pair{first: Flag, second: Flag}\n\ndef dup(x: Flag) -> Pair:\n  Pair{x, x}\n',true],
];
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'bend-diag-'));
let exact=0,structured=0;const mismatches=[];
try{for(const [name,source,full] of cases){
 const file=path.join(tmp,'input.bend');fs.writeFileSync(file,source);
 let expected,upstreamError;try{const book=U.book_nil();await U.book_load(book,file,'',new Map());U.book_valid(book);throw Error('Oracle accepted negative '+name);}catch(error){assert.equal(error.$,'Err',name);upstreamError=error;expected=U.err_show(error);}
 const loaded=D.f_load_origins('__main__',list([{$:'FSource',name:'__main__',path:file,text:source}]));assert.equal(loaded.result.error,'',name);
 const report=D.check_book_diagnostic(loaded.result.book,loaded.origins);assert.ok(report.error,name);assert.equal(report.error,D.check_book(loaded.result.book),name+' verdict');
 const actual=D.diagnostic_render(report);
 const wanted=full?expected:U.err_show({...upstreamError,spn:undefined});
 if(actual!==wanted){mismatches.push({name,full,expected:wanted,actual});console.error('FAIL',name,JSON.stringify({expected:wanted,actual}));}
 else{console.log('PASS',name,full?'exact source diagnostic':'exact structured diagnostic (span unavailable)');full?exact++:structured++;}
}
}finally{fs.rmSync(tmp,{recursive:true,force:true});}
console.log(JSON.stringify({exactSourceDiagnostics:exact,exactStructuredDiagnostics:structured,total:cases.length,mismatches}));
assert.equal(mismatches.length,0);

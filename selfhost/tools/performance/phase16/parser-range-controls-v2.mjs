import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
const [attemptArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-runner.mjs'));
const attempt=await verifyAttempt(path.resolve(attemptArg)),upstream=path.join(attempt.config.upstream,'bend2/bend.ts');
const code=fs.readFileSync(attempt.api.file,'utf8');for(const n of ['f_expr','f_lex_indexed'])assert(code.includes('function $'+n+'$('));
const view=path.join(out,'candidate.mjs');fs.writeFileSync(view,code+'\nexport const rangeControls={f_expr:run_lib((...xs)=>run_loop($f_expr$(...xs)),2),f_lex_indexed:run_lib((...xs)=>run_loop($f_lex_indexed$(...xs)),2)};\n');
const C=(await import(pathToFileURL(view))).rangeControls,U=await import(pathToFileURL(upstream));
const inputs=[import.meta.filename,attempt.api.file,upstream,process.execPath].map(identity);
const cases=[
 ['offload','f!(x)'],['name','x'],['literal','123'],['string-astral','"😀"'],['char-astral',"'😀'"],['type','Type'],['constructor','Box{x, y}'],['proof','{==}'],['group','( x )'],['call','f(x, y)'],['lambda','x => y'],['plus-lambda','+x => x'],['all','@x: Type -> x   '],['exists','&x: Type -> x   '],['binary','x + y   '],['binary-group','(x + y)   '],['binary-lines','x +\n y # comment\n  '],['list','[x,y]'],['tuple','(x,y)'],['equality','{x == y : Type}'],['annotation','{x : Type}'],['matcher','\\{Box: x; y}'],['empty-matcher','\\{}'],['nat-plus','2n+x  '],['nested-call','f(x)(y)'],['index','xs[i]'],['family','List<A, B>  ']
].map(([label,source])=>({label,source}));
const list=x=>{let a=[];while(x.$==='Con'){a.push(x.head);x=x.tail;}return a;};
const report={complete:false,pass:false,inputs,rows:[]};const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 for(const {label,source} of cases){const row={label,source,pass:false};report.rows.push(row);try{
  const book=U.book_nil();U.parse_book(book,'','type List<A:Type, B:Type> is Type:\n  L{}\nlaw f:\n  Type\n','',{});
  const p={book,dir:'',str:source,pos:0,stk:[],frs:0,ns:'',al:{}},reference=U.parse_term(p),begin=4097,candidate=C.f_expr(C.f_lex_indexed(begin,source),0).term;
  row.candidateTag=candidate.tag;row.referenceTag=reference.$;row.referenceRange=reference.s&&[reference.s.beg,reference.s.end];row.candidateRange=[candidate.originBegin-begin,candidate.originEnd-begin];
  assert.notEqual(candidate.tag,'Error');assert.deepEqual(row.candidateRange,row.referenceRange);
  // Lists, binary applications and matcher chains synthesize repeated nodes;
  // those generated inner nodes have independently specified upstream ranges.
  const pairs=[];
  if(label==='list'){pairs.push([list(candidate.kids)[1],reference.x[1]],[list(list(candidate.kids)[1].kids)[1],reference.x[1].x[1]]);}
  if(label==='binary'){pairs.push([list(candidate.kids)[0],reference.f],[list(list(candidate.kids)[0].kids)[0],reference.f.f]);}
  if(label==='exists'){pairs.push([list(candidate.kids)[0],reference.f],[list(candidate.kids)[1],reference.x]);}
  row.innerRanges=pairs.map(([a,b])=>({candidate:[a.originBegin-begin,a.originEnd-begin],reference:b.s&&[b.s.beg,b.s.end]}));for(const pair of row.innerRanges)assert.deepEqual(pair.candidate,pair.reference);
  row.pass=true;
 }catch(e){row.error=String(e.stack??e);}save();}
 inputs.forEach(verifyIdentity);report.complete=true;report.pass=report.rows.every(r=>r.pass);save();if(!report.pass)process.exitCode=1;
}catch(e){report.error=String(e.stack??e);save();process.exitCode=1;}
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,failed:report.rows.filter(r=>!r.pass).map(r=>({label:r.label,candidate:r.candidateRange,reference:r.referenceRange,error:r.error?.split('\n')[0]}))}));

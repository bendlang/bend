import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {spawnSync} from 'node:child_process';
const [upstreamArg,outArg]=process.argv.slice(2),upstream=fs.realpathSync(upstreamArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const hash=file=>createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:hash(file)});
const runner=path.join(out,'runner.mjs');fs.copyFileSync(import.meta.filename,runner);
const report={kind:'S4C-pinned-local-match-falsifier',complete:false,pass:false,rows:[],revision:'6018e28ecc67cf1fffc0c20c64b11023474c2df8',scope:'Tiny pinned TypeScript source loading/checking only. No Bend compiler or generated artifact, timing comparison or language change.',node:process.version,affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(s=>s.startsWith('Cpus_allowed_list:'))};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const prefix='type Flag is Data:\n  Flag{}\n\ntype Box is Data:\n  Box{+value: Flag}\n\ndef make(+x: Flag) -> Box:\n  Box{x}\n\n';
const cases=[
 ['existing-helper-boundary',prefix+'def take(+b: Box) -> Flag:\n  match b:\n    case Box{value}:\n      value\n\ndef use(+x: Flag) -> Flag:\n  take(make(x))\n',null],
 ['local-then-match',prefix+'def use(+x: Flag) -> Flag:\n  +made = make(x)\n  match made:\n    case Box{value}:\n      value\n','a match cannot scrutinize a local binder'],
 ['computed-constructor-destructure',prefix+'def use(+x: Flag) -> Flag:\n  Box{value} = make(x)\n  value\n','a match cannot scrutinize a computed value']
];
try{
 assert.equal(report.affinity.split(':')[1].trim(),'1');
 for(const [name,args] of [['git-revision',['rev-parse','HEAD']],['git-clean',['diff','--quiet','HEAD','--','bend2']]]){
  const a=fs.openSync(path.join(out,name+'.stdout'),'wx'),b=fs.openSync(path.join(out,name+'.stderr'),'wx');let r;
  try{r=spawnSync('git',['-C',upstream,...args],{stdio:['ignore',a,b],timeout:10000});}finally{fs.closeSync(a);fs.closeSync(b);}
  assert.ifError(r.error);assert.equal(r.signal,null);assert.equal(r.status,0);
 }
 assert.equal(fs.readFileSync(path.join(out,'git-revision.stdout'),'utf8').trim(),report.revision);
 const ts=path.join(upstream,'bend2/bend.ts');assert.equal(hash(ts),'461e0c5dd12789ea293daf01c1cb5b8504f8dfcf8d38b85744665a77ecc63168');
 report.inputs=[identity(ts),identity(runner),identity(process.execPath)];
 const U=await import(pathToFileURL(ts));
 for(const [id,text,wanted] of cases){
  const file=path.join(out,id+'.bend');fs.writeFileSync(file,text,{flag:'wx'});
  const row={id,input:identity(file),expected:wanted?'parse-error':'ok'};report.rows.push(row);save();
  const book=U.book_nil();let phase='parse';
  try{await U.book_load(book,file,'',new Map());phase='check';U.book_valid(book);assert.equal(book.open+book.hols,0);row.actual='ok';}
  catch(error){assert.equal(error?.$,'Err');row.actual=phase+'-error';row.diagnostic=U.err_show(error);}
  assert.equal(row.actual,row.expected,id);
  if(wanted)assert.ok(row.diagnostic.includes(wanted),row.diagnostic);
  row.pass=true;save();
 }
 for(const item of [...report.inputs,...report.rows.map(row=>row.input)])assert.equal(hash(item.file),item.sha256);
 report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.map(({id,actual,pass})=>({id,actual,pass})),error:report.error}));

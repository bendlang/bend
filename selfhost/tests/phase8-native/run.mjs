// Serial, retained actual C builds/executions of the migrated compiler API.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
const project=path.resolve(process.env.BEND_PHASE8_PROJECT||path.join(import.meta.dirname,'../..'));
const repo=path.resolve(import.meta.dirname,'../../..');
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=xs=>{const out=[];while(xs.$==='Con'){out.push(xs.head);xs=xs.tail;}assert.equal(xs.$,'Nil');return out;};
if(process.argv[2]==='--worker') {
  const [,, ,file,dir,reject]=process.argv;
  const driver=await import(pathToFileURL(path.join(project,'tools/typed-driver.mjs')));
  const api=await driver.loadApi();
  const result=reject?await driver.inspect(file,{mode:'native',api}):await driver.execute(file,{backend:'cpu',api,workdir:dir,timeoutMs:20000,args:['--threads','1']});
  fs.writeFileSync(path.join(dir,'result.json'),JSON.stringify(result,null,2)+'\n');
  process.exit(0);
}
if(!process.argv[2]||!process.env.BEND_TYPED_API||!process.env.BEND_BASE)throw Error('Usage: BEND_TYPED_API=... BEND_BASE=... node run.mjs NEW_DIRECTORY [fixture-name ...]');
const output=path.resolve(process.argv[2]);fs.mkdirSync(output,{recursive:false});
const report={kind:'phase8-retained-native-runtime-controls',started:new Date().toISOString(),node:process.version,toolchainEnv:Object.fromEntries(['CC','CPATH','LIBRARY_PATH','LD_LIBRARY_PATH'].map(k=>[k,process.env[k]??null])),cpuAllowed:fs.readFileSync('/proc/self/status','utf8').match(/^Cpus_allowed_list:\s*(.+)$/m)?.[1],api:{file:fs.realpathSync(process.env.BEND_TYPED_API),sha256:sha(process.env.BEND_TYPED_API)},base:{file:fs.realpathSync(process.env.BEND_BASE),sha256:sha(process.env.BEND_BASE)},inputs:[],rows:[],complete:false,pass:false,scope:'Actual checked selfhost emitted C, Clang CPU build and execution; Linux only, no GPU/audio device/window display claim.'};
const snapshot=file=>{file=path.resolve(file);if(!report.inputs.some(x=>x.file===file)){const rel=path.relative(repo,file);const destination=path.join(output,'inputs',rel.startsWith('..')?path.basename(file):rel);fs.mkdirSync(path.dirname(destination),{recursive:true});fs.copyFileSync(file,destination);report.inputs.push({file,snapshot:destination,sha256:sha(file)});}};
snapshot(import.meta.filename);
for(const name of ['typed-driver.mjs','native-build.mjs','compiler-abi.mjs','node-resource-args.mjs'])snapshot(path.join(project,'tools',name));
snapshot(path.join(project,'src/runtime/native/runtime.c'));
for(const name of fs.readdirSync(path.join(project,'src/runtime/native/effs')))snapshot(path.join(project,'src/runtime/native/effs',name));
for(const name of fs.readdirSync(path.join(import.meta.dirname,'fixtures')))snapshot(path.join(import.meta.dirname,'fixtures',name));
const save=()=>fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2)+'\n');
const record=(name,fn)=>{try{fn();report.rows.push({name,pass:true});}catch(error){report.rows.push({name,pass:false,error:String(error.stack||error)});}save();};
const {loadApi}=await import(pathToFileURL(path.join(project,'tools/typed-driver.mjs')));const api=await loadApi();
const term=(tag,name='',kids=[])=>({$:'KTerm',tag,name,id:0,quant:0,kids:list(kids),removed:{$:'Nil'}});
const def=(name,kind,value=term('Absent'),ctors=[],native=false)=>({$:'KDef',name,kind,arity:0,templates:0,typ:term('Typ'),value,ctors:list(ctors),native,unsafe:false});
const foreign=(name,original,path)=>def(name,'Def',term('Foreign',original,[term('Path',path)]));
const book=list([def('M.T','ADT',term('Absent'),[def('M.Pick','Ctr'),def('M.pick','Ctr')]),def('Global','ADT',term('Absent'),[def('Pick','Ctr'),def('Unit','Ctr')],true),def('M.answer','Def'),def('answer','Def'),foreign('M.get','get','effect.c')]);
record('shared scanner namespace, CID/FID, global fallback, exact Unicode text, boundaries and immutable input',()=>{
 const text='/* 😀 CID(Pick) */ CID(pick) FID(answer) CID(Unit) xCID(Pick) _FID(answer) CID( Pick) CID() end';
 const before=structuredClone(book),parsed=api.kf_source(book,'effect.c',text);
 assert.equal(parsed.error,'');assert.deepEqual(book,before);
 const rendered=array(parsed.parts).map(p=>p.tag==='Text'?p.name:`${p.tag}[${p.name}]`).join('');
 assert.equal(rendered,'/* 😀 CID[M.Pick] */ CID[M.pick] FID[M.answer] CID[Unit] xCID(Pick) _FID(answer) CID( Pick) CID() end');
 const native=api.nc_foreign_source(book,'effect.c','CID(Pick) CID(pick) FID(answer)');
 const cid=name=>'CID__CTOR_'+Array.from(name,c=>c.codePointAt(0)+'_').join('');
 assert.notEqual(cid('M.Pick'),cid('M.pick'));assert.ok(native.includes(cid('M.Pick')));assert.ok(native.includes(cid('M.pick')));assert.ok(native.includes('FID_M_ANSWER')); 
});
record('shared scanner rejects unknown name and duplicate source namespaces',()=>{
 assert.match(api.kf_source(book,'effect.c','CID(Unknown)').error,/names no constructor or def/);
 assert.match(api.kf_source(list([...array(book),foreign('N.get','get','effect.c')]),'effect.c','CID(Unit)').error,/two namespaces/);
});
const upstreamNames=['thread_count','chan_rendezvous','chan_close_send','chan_pipe','process_run','process_run_parallel','read_bytes','file_binary','tcp_bytes','tcp_listen_close','udp_bad_address','audio_only_open','audio_only_write','audio_only_close','marshal_imported_nullary','foreign_arrow_arity','foreign_types'];
const fixtures=[...upstreamNames.filter(name=>fs.existsSync(path.join(repo,'tests/io',name+'.bend'))).map(name=>({name,file:path.join(repo,'tests/io',name+'.bend')})),...['namespaced','window_only_close','unknown','duplicate'].map(name=>({name,file:path.join(import.meta.dirname,'fixtures',name+'.bend'),reject:name==='unknown'?/names no constructor or def/:name==='duplicate'?/two namespaces/:null}))];
const selected=new Set(process.argv.slice(3));
for(const fixture of fixtures.filter(x=>!selected.size||selected.has(x.name))){
 snapshot(fixture.file);const dir=path.join(output,fixture.name);fs.mkdirSync(dir);
 const stdout=fs.openSync(path.join(dir,'worker.stdout'),'wx'),stderr=fs.openSync(path.join(dir,'worker.stderr'),'wx');let child;const started=performance.now();
 try{child=spawnSync(process.execPath,['--stack-size=4096','--max-old-space-size=1536',import.meta.filename,'--worker',fixture.file,dir,fixture.reject?'reject':''],{cwd:dir,env:process.env,stdio:['ignore',stdout,stderr],timeout:90000});}finally{fs.closeSync(stdout);fs.closeSync(stderr);}
 const row={name:fixture.name,file:fixture.file,seconds:(performance.now()-started)/1000,workerExitCode:child.status,workerSignal:child.signal,workerError:child.error?.message||null};
 try{
  assert.equal(child.status,0,fs.readFileSync(path.join(dir,'worker.stderr'),'utf8'));row.result=JSON.parse(fs.readFileSync(path.join(dir,'result.json'),'utf8'));
  if(fixture.reject){assert.equal(row.result.status,'error');assert.match(row.result.diagnostic,fixture.reject);assert.equal(fs.existsSync(path.join(dir,path.basename(fixture.file,'.bend'))),false);}
  else {assert.equal(row.result.status,'ok',JSON.stringify(row.result));assert.equal(row.result.exitCode,0);assert.equal(row.result.stdout,fs.readFileSync(fixture.file,'utf8').split('\n').filter(l=>l.startsWith('#|')).map(l=>l.slice(2)).join('\n')+'\n');const source=path.join(dir,path.basename(fixture.file,'.bend')+'.c');row.generatedSource={file:source,sha256:sha(source)};}
  row.pass=true;
 }catch(error){row.pass=false;row.error=String(error.stack||error);}
 report.rows.push(row);save();console.log(fixture.name+': '+(row.pass?'PASS':'FAIL'));
}
record('consumed source and recipe inputs remain unchanged',()=>{for(const input of report.inputs)assert.equal(sha(input.file),input.sha256,input.file);assert.equal(sha(report.api.file),report.api.sha256);assert.equal(sha(report.base.file),report.base.sha256);});
report.complete=true;report.pass=report.rows.every(r=>r.pass);report.finished=new Date().toISOString();save();console.log(JSON.stringify({output,total:report.rows.length,passed:report.rows.filter(r=>r.pass).length,pass:report.pass}));if(!report.pass)process.exitCode=1;

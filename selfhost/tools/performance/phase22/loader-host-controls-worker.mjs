import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [driverFile,mockFile,fixtures,resultFile]=process.argv.slice(2);
for(const k of Object.keys(process.env))if(k.startsWith('BEND_')||k==='NODE_OPTIONS')delete process.env[k];
Object.assign(process.env,{BEND_TYPED_API:mockFile,BEND_BASE:path.join(fixtures,'base.bend'),BEND_TYPED_TRACE:''});
const mock=await import(pathToFileURL(mockFile)),driver=await import(pathToFileURL(driverFile));
const main=path.join(fixtures,'main.bend'),rows=[];
async function test(name,run){mock.events.length=0;try{await run();rows.push({name,pass:true,events:[...mock.events]});}catch(e){rows.push({name,pass:false,error:{name:e.name,message:e.message,stack:e.stack},events:[...mock.events]});}}
await test('ABI2 load entry accepted',async()=>{assert.equal(await driver.loadApi(),mock.default);});
for(const version of [undefined,0,1,3,-1,'2'])await test('inspect rejects ABI '+String(version),async()=>{
 const api=mock.makeApi();if(version===undefined)delete api.compiler_load_abi;else api.compiler_load_abi=()=>version;
 const r=await driver.inspect(main,{mode:'parse',api});assert.equal(r.status,'error');assert.equal(r.phase,'load');assert.match(r.diagnostic,/Unsupported compiler load ABI/);assert.equal(mock.events.length,0);
});
for(const name of ['f_source_header','f_complete_source','f_complete_seed','f_import_namespace_at','f_graph_trace','f_load_graph','f_source_located','f_source_completed'])await test('missing entry '+name,async()=>{
 const api=mock.makeApi();delete api[name];const r=await driver.inspect(main,{mode:'parse',api});assert.equal(r.status,'error');assert.equal(r.phase,'load');assert.ok(r.diagnostic.includes('Missing contextual compiler source API: '+name));assert.equal(mock.events.length,0);
});
await test('actual completed-result identity and physical aliases',async()=>{
 const r=driver.discoverSources(mock.makeApi(),main);assert.equal(r.loadTrace.result.error,'');
 assert.deepEqual(mock.events.filter(x=>x[0]==='complete').map(x=>x[1]),['leaf.bend','main.bend']);
 const retained=[];for(let n=r.sources;n.$==='Con';n=n.tail){let s=n.head;while(s.$==='FLocatedSource')s=s.source;assert.equal(s.$,'FCompletedSource');assert.ok(mock.completed.has(s.parsed));retained.push(s);}
 const aliases=retained.filter(s=>s.path.endsWith('/leaf.bend'));assert.equal(aliases.length,2);assert.equal(aliases[0].parsed,aliases[1].parsed);
 assert.equal(r.loadTrace.sources,r.sources);
});
await test('earlier completion failure prevents later missing-source traversal',async()=>{
 const r=await driver.inspect(path.join(fixtures,'reject-main.bend'),{mode:'parse',api:mock.makeApi()});assert.equal(r.phase,'parse');assert.match(r.diagnostic,/mock earlier failure/);assert.deepEqual(mock.events.filter(x=>x[0]==='complete').map(x=>x[1]),['reject.bend']);
});
await test('Base preparation uses graph only',async()=>{await driver.prepareBase(mock.makeApi());assert.deepEqual(mock.events,[['load-graph','Base']]);});
await test('ABI2 inspect check preserves checker result route',async()=>{const r=await driver.inspect(main,{api:mock.makeApi(),mode:'check'});assert.equal(r.status,'ok');assert.equal(r.phase,'check');assert.equal(r.checked,true);});
await test('checkup scans pinned line grammar and continues after failure',async()=>{
 const stdout=process.stdout.write,stderr=process.stderr.write;let a='',b='';const old=process.exitCode;
 process.stdout.write=function(x,...rest){a+=String(x);const cb=rest.find(x=>typeof x==='function');cb?.();return true;};process.stderr.write=function(x,...rest){b+=String(x);const cb=rest.find(x=>typeof x==='function');cb?.();return true;};
 let code;
 try{await driver.main([path.join(fixtures,'checkup.bend'),'--checkup']);code=process.exitCode;}finally{process.stdout.write=stdout;process.stderr.write=stderr;process.exitCode=old;}
 const expected=['./leaf.bend','./leaf.bend','./reject.bend',path.join(fixtures,'absolute.bend'),'./later.bend'];
 assert.deepEqual(a.split('\n').filter(x=>x.startsWith('--- ')),expected.map(x=>'--- '+x+' ---'));
 assert.equal(code,1);assert.equal((a.match(/41n\n/g)||[]).length,4);assert.equal((a.match(/exit 1\n/g)||[]).length,1);assert.ok((a+b).includes('mock earlier failure'));
 assert.ok(mock.events.some(x=>x[0]==='complete'&&x[1]==='later.bend'));
 rows.push({name:'checkup complete captured result',pass:true,actual:{stdout:a,stderr:b,exitCode:code}});
});
for(const args of [['--checkup','--check-only'],['--checkup','-o','out.js'],['--checkup','--','argument']])await test('existing CLI flag rejection '+args.join(' '),async()=>{await assert.rejects(()=>driver.main([main,...args]));assert.equal(mock.events.length,0);});
const report={kind:'phase22-loader-abi2-host-only-controls',complete:true,pass:rows.every(x=>x.pass),scope:'Actual private host functions driven by explicit mocked compiler protocol; no real Bend execution or compiler conformance claim.',rows,node:{version:process.version,args:process.execArgv}};
fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({pass:report.pass,rows:rows.length,failed:rows.filter(x=>!x.pass).map(x=>x.name)}));process.exitCode=report.pass?0:1;

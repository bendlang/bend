import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity,digest} from '../../development/workflow.mjs';
const [attemptArg,selectionArg,outArg]=process.argv.slice(2),attempt=fs.realpathSync(attemptArg),selection=fs.realpathSync(selectionArg),out=path.resolve(outArg);fs.mkdirSync(out);
const report={kind:'phase14-imported-law-public-api-controls',complete:false,pass:false,inputs:[import.meta.filename,process.execPath,selection].map(identity),rows:[]};const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});function array(v){const a=[];while(v?.$==='Con'){a.push(v.head);v=v.tail;}assert.equal(v?.$,'Nil');return a;}
function noMarker(root){const todo=[root],seen=new WeakSet();while(todo.length){const v=todo.pop();if(!v||typeof v!=='object'||seen.has(v))continue;seen.add(v);assert.notEqual(v.tag,'ImportLaw');assert.notEqual(v.kind,'ImportFill');for(const x of Object.values(v))if(x&&typeof x==='object')todo.push(x);}}
try{
 const m=await verifyAttempt(attempt);Object.assign(process.env,{BEND_TYPED_API:m.api.file,BEND_TYPED_RUNTIME:m.runtime.file,BEND_BASE:m.base.file,BEND_UPSTREAM:m.config.upstream});report.api=m.api;report.driver=identity(path.join(m.snapshot.root,'tools/typed-driver.mjs'));
 const D=await import(pathToFileURL(report.driver.file)),api=await D.loadApi(),seed=await D.prepareBase(api);report.seed={compilerSha256:seed.compilerSha256,baseSha256:seed.baseSha256,bookSha256:seed.bookSha256};
 const cases=JSON.parse(fs.readFileSync(selection));const chosen=cases.filter(x=>x.id?.includes('unsafe_law_')||x.id==='p14-safe-renamed-dependent'||x.id==='p14-safe-quantity');assert.equal(chosen.length,6);
 for(const row of chosen){
  const file=row.file??path.join(m.config.upstream,'tests',row.id),graph=D.discoverSources(api,file);graph.files.forEach(f=>report.inputs.push(identity(f)));
  const raw=list(array(graph.sources).map(s=>({$:'FSource',name:s.name,path:s.path,text:s.text}))),outputs=[];
  for(const [mode,sources,cached]of [['raw',raw,false],['handoff',graph.sources,false],['raw-seeded',raw,true],['handoff-seeded',graph.sources,true]]){
   const result=cached?api.f_load_graph_seed(graph.main,sources,seed.sourcePath,seed.sourceText,seed.book):api.f_load_graph(graph.main,sources);assert.equal(result.error,'');noMarker(result.book);const serialized=JSON.stringify(result),sha256=digest(serialized);if(outputs.length)assert.equal(sha256,outputs[0].sha256,'raw/handoff/seeded loaded result differs: '+row.id);else fs.writeFileSync(path.join(out,row.id.replaceAll('/','_')+'.loaded.json'),serialized+'\n');
   let names;if(!outputs.length){assert.equal(api.check_book(result.book),'');names=array(api.driver_bad_names(result.book));const specialized=api.specialize_book(result.book);assert.equal(specialized.error,'');noMarker(specialized.book);}else names=outputs[0].unsafeDefinitions;outputs.push({mode,sha256,checked:outputs.length===0?'direct':'exact-result-reuse',unsafeDefinitions:names,markerFreeLoaded:true,markerFreeSpecialized:outputs.length===0?'direct':'exact-result-reuse'});
  }
  report.rows.push({id:row.id,outputs});save();
 }
 const legacyFile=chosen.find(x=>x.id==='import/unsafe_law_own.bend');const file=path.join(m.config.upstream,'tests',legacyFile.id),graph=D.discoverSources(api,file),legacy=api.f_load(graph.main,graph.sources);assert.equal(legacy.error,'imported law fills require the canonical graph loader');report.legacy={supported:false,error:legacy.error,scope:'Old name-based f_load has no canonical dependency fill context; refuses unresolved markers instead of returning success.'};
 report.inputs.forEach(verifyIdentity);await verifyAttempt(attempt);report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1;}report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));

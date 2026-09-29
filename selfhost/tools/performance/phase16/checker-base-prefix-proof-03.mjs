import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'../../../..');
const attempt=path.join(root,'selfhost/build/phase16/checker-base-prefix-build-03');
const helper=await import(pathToFileURL(path.join(root,'selfhost/build/phase16/checker-base-prefix-source-03/project/tools/development/workflow.mjs')));
const {verifyAttempt,identity,verifyIdentity,validatedCache}=helper;
const m=await verifyAttempt(attempt),out=path.resolve(process.argv[2]);fs.mkdirSync(out);
const controlsFile=path.join(root,'selfhost/build/phase16/checker-base-prefix-controls-02/controls.json');
const controls=JSON.parse(fs.readFileSync(controlsFile));
const priorReport=path.join(root,'selfhost/build/phase12/normalizer-prefix-replay-01/report.json');
const history=JSON.parse(fs.readFileSync(priorReport));
const cacheIdentity=validatedCache(path.join(m.snapshot.root,'build/typed/cache'),m.api.file,m.base.file);
const cache=JSON.parse(fs.readFileSync(cacheIdentity.file));
const seed={...cache,sourceText:fs.readFileSync(m.base.file,'utf8')};
const inputs=[import.meta.filename,process.execPath,path.join(attempt,'attempt.json'),m.api.file,m.base.file,m.runtime.file,cacheIdentity.file,controlsFile,priorReport,
 history.original.request.file,history.original.session.file,path.join(root,'design/phase16/checker-base-prefix-proof.md'),
 ...fs.readdirSync(path.dirname(controls[0].file)).map(n=>path.join(path.dirname(controls[0].file),n))].map(identity);
for(const i of [history.original.request,history.original.session])verifyIdentity(i);
for(const key of Object.keys(process.env))if(key.startsWith('BEND_')||key==='NODE_OPTIONS')delete process.env[key];
Object.assign(process.env,{BEND_TYPED_API:m.api.file,BEND_BASE:m.base.file,BEND_TYPED_RUNTIME:m.runtime.file,BEND_UPSTREAM:m.config.upstream});
const host=await import(pathToFileURL(path.join(m.snapshot.root,'tools/typed-driver.mjs')));
const api=await host.loadApi();
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=xs=>{const a=[];for(;xs.$==='Con';xs=xs.tail)a.push(xs.head);assert.equal(xs.$,'Nil');return a;};
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const encoded=value=>JSON.stringify(value);
const equal=(a,b)=>encoded(a)===encoded(b);
const census=value=>{const stack=[value],seen=new WeakSet(),r={objects:0,KTerm:0,KDef:0,binders:0,locatedTerms:0};while(stack.length){const x=stack.pop();if(!x||typeof x!=='object'||seen.has(x))continue;seen.add(x);r.objects++;if(x.$==='KTerm'){r.KTerm++;r.binders+=['All','Lam','Bind'].includes(x.tag);r.locatedTerms+=x.originBegin>0;}if(x.$==='KDef')r.KDef++;for(const v of Object.values(x))if(v&&typeof v==='object')stack.push(v);}return r;};
const report={kind:'phase16-exact-base-prefix-law',complete:false,pass:false,installationEligible:false,inputs,priorSeedRejection:{report:identity(priorReport),original:history.original,sourceOverlap:false,reason:'Phase12 changed normalizer fallback, not graph Base reuse. Its matched-history resource gate remains required for later optimization.'},scope:'Finite exact term/range/list-order equality; actual fresh next; no production/cache change or speed claim.',rows:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 const freshBase=api.f_fresh_defs(seed.book,1),baseDefs=array(seed.book);
 report.base={idempotent:equal(freshBase.defs,seed.book),next:freshBase.next,census:census(seed.book),beforeSha256:sha(encoded(seed.book)),afterSha256:sha(encoded(freshBase.defs))};save();
 const graphs=[];
 for(const control of controls){
  const row={...control,pass:false};report.rows.push(row);
  try{
   row.stage="discover"; const graph=host.discoverSources(api,control.file,{seed}); row.stage="graph";
   const baseSource=array(graph.sources).find(s=>{while(s.$==='FLocatedSource')s=s.source;return s.name==='Base';})??{$:'FSource',name:'',path:'',text:''};
   row.seedMatch=api.f_seed_matches(baseSource,seed.sourcePath,seed.sourceText);
   row.wrongPathRejected=!api.f_seed_matches(baseSource,seed.sourcePath+'.missing',seed.sourceText);
   row.wrongTextRejected=!api.f_seed_matches(baseSource,seed.sourcePath,seed.sourceText+'\n');
   const raw=api.fs_load(graph.main,'',graph.sources,{$:'FGraph',book:list([]),error:'',done:list([])},list([]),{$:'FSeed',path:seed.sourcePath,book:seed.book,root:api.f_path_dir(api.f_source_path(api.f_graph_source(graph.main,graph.sources)))});
   const all=array(raw.book),prefix=all.slice(0,baseDefs.length),eligible=equal(list(prefix),seed.book);
   const ordinary=api.f_graph_result_at(raw,graph.sources),full=api.f_fresh_defs(raw.book,1);
   row.status=ordinary.error?'error':'ok';row.error=ordinary.error;row.eligible=eligible;row.raw=census(raw.book);row.full={next:full.next,sha256:sha(encoded(full.defs))};
   const publicResult=api.f_load_graph_seed(graph.main,graph.sources,seed.sourcePath,seed.sourceText,seed.book);
   row.authoritativeBookEqual=equal(ordinary.book,publicResult.book);
   row.authoritativeErrorEqual=ordinary.error===publicResult.error;
   row.publicError=publicResult.error;
   if(eligible){
    const suffix=list(all.slice(baseDefs.length)),tail=api.f_fresh_defs(suffix,freshBase.next),joined=list([...baseDefs,...array(tail.defs)]);
    row.suffix=census(suffix);row.split={next:tail.next,sha256:sha(encoded(joined))};row.exact=equal(full.defs,joined)&&full.next===tail.next;
    fs.writeFileSync(path.join(out,control.name+'.books.json'),JSON.stringify({raw:raw.book,ordinary,full,split:{book:joined,next:tail.next}})+'\n');
   }else{row.exact=true;row.fallback='No exact Base prefix: keep ordinary full freshening.';}
   row.pass=row.status===control.expected&&eligible===control.eligible&&row.exact&&row.authoritativeBookEqual&&row.authoritativeErrorEqual&&row.wrongPathRejected&&row.wrongTextRejected;
   graphs.push({control,graph,raw});
  }catch(e){row.status='error';row.error=String(e.message??e);row.phase=e.phase;row.discoveryRejected=row.stage==='discover';row.pass=control.expected==='error'&&control.discoveryError&&row.discoveryRejected&&e.phase==='parse';}
  save();
 }
 report.lawPass=report.base.idempotent&&report.rows.every(r=>r.pass);save();
 if(report.lawPass){
  const original=fs.readFileSync(m.api.file,'utf8'),names=['ffw_walk','f_alias_term','f_scope','f_pattern_sub','f_pattern_value','norm_join'],counts={};let transformed='const __counts = Object.create(null);\n'+original;
  for(const name of names){const re=new RegExp('function \\$'+name+'\\$\\(([^)]*)\\) \\{','g');const hits=[...transformed.matchAll(re)];assert.equal(hits.length,1,name);transformed=transformed.replace(re,(all,args)=>all+'\n  __counts['+JSON.stringify(name)+'] = (__counts['+JSON.stringify(name)+'] ?? 0) + 1;'+(name==='norm_join'?'\n  if (_a_0.$ === "Con") __counts.norm_join_copies = (__counts.norm_join_copies ?? 0) + 1;':''));}
  transformed+='\nexport const __probe = { reset(){ for(const k of Object.keys(__counts)) delete __counts[k]; }, read(){ return {...__counts}; } };\n';
  const file=path.join(out,'counted-api.mjs');fs.writeFileSync(file,transformed);const counted=await import(pathToFileURL(file));report.instrumentation={parent:m.api,derived:identity(file),functions:names,scope:'Actual entries into retained named functions; norm_join cons allocations at its nonempty branch. No inference about total constructor allocation or elapsed speed.'};report.operations=[];
  const run=(name,thunk,expected)=>{counted.__probe.reset();const value=thunk(counted.default);assert(equal(value,expected),name+' changed complete output');report.operations.push({name,counts:counted.__probe.read(),outputSha256:sha(encoded(value))});};
  run('Base freshening',a=>a.f_fresh_defs(seed.book,1),freshBase);
  for(const item of graphs){
   run(item.control.name+' ordinary graph result',a=>a.f_graph_result(item.raw),api.f_graph_result(item.raw));
   run(item.control.name+' graph load',a=>a.f_load_graph_seed(item.graph.main,item.graph.sources,seed.sourcePath,seed.sourceText,seed.book),api.f_load_graph_seed(item.graph.main,item.graph.sources,seed.sourcePath,seed.sourceText,seed.book));
  }
 }
 inputs.forEach(verifyIdentity);await verifyAttempt(attempt);report.complete=true;report.pass=report.lawPass;report.inputsVerified=true;
}catch(e){report.error=String(e.stack??e);}
report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,base:report.base,rows:report.rows.map(r=>({name:r.name,pass:r.pass,eligible:r.eligible,error:r.error,exact:r.exact})),error:report.error}));if(!report.pass)process.exitCode=1;

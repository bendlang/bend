import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [requestFile,out]=process.argv.slice(2),request=JSON.parse(fs.readFileSync(requestFile));
const identity=f=>({file:path.resolve(f),canonicalPath:fs.realpathSync(f),sha256:createHash('sha256').update(fs.readFileSync(f)).digest('hex')});
const verify=()=>request.inputs.forEach(i=>assert.deepEqual(identity(i.file),i));verify();
for(const k of Object.keys(process.env))if(k.startsWith('BEND_')||k==='NODE_OPTIONS')delete process.env[k];
Object.assign(process.env,{BEND_TYPED_API:request.originalApi,BEND_BASE:request.base,BEND_TYPED_RUNTIME:request.runtime,BEND_UPSTREAM:request.upstream});
const module=await import(pathToFileURL(request.countedApi)),api=module.default,host=await import(pathToFileURL(request.host));assert.equal(api.compiler_span_abi(),3);
const seed={...JSON.parse(fs.readFileSync(request.cache)),sourceText:fs.readFileSync(request.base,'utf8')};
host.validateSpanCache(seed,{compilerSha256:identity(request.originalApi).sha256,baseSha256:identity(request.base).sha256,sourcePath:fs.realpathSync(request.base),sourceText:seed.sourceText});
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=xs=>{const a=[];for(;xs.$==='Con';xs=xs.tail)a.push(xs.head);assert.equal(xs.$,'Nil');return a;};
const bookDigest=book=>{const h=createHash('sha256');let bytes=0,n=0;const add=x=>{bytes+=Buffer.byteLength(x);h.update(x);};for(;book.$==='Con';book=book.tail){add('{"$":"Con","head":');add(JSON.stringify(book.head));add(',"tail":');n++;}assert.equal(book.$,'Nil');add('{"$":"Nil"}');add('}'.repeat(n));return {sha256:h.digest('hex'),bytes,definitions:n};};
const census=book=>{const stack=[book],seen=new WeakSet(),r={objects:0,terms:0,definitions:0,binders:0,locatedTerms:0};while(stack.length){const x=stack.pop();if(!x||typeof x!=='object'||seen.has(x))continue;seen.add(x);r.objects++;if(x.$==='KTerm'){r.terms++;r.binders+=['All','Lam','Bind'].includes(x.tag);r.locatedTerms+=x.originBegin>0;}if(x.$==='KDef')r.definitions++;for(const v of Object.values(x))if(v&&typeof v==='object')stack.push(v);}return r;};
const report={kind:'phase16-serial-base-prefix-worker',mode:request.mode,complete:false,pass:false,inputs:request.inputs};
const save=()=>fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n');save();
try{
 const baseDigest=bookDigest(seed.book);report.baseDigest=baseDigest;
 let next=1;
 if(request.mode==='split'){
  let baseFresh=api.f_fresh_defs(seed.book,1);assert.deepEqual(bookDigest(baseFresh.defs),baseDigest);next=baseFresh.next;report.baseNext=next;baseFresh=null;
 }
 module.__probe.reset();
 let graph=host.discoverSources(api,request.source,{seed});
 let raw=api.fs_load(graph.main,'',graph.sources,{$:'FGraph',book:list([]),error:'',done:list([])},list([]),{$:'FSeed',path:seed.sourcePath,book:seed.book,root:api.f_path_dir(api.f_source_path(api.f_graph_source(graph.main,graph.sources)))});
 report.graphCounts=module.__probe.read();graph=null;
 let validated=api.f_graph_fresh_result(api.f_validate_result({$:'FResult',book:raw.book,error:raw.error,imports:list([])}));raw=null;
 report.error=validated.error;assert.equal(report.error,'');report.rawCensus=census(validated.book);
 let input=validated.book;validated=null;
 if(request.mode==='split'){
  const prefix=[],baseDefs=array(seed.book);for(let i=0;i<baseDefs.length;i++){assert.equal(input.$,'Con');prefix.push(input.head);input=input.tail;}assert.deepEqual(bookDigest(list(prefix)),baseDigest);report.suffixCensus=census(input);
 }
 module.__probe.reset();
 let fresh=api.f_fresh_defs(input,next);input=null;
 report.freshCounts=module.__probe.read();report.next=fresh.next;
 let output=fresh.defs;fresh=null;
 if(request.mode==='split')output=list([...array(seed.book),...array(output)]);
 report.output=bookDigest(output);report.outputCensus=census(output);output=null;
 verify();report.complete=true;report.pass=true;report.maxRssKiB=process.resourceUsage().maxRSS;report.affinity=fs.readFileSync('/proc/self/status','utf8').split('\n').find(x=>x.startsWith('Cpus_allowed_list:'));
}catch(e){report.errorDetails=String(e.stack??e);}
save();console.log(JSON.stringify({mode:report.mode,complete:report.complete,pass:report.pass,output:report.output,next:report.next,error:report.errorDetails}));if(!report.pass)process.exitCode=1;

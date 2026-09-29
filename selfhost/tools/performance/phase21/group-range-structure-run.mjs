// Complete-field R1 structural evidence. No compiler source or API extensions.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [planArg,outArg,candidateArg,baselineArg]=process.argv.slice(2);
const planFile=path.resolve(planArg),out=path.resolve(outArg),plan=JSON.parse(fs.readFileSync(planFile));
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const sha=x=>createHash('sha256').update(x).digest('hex'),id=file=>({file:path.resolve(file),sha256:sha(fs.readFileSync(file))});
const report={kind:'phase21-r1-complete-graph-structure',mode:candidateArg?'compare':'baseline',started:new Date().toISOString(),complete:false,pass:false,inputs:[id(import.meta.filename),id(planFile),...plan.inputs],rows:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const write=(name,x)=>fs.writeFileSync(path.join(out,name+'.json'),JSON.stringify(x,null,2)+'\n');
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const source=(name,file,text,begin)=>begin?{$:'FLocatedSource',source:{$:'FSource',name,path:file,text},begin,end:begin+text.length+1}:{$:'FSource',name,path:file,text};
const values=xs=>{const a=[];for(let x=xs;x.$==='Con';x=x.tail)a.push(x.head);return a;};
// Token-stream digest includes every field and its insertion order. Shared DAG
// children are visited at every serialized path, exactly as JSON serialization.
function digest(root){const h=createHash('sha256'),stack=[{value:root}],ranges={zero:0,nonzero:0},tags={};let nodes=0,buffer='';const emit=x=>{buffer+=x;if(buffer.length>32768){h.update(buffer);buffer='';}};while(stack.length){const task=stack.pop();if('token'in task){emit(task.token);continue;}const x=task.value;if(x===null||typeof x!=='object'){emit(JSON.stringify(x)??'undefined');continue;}nodes++;if('originBegin'in x){ranges[x.originBegin===0&&x.originEnd===0?'zero':'nonzero']++;const t=x.tag??x.$;tags[t]=(tags[t]??0)+1;}const keys=Object.keys(x);emit(Array.isArray(x)?'[':'{');stack.push({token:Array.isArray(x)?']':'}'});for(let i=keys.length-1;i>=0;i--){const k=keys[i];stack.push({value:x[k]});if(!Array.isArray(x))stack.push({token:JSON.stringify(k)+':'});if(i)stack.push({token:','});}}h.update(buffer);return{sha256:h.digest('hex'),nodes,ranges,tags};}
function difference(a,b){const ranges=[],nonrange=[],stack=[{a,b,path:'$'}];while(stack.length){const x=stack.pop();if(Object.is(x.a,x.b))continue;if(!x.a||!x.b||typeof x.a!=='object'||typeof x.b!=='object'){nonrange.push({path:x.path,parent:x.a,candidate:x.b});continue;}const ak=Object.keys(x.a),bk=Object.keys(x.b);if(JSON.stringify(ak)!==JSON.stringify(bk)){nonrange.push({path:x.path,parentKeys:ak,candidateKeys:bk});continue;}if('originBegin'in x.a&&(x.a.originBegin!==x.b.originBegin||x.a.originEnd!==x.b.originEnd))ranges.push({path:x.path,tag:x.a.tag??x.a.$,name:x.a.name,parent:[x.a.originBegin,x.a.originEnd],candidate:[x.b.originBegin,x.b.originEnd]});for(let i=ak.length-1;i>=0;i--){const k=ak[i];if(k!=='originBegin'&&k!=='originEnd')stack.push({a:x.a[k],b:x.b[k],path:x.path+'.'+k});}}return{ranges,nonrange};}
function selected(book,names){return values(book).filter(d=>names.has(d.name));}
function reference(B,text){const b=B.book_nil();try{B.parse_book(b,'',text,'',{});const defs={};for(const [name,d]of Object.entries(b.tlds))defs[name]={...d,T:B.term_lower(d.T),v:d.v?B.term_lower(d.v):d.v};const replacer=(key,value)=>key==='file'&&value&&typeof value==='object'?{representation:'source-file-handle',source:text,sha256:sha(text)}:value;return{error:'',book:JSON.parse(JSON.stringify(defs,replacer))};}catch(e){if(e?.$!=='Err')throw e;return{error:B.err_show(e)};}}
try{
 for(const x of report.inputs)assert.equal(id(x.file).sha256,x.sha256);
 const dirs=[plan.parentAttempt,...(candidateArg?[path.resolve(candidateArg)]:[])],images=[];
 for(const dir of dirs){const m=JSON.parse(fs.readFileSync(path.join(dir,'attempt.json'))),W=await import(pathToFileURL(path.join(m.snapshot.root,'tools/development/workflow.mjs')));await W.verifyAttempt(dir);report.inputs.push(id(path.join(dir,'attempt.json')),id(m.api.file));images.push({m,W,dir,K:(await import(pathToFileURL(m.api.file))).default});}
 assert.equal(id(images[0].m.api.file).sha256,plan.parentApiSha256);
 const baseFile=images[0].m.base.file,baseText=fs.readFileSync(baseFile,'utf8'),pin=path.join(images[0].m.config.upstream,'bend2/bend.ts'),B=await import(pathToFileURL(pin));report.inputs.push(id(baseFile),id(pin),id(process.execPath));
 for(const i of images)assert.equal(fs.readFileSync(i.m.base.file,'utf8'),baseText);
 const baseline=baselineArg?JSON.parse(fs.readFileSync(path.join(path.resolve(baselineArg),'report.json'))):null;if(baseline){assert(baseline.complete&&baseline.pass);report.inputs.push(id(path.join(path.resolve(baselineArg),'report.json')));}
 function record(name,mode,results,{large=false,names=null}={}){
  const measures=results.map(r=>({error:r.error,book:digest(r.book)})),row={name,mode,images:measures};
  if(baseline){const old=baseline.rows.find(x=>x.name===name&&x.mode===mode);assert(old,'missing baseline row');assert.deepEqual(measures[0],old.images[0]);}
  if(results.length===2){row.acceptanceSame=Boolean(results[0].error)===Boolean(results[1].error);row.diagnosticSame=results[0].error===results[1].error;row.differences=difference(results[0].book,results[1].book);row.pass=row.acceptanceSame&&row.differences.nonrange.length===0;}else row.pass=true;
  if(mode.includes('legacy'))row.legacyOriginsAbsent=measures.every(x=>x.book.ranges.nonzero===0);
  if(row.legacyOriginsAbsent===false)row.pass=false;
  if(!large)write(name+'-'+mode,{images:results});else if(names)write(name+'-'+mode+'-program',{images:results.map(r=>({error:r.error,definitions:selected(r.book,names)})),scope:'Only this persisted graph is a program projection; full book hashes and differences are in report.'});
  report.rows.push(row);save();
 }
 for(const c of plan.cases.filter(x=>!x.base)){const text=fs.readFileSync(c.file,'utf8');write(c.name+'-reference',reference(B,text));for(const indexed of [false,true]){const begin=indexed?plan.indexedStart:0,mode=indexed?'indexed':'legacy';record(c.name,'raw-'+mode,images.map(i=>indexed?i.K.f_parse_indexed(begin,text):i.K.f_parse(text)));record(c.name,'lowered-'+mode,images.map(i=>i.K.f_load_graph('main',list([source('main',c.file,text,begin)]))));}}
 const baseSource=source('Base',baseFile,baseText,1),seeds=images.map(i=>i.K.f_load_graph('Base',list([baseSource])));for(const x of seeds)assert.equal(x.error,'');
 record('Base','raw-indexed',images.map(i=>i.K.f_parse_indexed(1,baseText)),{large:true});record('Base','lowered-indexed',seeds,{large:true});
 for(const c of plan.cases.filter(x=>x.base)){const text=fs.readFileSync(c.file,'utf8'),begin=baseSource.end,raw=images.map(i=>i.K.f_parse_indexed(begin,text)),names=new Set(values(raw[0].book).map(x=>x.name));record(c.name,'raw-indexed',raw);record(c.name,'lowered-indexed',images.map((i,n)=>i.K.f_load_graph_seed('main',list([source('main',c.file,text,begin),baseSource]),baseFile,baseText,seeds[n].book)),{large:true,names});}
 for(const i of images)await i.W.verifyAttempt(i.dir);for(const x of report.inputs)assert.equal(id(x.file).sha256,x.sha256);
 report.complete=true;report.pass=report.rows.every(x=>x.pass);report.count=report.rows.length;
}catch(e){report.error=String(e.stack??e);}report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,count:report.rows.length,error:report.error}));if(!report.pass)process.exitCode=1;

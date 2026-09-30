import fs from 'node:fs';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [planFile,resultFile]=process.argv.slice(2),p=JSON.parse(fs.readFileSync(planFile));
const hash=x=>createHash('sha256').update(x).digest('hex');
const verify=()=>{for(const x of p.inputs)assert.equal(hash(fs.readFileSync(x.file)),x.sha256,x.file)};
const r={kind:p.kind,complete:false,pass:false,rows:[]};const save=()=>fs.writeFileSync(resultFile,JSON.stringify(r,null,2)+'\n');save();
try{
 verify();process.env.BEND_TYPED_API=p.baseline.api.file;process.env.BEND_TYPED_RUNTIME=p.baseline.runtime.file;process.env.BEND_BASE=p.baseline.base.file;
 for(const [name,entry] of Object.entries(p.drivers)){
  const D=await import(pathToFileURL(entry.file)),api=await D.loadApi();
  for(const mode of ['injected-observer','injected-mutation','default-mutation']){
   const saved={j_stops:api.j_stops,j_foreign_error:api.j_foreign_error,annotate_selected:api.annotate_selected};
   const events=[];let first=null;
   const hooks={j_stops:book=>{events.push('stops');const value=saved.j_stops(book);first??=value;return value},j_foreign_error:book=>{
    events.push('foreign');const error=saved.j_foreign_error(book);
    if(mode!=='injected-observer')Object.defineProperty(first,'p32Mutated',{value:true});
    return error;
   },annotate_selected:(book,defs,stops)=>{
    events.push(stops.p32Mutated?'annotate-mutated':'annotate-fresh');
    if(stops.p32Mutated)throw Error('P32_MUTATED_STOPS_REUSED');
    return saved.annotate_selected(book,defs,stops);
   }};
   let result;
   try{
    const options={mode:'library'};
    if(mode==='default-mutation')Object.assign(api,hooks);else options.api={...api,...hooks};
    result=await D.inspect(p.source.file,options);
   }finally{Object.assign(api,saved)}
   const shouldRefuse=name==='conditional'&&mode==='default-mutation';
   assert.equal(result.status,shouldRefuse?'error':'ok');
   assert.deepEqual(events,shouldRefuse?['stops','foreign','annotate-mutated']:['stops','foreign','stops','annotate-fresh']);
   if(shouldRefuse)assert.match(result.diagnostic,/P32_MUTATED_STOPS_REUSED/);
   const {code,...observation}=result;r.rows.push({driver:name,mode,events,observation,output:code?{sha256:hash(code),bytes:Buffer.byteLength(code)}:null});save();
  }
 }
 const positives=r.rows.filter(x=>x.output);assert.equal(new Set(positives.map(x=>x.output.sha256)).size,1);
 verify();r.complete=true;r.pass=true;
}catch(error){r.error=String(error?.stack??error);process.exitCode=1}
r.maxRssKiB=process.resourceUsage().maxRSS;save();console.log(JSON.stringify({complete:r.complete,pass:r.pass,rows:r.rows.length,error:r.error}));

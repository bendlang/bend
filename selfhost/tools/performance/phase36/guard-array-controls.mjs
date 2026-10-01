// A scalar root with a pure residual can still allocate native arrays: refuse
// proof sharing and preserve fill callbacks, mutation and reentry observations.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const [baseArg,outArg]=process.argv.slice(2);assert(baseArg&&outArg,'usage: guard-array-controls.mjs COHORT_DIR/array-refusal NEW_OUT');
const base=path.resolve(baseArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({path:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const mf=path.join(base,'derive.json'),meta=JSON.parse(fs.readFileSync(mf));assert.equal(meta.complete,true);
const report={kind:'phase36-checked-array-proof-refusal',complete:false,pass:false,inputs:[import.meta.filename,mf].map(identity),oracle:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));const modules=[];
try{
 for(const role of ['baseline','candidate']){const row=meta.variants[role],file=row.file??row.path;assert.equal(identity(file).sha256,row.sha256);report.inputs.push(identity(file));let text=fs.readFileSync(file,'utf8');
  if(role==='candidate'){const lines=text.split('\n'),at=lines.findIndex(line=>line.startsWith('G["guard.walk"]='));assert(at>=0);assert(!lines[at].includes('regionProofOpen('),'mixed array root must refuse scoped proof');
   assert(lines[at].includes('/* private scalar tree */'),'refusal must retain existing private tree optimization');
   text+='\nexport function guardState(){return regionProof!==null;}\n';
  }else text+='\nexport function guardState(){return false;}\n';
  const output=path.join(out,role+'-diagnostic.mjs');fs.writeFileSync(output,text,{flag:'wx'});report.inputs.push(identity(output));modules.push(await import(pathToFileURL(output)));
 }
 for(const depth of [0n,1n,2n,5n])for(const value of [0,1,3,100]){const leaves=2**Number(depth),expected=leaves*value+3*(leaves-1),results=modules.map(m=>m.default['guard.walk'](depth,value));for(const r of results)assert.equal(r,expected);report.oracle.push({depth:depth+'n',value,expected,results});}
 for(const mode of ['fill','fill-mutation-reentry','fill-throw','safe-integer']){
  const observations=modules.map(m=>{const events=[],fill=Array.prototype.fill,safe=Number.isSafeInteger,mix=m.G['guard.mix'],code=mix.code;let busy=false,value,error;
   function body(){events.push(['hook',m.guardState()]);assert.equal(m.guardState(),false,'native array hook inherited proof');
    if(mode==='fill-throw')throw Error('fill sentinel');
    if(mode==='fill-mutation-reentry'&&!busy){busy=true;mix.code=()=>37;events.push(['nested',m.default['guard.walk'](1n,1)]);}
   }
   try{if(mode==='safe-integer')Number.isSafeInteger=function(n){body();return safe(n);};else Array.prototype.fill=function(...args){body();return Reflect.apply(fill,this,args);};
    value=m.default['guard.walk'](1n,3);
   }catch(e){error={name:e.name,message:e.message};}
   finally{Array.prototype.fill=fill;Number.isSafeInteger=safe;mix.code=code;}
   assert(events.length>0,'host callback witness must execute');if(mode==='fill-mutation-reentry')assert(events.some(x=>x[0]==='nested'&&x[1]===37),'reentry must observe replacement mix');
   assert.equal(m.guardState(),false);return{value,error,events};
  });assert.deepEqual(observations[1],observations[0],mode);report.boundaries.push({mode,observations});
 }
 for(const row of report.inputs)assert.deepEqual(identity(row.path),row);report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,boundaries:report.boundaries.length,error:report.error}));

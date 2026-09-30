// Independent ordered semantic controls on the disposable edit-row prototype.
// Usage: node review-private-prototype.mjs BASELINE PRIVATE NEW_OUTPUT_DIRECTORY
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [oldArgument,newArgument,outArgument,entryMode='private']=process.argv.slice(2);
assert.ok(oldArgument&&newArgument&&outArgument,'usage: review-private-prototype.mjs BASELINE PRIVATE NEW_OUT');
assert.ok(['private','public'].includes(entryMode));
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex'),identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const json=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const save=(name,x)=>fs.writeFileSync(path.join(out,name),json(x),{flag:'wx'});
const report={kind:'phase30-independent-private-prototype-controls',complete:false,pass:false,node:process.version,entryMode,
  inputs:[identity(oldArgument),identity(newArgument),identity(import.meta.filename)],
  scope:'Original emitted edit-distance code vs disposable fixed private chain. Immutable compiled G.cell/f1..f4; Array.get/set and umin/b2u remain observable. No compiler admission or timing claim.',observations:[],knownLimitations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-private-prototype.mjs'));
try{
  const old=await import(pathToFileURL(path.resolve(oldArgument))),next=await import(pathToFileURL(path.resolve(newArgument)));
  const host=(arity,code)=>({arity,code,env:null,bound:[]});
  const key=k=>typeof k==='symbol'?k.toString():String(k);
  const descriptor=f=>({keys:Object.keys(f),arity:f.arity,env:f.env,bound:[...f.bound],codeType:typeof f.code});
  const normalize=v=>v?.code?descriptor(v):v;
  const modes={
    plain:()=>({a:['A','B','P','C']}),
    frozen:()=>({a:Object.freeze(['A','B','P','C'])}),
    named:events=>({get a(){events.push('record.a');return undefined},get b(){events.push('record.b');return 'B'},get prev(){events.push('record.prev');return 'P'},get cur(){events.push('record.cur');return 'C'}}),
    getter:events=>({get a(){events.push('record.a');return ['A','B','P','C']}}),
    proxy:events=>({a:new Proxy(['A','B','P','C'],{get(t,k,r){events.push(['vector.get',key(k)]);return Reflect.get(t,k,r)},has(t,k){events.push(['vector.has',key(k)]);return Reflect.has(t,k)}})}),
    sparse:()=>{const a=[];a.length=4;a[1]='B';a[2]='P';a[3]='C';return {a}},
    'slice-throw':events=>({a:{length:4,slice(){events.push('slice');throw Error('slice sentinel')}}}),
    'field-throw':events=>{const a=['A','B','P','C'];Object.defineProperty(a,2,{get(){events.push('field2');throw Error('field sentinel')}});return {a}},
    'zero-no-slice':events=>({a:{get length(){events.push('length');return 0},get slice(){throw Error('slice unexpectedly read')}}}),
    'length-change':events=>{let reads=0;return {a:{0:'A',1:'B',2:'P',3:'C',get length(){const n=++reads===1?4:3;events.push(['source.length',n]);return n},slice:Array.prototype.slice}}},
  };
  for(const n of [0,1,2,3,4,5,6])modes['custom-slice-'+n]=events=>({a:{get length(){events.push('source.length');return 4},get slice(){events.push('source.slice');return function(){events.push(['slice.receiver',this!==undefined]);return ['A','B','P','C',11,13].slice(0,n)}}}});
  modes['copied-proxy']=events=>({a:{length:4,slice(){
    events.push('slice');
    return new Proxy(['A','B','P','C'],{get(t,k,r){events.push(['copy.get',key(k)]);return Reflect.get(t,k,r)}});
  }}});
  modes['copied-changing-length']=events=>{const sizes=[3,5,5,1];return {a:{length:4,slice(){return new Proxy(['A','B','P','C',11],{get(t,k,r){if(k==='length'){const n=sizes.shift()??5;events.push(['copy.length',n]);return n}return Reflect.get(t,k,r)}})}}}};
  const run=(module,privateEntry,mode,fail='none',tupleMode='plain')=>{
    const events=[];let reads=0;
    module.G['Array.get']=host(3,([,array,index])=>{
      events.push(['Array.get',array,index]);reads++;
      if(fail==='read'+reads)throw Error('read '+reads+' sentinel');
      const values=[array,reads+2];
      if(tupleMode==='proxy')return new Proxy(values,{get(t,k,r){events.push(['tuple'+reads+'.get',key(k)]);return Reflect.get(t,k,r)}});
      if(tupleMode==='first-throws')return {get 0(){events.push('tuple.first');throw Error('tuple sentinel')},get 1(){events.push('tuple.second');return 4}};
      return values;
    });
    module.G['Array.set']=host(4,([,array,index,value])=>{events.push(['Array.set',array,index,value]);if(fail==='set')throw Error('set sentinel');return {stored:[array,index,value]}});
    module.G.b2u=host(1,([b])=>{events.push(['b2u',b]);if(fail==='b2u')throw Error('b2u sentinel');return Number(b)});
    module.G.umin=host(2,([a,b])=>{events.push(['umin',a,b]);if(fail==='umin')throw Error('umin sentinel');return Math.min(a,b)});
    try{
      const value=mode(events),raw=privateEntry&&entryMode==='private'?module.call(host(0,()=>module.P_cell(0,1,value)),[]):module.call(module.call(module.G.cell,[0,1]),[value]);
      return {events,result:normalize(raw)};
    }catch(error){return {events,error:{name:error.name,message:error.message}}}
  };
  for(const [name,mode]of Object.entries(modes)){
    const a=run(old,false,mode),b=run(next,true,mode);
    report.currentComparison={name,baseline:a,candidate:b};
    assert.deepEqual(b,a,name);report.observations.push({name,transcript:a});delete report.currentComparison;
  }
  for(const fail of ['read1','read2','read3','read4','set','b2u','umin']){
    const a=run(old,false,modes.plain,fail),b=run(next,true,modes.plain,fail);assert.deepEqual(b,a,fail);report.observations.push({name:fail,transcript:a});
  }
  for(const tupleMode of ['proxy','first-throws']){
    const a=run(old,false,modes.plain,'none',tupleMode),b=run(next,true,modes.plain,'none',tupleMode);assert.deepEqual(b,a,tupleMode);report.observations.push({name:'tuple-'+tupleMode,transcript:a});
  }
  // All ordinary public chain descriptors are still byte-identical definitions.
  for(const name of ['cell','cell.f1','cell.f2','cell.f3','cell.f4']){
    assert.deepEqual(descriptor(next.G[name]),descriptor(old.G[name]),name+' public shape');
    const sameCode=sha(next.G[name].code.toString())===sha(old.G[name].code.toString());
    if(entryMode==='private')assert.ok(sameCode,name+' public code unchanged by private-only prototype');
    report.observations.push({name:'public-'+name,descriptor:descriptor(old.G[name]),baselineCodeSha256:sha(old.G[name].code.toString()),candidateCodeSha256:sha(next.G[name].code.toString()),sameCode});
  }
  // The unguarded disposable prototype intentionally does not promise this.
  // Record the concrete difference so it cannot become a production assumption.
  {
    const altered=host(2,()=>host(1,()=>({$: 'Dp',a:['RA','RB','RP','RC']}))),oldSaved=old.G.cell,newSaved=next.G.cell;
    old.G.cell=altered;next.G.cell=altered;
    const observe=module=>{try{return {result:module.default.row(1n,0,1,{a:['A','B','P','C']})}}catch(error){return {error:{name:error.name,message:error.message}}}};
    const a=observe(old),b=observe(next);
    report.knownLimitations.push({name:'ordinary-G-cell-replacement',baseline:a,candidate:b,equal:json(a)===json(b)});
    old.G.cell=oldSaved;next.G.cell=newSaved;
  }
  report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
save('report.json',report);console.log(json({complete:report.complete,pass:report.pass,observations:report.observations.length,knownLimitations:report.knownLimitations,error:report.error}));

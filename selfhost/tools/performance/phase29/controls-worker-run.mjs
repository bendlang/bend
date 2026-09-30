// Same checked Nat-loop source, scalar oracles and original public ABI.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [configFile,outArgument]=process.argv.slice(2);
assert.ok(configFile&&outArgument,'usage: controls-worker-run.mjs CONFIG NEW_OUT');
const config=JSON.parse(fs.readFileSync(configFile)),out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const encode=x=>typeof x==='bigint'?{$bigint:String(x)}:typeof x==='number'&&!Number.isFinite(x)?{$number:String(x)}:Object.is(x,-0)?{$number:'-0'}:x;
const save=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,(_,x)=>encode(x),2)+'\n',{flag:'wx'});
const report={kind:'phase29-independent-checked-worker-controls',complete:false,pass:false,node:process.version,args:process.execArgv,
  affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(x=>x.startsWith('Cpus_allowed_list:')),
  inputs:[identity(configFile),identity(import.meta.filename),...Object.values(config.modules).map(identity)],
  scope:'Same checked source, independent scalar oracles, public partials and observable ordinary host callbacks. No timing.',scalarChecks:0,observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls-worker-run.mjs'));save(path.join(out,'config.json'),config);
try{
  const modules={};for(const [name,file]of Object.entries(config.modules))modules[name]=await import(pathToFileURL(file));
  assert.deepEqual(Object.keys(modules).sort(),['baseline','candidate','upstream']);
  const check=(name,args,want)=>{for(const [side,module]of Object.entries(modules)){const got=module.default[name](...args);assert.ok(Object.is(got,want),side+' '+name+' '+JSON.stringify(args.map(encode))+' expected '+JSON.stringify(encode(want))+' got '+JSON.stringify(encode(got)));report.scalarChecks++;}};
  const counts=[0,1,2,3,4,10,31,64,127],values=[0,1,17,2147483648,4294967295];
  for(const n of counts)for(const x of values){
    check('count',[BigInt(n),x],(x+n)>>>0);check('capture',[BigInt(n),x],(x+n)>>>0);check('at_zero',[BigInt(n),x],(x+n)>>>0);
    check('non_tail',[BigInt(n),x],(x+n)>>>0);check('changed_counter',[BigInt(n),x],(x+Math.ceil(n/2))>>>0);
    for(const y of values){
      check('swap',[BigInt(n),x,y],n%2?(Math.imul(y,1000)+x)>>>0:(Math.imul(x,1000)+y)>>>0);
      let a=x,b=y;for(let i=0;i<n;i++)[a,b]=[(a+b)>>>0,a];check('shifted',[BigInt(n),x,y],(Math.imul(a,1000)+b)>>>0);
      check('transition',[BigInt(n),x,y],(x+y+2*n)>>>0);
    }
    for(const b of [true,false])check('bool_carried',[BigInt(n),b,x],(x+n+((n%2?!b:b)?1:0))>>>0);
    for(const m of [0n,1n,4294967295n,281474976710400n])check('nat_carried',[BigInt(n),m,x],n?Number((m+BigInt(n)-1n)&0xffffffffn):x);
  }
  for(const n of counts)for(const x of [-Infinity,-1,-0,0,2**-149,0.5,65536,Infinity,NaN]){
    let want=Math.fround(x);for(let i=0;i<n;i++)want=Math.fround(want+Math.fround(0.5));check('float_carried',[BigInt(n),Math.fround(x)],want);
  }
  check('count',[50000n,4294942295],24999);
  check('swap',[50000n,17,19],17019);
  // Ordinary host callbacks are observable. Native primitive bindings stay fixed.
  const transcripts={};
  for(const side of ['baseline','candidate']){
    const {default:api,G,call}=modules[side],trace=[],host=(arity,code)=>({arity,code,env:null,bound:[]});
    const note=(name,value)=>trace.push({name,value});
    const describe=f=>({keys:Object.keys(f),arity:f.arity,env:f.env,bound:[...f.bound],codeType:typeof f.code});
    for(const n of [0n,1n,2n]){
      const partial=api.count(n);note('count-partial-'+n,describe(partial));note('count-result-'+n,call(partial,[13]));note('count-bound-after-'+n,[...partial.bound]);
    }
    const captured=[];G.remember=host(1,([f])=>{captured.push(f);return call(f,[{$:'Unit',a:[]}]);});
    const partial=api.capture(4n);assert.equal(captured.length,0,'partial must not execute body');
    assert.equal(call(partial,[10]),14);note('captured-closure-values',captured.map(f=>call(f,[{$:'Unit',a:[]}])));
    assert.deepEqual(captured.map(f=>call(f,[{$:'Unit',a:[]}])),[10,11,12,13],'fresh aliases per iteration');
    captured.length=0;const zero=api.at_zero(0n);assert.equal(captured.length,0,'zero branch body waits for residual argument');assert.equal(call(zero,[23]),23);assert.equal(captured.length,1);note('zero-partial',describe(zero));
    for(const fail of ['none','left','right']){
      const events=[];G.step_left=host(1,([x])=>{events.push(['left',x]);if(fail==='left')throw Error('left sentinel');return (x+1)>>>0;});
      G.step_right=host(1,([x])=>{events.push(['right',x]);if(fail==='right')throw Error('right sentinel');return (x+1)>>>0;});
      if(fail==='none'){assert.equal(api.transition(3n,5,7),18);assert.deepEqual(events,[['left',5],['right',7],['left',6],['right',8],['left',7],['right',9]]);}
      else{assert.throws(()=>api.transition(3n,5,7),new RegExp('^Error: '+fail+' sentinel$'));assert.deepEqual(events,fail==='left'?[['left',5]]:[['left',5],['right',7]]);}
      note('transition-'+fail,events);
    }
    transcripts[side]=trace;
  }
  assert.deepEqual(transcripts.candidate,transcripts.baseline,'unchanged public descriptor and demand transcript');report.observations=transcripts.candidate;
  report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
save(path.join(out,'report.json'),report);console.log(JSON.stringify({complete:report.complete,pass:report.pass,scalarChecks:report.scalarChecks,observations:report.observations.length,error:report.error}));

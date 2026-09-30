// Selected-arm prebinding controls through the production j_library entry point.
// Synthetic KDefs exercise emission/runtime semantics, not frontend admission.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';

const [configFile,outArgument]=process.argv.slice(2);
assert.ok(configFile&&outArgument,'usage: test-arm.mjs CONFIG NEW_OUT');
const config=JSON.parse(fs.readFileSync(configFile)),candidate=config.candidate??config,out=path.resolve(outArgument);
fs.mkdirSync(out);
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const json=value=>JSON.stringify(value,(_,x)=>typeof x==='bigint'?String(x)+'n':x,2)+'\n';
const save=(file,value)=>fs.writeFileSync(file,json(value),{flag:'wx'});
const report={kind:'phase27-selected-arm-controls',complete:false,pass:false,node:process.version,args:process.execArgv,affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(x=>x.startsWith('Cpus_allowed_list:')),inputs:[...['api','driver','runtime','base'].map(k=>identity(candidate[k])),identity(import.meta.filename)],observations:[],scope:'Synthetic KDefs emitted using unchanged production j_library; not checked source or a new production export. No timing claim.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-test-arm.mjs'));save(path.join(out,'config.json'),config);

try{
  for(const k of Object.keys(process.env))if(k.startsWith('BEND_'))delete process.env[k];
  process.env.BEND_TYPED_API=candidate.api;process.env.BEND_TYPED_RUNTIME=candidate.runtime;process.env.BEND_BASE=candidate.base;
  const {loadApi}=await import(pathToFileURL(candidate.driver));const api=await loadApi();
  const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
  const t=(tag,name='',kids=[],id=0,quant=0,removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0});
  const variable=id=>t('Var','',[],id),lam=(id,body,q=2)=>t('Lam','',[body],id,q),all=(id,a,b,q=2,name='')=>t('All',name,[a,b],id,q);
  const ref=n=>t('Ref',n),app=(f,x)=>t('App','',[f,x]),ctr=(n,xs)=>t('Ctr',n,xs),mat=(n,arm,rest=t('Efq'))=>t('Mat',n,[arm,rest]);
  const nat=t('ADT','Nat'),record=t('ADT','ArmRecord'),recordFn=t('ADT','ArmFunction'),erasedRecord=t('ADT','ArmErased'),zeroRecord=t('ADT','ArmZero');
  const out4=t('ADT','ArmOutput'),out5=t('ADT','ArmCaptured'),out2=t('ADT','ArmPair');
  const def=(name,value,typ,kind='Def',ctors=[])=>({$:'KDef',name,kind,arity:0,templates:0,typ,value,ctors:list(ctors),native:false,unsafe:false});
  const telescope=(ids,types,result,quantities=[])=>ids.reduceRight((rest,id,i)=>all(id,types[i],rest,quantities[i]??2,'field'+i),result);
  const datatype=(name,constructor,types,quantities=[])=>{
    const typ=t('ADT',name),ids=types.map((_,i)=>1000+i),c={...def(constructor,t('Absent'),telescope(ids,types,typ,quantities),'Ctr'),arity:types.length};
    return def(name,t('Absent'),t('Typ'),'ADT',[c]);
  };
  const fnType=all(800,nat,nat),armType=telescope([1,2,3,4],[nat,nat,nat,nat],out4),directType=all(80,record,all(81,nat,all(82,nat,out4)));
  const arm=(body=ctr('ArmOut',[1,2,3,4].map(variable)))=>[1,2,3,4].reduceRight((rest,id)=>lam(id,rest),body);
  const rows=[datatype('ArmRecord','ArmRec',[nat,nat]),datatype('ArmFunction','ArmFun',[fnType,nat]),datatype('ArmErased','ArmEr',[nat,nat],[0,2]),datatype('ArmZero','ArmZ',[]),datatype('ArmOutput','ArmOut',[nat,nat,nat,nat]),datatype('ArmCaptured','ArmCap',[nat,nat,nat,nat,nat]),datatype('ArmPair','ArmPairOut',[nat,nat]),
    def('direct',mat('ArmRec',arm()),directType),
    def('annotated',mat('ArmRec',t('Ann','',[arm(),armType])),directType),
    def('captured',lam(90,mat('ArmRec',arm(ctr('ArmCap',[90,1,2,3,4].map(variable))))),all(90,nat,all(80,record,all(81,nat,all(82,nat,out5))))),
    def('lateEffect',mat('ArmRec',arm(app(ref('tick'),variable(4)))),all(80,record,all(81,nat,all(82,nat,nat)))),
    def('tick',t('Absent'),all(900,nat,nat)),
    def('factory',t('Absent'),all(901,nat,armType)),
    def('effectfulArm',mat('ArmRec',app(ref('factory'),ctr('Zero',[]))),directType),
    def('erased',mat('ArmEr',arm()),all(80,erasedRecord,all(81,nat,all(82,nat,out4)))),
    def('etaShort',mat('ArmFun',lam(1,variable(1))),all(80,recordFn,nat)),
    def('functionResult',mat('ArmFun',lam(1,lam(2,lam(3,variable(1))))),all(80,recordFn,all(81,nat,fnType))),
    def('equalArity',mat('ArmRec',lam(1,lam(2,ctr('ArmPairOut',[variable(1),variable(2)])))),all(80,record,out2)),
    def('zeroFields',mat('ArmZ',lam(3,lam(4,ctr('ArmPairOut',[variable(3),variable(4)])))),all(80,zeroRecord,all(81,nat,all(82,nat,out2)))),
  ];
  const liftIds=Array.from({length:35},(_,i)=>200+i),liftBody=liftIds.reduceRight((rest,id)=>lam(id,rest),variable(200));
  rows.push(def('lifted',mat('ArmRec',liftBody),all(80,record,telescope(liftIds.slice(2),liftIds.slice(2).map(()=>nat),nat))));
  save(path.join(out,'book.json'),rows);
  const program=api.j_library(list(rows)),runtime=fs.readFileSync(candidate.runtime,'utf8'),moduleFile=path.join(out,'program.mjs');
  fs.writeFileSync(moduleFile,runtime+'\n'+program,{flag:'wx'});report.module=identity(moduleFile);report.runtimePrefixSha256=sha(runtime);
  const {default:a,G,call}=await import(pathToFileURL(moduleFile));
  const host=(arity,code,env=null,bound=[])=>({arity,code,env,bound});
  const recordValue=values=>({$:'ArmRec',a:values}),output=values=>({$:'ArmOut',a:values});
  const descriptor=f=>({keys:Object.keys(f),arity:f.arity,env:f.env,bound:[...f.bound],boundOwnIndices:Array.from({length:f.bound.length},(_,i)=>Object.hasOwn(f.bound,i)),codeType:typeof f.code,codeName:f.code.name,codeLength:f.code.length,codeSha256:sha(f.code.toString()),attributes:Object.fromEntries(Object.entries(Object.getOwnPropertyDescriptors(f)).map(([k,d])=>[k,{enumerable:d.enumerable,writable:d.writable,configurable:d.configurable}]))});
  const note=(name,value)=>report.observations.push({name,value});
  const equal=(name,actual,expected)=>{assert.deepEqual(actual,expected,name);note(name,actual);};
  const expectError=(name,run,message)=>{let error;try{run();}catch(e){error=e;}assert.ok(error,name+' must throw');if(message)assert.equal(error.message,message);const value={name:error.name,message:error.message};note(name,value);return value;};
  for(const name of ['direct','annotated','captured','lateEffect','effectfulArm','erased','etaShort','functionResult','equalArity','zeroFields','lifted']){
    assert.equal(G[name].arity,1,name+' preserves public matcher/leading-lambda arity');
    const statement=program.split('\n').find(line=>line.startsWith('G['+JSON.stringify(name)+']='));
    assert.ok(statement,name+' emitted assignment');
    (report.emission??=[]).push({name,prebound:statement.includes('/* prebind-arm */'),bytes:Buffer.byteLength(statement)});
  }
  const originalFields=[7n,9n],p=a.direct(recordValue(originalFields));
  equal('direct-descriptor-arity',p.arity,4);equal('direct-descriptor-env',p.env,null);equal('direct-descriptor-bound',p.bound,[7n,9n]);assert.notEqual(p.bound,originalFields);note('direct-descriptor',descriptor(p));
  originalFields[0]=700n;equal('field-snapshot-owned',p.bound,[7n,9n]);
  const q=call(p,[11n]);assert.equal(q.code,p.code);assert.equal(q.env,p.env);assert.notEqual(q.bound,p.bound);equal('partial-original-unmodified',p.bound,[7n,9n]);equal('partial-next-bound',q.bound,[7n,9n,11n]);
  equal('staged-field-argument-order',call(q,[13n]),output([7n,9n,11n,13n]));
  equal('saturated-field-argument-order',a.direct(recordValue([2n,3n]),5n,7n),output([2n,3n,5n,7n]));
  const invoke=host(2,([f,x])=>call(f,[x]));equal('higher-order-partial',call(invoke,[q,17n]),output([7n,9n,11n,17n]));
  const captured=a.captured(23n),cp=call(captured,[recordValue([29n,31n])]);equal('captured-env-null',cp.env,null);note('captured-descriptor',descriptor(cp));equal('captured-value-order',call(cp,[37n,41n]),{$:'ArmCap',a:[23n,29n,31n,37n,41n]});
  equal('annotated-arm',a.annotated(recordValue([43n,47n]),53n,59n),output([43n,47n,53n,59n]));
  const calls=[],f=host(1,function([x]){calls.push(x);return x+this.delta},{delta:1n}),rf={$:'ArmFun',a:[f,61n]};
  equal('eta-short-overapplication',a.etaShort(rf),62n);equal('function-result-overapplication',a.functionResult(rf,67n,71n),72n);equal('function-field-called-values',calls,[61n,71n]);
  const ticks=[];G.tick=host(1,([x])=>{ticks.push(x);return x;});const delayed=a.lateEffect(recordValue([1n,2n]));equal('partial-does-not-run-body',ticks,[]);const delayed2=call(delayed,[3n]);equal('second-partial-does-not-run-body',ticks,[]);equal('late-body-result',call(delayed2,[4n]),4n);equal('late-body-once',ticks,[4n]);
  const factories=[];const factoryEnv={label:'factory'};G.factory=host(1,([x])=>{factories.push(x);return host(4,function(xs){assert.equal(this,factoryEnv);return output(xs);},factoryEnv);});
  const effect=a.effectfulArm(recordValue([73n,79n]));equal('effectful-arm-evaluated-at-match',factories,[0n]);assert.equal(effect.env,factoryEnv);equal('effectful-arm-descriptor',effect.arity,4);equal('effectful-arm-result',call(effect,[83n,89n]),output([73n,79n,83n,89n]));
  equal('erased-slot-suppressed',a.erased({$:'ArmEr',a:[97n,101n]},103n,107n),output([null,101n,103n,107n]));
  equal('equal-arity-arm',a.equalArity(recordValue([109n,113n])),{$:'ArmPairOut',a:[109n,113n]});
  const zero=a.zeroFields({$:'ArmZ',a:[]});equal('zero-field-descriptor',zero.arity,2);equal('zero-field-result',call(zero,[127n,131n]),{$:'ArmPairOut',a:[127n,131n]});
  const lp=a.lifted(recordValue([137n,139n]));equal('lifted-field-and-argument-order',call(lp,Array.from({length:33},(_,i)=>BigInt(149+i))),137n);note('lifted-descriptor',descriptor(lp));
  equal('trusted-foreign-tag',a.direct({$:'DifferentTag',a:[151n,157n]},163n,167n),output([151n,157n,163n,167n]));
  const namedReads=[],named={get field0(){namedReads.push(0);return 173n},get field1(){namedReads.push(1);return 179n}};equal('named-fields-result',a.direct(named,181n,191n),output([173n,179n,181n,191n]));equal('named-fields-order',namedReads,[0,1]);
  const reads=[],fields=[];for(let i=0;i<2;i++)Object.defineProperty(fields,i,{get(){reads.push(i);return BigInt(i+193)},enumerable:true});
  const gp=a.direct(recordValue(fields));equal('field-getter-order',reads,[0,1]);equal('field-getter-snapshot',gp.bound,[193n,194n]);
  const frozen=Object.freeze([197n,199n]);equal('frozen-field-vector',a.direct(recordValue(frozen),211n,223n),output([197n,199n,211n,223n]));
  const sparse=[];sparse.length=2;sparse[1]=227n;const sp=a.direct(recordValue(sparse));equal('sparse-snapshot-holes',[Object.hasOwn(sp.bound,0),Object.hasOwn(sp.bound,1)],[false,true]);equal('sparse-snapshot-result',call(sp,[229n,233n]),output([undefined,227n,229n,233n]));
  for(const count of [0,1,2,3,4,5]){
    const values=Array.from({length:count},(_,i)=>BigInt(239+i));
    if(count>4){expectError('long-fields-overapply',()=>a.direct(recordValue(values)));continue;}
    const got=a.direct(recordValue(values));
    if(count<4){equal('length-'+count+'-descriptor-bound',got.bound,values);equal('length-'+count+'-result',call(got,Array.from({length:4-count},(_,i)=>BigInt(251+i))),output([...values,...Array.from({length:4-count},(_,i)=>BigInt(251+i))]));}
    else equal('length-four-eager-saturation',got,output(values));
  }
  // The existing slice protocol is observable even on trusted foreign records.
  for(const count of [0,1,2,4,5]){
    const trace=[],values=Array.from({length:count},(_,i)=>BigInt(263+i));
    const supplied={get length(){trace.push('source.length');return 2},get slice(){trace.push('source.slice');return function(...args){trace.push(['slice-call-this',this===supplied,'args',args.length]);return values;}}};
    if(count===5){expectError('custom-slice-five-overapply',()=>a.direct(recordValue(supplied)));note('custom-slice-five-trace',trace);}
    else{const got=a.direct(recordValue(supplied));if(count<4){assert.equal(got.bound,values);equal('custom-slice-'+count+'-result',call(got,Array.from({length:4-count},()=>271n)),output([...values,...Array.from({length:4-count},()=>271n)]));}else equal('custom-slice-four-result',got,output(values));note('custom-slice-'+count+'-trace',trace);}
  }
  for(const mode of ['array-proxy','returned-vector-proxy','throwing-slice','throwing-field','zero-length-no-slice']){
    const trace=[],key=k=>typeof k==='symbol'?k.toString():String(k);let input;
    if(mode==='array-proxy')input=new Proxy([277n,281n],{get(t,k,r){trace.push(['get',key(k)]);return Reflect.get(t,k,r)},has(t,k){trace.push(['has',key(k)]);return Reflect.has(t,k)}});
    if(mode==='returned-vector-proxy'){
      const result=new Proxy([283n,293n],{get(t,k,r){trace.push(['result-get',key(k)]);return Reflect.get(t,k,r)}});
      input={get length(){trace.push('source.length');return 2},slice(){trace.push('source.slice-call');return result;}};
    }
    if(mode==='throwing-slice')input={length:2,slice(){trace.push('slice-throw');throw Error('slice-sentinel')}};
    if(mode==='throwing-field'){input=[];Object.defineProperty(input,0,{get(){trace.push('field0');return 307n}});Object.defineProperty(input,1,{get(){trace.push('field1');throw Error('field-sentinel')}});}
    if(mode==='zero-length-no-slice')input={get length(){trace.push('zero.length');return 0},get slice(){throw Error('zero slice must not be read')}};
    const value={$:'ArmRec',get a(){trace.push('record.a');return input}};
    if(mode.startsWith('throwing'))expectError(mode,()=>{const partial=a.direct(value);trace.push('later-argument');return call(partial,[311n,313n]);},mode==='throwing-slice'?'slice-sentinel':'field-sentinel');
    else{const got=a.direct(value);note(mode+'-trace-before-descriptor',trace.slice());assert.equal(got.arity,4);if(mode==='zero-length-no-slice')assert.deepEqual(got.bound,[]);}
    note(mode+'-trace',trace.slice());
  }
  {
    const trace=[];let reads=0;
    const vector={0:317n,1:331n,get length(){const n=++reads===1?2:1;trace.push(['length',n]);return n},slice:Array.prototype.slice};
    const got=a.direct(recordValue(vector));equal('changing-source-length-result',call(got,[337n,347n,349n]),output([317n,337n,347n,349n]));equal('changing-source-length-trace',trace,[['length',2],['length',1]]);
  }
  {
    const trace=[],lengths=[3,4,4,1];
    const copied=new Proxy([353n,359n,367n,373n],{get(target,key,receiver){if(key==='length'){const value=lengths.shift()??4;trace.push(['length',value]);return value}return Reflect.get(target,key,receiver)}});
    const vector={length:2,slice(){return copied}};
    equal('changing-copied-length-result',a.direct(recordValue(vector)),output([353n,359n,367n,373n]));equal('changing-copied-length-trace',trace,[['length',3],['length',4],['length',4],['length',1]]);
  }
  if(config.expectPrebinding!==undefined){
    for(const name of ['direct','annotated','captured','lateEffect','functionResult'])assert.equal(report.emission.find(x=>x.name===name).prebound,config.expectPrebinding,name+' lowering expectation');
    for(const name of ['effectfulArm','erased','etaShort','equalArity','zeroFields','lifted'])assert.equal(report.emission.find(x=>x.name===name).prebound,false,name+' must use fallback');
  }
  if(config.baseline){const old=JSON.parse(fs.readFileSync(config.baseline));assert.ok(old.complete&&old.pass);assert.deepEqual(JSON.parse(json(report.observations)),old.observations,'Baseline descriptor/output/effect/read transcript');report.baseline=identity(config.baseline);}
  report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
save(path.join(out,'report.json'),report);console.log(json({complete:report.complete,pass:report.pass,observations:report.observations.length,emission:report.emission,error:report.error}));

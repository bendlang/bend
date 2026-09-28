import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {verifyAttempt} from '../../development/workflow.mjs';

const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const t=(tag,name='',id=0,kids=[],quant=0,removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed)});
const app=(f,x)=>t('App','',0,[f,x]),v=id=>t('Var','x',id),ctr=(name,...xs)=>t('Ctr',name,0,xs);
const ref=name=>t('Ref',name),lam=(id,body)=>t('Lam','x',id,[body],1);
const def=(name,arity,value,extra={})=>({$:'KDef',name,kind:'Def',arity,templates:0,typ:t('Absent'),value,ctors:nil,native:false,unsafe:true,...extra});

// Worker process for bounded divergence and reflective host-boundary witnesses.
if(process.argv[2]==='--worker'){
  const [view,file,output]=process.argv.slice(3),K=(await import(pathToFileURL(view))).default;
  const input=JSON.parse(fs.readFileSync(file));
  let observation;
  try{
    if(input.mode==='getter-spine'){
      let reads=0;
      const args={$:'Con',head:ctr('Unused'),get tail(){if(++reads===3)throw TypeError('third tail read');return nil;}};
      const d=def('f',1,lam(1,ctr('Result')));
      const value=K.norm_ref(list([d]),ref('f'),args,d);
      observation={value,tailReads:reads};
    }else observation={value:K.wnf(input.book,input.term)};
  }catch(error){observation={error:{name:error.name,message:error.message,stack:error.stack}};}
  fs.writeFileSync(output,JSON.stringify(observation,null,2)+'\n');
  process.exit(0);
}

const [baselineArg,candidateArg,outputArg,mode='delayed']=process.argv.slice(2);
const out=path.resolve(outputArg);fs.mkdirSync(out,{recursive:false});
const report={kind:'phase12-normalizer-exact-controls',complete:false,pass:false,
  scope:'Read-only private export views of maintained genuine checked artifacts; exports add no transformed algorithm. Not a new component bootstrap or fixed point.',
  inputs:[identity(import.meta.filename),identity(process.execPath)],variants:[],rows:[],children:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const exportNames={wnf:2,strong:2,compare:4,norm_compare:5,check:5,infer:5,norm_ref:4};
const env={...process.env};for(const key of Object.keys(env))if(key.startsWith('BEND_')||key==='NODE_OPTIONS')delete env[key];
function child(label,args,extraEnv={},timeout=30000){
  const directory=path.join(out,label);fs.mkdirSync(directory);
  const stdout=path.join(directory,'stdout'),stderr=path.join(directory,'stderr');
  const a=fs.openSync(stdout,'wx'),b=fs.openSync(stderr,'wx');
  const argv=['-c','2',process.execPath,'--stack-size=4096','--max-old-space-size=4096',...args];
  let result;
  try{result=spawnSync('taskset',argv,{cwd:out,env:{...env,...extraEnv},timeout,stdio:['ignore',a,b]});}
  finally{fs.closeSync(a);fs.closeSync(b);}
  const execution={label,command:'taskset',argv,timeout,status:result.status,signal:result.signal,error:result.error?String(result.error):null,stdout:identity(stdout),stderr:identity(stderr)};
  report.children.push(execution);save();return execution;
}
try{
  const baseline=await verifyAttempt(path.resolve(baselineArg)),candidate=await verifyAttempt(path.resolve(candidateArg));
  assert.equal(baseline.api.sha256,'63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f');
  for(const [name,attempt] of [['baseline',baseline],['candidate',candidate]]){
    const api=attempt.api.file;report.inputs.push(identity(api));
    let source=fs.readFileSync(api,'utf8');
    for(const name of Object.keys(exportNames))assert.equal(source.split('function $'+name+'$(').length,2);
    source+='\nexport const phase12Private={'+Object.entries(exportNames).map(([name,n])=>{
      const args=Array.from({length:n},(_,i)=>'a'+i).join(',');return name+':('+args+')=>run_loop($'+name+'$('+args+'))';
    }).join(',')+'};\n';
    const view=path.join(out,name+'-exports.mjs'),wrapper=path.join(out,name+'-api.mjs');
    fs.writeFileSync(view,source);
    fs.writeFileSync(wrapper,'import K,{phase12Private} from '+JSON.stringify(pathToFileURL(view).href)+';\nexport default {...K,...phase12Private};\n');
    report.variants.push({name,original:identity(api),exports:identity(view),wrapper:identity(wrapper)});
  }
  const APIs=await Promise.all(report.variants.map(async x=>(await import(pathToFileURL(x.wrapper.file))).default));
  const a=ctr('A'),b=ctr('B'),x=v(90),y=v(91),efq=t('Efq');
  const matcher=t('Mat','A',0,[b,efq]);
  const mat=(name,body,rest=efq)=>t('Mat',name,0,[body,rest]);
  const cases=[];
  const add=(name,defs,term,expected)=>cases.push({name,book:list(defs),term,...(expected===undefined?{}:{expected})});
  add('zero arity successful',[def('f',0,a)],ref('f'),a);
  add('identity',[def('f',1,lam(1,v(1)))],app(ref('f'),a),a);
  add('under applied',[def('f',2,lam(1,lam(2,v(2))))],app(ref('f'),a),app(ref('f'),a));
  add('missing definition',[],app(ref('missing'),x),app(ref('missing'),x));
  add('foreign opaque',[def('f',1,t('Foreign'))],app(ref('f'),x),app(ref('f'),x));
  add('absent opaque',[def('f',1,t('Absent'))],app(ref('f'),x),app(ref('f'),x));
  add('zero arity datatype',[def('D',0,t('Absent'),{kind:'ADT'})],ref('D'),t('ADT','D'));
  add('parameterized datatype opaque',[def('D',1,t('Absent'),{kind:'ADT'})],app(ref('D'),a),app(ref('D'),a));
  add('matching constructor',[def('f',1,matcher)],app(ref('f'),a),b);
  add('nonmatching constructor',[def('f',1,matcher)],app(ref('f'),ctr('Other')),app(ref('f'),ctr('Other')));
  add('neutral stuck original',[def('f',1,matcher)],app(ref('f'),x),app(ref('f'),x));
  add('pending Efq',[def('f',1,efq)],app(ref('f'),x),app(ref('f'),x));
  add('zero pending Efq',[def('f',0,efq)],app(ref('f'),x),app(efq,x));
  add('annotated arm',[def('f',1,t('Ann','',0,[matcher,t('Absent')]))],app(ref('f'),x),app(ref('f'),x));
  add('default lambda',[def('f',1,mat('A',a,lam(3,v(3))))],app(ref('f'),b),b);
  add('partly consumed fallback',[def('f',2,lam(1,matcher))],app(app(ref('f'),a),x),app(app(ref('f'),a),x));
  add('extra application preserves whole fallback',[def('f',1,matcher)],app(app(ref('f'),x),y),app(app(ref('f'),x),y));
  add('extra application after consumed arity',[def('f',1,lam(1,matcher))],app(app(ref('f'),a),x),app(matcher,x));
  add('nested reference replaces fallback',[def('f',1,lam(1,app(ref('g'),v(1)))),def('g',1,matcher)],app(ref('f'),x),app(ref('g'),x));
  add('constructor fields extend pending arity',[def('f',1,mat('Pair',lam(1,matcher)))],app(ref('f'),ctr('Pair',a,x)),app(ref('f'),ctr('Pair',a,x)));
  add('successful constructor field consumption',[def('f',1,mat('Pair',lam(1,lam(2,v(2)))))],app(ref('f'),ctr('Pair',a,b)),b);
  const annotated=t('Ann','',0,[x,t('Typ','',0,[t('Qua','',0,[],2)])]);
  add('raw scrutinee preserved',[def('f',1,matcher)],app(ref('f'),annotated),app(ref('f'),annotated));
  const decorated=t('Ref','f',571,[],2,['Removed']);
  add('head metadata and argument order',[def('f',2,matcher)],app(app(decorated,x),y),app(app(decorated,x),y));
  add('blocked rewrite',[def('f',1,t('Rwt','',0,[x,t('Absent'),lam(1,a)]))],app(ref('f'),b));
  add('reflexive rewrite',[def('f',1,t('Rwt','',0,[t('Rfl'),t('Absent'),lam(1,a)]))],app(ref('f'),b),a);
  add('parallel let body',[def('f',1,t('Let','',0,[t('Bind','x',2,[a]),lam(1,v(2))]))],app(ref('f'),b),a);
  for(const input of cases){
    const file=path.join(out,'case-'+report.rows.length+'.json');fs.writeFileSync(file,JSON.stringify(input)+'\n');
    const observed=APIs.map(K=>K.wnf(input.book,input.term));
    report.rows.push({name:input.name,input:identity(file),observed,exact:JSON.stringify(observed[0])===JSON.stringify(observed[1])});save();
    assert.deepEqual(observed[1],observed[0],input.name);
    if(input.expected!==undefined)assert.deepEqual(observed[0],input.expected,input.name+' baseline expectation');
  }
  const loop1=lam(1001,app(v(1001),v(1001))),loop2=lam(1002,app(v(1002),v(1002))),omega=app(loop1,loop2);
  const bounded=[
    {name:'unused omega',book:list([def('f',1,lam(1,a))]),term:app(ref('f'),omega),expected:a},
    {name:'stuck before later omega',book:list([def('f',2,matcher)]),term:app(app(ref('f'),x),omega),expected:app(app(ref('f'),x),omega)},
    {name:'demanded omega',book:list([def('f',1,matcher)]),term:app(ref('f'),omega),timeout:true},
    {name:'reflective third tail read',mode:'getter-spine',rawBoundary:true},
  ];
  for(let i=0;i<bounded.length;i++){
    const input=bounded[i],file=path.join(out,'bounded-'+i+'.json');fs.writeFileSync(file,JSON.stringify(input)+'\n');
    const results=[];
    for(const variant of report.variants){
      const output=path.join(out,'bounded-'+i+'-'+variant.name+'.json');
      const execution=child('bounded-'+i+'-'+variant.name,[import.meta.filename,'--worker',variant.wrapper.file,file,output],{},input.timeout?1200:10000);
      const observation=fs.existsSync(output)?JSON.parse(fs.readFileSync(output)):null;
      results.push({variant:variant.name,execution,observation});
      if(input.timeout)assert.match(execution.error??'',/ETIMEDOUT/);
      else{assert.equal(execution.error,null);assert.equal(execution.signal,null);assert.equal(execution.status,0);}
      if(input.expected)assert.deepEqual(observation.value,input.expected);
    }
    report.rows.push({name:input.name,input:identity(file),results,rawBoundary:input.rawBoundary??false});save();
    if(input.rawBoundary){
      assert.equal(results[0].observation.error?.message,'third tail read');
      if(mode==='seed')assert.equal(results[1].observation.error?.message,'third tail read');
      else assert.deepEqual(results[1].observation.value,ctr('Result'));
    }
  }
  const tests=path.resolve(import.meta.dirname,'../../../tests');
  for(const file of ['kernel.mjs','normalize.mjs']){
    const original=path.join(tests,file),copy=path.join(out,file);fs.copyFileSync(original,copy);
    report.inputs.push(identity(original),identity(copy));
  }
  const priorControls=path.resolve(import.meta.dirname,'../phase9/checker-controls.mjs'),controlCopy=path.join(out,'prior-controls.mjs');
  fs.copyFileSync(priorControls,controlCopy);report.inputs.push(identity(priorControls),identity(controlCopy));
  for(const variant of report.variants){
    const api=variant.wrapper.file;
    for(const [name,args] of [['kernel',[path.join(out,'kernel.mjs')]],['normalize',[path.join(out,'normalize.mjs')]],['prior',[controlCopy,api]]]){
      const execution=child(variant.name+'-'+name,args,{BEND_KERNEL_API:api,BEND_ANNOTATE_API:api,BEND_NORMALIZE_API:api});
      assert.equal(execution.error,null);assert.equal(execution.signal,null);assert.equal(execution.status,0);
    }
  }
  report.changedInputs=report.inputs.filter(i=>identity(i.file).sha256!==i.sha256);
  report.complete=true;report.pass=report.changedInputs.length===0;
}catch(error){report.error=String(error.stack??error);}
save();console.log(JSON.stringify({pass:report.pass,complete:report.complete,error:report.error,rows:report.rows.length}));
if(!report.pass)process.exitCode=1;

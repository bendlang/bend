// Independent synthetic identity, ABI and evaluation-order witnesses.
// These KDefs test guards/emission; they do not claim frontend admission.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [configFile,outArgument]=process.argv.slice(2);
assert.ok(configFile&&outArgument,'usage: controls-guards.mjs CONFIG NEW_OUT');
const config=JSON.parse(fs.readFileSync(configFile)),candidate=config.candidate??config,out=path.resolve(outArgument);
fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const save=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,(_,x)=>typeof x==='bigint'?String(x)+'n':x,2)+'\n',{flag:'wx'});
const manifest=path.join(import.meta.dirname,'controls-operations.json');
const report={kind:'phase29-independent-primitive-guards',complete:false,pass:false,node:process.version,args:process.execArgv,
  affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(x=>x.startsWith('Cpus_allowed_list:')),
  inputs:[...['api','driver','runtime','base'].map(k=>identity(candidate[k])),identity(configFile),identity(import.meta.filename),identity(manifest)],
  scope:'Synthetic KDefs; recognizer refusal, emitted code ABI and host-observable argument order. No timing or checked-source claim.',guards:[],observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls-guards.mjs'));save(path.join(out,'config.json'),config);
try{
  for(const key of Object.keys(process.env))if(key.startsWith('BEND_'))delete process.env[key];
  process.env.BEND_TYPED_API=candidate.api;process.env.BEND_TYPED_RUNTIME=candidate.runtime;process.env.BEND_BASE=candidate.base;
  const {loadApi}=await import(pathToFileURL(candidate.driver));let api=await loadApi();
  if(typeof api.j_primitive_call!=='function'){
    const original=fs.readFileSync(candidate.api,'utf8');
    assert.equal(original.split('function $j_primitive_call$(').length,2,'one internal guard');
    const addition='\n// Diagnostic export only; original generated bodies remain byte-identical.\nexport const phase29GuardApi={j_primitive_call:(book,spine)=>run_loop($j_primitive_call$(book,spine))};\n';
    const file=path.join(out,'diagnostic-api.mjs');fs.writeFileSync(file,original+addition,{flag:'wx'});
    assert.equal(fs.readFileSync(file,'utf8').slice(0,original.length),original);
    report.diagnostic={...identity(file),parentSha256:report.inputs[0].sha256,appendOnly:true,unchangedPrefixBytes:Buffer.byteLength(original)};
    api={...api,...(await import(pathToFileURL(file))).phase29GuardApi};
  }
  const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
  const array=xs=>{const a=[];for(;xs.$==='Con';xs=xs.tail)a.push(xs.head);return a;};
  let id=100;
  const t=(tag,name='',kids=[],binder=0,quant=0,removed=[])=>({$:'KTerm',tag,name,id:binder,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0});
  const literal=(number,kind='U32')=>({$:'KLiteral',kind,number,text:'',originBegin:0,originEnd:0});
  const typ=name=>t('ADT',name),all=(a,b,q=2,binder=id++)=>t('All','',[a,b],binder,q);
  const ref=name=>t('Ref',name),app=(f,x)=>t('App','',[f,x]),variable=binder=>t('Var','',[],binder),lam=(binder,body)=>t('Lam','',[body],binder,2);
  const d=(name,kind='Def',native=true,type=t('Typ'),value=t('Absent'),ctors=[],arity=0)=>({$:'KDef',name,kind,arity,templates:0,typ:type,value,ctors:list(ctors),native,unsafe:false});
  const owners=[['U32',['U32']],['Word.Nil',['WNil']],['Word.Con',['WCon']],['Bool',['True','False']],['Nat',['Zero','Succ']],['F32',['F32']]];
  const ownerRows=()=>[...owners.map(([name,cs])=>d(name,'ADT',true,t('Typ'),t('Absent'),cs.map(c=>d(c,'Ctr')))),d('Word')];
  const operations=JSON.parse(fs.readFileSync(manifest)).operations;
  const definition=op=>d(op.name,'Def',true,op.domains.reduceRight((rest,x)=>all(typ(x),rest),typ(op.result)),t('Absent'),[],op.domains.length);
  const call=op=>t('Call',op.name,op.domains.map((_,i)=>variable(i+1)));
  const check=(name,rows,spine,expected)=>{const got=api.j_primitive_call(list(rows),spine);assert.equal(got,expected,name);report.guards.push({name,expected,got});};
  for(const op of operations){
    check(op.name+'-accepted',[...ownerRows(),definition(op)],call(op),true);
    for(const change of ['non-native','wrong-kind','template','foreign','annotated-foreign','wrong-arity-low','wrong-arity-high']){
      const def=definition(op);
      if(change==='non-native')def.native=false;
      if(change==='wrong-kind')def.kind='ADT';
      if(change==='template')def.templates=1;
      if(change==='foreign')def.value=t('Foreign',op.name);
      if(change==='annotated-foreign')def.value=t('Ann','',[t('Foreign',op.name),def.typ]);
      if(change==='wrong-arity-low')def.arity--;
      if(change==='wrong-arity-high')def.arity++;
      check(op.name+'-'+change,[...ownerRows(),def],call(op),false);
    }
    for(const count of [0,op.domains.length+1])check(op.name+'-arguments-'+count,[...ownerRows(),definition(op)],t('Call',op.name,Array.from({length:count},()=>literal(0))),false);
    for(let at=0;at<op.domains.length;at++){
      for(const change of ['erased','wrong-type','parameterized','removed']){
        const def=definition(op);let head=def.typ;
        for(let i=0;i<at;i++)head=array(head.kids)[1];
        if(change==='erased')head.quant=0;
        else{const [domain,result]=array(head.kids);head.kids=list([change==='wrong-type'?typ('Wrong'):change==='parameterized'?{...domain,kids:list([literal(1)])}:{...domain,removed:list([domain.name])},result]);}
        check(op.name+'-argument-'+at+'-'+change,[...ownerRows(),def],call(op),false);
      }
    }
    for(const change of ['wrong-type','parameterized','removed','extra-all']){
      const def=definition(op);let head=def.typ;
      for(let i=1;i<op.domains.length;i++)head=array(head.kids)[1];
      const [domain,result]=array(head.kids);head.kids=list([domain,change==='wrong-type'?typ('Wrong'):change==='parameterized'?{...result,kids:list([literal(1)])}:change==='removed'?{...result,removed:list([result.name])}:all(typ('U32'),result)]);
      check(op.name+'-result-'+change,[...ownerRows(),def],call(op),false);
    }
  }
  const add=operations.find(x=>x.name==='U32.add'),shift=operations.find(x=>x.name==='U32.shln'),fadd=operations.find(x=>x.name==='F32.add');
  for(const [owner,cs]of owners){
    const op=owner==='Nat'?shift:owner==='F32'?fadd:add;
    for(const change of ['non-native','wrong-kind','missing']){
      const rows=ownerRows(),at=rows.findIndex(x=>x.name===owner);
      if(change==='missing')rows.splice(at,1);else if(change==='wrong-kind')rows[at].kind='Def';else rows[at].native=false;
      check(owner+'-owner-'+change,[...rows,definition(op)],call(op),false);
    }
    for(const constructor of cs)for(const change of ['non-native','wrong-kind','missing']){
      const rows=ownerRows(),ownerRow=rows.find(x=>x.name===owner),ctors=array(ownerRow.ctors),at=ctors.findIndex(x=>x.name===constructor);
      if(change==='missing')ctors.splice(at,1);else if(change==='wrong-kind')ctors[at].kind='Def';else ctors[at].native=false;
      ownerRow.ctors=list(ctors);check(owner+'/'+constructor+'-'+change,[...rows,definition(op)],call(op),false);
    }
  }
  for(const name of ['U32.addx','xU32.add','Nat.add','F32.pow','F32.to_u32'])check('unsupported-'+name,[...ownerRows(),{...definition(add),name}],t('Call',name,[literal(1),literal(2)]),false);
  check('non-call-tag',[...ownerRows(),definition(add)],{...call(add),tag:'Ref'},false);
  check('absent-definition',ownerRows(),call(add),false);

  // Emit actual call sites, then inject observable host definitions only for
  // ordinary argument-producing laws. Native primitive bindings are unchanged.
  const emittedOps=['U32.add','U32.div','U32.mod','U32.shln','U32.shrn','U32.mul','F32.add','F32.div'];
  const rows=[...ownerRows(),...operations.map(definition)];
  for(const name of emittedOps){
    const op=operations.find(x=>x.name===name),key=name.replaceAll('.','_');
    rows.push(d(key+'_left','Def',false,typ(op.domains[0])),d(key+'_right','Def',false,typ(op.domains[1])));
    rows.push(d('order_'+key,'Def',false,typ(op.result),app(app(ref(name),ref(key+'_left')),ref(key+'_right'))));
  }
  rows.push(d('partial','Def',false,all(typ('U32'),all(typ('U32'),typ('U32'))),lam(501,app(ref('U32.add'),variable(501)))));
  save(path.join(out,'emission-book.json'),rows);
  const runtime=fs.readFileSync(candidate.runtime,'utf8'),emission=api.j_library(list(rows)),moduleFile=path.join(out,'controls.mjs');
  fs.writeFileSync(moduleFile,runtime+'\n'+emission,{flag:'wx'});report.module=identity(moduleFile);
  const {default:generated,G,call:invoke}=await import(pathToFileURL(moduleFile));
  const host=(arity,code,bound=[])=>({arity,code,env:null,bound});
  for(const name of emittedOps){
    const key=name.replaceAll('.','_'),isFloat=name.startsWith('F32'),isShift=name.endsWith('shln')||name.endsWith('shrn');
    const values=isShift?[13,40n]:isFloat?[Math.fround(3.5),0]:[13,0];
    for(const fail of ['none','left','right']){
      const trace=[];for(let i=0;i<2;i++){const label=i?'right':'left';G[key+'_'+label]=host(0,()=>{trace.push(label);if(fail===label)throw Error(label+' sentinel');return values[i]});}
      const row={name,fail,trace,pass:false};report.observations.push(row);
      if(fail==='none'){row.result=generated['order_'+key]();assert.deepEqual(trace,['left','right']);}
      else{assert.throws(()=>generated['order_'+key](),new RegExp('^Error: '+fail+' sentinel$'));assert.deepEqual(trace,fail==='left'?['left']:['left','right']);}
      row.pass=true;
    }
  }
  const partial=generated.partial(4294967295);
  assert.equal(partial.arity,2);assert.equal(partial.env,null);assert.deepEqual(partial.bound,[4294967295]);
  assert.equal(invoke(partial,[2]),1);assert.deepEqual(partial.bound,[4294967295]);
  report.observations.push({name:'public-partial-descriptor',arity:partial.arity,env:partial.env,bound:partial.bound,result:1,pass:true});
  report.emission={primitiveMarkers:(emission.match(/\/\* primitive \*\//g)||[]).length};
  assert.ok(report.emission.primitiveMarkers>=emittedOps.length,'actual saturated probes were optimized');
  report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
save(path.join(out,'report.json'),report);
console.log(JSON.stringify({complete:report.complete,pass:report.pass,guards:report.guards.length,observations:report.observations.length,error:report.error}));

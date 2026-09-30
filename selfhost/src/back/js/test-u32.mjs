// Direct U32 recognizer guard controls. Synthetic KDefs test the recognizer,
// not whether a forged book would pass the normal frontend/checker.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [configFile,outArgument]=process.argv.slice(2);
assert.ok(configFile&&outArgument,'usage: test-u32.mjs CANDIDATE_CONFIG NEW_OUT_DIR');
const config=JSON.parse(fs.readFileSync(configFile)),candidate=config.candidate??config,out=path.resolve(outArgument);
fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const report={kind:'phase26-u32-recognizer-guards',complete:false,pass:false,node:process.version,args:process.execArgv,affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(x=>x.startsWith('Cpus_allowed_list:')),api:identity(candidate.api),driver:identity(candidate.driver),runtime:identity(candidate.runtime),tool:identity(import.meta.filename),observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'test-u32.mjs'));
fs.writeFileSync(path.join(out,'config.json'),JSON.stringify(candidate,null,2)+'\n',{flag:'wx'});
try{
  process.env.BEND_TYPED_API=candidate.api;process.env.BEND_TYPED_RUNTIME=candidate.runtime;process.env.BEND_BASE=candidate.base;
  const {loadApi}=await import(pathToFileURL(candidate.driver));
  let api=await loadApi();
  if(typeof api.j_u32_worker!=='function'||typeof api.j_u32_bounded!=='function'){
    const original=fs.readFileSync(candidate.api,'utf8');
    for(const name of ['j_u32_worker','j_u32_bounded'])assert.equal(original.split('function $'+name+'$(').length,2,'One exact internal definition '+name);
    const addition='\n// Diagnostic exports only: existing generated bodies remain byte-identical.\nexport const phase26GuardApi={j_u32_worker:(book,d)=>run_loop($j_u32_worker$(book,d)),j_u32_bounded:(todo,fuel)=>run_loop($j_u32_bounded$(todo,fuel))};\n';
    const diagnostic=path.join(out,'diagnostic-api.mjs');fs.writeFileSync(diagnostic,original+addition,{flag:'wx'});
    assert.equal(fs.readFileSync(diagnostic,'utf8').slice(0,original.length),original);
    report.diagnostic={...identity(diagnostic),parentSha256:report.api.sha256,unchangedPrefixBytes:Buffer.byteLength(original),appendOnly:true};
    api={...api,...(await import(pathToFileURL(diagnostic))).phase26GuardApi};
  }
  const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
  let nextId=100;
  const t=(tag,name='',kids=[],id=0,quant=0,removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0});
  const lit=n=>({$:'KLiteral',kind:'U32',number:n>>>0,text:'',originBegin:0,originEnd:0});
  const variable=id=>t('Var','',[],id),lam=body=>t('Lam','',[body],nextId++,2),mat=(name,arm,rest=t('Efq'))=>t('Mat',name,[arm,rest]);
  const u32=t('ADT','U32'),all=(dom,cod,q=2)=>t('All','',[dom,cod],nextId++,q);
  const d=(name,kind='Def',ctors=[],native=true,typ=t('Typ'),value=t('Absent'))=>({$:'KDef',name,kind,arity:0,templates:0,typ,value,ctors:list(ctors),native,unsafe:false});
  const owners=[['U32',['U32']],['Word.Nil',['WNil']],['Word.Con',['WCon']],['Bool',['False','True']]];
  const bookRows=()=>[...owners.map(([name,cs])=>d(name,'ADT',cs.map(c=>d(c,'Ctr')))),d('Word')];
  const definition=(value=mat('U32',lam(lit(7))),typ=all(u32,u32))=>d('probe','Def',[],false,typ,value);
  const rowsToList=rows=>list(rows);
  const check=(name,rows,def,kind)=>{const result=api.j_u32_worker(rowsToList(rows),def);assert.equal(result.$,kind,name);report.observations.push({name,kind:result.$,...(kind==='Some'?{worker:result.value}:{})});return result.value;};
  const yes=(name,def=definition())=>check(name,bookRows(),def,'Some');
  const no=(name,def=definition())=>check(name,bookRows(),def,'None');
  const baseCode=yes('closed-default-constant');
  yes('annotated-root',definition(t('Ann','',[definition().value,all(u32,u32)])));
  for(const [owner,constructors]of owners){
    for(const mode of ['native-false','wrong-kind','missing']){
      const rows=bookRows(),index=rows.findIndex(x=>x.name===owner);
      if(mode==='native-false')rows[index].native=false;
      if(mode==='wrong-kind')rows[index].kind='Def';
      if(mode==='missing')rows.splice(index,1);
      check(owner+'-owner-'+mode,rows,definition(),'None');
    }
    for(const constructor of constructors)for(const mode of ['native-false','wrong-kind','missing']){
      const rows=bookRows(),ownerDef=rows.find(x=>x.name===owner),cs=[];
      for(let xs=ownerDef.ctors;xs.$==='Con';xs=xs.tail){const c=xs.head;if(c.name===constructor){if(mode==='missing')continue;if(mode==='native-false')c.native=false;if(mode==='wrong-kind')c.kind='Def';}cs.push(c);}
      ownerDef.ctors=list(cs);check(owner+'/'+constructor+'-'+mode,rows,definition(),'None');
    }
  }
  for(const mode of ['native-false','wrong-kind','missing']){const rows=bookRows(),index=rows.findIndex(x=>x.name==='Word');if(mode==='missing')rows.splice(index,1);else if(mode==='wrong-kind')rows[index].kind='ADT';else rows[index].native=false;check('Word-definition-'+mode,rows,definition(),'None');}
  no('erased-input',definition(undefined,all(u32,u32,0)));
  no('non-function-type',definition(undefined,u32));
  no('non-u32-input',definition(undefined,all(t('ADT','Bool'),u32)));
  no('parameterized-u32-input',definition(undefined,all(t('ADT','U32',[lit(1)]),u32)));
  no('removed-u32-input',definition(undefined,all(t('ADT','U32',[],0,0,['U32']),u32)));
  no('string-result',definition(undefined,all(u32,t('ADT','String'))));
  no('function-result',definition(undefined,all(u32,all(u32,u32))));
  no('removed-u32-result',definition(undefined,all(u32,t('ADT','U32',[],0,0,['U32']))));
  no('non-u32-root',definition(mat('F32',lam(lit(7)))));
  no('capturing-leading-lambda',definition(lam(definition().value),all(u32,all(u32,u32))));
  no('open-default-result',definition(mat('U32',t('Lam','',[variable(42)],42,2))));
  no('effectful-default-result',definition(mat('U32',lam(t('App','',[t('Ref','effect'),lit(7)])))));
  no('structural-word-return',definition(mat('U32',t('Lam','',[t('Ctr','U32',[variable(42)])],42,2))));
  no('non-u32-literal-result',definition(mat('U32',lam({...lit(7),kind:'F32'}))));
  const ignoredBit=definition(mat('U32',mat('WCon',lam(lam(lit(19))))));
  yes('ignored-bit-and-tail',ignoredBit);
  const selectedBits=(depth,max,acc)=>depth===max?lam(lit(acc)):mat('WCon',mat('False',selectedBits(depth+1,max,acc),mat('True',selectedBits(depth+1,max,acc+2**depth))));
  const eight=definition(mat('U32',selectedBits(0,8,0))),eightCode=yes('ordered-byte-decision',eight);
  const duplicate=definition(mat('U32',mat('WCon',mat('True',lam(lit(11)),mat('True',lam(lit(99)),mat('False',lam(lit(13))))))));
  const duplicateCode=yes('ordered-duplicate-bool-first-arm',duplicate);
  no('reachable-open-bool-arm',definition(mat('U32',mat('WCon',mat('True',lam(lit(11)),mat('False',lam(variable(42))))))));
  const count=term=>{let n=0,stack=[term];while(stack.length){const x=stack.pop();n++;if(x.$==='KLiteral')continue;for(let xs=x.kids;xs.$==='Con';xs=xs.tail)stack.push(xs.head);}return n;};
  const ten=definition(mat('U32',selectedBits(0,10,0))),eleven=definition(mat('U32',selectedBits(0,11,0)));
  assert.ok(count(ten.value)<8192&&count(eleven.value)>8192);
  yes('large-in-budget-worker',ten);no('oversize-worker-refused',eleven);
  report.budgetTreeNodes={accepted:count(ten.value),refused:count(eleven.value)};
  for(const [nodes,fuel,expected]of [[0,0,true],[1,0,false],[8192,8192,true],[8193,8192,false]]){
    const result=api.j_u32_bounded(list(Array.from({length:nodes},()=>lit(0))),fuel);assert.equal(result,expected);report.observations.push({name:'bounded-'+nodes+'-nodes-'+fuel+'-fuel',result});
  }
  // Execute the returned scalar worker, without any compiler-generated host adapter.
  const fn=(arity,code,env=null,bound=[])=>({arity,code,env,bound});
  const build=code=>Function('fn','return '+code)(fn);
  const constant=build(baseCode),byte=build(eightCode),priority=build(duplicateCode);
  const inputs=[...Array(256).keys(),2147483647,2147483648,3000000000,4294967295];
  for(const n of inputs){assert.equal(constant.code([n]),7);assert.equal(byte.code([n]),n&255);assert.equal(priority.code([n]),(n&1)?11:13);}
  assert.equal(constant.arity,1);assert.deepEqual(constant.bound,[]);
  report.scalarExecutions={workers:3,points:inputs.length,total:inputs.length*3,domain:'valid JS U32 numeric values'};
  assert.equal(identity(candidate.api).sha256,report.api.sha256);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,scalarExecutions:report.scalarExecutions,error:report.error}));

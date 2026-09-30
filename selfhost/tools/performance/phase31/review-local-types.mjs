// Checked API recognition controls. Synthetic metadata is not frontend acceptance.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [attempt,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const id=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const manifest=JSON.parse(fs.readFileSync(path.join(attempt,'attempt.json'))),driver=path.join(manifest.snapshot.root,'tools/typed-driver.mjs');
const report={complete:false,pass:false,scope:'Actual checked compiler local-type/native predicates on canonical Base plus small synthetic metadata; no timing or source conformance claim.',inputs:[id(import.meta.filename),id(path.join(attempt,'attempt.json')),id(driver),...['api','base','runtime'].map(k=>id(manifest[k].file))],observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const list=(xs,tail={$:'Nil'})=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),tail);
const t=(tag,name='',kids=[],id=0,quant=0)=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list([]),originBegin:0,originEnd:0});
const ty=(name,args=[])=>t('ADT',name,args),all=(a,b,q=2,id=90000)=>t('All','',[a,b],id,q),kind=q=>t('Typ','',[t('Qua','',[],0,q)]);
const def=(name,typ,extra={})=>({$:'KDef',name,kind:'ADT',arity:0,templates:0,typ,value:t('Absent'),ctors:list([]),native:false,unsafe:false,...extra});
const record=(name,fields,quant=1)=>def(name,kind(quant),{ctors:list([def(name+'Pack',fields.reduceRight((b,a,i)=>all(a,b,2,90000+i),ty(name)),{kind:'Ctr',arity:fields.length})])});
try{
 for(const key of ['api','runtime','base'])assert.equal(id(manifest[key].file).sha256,manifest[key].sha256);
 for(const key of Object.keys(process.env))if(key.startsWith('BEND_'))delete process.env[key];
 process.env.BEND_TYPED_API=manifest.api.file;process.env.BEND_TYPED_RUNTIME=manifest.runtime.file;process.env.BEND_BASE=manifest.base.file;
 const D=await import(pathToFileURL(driver)),publicApi=await D.loadApi(),base=(await D.prepareBase(publicApi)).book;
 const source=fs.readFileSync(manifest.api.file,'utf8'),names=['j_region_local_type','j_region_local_signature','j_region_signature','j_region_local_native','lookup'];
 for(const name of names)assert.equal(source.split('function $'+name+'$(').length,2,name+' exact generated declaration');
 const suffix='\nexport const review={'+names.map(name=>JSON.stringify(name)+':(...a)=>run_loop($'+name+'$(...a))').join(',')+'};\n';
 const inspected=path.join(out,'inspected-api.mjs');fs.writeFileSync(inspected,source+suffix,{flag:'wx'});assert.equal(fs.readFileSync(inspected,'utf8').slice(0,source.length),source);
 report.inspection={module:id(inspected),unchangedSource:id(manifest.api.file),appendedExport:suffix,scope:'Byte-exact compiled body plus read-only diagnostic exports; original public API unchanged.'};
 const api=(await import(pathToFileURL(inspected))).review;
 const check=(name,actual,expected)=>{report.observations.push({name,actual,expected});assert.equal(actual,expected,name)};
 const u=ty('U32'),a=ty('Array',[u]),pair=ty('Sigma',[t('Qua','',[],0,1),t('Qua','',[],0,2),a,t('Lam','',[u],99100,2)]);
 for(const [name,type,expected]of [['scalar',u,true],['local-array',a,true],['foreign-array-element',ty('Array',[ty('String')]),false],['canonical-tuple',pair,true],['function',all(u,u),false]])check(name,api.j_region_local_type(base,type),expected);
 const rs=[record('EmptyLocal',[]),record('SmallLocal',[a,u]),record('RecursiveLocal',[ty('RecursiveLocal')]),record('FunctionLocal',[all(u,u)]),record('WideLocal',Array(33).fill(u))];
 for(const r of rs)check(r.name,api.j_region_local_type(list(rs,base),ty(r.name)),['EmptyLocal','SmallLocal'].includes(r.name));
 const dag=[];for(let n=0;n<=8;n++)dag.push(record('Level'+n,n?[ty('Level'+(n-1)),ty('Level'+(n-1))]:[u]));
 check('shared-dag-small',api.j_region_local_type(list(dag,base),ty('Level2')),true);check('shared-dag-budget-refusal',api.j_region_local_type(list(dag,base),ty('Level8')),false);
 const signature=all(a,u);check('private-container-signature',api.j_region_local_signature(base,signature,1),true);check('public-container-signature-refused',api.j_region_signature(base,signature,1),false);check('erased-helper-refused',api.j_region_local_signature(base,all(u,u,0),1),false);
 for(const name of ['Array.new','Array.get','Array.set']){
  const n=name==='Array.set'?4:3,call=t('Call',name,[u,...Array(n-1).fill(t('Absent'))]);
  check(name,api.j_region_local_native(base,call),true);
  check(name+'-wrong-erased-type',api.j_region_local_native(base,t('Call',name,[ty('String'),...Array(n-1).fill(t('Absent'))])),false);
  check(name+'-partial',api.j_region_local_native(base,t('Call',name,[u])),false);
  const original=api.lookup(base,name);check(name+'-shadowed',api.j_region_local_native(list([{...original,native:false}],base),call),false);
  check(name+'-foreign',api.j_region_local_native(list([{...original,value:t('Foreign')}],base),call),false);
 }
 for(const entry of report.inputs)assert.equal(id(entry.file).sha256,entry.sha256);
 report.complete=true;report.pass=true;
}catch(e){report.error=String(e.stack??e);process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));

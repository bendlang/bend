// Prepared checked-predicate controls. Synthetic metadata is not frontend
// acceptance. Root must grant a serial slot before importing the compiler.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';

const [attemptArg,outArg]=process.argv.slice(2),attempt=path.resolve(attemptArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const manifestFile=path.join(attempt,'attempt.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));
const driver=path.join(manifest.snapshot.root,'tools/typed-driver.mjs');
const report={kind:'phase32-checked-local-vector-predicates',complete:false,pass:false,scope:'Actual checked compiler predicates on canonical Base plus synthetic metadata; no source-conformance, execution-speed or release claim.',inputs:[import.meta.filename,manifestFile,driver,...['api','runtime','base'].map(k=>manifest[k].file)].map(identity),observations:[],aliasWitness:null};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const list=(xs,tail={$:'Nil'})=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),tail);
const term=(tag,name='',kids=[],id=0,quant=0)=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list([]),originBegin:0,originEnd:0});
const ty=(name,args=[])=>term('ADT',name,args),ref=name=>term('Ref',name);
const all=(a,b,q=2,id=90000)=>term('All','',[a,b],id,q),kind=q=>term('Typ','',[term('Qua','',[],0,q)]);
const def=(name,typ,extra={})=>({$:'KDef',name,kind:'ADT',arity:0,templates:0,typ,value:term('Absent'),ctors:list([]),native:false,unsafe:false,...extra});
const record=(name,fields,quant=2,ctorName=name+'Pack')=>def(name,kind(quant),{ctors:list([def(ctorName,fields.reduceRight((b,a,i)=>all(a,b,2,90000+i),ty(name)),{kind:'Ctr',arity:fields.length})])});
const alias=(name,value)=>def(name,kind(2),{kind:'Def',value});
try{
 for(const key of ['api','runtime','base'])assert.equal(identity(manifest[key].file).sha256,manifest[key].sha256);
 let source=fs.readFileSync(manifest.api.file,'utf8');
 const names=['j_region_local_type','j_region_local_vector','j_region_record','wnf'];
 for(const name of names){const needle='function $'+name+'$(';assert.ok(source.includes(needle));assert.equal(source.indexOf(needle),source.lastIndexOf(needle),name+' exact declaration')}
 const suffix='\nexport const review={'+names.map(name=>JSON.stringify(name)+':(...a)=>run_loop($'+name+'$(...a))').join(',')+'};\n';
 const inspected=path.join(out,'inspected-api.mjs');fs.writeFileSync(inspected,source+suffix,{flag:'wx'});
 report.inspection={module:identity(inspected),unchangedSource:identity(manifest.api.file),appendedExport:suffix,scope:'Unchanged generated bodies plus diagnostic exports. Only this single compiler module is imported.'};
 source=null;
 for(const key of Object.keys(process.env))if(key.startsWith('BEND_'))delete process.env[key];
 process.env.BEND_TYPED_API=inspected;process.env.BEND_TYPED_RUNTIME=manifest.runtime.file;process.env.BEND_BASE=manifest.base.file;
 const D=await import(pathToFileURL(driver)),publicApi=await D.loadApi();
 const api=(await import(pathToFileURL(inspected))).review,base=(await D.prepareBase(publicApi)).book;
 const u=ty('U32'),a=ty('Array',[u]);
 const sigma=ty('Sigma',[term('Qua','',[],0,1),term('Qua','',[],0,2),a,term('Lam','',[u],99100,2)]);
 const pair=record('ReviewPair',[u,u]),nest=record('ReviewNest',[ty('ReviewPair'),u]),dp=record('ReviewDp',[a,u]);
 const defs=[pair,nest,dp,record('ReviewAffineFlat',[u,u],1),record('ReviewEmpty',[]),
  record('ReviewNamedTuple',[a,u],2,'Tuple'),record('ReviewRecursive',[ty('ReviewRecursive')]),record('ReviewFunction',[all(u,u)]),record('ReviewWide',Array(33).fill(u)),
  alias('ReviewPairAlias',ty('ReviewPair')),alias('ReviewNestAlias',ty('ReviewNest')),alias('ReviewDpAlias',ty('ReviewDp')),alias('ReviewSigmaAlias',sigma),alias('ReviewPairAlias2',ref('ReviewPairAlias'))];
 const erased=record('ReviewErased',[u]);erased.ctors.head.typ={...erased.ctors.head.typ,quant:0};defs.push(erased);
 const native=record('ReviewNative',[u]);native.native=true;defs.push(native);
 const book=list(defs,base);
 const cases=[
  ['scalar',u,true,false],['array',a,true,false],['sigma',sigma,true,true],['alias-sigma',ref('ReviewSigmaAlias'),true,true],
  ['terminal-pair',ty('ReviewPair'),true,false],['alias-terminal-pair',ref('ReviewPairAlias'),true,false],['alias-chain-terminal-pair',ref('ReviewPairAlias2'),true,false],
  ['nested-record',ty('ReviewNest'),true,true],['alias-nested-record',ref('ReviewNestAlias'),true,true],
  ['array-record',ty('ReviewDp'),true,true],['alias-array-record',ref('ReviewDpAlias'),true,true],
  ['affine-flat-private-record',ty('ReviewAffineFlat'),true,true],['empty-terminal-record',ty('ReviewEmpty'),true,false],
  ['ordinary-ctor-named-Tuple',ty('ReviewNamedTuple'),true,true],
  ['recursive-refused',ty('ReviewRecursive'),false,false],['function-field-refused',ty('ReviewFunction'),false,false],['wide-refused',ty('ReviewWide'),false,false],
  ['erased-field-refused',ty('ReviewErased'),false,false],['native-ordinary-refused',ty('ReviewNative'),false,false],['function-refused',all(u,u),false,false],['wrong-array-element',ty('Array',[ty('String')]),false,false]
 ];
 for(const [name,type,localExpected,vectorExpected] of cases){
  const local=api.j_region_local_type(book,type);assert.equal(local,localExpected,name+' local proof');
  // Production calls representation classification only after local admission.
  const vector=local&&api.j_region_local_vector(book,type);assert.equal(vector,vectorExpected,name+' guarded representation');
  report.observations.push({name,local,vector,localExpected,vectorExpected});
 }
 const raw=api.j_region_record(book,ref('ReviewPairAlias')),normalized=api.j_region_record(book,api.wnf(book,ref('ReviewPairAlias')));
 assert.equal(raw,false);assert.equal(normalized,true);
 report.aliasWitness={rawTerminalPredicate:raw,normalizedTerminalPredicate:normalized,correctVector:api.j_region_local_vector(book,ref('ReviewPairAlias')),meaning:'Testing public-terminal admission on an unnormalized alias would wrongly permit unboxing.'};
 assert.equal(report.aliasWitness.correctVector,false);
 for(const input of report.inputs)assert.deepEqual(identity(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));

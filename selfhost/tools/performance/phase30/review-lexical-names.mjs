// Actual compiler lexical-name controls: synthetic backend identities and a
// separately checked source program, with an independent numeric oracle.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [attemptArgument,checkedModuleArgument,outArgument]=process.argv.slice(2);
assert.ok(attemptArgument&&checkedModuleArgument&&outArgument);
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const stringify=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const manifestFile=path.resolve(attemptArgument,'attempt.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));
const driver=path.join(manifest.snapshot.root,'tools/typed-driver.mjs'),checkedModule=path.resolve(checkedModuleArgument),receiptFile=checkedModule+'.json';
const report={kind:'phase30-independent-lexical-helper-names',complete:false,pass:false,node:process.version,
 inputs:[import.meta.filename,manifestFile,driver,checkedModule,receiptFile,...['api','runtime','base'].map(k=>manifest[k].file)].map(identity),
 names:[],synthetic:[],checked:[],scope:'Synthetic KDefs exercise actual backend identity; source acceptance is claimed only for the separately checked fixture.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const save=(name,value)=>fs.writeFileSync(path.join(out,name),stringify(value),{flag:'wx'});
try{
 const receipt=JSON.parse(fs.readFileSync(receiptFile));
 assert.equal(receipt.complete,true);assert.equal(receipt.observation.checked,true);assert.equal(receipt.observation.status,'ok');
 assert.equal(receipt.attempt.sha256,identity(manifestFile).sha256);assert.equal(receipt.output.sha256,identity(checkedModule).sha256);
 for(const k of ['api','runtime','base'])assert.equal(identity(manifest[k].file).sha256,manifest[k].sha256);
 for(const key of Object.keys(process.env))if(key.startsWith('BEND_'))delete process.env[key];
 process.env.BEND_TYPED_API=manifest.api.file;process.env.BEND_TYPED_RUNTIME=manifest.runtime.file;process.env.BEND_BASE=manifest.base.file;
 const {loadApi}=await import(pathToFileURL(driver)),api=await loadApi();
 const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
 const t=(tag,name='',kids=[],id=0,quant=0)=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list([]),originBegin:0,originEnd:0});
 const lit=number=>({$:'KLiteral',kind:'U32',number,text:'',originBegin:0,originEnd:0});
 const typ=name=>t('ADT',name),v=id=>t('Var','',[],id),ref=name=>t('Ref',name),lam=(id,body)=>t('Lam','',[body],id,2),all=(id,a,b)=>t('All','',[a,b],id,2);
 const app=(f,x)=>t('App','',[f,x]),call=(name,args)=>args.reduce(app,ref(name));
 const mat=(name,arm,rest=t('Efq'))=>t('Mat',name,[arm,rest]);
 const d=(name,kind='Def',native=false,type=t('Typ'),value=t('Absent'),ctors=[],arity=0)=>({$:'KDef',name,kind,arity,templates:0,typ:type,value,ctors:list(ctors),native,unsafe:false});
 const nat=typ('Nat'),u32=typ('U32'),bool=typ('Bool');
 const names=['step','Step','step_1','step1','a.b','a/b','a_b','a1','a_1','class','constructor','__proto__','toString','λ','é','e\u0301','🙂','a-b'];
 const encoded=name=>'$R'+[...name].map(c=>'_'+c.codePointAt(0)).join('');
 assert.equal(new Set(names.map(encoded)).size,names.length);
 const owners=[d('Nat','ADT',true,t('Typ'),t('Absent'),[d('Zero','Ctr',true,nat),d('Succ','Ctr',true,all(900,nat,nat),t('Absent'),[],1)]),
 ...[['U32',['U32']],['Word.Nil',['WNil']],['Word.Con',['WCon']]].map(([name,cs])=>d(name,'ADT',true,t('Typ'),t('Absent'),cs.map(c=>d(c,'Ctr',true)))),
 d('Bool','ADT',true,t('Typ'),t('Absent'),[d('True','Ctr',true,bool),d('False','Ctr',true,bool)]),
 d('Word','Def',true),d('U32.add','Def',true,all(901,u32,all(902,u32,u32)),t('Absent'),[],2)];
 const helpers=names.map((name,index)=>d(name,'Def',false,all(3,u32,u32),lam(30,call('U32.add',[v(30),lit(index+1)])),[],1));
 const step=names.reduce((value,name)=>call(name,[value]),v(11));
 const loop=d('loop','Def',false,all(1,nat,all(2,u32,u32)),mat('Zero',lam(12,v(12)),mat('Succ',lam(10,lam(11,call('loop',[v(10),step]))))),[],2);
 // Definitions deliberately follow their caller, exercising forward binding.
 const book=[...owners,loop,...helpers];save('names.book.json',book);
 const emitted=api.j_library(list(book)),moduleFile=path.join(out,'names.mjs');
 fs.writeFileSync(moduleFile,fs.readFileSync(manifest.runtime.file,'utf8')+'\n'+emitted,{flag:'wx'});
 const line=emitted.split('\n').find(line=>line.startsWith('G["loop"]=')).replaceAll('\r','');
 assert.ok(line.includes('/* private scalar region */'));assert.ok(!line.includes('$R['));
 for(const name of names){const lexical=encoded(name);assert.ok(line.includes('function '+lexical+'('),name+' declaration');assert.ok(line.includes(lexical+'('),name+' call');report.names.push({source:name,lexical});}
 report.syntheticModule=identity(moduleFile);
 const synthetic=await import(pathToFileURL(moduleFile)),increment=names.length*(names.length+1)/2;
 for(const n of [0n,1n,3n,31n,50000n])for(const seed of [0,17,4294967295]){
  const expected=(seed+Number(n)*increment)>>>0,actual=synthetic.default.loop(n,seed);assert.equal(actual,expected);report.synthetic.push({n,seed,expected,actual});
 }
 for(const [index,name]of names.entries())assert.equal(synthetic.default[name](19),20+index,name+' public export');
 const original=await import(pathToFileURL(checkedModule)),sourceText=fs.readFileSync(checkedModule,'utf8');
 for(const name of ['step','Step','step_1','step1'])assert.ok(sourceText.includes('function '+encoded(name)+'('),'checked helper '+name);
 function oracle(n,seed){let x=seed>>>0;for(let i=0;i<n;i++){x=Math.imul((x+3)>>>0,5)>>>0;x=((x^2654435761)+1013904223)>>>0}return Math.imul((x+3)>>>0,5)>>>0}
 for(const n of [0,1,2,3,7,31,128,1000,50000])for(const seed of [0,1,17,2147483648,4294967295]){
  const expected=oracle(n,seed),actual=original.default.bench(n,seed);assert.equal(actual,expected);report.checked.push({n,seed,expected,actual});
 }
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
save('report.json',report);console.log(stringify({complete:report.complete,pass:report.pass,names:report.names.length,synthetic:report.synthetic.length,checked:report.checked.length,error:report.error}));

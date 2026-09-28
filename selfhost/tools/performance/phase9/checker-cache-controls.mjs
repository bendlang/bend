// Full public-B1 result comparisons, including chronology and prefix fallback.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [baselineArg,candidateArg,outputArg]=process.argv.slice(2);
const id=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const inputs=[baselineArg,candidateArg,import.meta.filename].map(id),output=path.resolve(outputArg);
fs.mkdirSync(output,{recursive:false});
const {default:B}=await import(pathToFileURL(inputs[0].file)),{default:C}=await import(pathToFileURL(inputs[1].file));
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const t=(tag,name='',id=0,quant=0,kids=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:nil});
const typ=q=>t('Typ','',0,0,[t('Qua','',0,q)]),adt=n=>t('ADT',n),boolType=adt('Bool');
const d=(name,type,value=t('Absent'),arity=0,kind='Def',ctors=[])=>({$:'KDef',name,kind,arity,templates:0,typ:type,value,ctors:list(ctors),native:false,unsafe:false});
const bool=d('Bool',typ(2),t('Absent'),0,'ADT',[d('True',boolType,t('Absent'),0,'Ctr'),d('False',boolType,t('Absent'),0,'Ctr')]);
const ty=(id,q=1)=>t('All','x',id,q,[boolType,boolType]),body=id=>t('Lam','x',id,1,[t('Var','x',id)]);
const law=d('f',ty(100),t('Absent'),1),fill=d('f',ty(101),body(102),1);
const early=d('early',boolType,t('Ctr','True')),later=d('later',boolType,t('Ctr','True')),use=d('use',boolType,t('Ref','later'));
const scenarios=[
 ['alpha-law-fill',[bool,law,fill],''],
 ['fresh-definition-despite-global-seed',[bool,fill],''],
 ['duplicate-law',[bool,law,law],'f: duplicate declaration'],
 ['duplicate-definition',[bool,fill,fill],'f: duplicate declaration'],
 ['changed-signature',[bool,law,{...fill,typ:ty(101,2)}],'f: definition does not match prior law signature'],
 ['future-safe-body',[bool,use,later],'use: live use of an unfilled law'],
 ['future-unsafe-body',[bool,{...use,unsafe:true},later],''],
 ['internal-spelling-is-not-cache-kind',[bool,d('$kernel.cache',boolType,t('Ctr','True'))],''],
 ['duplicate-constructor',[bool,d('Other',typ(2),t('Absent'),0,'ADT',[d('True',adt('Other'),t('Absent'),0,'Ctr')])],'Other: duplicate constructor name'],
 ['raw-empty-constructor-after-prior-definition',[bool,d('Raw',typ(2),t('Absent'),0,'ADT',[d('',adt('Raw'),t('Absent'),0,'Ctr')])],''],
];
const rows=[];
function compare(name,book,prefix,expected){
  const call=K=>prefix?K.check_book_diagnostic_from_exact_prefix(book,prefix,nil):K.check_book_diagnostic(book,nil);
  const before=JSON.stringify(book),a=call(B),b=call(C);
  assert.equal(a.error,expected,name+' baseline oracle');assert.equal(JSON.stringify(book),before,'Input mutation');
  if(a.error==='')assert.deepEqual(a.book,book,'Baseline exposed metadata');
  let same=true;try{assert.deepEqual(b,a);if(b.error==='')assert.deepEqual(b.book,book);}catch{same=false;}
  rows.push({name,prefix:!!prefix,expected,baseline:a,candidate:b,same});
}
for(const [name,defs,expected] of scenarios)compare(name,list(defs),null,expected);
const prefix=list([bool,early]),whole=list([bool,early,law,fill]);assert.equal(B.check_book(prefix),'');assert.equal(C.check_book(prefix),'');
assert.equal(B.exact_prefix(whole,prefix),true);assert.equal(C.exact_prefix(whole,prefix),true);
compare('valid-exact-prefix',whole,prefix,'');
const altered=list([bool,{...early,value:t('Ctr','False')}]);assert.equal(B.check_book(altered),'');assert.equal(C.check_book(altered),'');
assert.equal(B.exact_prefix(whole,altered),false);assert.equal(C.exact_prefix(whole,altered),false);
compare('altered-prefix-falls-back',whole,altered,'');
const badWhole=list([bool,use,later]),wrongPrefix=list([bool,later]);
assert.equal(B.exact_prefix(badWhole,wrongPrefix),false);assert.equal(C.exact_prefix(badWhole,wrongPrefix),false);
compare('nonprefix-cannot-hide-future-use',badWhole,wrongPrefix,'use: live use of an unfilled law');
compare('true-prefix-keeps-future-use-rejection',badWhole,list([bool]),'use: live use of an unfilled law');
const changedInputs=inputs.filter(before=>id(before.file).sha256!==before.sha256),pass=rows.every(r=>r.same)&&changedInputs.length===0;
fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({kind:'chronological-cache-controls',inputs,pass,changedInputs,rows},null,2)+'\n');
console.log(JSON.stringify({pass,controls:rows.length,differences:rows.filter(r=>!r.same).map(r=>({name:r.name,baseline:r.baseline.error,candidate:r.candidate.error}))}));if(!pass)process.exitCode=1;

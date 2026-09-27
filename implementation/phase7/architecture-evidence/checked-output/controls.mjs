// P7-A01: use genuine checked bodies; expose functions, never rewrite them.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';

const [baselineArg,candidateArg,runtimeArg,outArg]=process.argv.slice(2);
assert.ok(outArg,'Expected BASELINE_CHECKED_API CANDIDATE_CHECKED_API RUNTIME NEW_OUTPUT');
const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const digest=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({file:path.resolve(file),sha256:digest(fs.readFileSync(file))});
const report={kind:'checked-output-slice',complete:false,pass:false,checks:0,rows:[],boundaries:[],
  inputs:[baselineArg,candidateArg,runtimeArg,import.meta.filename].map(identity),
  scope:'Successful Ref/Var/App/Lam/Ctr/Ann checked outputs consumed by unchanged JavaScript backend; chronological validation stays separate. No specialization retirement or performance claim.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const equal=(a,b,why)=>{report.checks++;assert.deepEqual(a,b,why);};
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const array=xs=>{const out=[];for(let p=xs;p.$==='Con';p=p.tail)out.push(p.head);return out;};
const t=(tag,name='',id=0,quant=0,kids=[],removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed)});
const qua=q=>t('Qua','',0,q),typ=q=>t('Typ','',0,0,[qua(q)]),v=id=>t('Var','x',id);
const all=(id,q,a,b)=>t('All','x',id,q,[a,b]),lam=(id,b,q=1)=>t('Lam','x',id,q,[b]);
const ref=n=>t('Ref',n),app=(f,x)=>t('App','',0,0,[f,x]),ctr=(n,...xs)=>t('Ctr',n,0,0,xs);
const adt=(n,...xs)=>t('ADT',n,0,0,xs),ann=(x,ty)=>t('Ann','',0,0,[x,ty]);
const def=(name,ty,value=t('Absent'),arity=0,kind='Def',ctors=[],templates=0)=>
  ({$:'KDef',name,kind,arity,templates,typ:ty,value,ctors:list(ctors),native:false,unsafe:false});
const flag=def('Flag',typ(2),t('Absent'),0,'ADT',[def('On',adt('Flag'),t('Absent'),0,'Ctr'),def('Off',adt('Flag'),t('Absent'),0,'Ctr')]);
const main=(value,ty=adt('Flag'))=>def('main',ty,value);
const id=def('id',all(10,1,adt('Flag'),adt('Flag')),lam(11,v(11)),1);
const ignore=def('ignore',all(20,0,adt('Flag'),adt('Flag')),lam(21,ctr('On'),0),1);
const poly=def('poly',all(30,0,typ(1),all(31,1,v(30),v(30))),lam(32,lam(33,v(33)),0),2);
const box=def('Box',all(100,0,t('Qnt'),all(101,0,t('Typ','',0,0,[v(100)]),t('Typ','',0,0,[v(100)]))),t('Absent'),2,'ADT',[
  def('Box',all(102,0,t('Qnt'),all(103,0,t('Typ','',0,0,[v(102)]),all(104,1,v(103),adt('Box',v(102),v(103))))),t('Absent'),1,'Ctr')]);
const bag=def('Bag',typ(2),t('Absent'),0,'ADT',[def('Bag',all(200,1,adt('Flag'),all(201,1,adt('Flag'),adt('Bag'))),t('Absent'),2,'Ctr')]);
const apply=def('apply',all(300,1,all(301,1,adt('Flag'),adt('Flag')),all(302,1,adt('Flag'),adt('Flag'))),lam(303,lam(304,app(v(303),v(304)))),2);
const positives=[
  ['constructor',[flag,main(ctr('On'))]],
  ['identity-application',[flag,id,main(app(ref('id'),ctr('Off')))]],
  ['erased-argument',[flag,ignore,main(app(ref('ignore'),ctr('Off')))]],
  ['dependent-application',[flag,poly,main(app(app(ref('poly'),adt('Flag')),ctr('On')))]],
  ['dependent-constructor-telescope',[flag,box,main(ctr('Box',ctr('Off')),adt('Box',qua(2),adt('Flag')))]],
  ['two-constructor-fields',[flag,bag,main(ctr('Bag',ctr('On'),ctr('Off')),adt('Bag'))]],
  ['higher-order-function-argument',[flag,id,apply,main(app(app(ref('apply'),ref('id')),ctr('Off')))]],
  ['annotated-beta',[flag,main(app(ann(lam(401,v(401)),all(402,1,adt('Flag'),adt('Flag'))),ctr('On')))]],
];
const template=def('choose',all(500,0,adt('Flag'),adt('Flag')),lam(501,v(501),0),1,'Def',[],1);
const templateSource=[flag,template,main(app(ref('choose'),ctr('On')))];
const negatives=[
  ['undefined-name',[flag,main(ref('missing'))]],
  ['affine-duplicate',[flag,bag,def('dup',all(600,1,adt('Flag'),adt('Bag')),lam(601,ctr('Bag',v(601),v(601))),1)]],
  ['constructor-goal',[flag,main(ctr('On'),typ(1))]],
  ['argument-goal',[flag,id,main(app(ref('id'),typ(1)))]],
  ['first-error',[flag,main(app(ref('missing-function'),ref('missing-argument')))]],
  ['chronological-forward-reference',[flag,main(ref('later')),def('later',adt('Flag'),ctr('On'))]],
  ['chronological-law-unfilled-use',[flag,def('later',adt('Flag')),main(ref('later')),def('later',adt('Flag'),ctr('On'))]],
];
async function expose(file,label){
  const source=fs.readFileSync(file,'utf8');
  const roots=[['checkDefinition','check_definition_result',2],['checkBook','check_book',1],['context','book_context',1],['annotate','annotate',4]];
  for(const [,name]of roots)assert.equal(source.split('function $'+name+'$(').length,2,'existing checked body '+name);
  const target=path.join(out,label+'.mjs');
  fs.writeFileSync(target,source+'\n'+roots.map(([alias,name,n])=>`export const ${alias}=run_lib($${name}$,${n});`).join('\n')+'\n',{flag:'wx'});
  const m=await import(pathToFileURL(target));assert.equal(m.G,undefined,'named-field checked B1 required');
  return {...m,api:m.default,identity:identity(target)};
}
function runProgram(label,code){
  const file=path.join(out,label+'.mjs');fs.writeFileSync(file,fs.readFileSync(runtimeArg,'utf8')+'\n'+code,{flag:'wx'});
  const p=spawnSync(process.execPath,['--stack-size=4096',file],{encoding:'utf8',timeout:10000,maxBuffer:2**20});
  const result={status:p.status,signal:p.signal,stdout:p.stdout,stderr:p.stderr,error:p.error?.message,codeSha256:digest(code)};
  fs.writeFileSync(path.join(out,label+'.result.json'),JSON.stringify(result,null,2)+'\n');return result;
}
function observations(r){return {typ:r.typ,uses:r.uses,error:r.error};}
function checkedDefinitions(M,book){
  const context=M.context(book);
  return list(array(book).map(d=>d.kind!=='Def'||d.value.tag==='Absent'||d.templates>0?d:
    {...d,value:M.checkDefinition(context,d).term}));
}
try{
  const B=await expose(baselineArg,'baseline-exposed'),C=await expose(candidateArg,'candidate-exposed');
  report.exposures=[B.identity,C.identity];
  // Existing specialization is deliberately retained: it supplies this narrower
  // positive case and earns no deletion credit in the checked-output experiment.
  equal(B.checkBook(list(templateSource)),'','template source checks');
  const specialized=B.api.specialize_book(list(templateSource));equal(specialized.error,'','existing specialization succeeds');
  positives.push(['after-existing-template-specialization',array(specialized.book),templateSource]);
  fs.writeFileSync(path.join(out,'fixtures.json'),JSON.stringify({positives,negatives,templateSource},null,2)+'\n');
  for(const [id,defs,chronologicalDefs=defs]of positives){
    const book=list(defs),inputHash=digest(JSON.stringify(book));
    equal(B.checkBook(list(chronologicalDefs)),'',id+' baseline chronological source validation');
    equal(C.checkBook(list(chronologicalDefs)),'',id+' candidate chronological source validation');
    const bc=B.context(book),cc=C.context(book),annotated=B.api.annotate_selected(bc,book,nil);
    const direct=checkedDefinitions(C,book);
    for(const d of defs.filter(d=>d.kind==='Def'&&d.value.tag!=='Absent'&&d.templates===0)){
      const br=B.checkDefinition(bc,d),cr=C.checkDefinition(cc,d);
      equal(observations(cr),observations(br),id+'/'+d.name+' type, uses, error');
      equal(cr.error,'',id+'/'+d.name+' direct check succeeds');
      equal(cr.term,array(annotated).find(x=>x.name===d.name).value,id+'/'+d.name+' exact annotated term');
    }
    const baselineCode=B.api.j_program_selected(bc,annotated),candidateCode=C.api.j_program_selected(cc,direct);
    equal(candidateCode,baselineCode,id+' exact unchanged backend output');
    const baselineRun=runProgram(id+'-baseline',baselineCode),candidateRun=runProgram(id+'-candidate',candidateCode);
    equal(baselineRun.status,0,id+' baseline program executes');equal(candidateRun.status,0,id+' candidate program executes');
    equal(candidateRun.stdout,baselineRun.stdout,id+' output');equal(candidateRun.stderr,baselineRun.stderr,id+' stderr');
    equal(digest(JSON.stringify(book)),inputHash,id+' immutable source book');
    report.rows.push({id,pass:true,definitions:defs.length,program:baselineRun.stdout,codeSha256:digest(candidateCode),directAnnotationCalls:0});save();
  }
  for(const [id,defs]of negatives){
    const book=list(defs),br=B.checkBook(book),cr=C.checkBook(book);assert.ok(br,id+' fixture must reject');equal(cr,br,id+' chronological diagnostic');
    const bc=B.context(book),cc=C.context(book);let failures=0;
    for(const d of defs.filter(d=>d.kind==='Def'&&d.value.tag!=='Absent')){
      const a=B.checkDefinition(bc,d),b=C.checkDefinition(cc,d);
      equal(observations(b),observations(a),id+'/'+d.name+' type, uses, error');
      if(a.error){failures++;equal(b,a,id+'/'+d.name+' exact failed result including DTrace');}
    }
    report.rows.push({id,pass:true,rejected:br,exactFailedResults:failures});save();
  }
  const letMain=main(t('Let','',0,0,[t('Bind','x',700,1,[ann(ctr('On'),adt('Flag'))]),v(700)]));
  const matchMain=main(app(ann(t('Mat','On',0,0,[ctr('Off'),t('Mat','Off',0,0,[ctr('On'),t('Efq')])]),all(701,1,adt('Flag'),adt('Flag'))),ctr('On')));
  for(const [id,defs]of [['unsupported-let',[flag,letMain]],['unsupported-match',[flag,matchMain]],['unsupported-template-before-specialization',templateSource]]){
    const book=list(defs);equal(B.checkBook(book),'',id+' valid source');equal(C.checkBook(book),'',id+' candidate source semantics');
    const context=C.context(book),direct=checkedDefinitions(C,book),baselineAnnotated=B.api.annotate_selected(B.context(book),book,nil);
    const value=array(direct).find(d=>d.name==='main').value,expected=array(baselineAnnotated).find(d=>d.name==='main').value;
    const same=digest(JSON.stringify(value))===digest(JSON.stringify(expected));
    report.boundaries.push({id,termMatchesAnnotation:same,directTerm:value,baselineAnnotatedTerm:expected,
      supported:false,reason:id.includes('template')?'No instance book is produced; existing specialization still required.':'Checked children/binder structure not reconstructed by this bounded slice.'});save();
  }
  report.complete=true;report.pass=true;save();console.log(JSON.stringify({complete:true,pass:true,checks:report.checks,rows:report.rows.length,boundaries:report.boundaries.length}));
}catch(error){report.error=String(error.stack??error);save();console.error(report.error);process.exitCode=1;}

// Diagnostic helper-plan controls, not compiler or generated-program timing.
// Root owns execution. No source files or checked API bytes are overwritten.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [baselineArg,candidateArg,outArg]=process.argv.slice(2);
assert(baselineArg&&candidateArg&&outArg,'usage: cost-inline-controls.mjs BASELINE_API CANDIDATE_API NEW_OUT');
const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase36-inline-identity-preflight-controls',complete:false,pass:false,
  scope:'Synthetic internal typed helper plans and diagnostic visit counts; no normal checked request timing.',
  inputs:[import.meta.filename,baselineArg,candidateArg].map(identity),observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const t=(tag,name='',kids=[],id=0,quant=0)=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list([]),originBegin:7,originEnd:13});
const lit=number=>({$:'KLiteral',kind:'U32',number,text:'',originBegin:17,originEnd:19});
const ty=name=>t('ADT',name),u32=ty('U32'),array=t('ADT','Array',[u32]),box=ty('Box');
const all=(a,b)=>t('All','',[a,b],99,2),kind=t('Typ','',[t('Qua','',[],0,2)]);
const def=(name,typ,value,{native=false,kind='Def',arity=1,ctors=[]}={})=>
  ({$:'KDef',name,kind,arity,templates:0,typ,value,ctors:list(ctors),native,unsafe:false});
const ctr=(name,typ,arity,native=false)=>def(name,typ,t('Absent'),{kind:'Ctr',arity,native});
const rows=[def('Word',kind,t('Absent'),{native:true,arity:0}),
  def('Box',kind,t('Absent'),{kind:'ADT',arity:0,ctors:[ctr('Box',all(array,box),1)]})];
for(const [name,constructors]of [['U32',['U32']],['Word.Nil',['WNil']],['Word.Con',['WCon']],['Bool',['False','True']]])
  rows.push(def(name,kind,t('Absent'),{kind:'ADT',native:true,arity:0,ctors:constructors.map(n=>ctr(n,ty(name),0,true))}));
const ann=(body,typ=u32)=>t('Ann','',[body,typ]);
const scalar=def('scalar',all(u32,u32),ann(lit(3)));
const vector=def('vector',all(u32,box),ann(t('JVector','Box',[t('JSlot','',[],0)]),box));
const native={...vector,name:'native',native:true};
const residual={...vector,name:'residual',value:t('JResidual','',[vector.value])};
const fold={...scalar,name:'fold',value:t('JFold','Box',[ann(lit(7))])};
const caller=def('caller',all(u32,box),ann(t('JCall','vector',[lit(5)]),box));
function apiCopy(api,role){
  const original=fs.readFileSync(api,'utf8'),names=['j_region_declarations','j_region_inline_defs','j_region_definitions'];
  if(role==='candidate')names.push('j_region_inline_available');
  for(const name of [...names,'j_region_inline_term'])assert.equal(original.split('function $'+name+'$(').length,2,name);
  const suffix='\n// Diagnostic exports and counter wrappers; not performance measurement.\n'+
    'let phase36InlineVisits=0;const phase36InlineOriginal=$j_region_inline_term$;'+
    '$j_region_inline_term$=function(...args){phase36InlineVisits++;return phase36InlineOriginal(...args);};\n'+
    'export const phase36Cost={reset:()=>{phase36InlineVisits=0;},visits:()=>phase36InlineVisits,'+
    names.map(n=>n+':(...a)=>run_loop($'+n+'$(...a))').join(',')+'};\n';
  const file=path.join(out,role+'-diagnostic-api.mjs');fs.writeFileSync(file,original+suffix,{flag:'wx'});
  report[role+'Diagnostic']={...identity(file),parent:identity(api),unchangedPrefixBytes:Buffer.byteLength(original)};
  return file;
}
try{
  const baseline=(await import(pathToFileURL(apiCopy(baselineArg,'baseline')))).phase36Cost;
  const candidate=(await import(pathToFileURL(apiCopy(candidateArg,'candidate')))).phase36Cost;
  function probe(name,helpers,expected,{emit=true,identityPass=false}={}){
    const hs=list(helpers),book=list([...rows,...helpers]);
    assert.equal(candidate.j_region_inline_available(book,hs),expected,name+': availability');
    const oldPlan=baseline.j_region_inline_defs(book,hs,hs),newPlan=candidate.j_region_inline_defs(book,hs,hs);
    assert.deepEqual(newPlan,oldPlan,name+': unchanged transformer');
    if(identityPass)assert.deepEqual(oldPlan,hs,name+': old pass is structural identity including spans');
    const row={name,available:expected,identityPass,emissionCompared:emit};
    if(emit){
      baseline.reset();const a=baseline.j_region_declarations(book,hs);row.baselineInlineVisits=baseline.visits();
      candidate.reset();const b=candidate.j_region_declarations(book,hs);row.candidateInlineVisits=candidate.visits();
      assert.equal(b,a,name+': exact declarations');
      if(!expected)assert.equal(row.candidateInlineVisits,0,name+': no rebuilding');
      else assert.equal(row.candidateInlineVisits,row.baselineInlineVisits,name+': unchanged vector path');
      row.bytes=Buffer.byteLength(a);row.sha256=createHash('sha256').update(a).digest('hex');
    }
    report.observations.push(row);
  }
  probe('empty',[],false,{identityPass:true});
  probe('scalar-Ann',[scalar],false,{identityPass:true});
  probe('native-vector-only',[native],false,{identityPass:true});
  probe('residual-vector-only',[residual],false,{identityPass:true});
  probe('fold-only',[fold],false,{identityPass:true,emit:false});
  probe('non-Def-vector',[{...vector,kind:'Ctr'}],false,{identityPass:true,emit:false});
  probe('vector-without-call',[vector],true);
  probe('vector-call',[caller,vector],true);
  probe('vector-after-scalars',[scalar,residual,vector],true);
  let deep=lit(3);for(let i=0;i<2100;i++)deep=ann(deep);
  probe('budget-failure-keeps-original',[{...scalar,value:deep}],false,{identityPass:true,emit:false});
  for(const row of report.inputs)assert.deepEqual(identity(row.file),row);
  report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));

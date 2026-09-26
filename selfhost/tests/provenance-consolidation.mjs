// Compare complete, ordered provenance across two genuinely built compiler APIs.
// Usage: node tests/provenance-consolidation.mjs BASELINE_API CANDIDATE_API NEW_REPORT
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {createCompilerAbi} from '../tools/compiler-abi.mjs';

const [beforeArg,afterArg,reportArg]=process.argv.slice(2);
assert.ok(beforeArg&&afterArg&&reportArg,'Expected BASELINE_API CANDIDATE_API NEW_REPORT');
const reportPath=path.resolve(reportArg);
assert.ok(!fs.existsSync(reportPath),'Preserve existing report: '+reportPath);
const hash=value=>createHash('sha256').update(value).digest('hex');
const valueHash=value=>hash(JSON.stringify(value));
const identity=file=>({path:path.resolve(file),canonicalPath:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const identities=[beforeArg,afterArg,fileURLToPath(import.meta.url),fileURLToPath(new URL('../tools/compiler-abi.mjs',import.meta.url))].map(identity);
const nil={$:'Nil'},list=items=>items.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const array=value=>{const items=[];while(value?.$==='Con'){items.push(value.head);value=value.tail;}assert.equal(value?.$,'Nil');return items;};
const source=(file,text,name=file)=>({$:'FSource',name,path:file,text});
const fields={Nil:[],Con:['head','tail'],FSource:['name','path','text'],FParsedSource:['name','path','text','parsed'],
  FResult:['book','error','imports'],FLoadTrace:['result','done','sources'],FProvenance:['result','origins'],
  KTerm:['tag','name','id','quant','kids','removed'],KDef:['name','kind','arity','templates','typ','value','ctors','native','unsafe'],
  DOrigin:['definition','term','source','begin','end','path']};
const load=async file=>{const module=await import(pathToFileURL(file));return module.G?createCompilerAbi({fields,ctor:module.ctor}).wrap(module.default):module.default;};
const B=await load(identities[0].canonicalPath),C=await load(identities[1].canonicalPath);
const required=['f_load_origins','f_load_origins_for','f_loaded_origins_for','f_load_graph','f_load_graph_trace','f_load_graph_seed_trace','f_parse','f_source_parsed'];
for(const [label,api] of [['baseline',B],['candidate',C]])for(const name of required)assert.equal(typeof api[name],'function',`${label} must export ${name}`);

const prelude='type Flag is Data:\n  On{}\n  Off{}\n\n';
const cases=[];
const single=(id,text,rejected=false)=>{const main=`/provenance/${id}/main.bend`;cases.push({id,main,sources:[source(main,text)],rejected});};
single('empty','');
single('occurrences','# 😀 preceding codepoint\r\n'+prelude+
  'type Box is Data:\n  Mk{value: Flag}\n'+
  'def first() -> Flag:\n  (x => x)(Missing)\n'+
  'def repeated() -> Box:\n  Mk{Missing}\n'+
  'def same() -> Box:\n  Mk{Missing}\n');
single('declaration-events',prelude+'law broken:\n  Flag\ndef broken():\n  Missing\n');
single('parse-error','def main(\n',true);
single('missing-import','import ./absent.bend as Absent\n',true);
single('duplicate-declaration',prelude+'def value() -> Flag:\n  On{}\ndef value() -> Flag:\n  Off{}\n',true);
const graph=(id,entries,rejected=false)=>{const directory=`/provenance/${id}/`;cases.push({id,main:directory+'main.bend',sources:entries.map(([file,text])=>source(directory+file,text)),rejected});};
graph('cycle',[['main.bend','import ./child.bend as Child\n'],['child.bend','import ./main.bend as Main\n']],true);
graph('aliases',[
  ['main.bend','import ./child.bend as A\nimport ./child.bend as B\ndef main() -> A.Flag:\n  B.On{}\n'],
  ['child.bend',prelude+'def missing() -> Flag:\n  Missing\n'],
]);
graph('diamond',[
  ['main.bend','import ./left.bend as L\nimport ./right.bend as R\ndef main() -> L.Flag:\n  R.make()\n'],
  ['left.bend','import ./shared.bend as S\ndef make() -> S.Flag:\n  S.On{}\n'],
  ['right.bend','import ./shared.bend as S\ndef make() -> S.Flag:\n  S.Off{}\n'],
  ['shared.bend','# 😀 imported origin\n'+prelude+'law broken:\n  Flag\ndef broken():\n  (x => x)(Missing)\n'],
]);
const base=source('/provenance/seed/base.bend',prelude,'Base');
const main=source('/provenance/seed/main.bend','import Base\ndef main() -> Flag:\n  Missing\n');
cases.push({id:'seeded-base',main:main.name,sources:[main,base],base,rejected:false});

const report={kind:'provenance-consolidation-equivalence',complete:false,pass:false,identities,
  node:{path:process.execPath,version:process.version,args:process.execArgv},required,
  scope:'Ordered loader/provenance equality, token ranges and final-core routes; no checker-conformance or performance claim.',
  cases,checks:0,rows:[]};
fs.mkdirSync(path.dirname(reportPath),{recursive:true});
const save=()=>fs.writeFileSync(reportPath,JSON.stringify(report,null,2)+'\n');
const eq=(a,b,label)=>{report.checks++;assert.deepEqual(a,b,label);};
function routeTerm(definition,route){
  const [slot,...rest]=route;
  let term;
  if(slot===0)term=definition.typ;
  else if(slot===1)term=definition.value;
  else if(slot===2){const constructor=array(definition.ctors)[rest.shift()];if(rest.shift()!==0||!constructor)return undefined;term=constructor.typ;}
  else return undefined;
  for(const index of rest){if(!term)return undefined;term=array(term.kids)[index];}
  return term;
}
function inspectOrigins(provenance,sources){
  const definitions=array(provenance.result.book),texts=new Set(sources.map(s=>s.text));
  for(const origin of array(provenance.origins)){
    assert.equal(origin.$,'DOrigin');assert.ok(texts.has(origin.source));
    assert.ok(Number.isInteger(origin.begin)&&origin.begin>=0&&origin.end>origin.begin&&origin.end<=origin.source.length);
    assert.ok(['Ref','ADT','Ctr'].includes(origin.term.tag));
    if(origin.term.name==='Missing')assert.equal(origin.source.slice(origin.begin,origin.end),'Missing','UTF-16 range selects the actual token');
    const route=array(origin.path),wanted=valueHash(origin.term);
    assert.ok(definitions.some(d=>d.name===origin.definition&&valueHash(routeTerm(d,route)??null)===wanted),'origin follows a matching final declaration event');
  }
}
save();
for(const fixture of cases)for(const mode of ['raw','parsed']){
  const row={id:fixture.id,mode,inputSha256:valueHash(fixture),complete:false,pass:false,observations:[]};report.rows.push(row);
  const observe=(label,a,b)=>{eq(a,b,`${fixture.id}/${mode}/${label}`);row.observations.push({label,sha256:valueHash(a)});};
  try{
    const prepare=api=>list(fixture.sources.map(s=>mode==='raw'?s:api.f_source_parsed(s.name,s.path,s.text,api.f_parse(s.text))));
    const bs=prepare(B),cs=prepare(C),inputsBefore=[valueHash(bs),valueHash(cs)];
    const before=B.f_load_origins(fixture.main,bs),after=C.f_load_origins(fixture.main,cs);
    observe('all origins',after,before);assert.equal(Boolean(before.result.error),fixture.rejected,'fixture must reach its declared loading outcome');
    observe('baseline loaded result',before.result,B.f_load_graph(fixture.main,bs));
    observe('candidate loaded result',after.result,C.f_load_graph(fixture.main,cs));
    inspectOrigins(after,fixture.sources);
    const bt=B.f_load_graph_trace(fixture.main,bs),ct=C.f_load_graph_trace(fixture.main,cs);
    observe('trace',ct,bt);observe('trace result',ct.result,after.result);
    const filters=[...new Set([...array(before.result.book).map(d=>d.name),'','not-a-definition'])];
    for(const name of filters){
      const bf=B.f_load_origins_for(fixture.main,bs,name),cf=C.f_load_origins_for(fixture.main,cs,name);
      observe(`filter ${JSON.stringify(name)}`,cf,bf);
      observe(`filter result ${JSON.stringify(name)}`,cf.result,after.result);
      observe(`filter order ${JSON.stringify(name)}`,array(cf.origins),array(after.origins).filter(o=>o.definition===name));
      observe(`baseline trace filter ${JSON.stringify(name)}`,B.f_loaded_origins_for(bt,name),bf);
      observe(`candidate trace filter ${JSON.stringify(name)}`,C.f_loaded_origins_for(ct,name),bf);
    }
    if(fixture.base){
      const bb=B.f_load_graph('Base',list([fixture.base])).book,cb=C.f_load_graph('Base',list([fixture.base])).book;
      for(const [label,seedPath,seedText] of [['valid',fixture.base.path,fixture.base.text],['wrong path',fixture.base.path+'.changed',fixture.base.text],['wrong bytes',fixture.base.path,fixture.base.text+'\n']]){
        const bst=B.f_load_graph_seed_trace(fixture.main,bs,seedPath,seedText,bb),cst=C.f_load_graph_seed_trace(fixture.main,cs,seedPath,seedText,cb);
        observe(`seed ${label}`,cst,bst);observe(`seed ${label} result`,cst.result,after.result);
        for(const name of filters)observe(`seed ${label} origins ${JSON.stringify(name)}`,C.f_loaded_origins_for(cst,name),B.f_loaded_origins_for(bst,name));
      }
    }
    observe('caller inputs unchanged',[valueHash(bs),valueHash(cs)],inputsBefore);
    row.originCount=array(after.origins).length;row.filters=filters;row.complete=true;row.pass=true;
  }catch(error){row.error={message:error.message,stack:error.stack};}
  save();
}
for(const initial of identities)eq(identity(initial.path),initial,'consumed artifact remained unchanged');
report.complete=report.rows.length===cases.length*2&&report.rows.every(row=>row.complete);
report.pass=report.complete&&report.rows.every(row=>row.pass);save();
console.log(JSON.stringify({report:reportPath,complete:report.complete,pass:report.pass,checks:report.checks,rows:report.rows.map(({id,mode,pass,error})=>({id,mode,pass,error:error?.message}))}));
if(!report.pass)process.exitCode=1;

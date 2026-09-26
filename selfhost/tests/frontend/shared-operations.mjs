// Cross-version whole-result controls for shared loader/error operations.
// Test-only exports expose existing checked function bodies without rewriting them.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';

const [beforeArg,afterArg,outArg]=process.argv.slice(2);
assert.ok(beforeArg&&afterArg&&outArg,'Expected BASELINE_API CANDIDATE_API NEW_DIRECTORY');
const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
const identity=file=>({file:path.resolve(file),sha256:hash(fs.readFileSync(file))});
const valueHash=value=>hash(JSON.stringify(value));
const report={kind:'shared-frontend-operations',complete:false,pass:false,checks:0,rows:[],
  inputs:[beforeArg,afterArg,import.meta.filename].map(identity),
  scope:'Exact ordered graph/trace/seed results and embedded-error selection; test-only exports retain checked bodies. No timing or fixed-point claim.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const unlist=xs=>{const out=[];for(let node=xs;node.$==='Con';node=node.tail)out.push(node.head);return out;};
const term=(tag,name='',kids=[],id=0)=>({$:'KTerm',tag,name,id,quant:0,kids:list(kids),removed:nil});
const absent=term('Absent'),err=name=>term('Error',name);
const def=(name,typ=absent,value=absent,ctors=[])=>({$:'KDef',name,kind:'Def',arity:0,templates:0,typ,value,ctors:list(ctors),native:false,unsafe:false});
const source=(name,text,file=name)=>({$:'FSource',name,path:file,text});
const prelude='type Flag is Data:\n  On{}\n  Off{}\n';
const main='/shared/main.bend',base=source('Base',prelude,'/shared/base.bend');
const emptyGraph={$:'FGraph',book:nil,error:'',done:nil};
const compare=(a,b,label)=>{report.checks++;assert.deepEqual(a,b,label);};
async function expose(file,label){
  const text=fs.readFileSync(file,'utf8');
  const exports=[['errorTerm','f_error_term',1],['errorDefs','f_error_defs',1],['graph','f_graph_load',5]];
  for(const [,name] of exports)assert.equal(text.split('function $'+name+'$(').length,2,'Existing checked body '+name);
  const target=path.join(out,label+'.mjs');
  fs.writeFileSync(target,text+'\n'+exports.map(([alias,name,arity])=>`export const ${alias} = run_lib($${name}$, ${arity});`).join('\n')+'\n',{flag:'wx'});
  const module=await import(pathToFileURL(target));assert.equal(module.G,undefined,'Use named-field checked B1');
  return {api:module.default,...module,exposure:identity(target)};
}
try{
  const B=await expose(beforeArg,'baseline'),C=await expose(afterArg,'candidate');
  report.exposures=[B.exposure,C.exposure];
  for(const api of [B.api,C.api])for(const name of ['f_parse','f_source_parsed','f_load_graph','f_load_graph_trace','f_load_graph_seed','f_load_graph_seed_trace','f_main_names'])assert.equal(typeof api[name],'function',name);
  const fixtures=[
    ['empty',[source(main,'')],false],
    ['simple',[source(main,prelude+'def main() -> Flag:\n  On{}\n')],false],
    ['law-fill',[source(main,prelude+'law pick:\n  for +a: Flag\n  for +b: Flag\n  Flag\n@unsafe\ndef pick(a, b):\n  a\ndef main() -> Flag:\n  pick(On{}, Off{})\n')],false],
    ['parse-error',[source(main,'def main(\n')],true],
    ['missing-source',[],true],
    ['empty-main-path',[source(main,prelude,'')],true],
    ['missing-import',[source(main,'import ./absent.bend as A\n')],true],
    ['cycle',[source(main,'import ./child.bend as C\n'),source('/shared/child.bend','import ./main.bend as M\n')],true],
    ['aliases',[source(main,'import ./child.bend as A\nimport ./child.bend as B\ndef main() -> A.Flag:\n  B.On{}\n'),source('/shared/child.bend',prelude)],false],
    ['diamond',[source(main,'import ./left.bend as L\nimport ./right.bend as R\n'),source('/shared/left.bend','import ./child.bend as C\n'),source('/shared/right.bend','import ./child.bend as C\n'),source('/shared/child.bend',prelude)],false],
    ['duplicate-declaration',[source(main,prelude+'def value() -> Flag:\n  On{}\ndef value() -> Flag:\n  Off{}\n')],true],
    ['partial-failure',[source(main,'import ./child.bend as C\nimport ./absent.bend as A\n'),source('/shared/child.bend',prelude)],true],
    ['empty-base-path',[source(main,'import Base\n'),source('Base',prelude,'')],true],
    ['valid-base',[source(main,'import Base\ndef main() -> Flag:\n  On{}\n'),base],false],
    ['unused-base',[source(main,prelude),base],false],
  ];
  const seeds=[B,C].map(M=>M.api.f_load_graph('Base',list([base])).book);
  compare(seeds[0],seeds[1],'Base seed books');
  for(const [id,sources,rejected] of fixtures)for(const mode of ['raw','parsed']){
    const prepare=api=>list(sources.map(s=>mode==='raw'?s:api.f_source_parsed(s.name,s.path,s.text,api.f_parse(s.text))));
    const bs=prepare(B.api),cs=prepare(C.api),originals=[valueHash(bs),valueHash(cs)];
    const expected=B.api.f_load_graph(main,bs),actual=C.api.f_load_graph(main,cs);
    assert.equal(Boolean(expected.error),rejected,id+' fixture outcome');compare(actual,expected,id+'/'+mode+'/graph');
    const bt=B.api.f_load_graph_trace(main,bs),ct=C.api.f_load_graph_trace(main,cs);
    compare(ct,bt,id+'/'+mode+'/trace');compare(ct.result,actual,id+'/trace-result');
    const names=C.api.f_main_names(main,cs);compare(names,B.api.f_main_names(main,bs),id+'/names');
    if(id==='law-fill')compare(unlist(names),['Flag','pick','main'],id+'/first-occurrence-order');
    for(const [seedId,seedPath,seedText,valid] of [['valid',base.path,base.text,true],['stale-text',base.path,base.text+'#stale',false],['stale-path','/elsewhere',base.text,false],['disabled','','',false]]){
      const bseed=valid?seeds[0]:nil,cseed=valid?seeds[1]:nil;
      const br=B.api.f_load_graph_seed(main,bs,seedPath,seedText,bseed),cr=C.api.f_load_graph_seed(main,cs,seedPath,seedText,cseed);
      compare(cr,br,id+'/'+mode+'/'+seedId);compare(cr,actual,id+'/'+mode+'/'+seedId+'/ordinary');
      compare(C.api.f_load_graph_seed_trace(main,cs,seedPath,seedText,cseed),B.api.f_load_graph_seed_trace(main,bs,seedPath,seedText,bseed),id+'/'+mode+'/'+seedId+'/trace');
    }
    compare([valueHash(bs),valueHash(cs)],originals,id+'/input-immutability');
    report.rows.push({id,mode,pass:true,error:actual.error,graphSha256:valueHash(actual),traceSha256:valueHash(ct)});save();
  }
  // Direct parsed-source API: trust its cached parse while retaining original
  // text for provenance. This does not model a driver-validated persisted cache.
  const validText=prelude+'def main() -> Flag:\n  On{}\n',invalidText='def main(\n';
  for(const [id,text,cachedText,rejected] of [
    ['invalid-text-valid-parse',invalidText,validText,false],
    ['valid-text-invalid-parse',validText,invalidText,true],
  ]){
    const bs=list([B.api.f_source_parsed(main,main,text,B.api.f_parse(cachedText))]);
    const cs=list([C.api.f_source_parsed(main,main,text,C.api.f_parse(cachedText))]);
    const originals=[valueHash(bs),valueHash(cs)],expected=B.api.f_load_graph(main,bs),actual=C.api.f_load_graph(main,cs);
    assert.equal(Boolean(expected.error),rejected,id+'/fixture-outcome');compare(actual,expected,id+'/graph');
    const bt=B.api.f_load_graph_trace(main,bs),ct=C.api.f_load_graph_trace(main,cs);
    compare(ct,bt,id+'/trace');compare(ct.result,actual,id+'/trace-result');
    compare(C.api.f_main_names(main,cs),B.api.f_main_names(main,bs),id+'/names');
    compare([valueHash(bs),valueHash(cs)],originals,id+'/input-immutability');
    report.rows.push({id,mode:'trusted-parsed',pass:true,error:actual.error,graphSha256:valueHash(actual),traceSha256:valueHash(ct)});save();
  }
  // This marked book is a direct trusted-API selection sentinel, not evidence
  // for a driver-validated cache. Maintained cache tests cover hashes/invalidation.
  for(const mode of ['raw','parsed'])for(const [id,seedPath,seedText,used] of [
    ['valid',base.path,base.text,true],['stale-text',base.path,base.text+'#stale',false],
    ['stale-path','/elsewhere',base.text,false],['disabled','','',false],
    ['unused',base.path,base.text,false],
  ]){
    const sources=[source(main,id==='unused'?prelude:'import Base\n'),base];
    const prepare=M=>list(sources.map(s=>mode==='raw'?s:M.api.f_source_parsed(s.name,s.path,s.text,M.api.f_parse(s.text))));
    const bs=prepare(B),cs=prepare(C),bseed=list([...unlist(seeds[0]),def('seed_probe_marker')]),cseed=list([...unlist(seeds[1]),def('seed_probe_marker')]);
    const originals=[valueHash(bs),valueHash(cs),valueHash(bseed),valueHash(cseed)];
    const expected=B.api.f_load_graph_seed(main,bs,seedPath,seedText,bseed),actual=C.api.f_load_graph_seed(main,cs,seedPath,seedText,cseed);
    compare(actual,expected,'seed-selection/'+id+'/'+mode);compare(actual.error,'','seed-selection/'+id+'/accepted');
    compare(unlist(actual.book).some(d=>d.name==='seed_probe_marker'),used,'seed-selection/'+id+'/selected');
    compare(C.api.f_load_graph_seed_trace(main,cs,seedPath,seedText,cseed),B.api.f_load_graph_seed_trace(main,bs,seedPath,seedText,bseed),'seed-selection/'+id+'/trace');
    compare([valueHash(bs),valueHash(cs),valueHash(bseed),valueHash(cseed)],originals,'seed-selection/'+id+'/input-immutability');
    report.rows.push({id:'seed-selection-'+id,mode,pass:true,selected:used});save();
  }
  const prior={$:'FGraph',book:list([def('already')]),error:'earlier error',done:nil};
  const loaded=term('Loaded',main,[term('Ref','first')]);
  const graphCases=[
    ['prior-error-wins','missing','',nil,prior,nil,'earlier error'],
    ['missing-before-cycle','missing','',nil,emptyGraph,list(['missing']),'module source was not supplied'],
    ['empty-base-before-seed','Base','',list([source('Base',prelude,'')]),emptyGraph,nil,'module source was not supplied'],
    ['cycle-before-cache',main,'',list([source(main,prelude)]),{$:'FGraph',book:nil,error:'',done:list([loaded])},list([main]),'cyclic import through '+main],
    ['namespace-conflict',main,'second',list([source(main,prelude)]),{$:'FGraph',book:nil,error:'',done:list([loaded])},nil,'one namespace per source file: '+main],
  ];
  for(const [id,...values] of graphCases){
    const expectedError=values.pop(),original=valueHash(values),actual=C.graph(...values);
    compare(valueHash(values),original,id+'/candidate-input-immutability');
    const expected=B.graph(...values);compare(valueHash(values),original,id+'/baseline-input-immutability');
    assert.equal(expected.error,expectedError,id);compare(actual,expected,id);report.rows.push({id,pass:true,error:actual.error});
  }
  const terms=[['absent',absent,''],['named',err('first'),'first'],['empty-error-children',term('Error','',[err('hidden')]),''],['children-left-first',term('Pair','',[err('left'),err('right')]),'left'],['skip-empty-child',term('Pair','',[err(''),err('next')]),'next']];
  for(const [id,t,wanted] of terms){
    const original=valueHash(t);assert.equal(B.errorTerm(t),wanted,id);compare(valueHash(t),original,id+'/baseline-input-immutability');
    compare(C.errorTerm(t),wanted,id);compare(valueHash(t),original,id+'/candidate-input-immutability');report.rows.push({id:'term-'+id,pass:true,error:wanted});
  }
  const books=[['empty',[], ''],['type-before-value',[def('x',err('type'),err('value'))],'type'],['value-before-ctor',[def('x',absent,err('value'),[def('Ctor',err('ctor'))])],'value'],['ctor-before-next',[def('x',absent,absent,[def('Ctor',err('ctor'))]),def('y',err('next'))],'ctor'],['nested-ctor',[def('x',absent,absent,[def('C',absent,absent,[def('D',err('deep'))])])],'deep'],['empty-error-skips-children',[def('x',term('Error','',[err('hidden')])),def('y',err('next'))],'next']];
  for(const [id,defs,wanted] of books){
    const book=list(defs),original=valueHash(book);assert.equal(B.errorDefs(book),wanted,id);compare(valueHash(book),original,id+'/baseline-input-immutability');
    compare(C.errorDefs(book),wanted,id);compare(valueHash(book),original,id+'/candidate-input-immutability');report.rows.push({id:'book-'+id,pass:true,error:wanted});
  }
  for(const input of [...report.inputs,...report.exposures])compare(identity(input.file),input,'Stable input/artifact');
  report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,checks:report.checks,rows:report.rows.length,error:report.error}));

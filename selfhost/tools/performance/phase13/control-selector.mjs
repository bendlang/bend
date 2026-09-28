// Independent actual-selector tests. Synthetic owners are not checked compiler roots.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity,verifyAttempt} from '../../development/workflow.mjs';

const [outArg]=process.argv.slice(2),out=path.resolve(outArg),root=path.resolve(import.meta.dirname,'../../..');
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const helper=path.join(root,'build/phase12/integrated-03/snapshot/tools/development/equality.mjs');
const origins=[helper,...['rewriter-structure.mjs','rewriter-v5.mjs','selector-fusion.mjs'].map(n=>path.join(import.meta.dirname,n))],consumed=[];
for(const file of origins){const target=path.join(out,path.relative(root,file));fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(file,target);consumed.push(target);}
const R=await import(pathToFileURL(consumed[1])),V=await import(pathToFileURL(consumed[2])),S=await import(pathToFileURL(consumed[3]));
const m=await verifyAttempt(path.join(root,'build/phase12/integrated-03')),source=fs.readFileSync(m.checkedApi.file,'utf8');
const encode=value=>JSON.stringify(value,(_k,v)=>v===undefined?{$controlUndefined:true}:v,2);
const report={kind:'phase13-independent-actual-selector-controls',complete:false,pass:false,scope:'Actual frozen selector versus v5 on synthetic generated owners, with exact existing candidate reproduction. Private appended exports change no tested body. Not a new checked B1, full compiler gate, performance measurement or universal stack-equivalence claim.',inputs:[import.meta.filename,process.execPath,...origins,...consumed,m.checkedApi.file].map(identity),rows:[],refusals:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),encode(report)+'\n');save();
const branch=(param,body)=>`run_clo((${param})=>{${body}})`;
const choose=(condition,yes,no)=>`return $kc$(${condition},${yes},${no});`;
const tag=(name='B',value='term')=>`$String$eq$($tg$(${value}),"${name}")`;
const terminal=(label,unit)=>branch(unit,`return effect("${label}",${unit});`);
const oneChild=(condition=tag(),innerYes=terminal('B','ub'),outerNo='uab')=>choose(tag('A'),terminal('A','ua'),branch(outerNo,choose(condition,innerYes,terminal('O','uo'))));
const chain=choose(tag('A'),terminal('A','ua'),branch('uab',choose(tag('B'),terminal('B','ub'),branch('ubc',choose(tag('C'),terminal('C','uc'),terminal('O','uo'))))));
const insert=(body,params='term,effect',base=source)=>base.replace('export default {',()=>`function $controlProbe$(${params}) {${body}}\nexport default {`);
const observe=fn=>{try{return{value:fn()};}catch(e){return{error:{name:e?.name??typeof e,message:e?.message??String(e)}};}};
const arrowBodies=src=>{const view=R.moduleView(src),owner=view.functions.get('$controlProbe$'),result={};for(let i=owner.body+1;i<owner.end;i++){if(view.ts[i].text!=='(')continue;const body=view.ts[i].close+3;if(view.ts[body]?.text!=='{')continue;const a=view.arrow([i,view.ts[body].close+1]);if(a)result[a.param]=src.slice(view.ts[a.body].start,view.ts[a.end].end);}return result;};
const runCase=(api,setup,mode='normal',invocation='ordinary')=>{
 const events=[],term=setup(events),units=[];
 const effect=(label,unit)=>{events.push(['body',label,unit?.$]);units.push(unit);if(mode==='throw')throw new Error('body:'+label);if(mode==='unit')return unit;if(mode==='closure')return ()=>[label,unit.$];if(mode==='jump')return{$:'$JMP',f:(x)=>{events.push(['jump',x]);return x;},x:[label]};return label;};
 const result=observe(()=>{let value=invocation==='partial'?api(term)(effect):invocation==='extra'?api(term,effect,99):api(term,effect);if(mode==='closure')value=value();if(mode==='unit'){const second=api(term,effect);return{first:value.$,second:second.$,distinct:value!==second};}return value;});
 return{result,events};
};
try{
 const candidate=path.join(root,'build/phase13/selector-norm-eval-02/api.mjs'),actual=S.transform(source,{families:['$norm_eval_node$']});report.inputs.push(identity(candidate));assert.equal(actual.source,fs.readFileSync(candidate,'utf8'));report.existingCandidate={api:identity(candidate),removed:actual.report.removedIntermediateSelectors,exact:true};save();
 const input=insert(chain),inputFile=path.join(out,'input.mjs');fs.writeFileSync(inputFile,input);report.inputs.push(identity(inputFile));
 const baseline=V.transform(input,{version:5}),candidateResult=S.transform(input,{families:['$controlProbe$']});assert.equal(candidateResult.report.removedIntermediateSelectors,2);
 const before=arrowBodies(baseline.source),after=arrowBodies(candidateResult.source);report.bodyIdentity={preserved:[],removed:[]};
 for(const unit of ['ua','ub','uc','uo']){assert.equal(after[unit],before[unit]);report.bodyIdentity.preserved.push(unit);}
 for(const unit of ['uab','ubc']){assert.ok(before[unit]);assert.equal(after[unit],undefined);report.bodyIdentity.removed.push(unit);}save();
 const apis=[];for(const [name,body]of[['baseline',baseline.source],['candidate',candidateResult.source]]){const file=path.join(out,name+'.mjs');fs.writeFileSync(file,body+'\nexport const control=run_lib((term,effect)=>run_loop($controlProbe$(term,effect)),2);\n');report.inputs.push(identity(file));apis.push((await import(pathToFileURL(file))).control);}
 const cases=[];
 for(const value of ['A','B','C','Other','']){cases.push({name:'native '+JSON.stringify(value),setup:()=>({tag:value})});cases.push({name:'boxed '+JSON.stringify(value),setup:()=>({tag:new String(value)}),boundary:'Non-native tag fallback; may reject malformed tags.'});}
 for(const value of ['A','B','C','Other'])cases.push({name:'getter '+value,setup:events=>({get tag(){events.push(['get',value]);return value;}})});
 cases.push({name:'changing getter chooses second test',setup:events=>{let i=0;return{get tag(){const value=['Other','B','C'][i++];events.push(['get',value]);return value;}};}});
 for(const throwAt of [1,2,3])cases.push({name:'getter throws at '+throwAt,setup:events=>{let i=0;return{get tag(){events.push(['get',++i]);if(i===throwAt)throw new Error('getter:'+i);return'Other';}};}});
 for(const value of [null,undefined])cases.push({name:'raw '+String(value),setup:()=>({tag:value}),boundary:'Malformed raw host term outside ordinary native-tag contract.'});
 cases.push({name:'raw tag fallback throws',setup:events=>({tag:{codePointAt(){events.push(['codePointAt']);throw new Error('tag-fallback');}}}),boundary:'Host representation probe.'});
 for(const label of ['A','B','C','Other'])cases.push({name:'selected body throws '+label,setup:()=>({tag:label}),mode:'throw'});
 for(const mode of ['unit','closure','jump'])cases.push({name:'selected body '+mode,setup:()=>({tag:'C'}),mode});
 for(const invocation of ['partial','extra'])cases.push({name:'public '+invocation+' arguments',setup:()=>({tag:'B'}),invocation});
 for(const c of cases){const observations=apis.map(api=>runCase(api,c.setup,c.mode,c.invocation));report.rows.push({name:c.name,boundary:c.boundary,observations,pass:encode(observations[0])===encode(observations[1])});save();}
 const negatives=[
  {name:'discarded Unit direct use',body:oneChild(tag(),branch('ub','return effect("B",uab);'))},
  {name:'discarded Unit nested capture',body:oneChild(tag(),branch('ub','return (later)=>{return effect("B",uab);};'))},
  {name:'arrow shadows owner parameter',body:oneChild(tag(),branch('term','return effect("B",term);'))},
  {name:'owner const declaration',body:'const local=term;'+oneChild()},
  {name:'owner assignment',body:'term=term;'+oneChild()},
  ...['<<=','>>=','>>>='].map(op=>({name:'owner shift write '+op,params:'term,effect,x',body:`x ${op} 1;`+oneChild()})),
  {name:'owner increment',params:'term,effect,x',body:'x++;'+oneChild()},
  {name:'non-tag child condition',body:oneChild('term')},
  {name:'non-owner child term',body:oneChild(tag('B','uab'))},
  {name:'computed child term',body:oneChild(tag('B','term.child'))},
  {name:'forced child condition',body:oneChild('run_loop('+tag()+')')},
  {name:'unparenthesized nested arrow',body:oneChild(tag(),branch('ub','return later=>{return effect("B",ub);};'))},
  {name:'tag accessor body mutation',body:oneChild(),mutate:s=>s.replace('const _tag_0 = _t_0["tag"];','const _tag_0 = _t_0["other"];')},
  {name:'equality helper body mutation',body:oneChild(),mutate:s=>s.replace('return $String$eq$fin$(($String$cmp$(_a_0, _b_0)));','return false;')},
  {name:'runtime body mutation',body:oneChild(),mutate:s=>s.replace('function run_tail(f, x) {','function run_tail(f, x) {\n  x = x;')},
  {name:'protected runtime shadow',params:'term,effect,run_tail',body:oneChild()},
  {name:'protected helper shadow',params:'term,effect,$tg$',body:oneChild()},
  {name:'protected helper rebinding',body:'$tg$=effect;'+oneChild()},
  {name:'unknown owner',body:oneChild(),options:{families:['$missing$']}},
  {name:'duplicate owner',body:oneChild(),options:{families:['$controlProbe$','$controlProbe$']}},
  {name:'unknown option',body:oneChild(),options:{families:['$controlProbe$'],other:true}},
 ];
 for(let i=0;i<negatives.length;i++){
  const c=negatives[i],dir=path.join(out,'refuse-'+i);fs.mkdirSync(dir);const raw=insert(c.body,c.params??'term,effect'),input=c.mutate?c.mutate(raw):raw;const file=path.join(dir,'input.mjs');fs.writeFileSync(file,input);report.inputs.push(identity(file));let prerequisite=false,result,error;
  try{V.transform(input,{version:5});prerequisite=true;result=S.transform(input,c.options??{families:['$controlProbe$']});}catch(e){error={name:e.name,message:e.message};}
  report.refusals.push({name:c.name,input:identity(file),prerequisiteAccepted:prerequisite,accepted:!!result,error,pass:!result&&!!error});save();
 }
 report.inputs.forEach(verifyIdentity);report.inputsVerified=true;report.complete=true;report.pass=report.rows.every(r=>r.pass)&&report.refusals.every(r=>r.pass);if(!report.pass)process.exitCode=1;
}catch(e){report.error=e.stack;process.exitCode=1;}
save();console.log(encode({complete:report.complete,pass:report.pass,rows:report.rows.length,refusals:report.refusals.length,failures:[...report.rows,...report.refusals].filter(r=>!r.pass),error:report.error}));

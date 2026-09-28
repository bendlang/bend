// Independent constant-scope selector boundary controls on the actual helper.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity,verifyAttempt} from '../../development/workflow.mjs';
const [outArg,candidateArg]=process.argv.slice(2),out=path.resolve(outArg),root=path.resolve(import.meta.dirname,'../../..');
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const helper=path.join(root,'build/phase12/integrated-03/snapshot/tools/development/equality.mjs');
const origins=[helper,...['rewriter-structure.mjs','rewriter-v5.mjs','rewriter-selector-const.mjs'].map(n=>path.join(import.meta.dirname,n))],consumed=[];
for(const file of origins){const target=path.join(out,path.relative(root,file));fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(file,target);consumed.push(target);}
const R=await import(pathToFileURL(consumed[1])),V=await import(pathToFileURL(consumed[2])),S=await import(pathToFileURL(consumed[3]));
const m=await verifyAttempt(path.join(root,'build/phase12/integrated-03')),source=fs.readFileSync(m.checkedApi.file,'utf8');
const encode=value=>JSON.stringify(value,(_k,v)=>v===undefined?{$controlUndefined:true}:v,2);
const report={kind:'phase13-independent-actual-const-selector-controls',complete:false,pass:false,scope:'Synthetic generated owners transformed by actual frozen v5 and constant-scope selector. Private appended exports do not modify tested function bodies. No checked-B1, whole compiler, performance or universal stack-equivalence claim.',inputs:[import.meta.filename,process.execPath,...origins,...consumed,m.checkedApi.file].map(identity),rows:[],refusals:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),encode(report)+'\n');save();
const branch=(param,body)=>`run_clo((${param})=>{${body}})`;
const terminal=(label,unit)=>`return effect("${label}",${unit});`;
const choice=(yes=terminal('A','ua'),second=terminal('B','ub'),last=terminal('O','uo'),falsePrefix='')=>`return $kc$($String$eq$($tg$(term),"A"),${branch('ua',yes)},${branch('uab',falsePrefix+`return $kc$($String$eq$($tg$(term),"B"),${branch('ub',second)},${branch('uo',last)});`)});`;
const insert=(body,params='term,effect,x')=>source.replace('export default {',()=>`function $controlProbe$(${params}) {${body}}\nexport default {`);
const observe=fn=>{try{return{value:fn()};}catch(e){return{error:{name:e?.name??typeof e,message:e?.message??String(e)}};}};
function ownerRanges(src){const v=R.moduleView(src),f=v.functions.get('$controlProbe$'),arrows=[],constants=[];for(let i=f.body+1;i<f.end;i++){const t=v.ts[i];if(t.text==='const'){const end=v.semicolon(i+1,f.end);assert.ok(end>=0);constants.push(src.slice(t.start,v.ts[end].end));}if(t.text!=='(')continue;const body=t.close+3;if(v.ts[body]?.text!=='{')continue;const a=v.arrow([i,v.ts[body].close+1]);if(a)arrows.push(src.slice(v.ts[a.range[0]].start,v.ts[a.range[1]-1].end));}return{arrows,constants};}
function evidence(baseline,candidate){const before=ownerRanges(baseline),after=ownerRanges(candidate);assert.deepEqual([...after.constants].sort(),[...before.constants].sort());for(const arrow of after.arrows)assert.ok(before.arrows.includes(arrow),'A retained synthetic arrow changed');return{constantCount:after.constants.length,constantsExact:true,survivingArrows:after.arrows.length,allSurvivingArrowsExact:true};}
const positives=[
 {name:'selected constant initializer',body:choice('const value=effect("init-A",ua);return effect("A",value);')},
 {name:'selected and unselected throwing initializers',body:choice('const value=effect("throw-A",ua);return effect("A",value);','const value=effect("throw-B",ub);return effect("B",value);','const value=effect("throw-O",uo);return effect("O",value);')},
 {name:'unselected throwing initializer remains unforced',body:choice('const value=effect("throw-A",ua);return effect("A",value);')},
 {name:'parent initializer before tag selection',body:'const prior=effect("before",x);'+choice('return effect("A",prior);')},
 {name:'selected closure retains constant',body:choice('const local=17;return (later)=>{return effect("closure",local);};')},
 {name:'same constant spelling in sibling blocks',body:choice('const local=17;return effect("A",local);','const local=25;return effect("B",local);','const local=33;return effect("O",local);')},
 {name:'nested constant shadows non-parameter constant',body:choice('const local=17;return (later)=>{const local=25;return effect("nested",local);};')},
 {name:'later constant TDZ in selected branch',body:choice('const before=effect("before",later);const later=17;return effect("A",before);')},
 {name:'later parent constant stays uninitialized after return',body:choice('return effect("A",later);')+'const later=17;'},
 {name:'parenthesized comma initializer',body:choice('const value=(effect("first",ua),effect("second",ua));return effect("A",value);')},
 {name:'constant named undefined is lexical',body:choice('const undefined=17;return effect("A",undefined);')},
 {name:'separate constant declarations',body:choice('const first=17;const second=25;return effect("A",[first,second]);')},
 {name:'initializer callback without writes',body:choice('const value=((later)=>{return effect("callback",later);})(17);return effect("A",value);')},
 {name:'initializer nested constant stays in place',body:choice('const value=((later)=>{const inner=25;return effect("callback",inner);})(17);return effect("A",value);')},
];
const negatives=[
 {name:'constant shadows owner parameter in selected branch',body:choice('const term=17;return effect("A",term);')},
 {name:'constant shadows owner parameter in sibling branch',body:choice(terminal('A','ua'),'const term=17;return effect("B",term);')},
 {name:'constant shadows owner parameter in nested block arrow',body:choice('return (later)=>{const term=17;return effect("A",term);};')},
 {name:'constant shadows effect parameter',body:choice('const effect=x;return effect("A",ua);')},
 {name:'write inside initializer callback',body:choice('const value=((later)=>{x=17;return later;})(25);return effect("A",value);')},
 ...['<<=','>>=','>>>=','+=','&&=','??='].map(op=>({name:'compound write inside initializer '+op,body:choice(`const value=(x ${op} 1);return effect("A",value);`)})),
 {name:'property write inside initializer',body:choice('const value=(term.tag="B");return effect("A",value);')},
 {name:'increment inside initializer callback',body:choice('const value=((later)=>{x++;return later;})(25);return effect("A",value);')},
 {name:'let declaration inside initializer callback',body:choice('const value=((later)=>{let local=17;return local;})(25);return effect("A",value);')},
 {name:'destructuring declaration',body:choice('const {tag:local}=term;return effect("A",local);')},
 {name:'array destructuring declaration',body:choice('const [local]=x;return effect("A",local);')},
 {name:'multiple declarators',body:choice('const local=17,another=25;return effect("A",local);')},
 {name:'missing initializer',body:choice('const local;return effect("A",local);')},
 {name:'bare arrow in initializer',body:choice('const value=later=>{return later;};return effect("A",value);')},
 {name:'constant before child prevents false-arrow removal',body:choice(undefined,undefined,undefined,'const local=17;')},
 {name:'constant used as nested tag source',body:'const local=term;'+choice().replace('$tg$(term),"B"','$tg$(local),"B"')},
 {name:'removed Unit initializer use',body:choice(undefined,'const local=uab;return effect("B",local);')},
 {name:'protected helper constant shadow',body:choice('const $tg$=x;return effect("A",ua);')},
];
try{
 const candidate=path.resolve(candidateArg),manifestFile=path.join(path.dirname(candidate),'manifest.json'),manifest=JSON.parse(fs.readFileSync(manifestFile,'utf8'));report.inputs.push(identity(candidate),identity(manifestFile));const actual=S.transform(source,{families:manifest.options.families});assert.equal(actual.source,fs.readFileSync(candidate,'utf8'));report.existingCandidate={api:identity(candidate),families:manifest.options.families,removed:actual.report.removedIntermediateSelectors,exact:true};save();
 for(let i=0;i<positives.length;i++){
  const c=positives[i],dir=path.join(out,'positive-'+i);fs.mkdirSync(dir);const input=insert(c.body),inputFile=path.join(dir,'input.mjs');fs.writeFileSync(inputFile,input);report.inputs.push(identity(inputFile));let baseline,candidate,error;try{baseline=V.transform(input,{version:5});candidate=S.transform(input,{families:['$controlProbe$']});}catch(e){error=e.stack;}
  const row={name:c.name,input:identity(inputFile),accepted:!!candidate,error,pass:false,observations:[]};report.rows.push(row);save();if(!candidate)continue;
  row.unchanged=evidence(baseline.source,candidate.source);const apis=[];for(const [name,body]of[['baseline',baseline.source],['candidate',candidate.source]]){const file=path.join(dir,name+'.mjs');fs.writeFileSync(file,body+'\nexport const control=(...args)=>run_loop($controlProbe$(...args));\n');report.inputs.push(identity(file));apis.push((await import(pathToFileURL(file))).control);}
  for(const tag of ['A','B','Other']){const observations=apis.map(api=>{const events=[];const effect=(name,value)=>{const normalized=value&&typeof value==='object'&&value.$==='Unit'?{$:'Unit'}:value;events.push([name,normalized]);if(name.startsWith('throw-'))throw new Error(name);return value;};const result=observe(()=>{const value=api({tag},effect,7);return typeof value==='function'?value(99):value;});return{result,events};});row.observations.push({tag,observations,pass:encode(observations[0])===encode(observations[1])});}
  row.pass=row.observations.every(r=>r.pass);save();
 }
 for(let i=0;i<negatives.length;i++){
  const c=negatives[i],dir=path.join(out,'refuse-'+i);fs.mkdirSync(dir);const input=insert(c.body),inputFile=path.join(dir,'input.mjs');fs.writeFileSync(inputFile,input);report.inputs.push(identity(inputFile));let prerequisite=false,candidate,error;try{V.transform(input,{version:5});prerequisite=true;candidate=S.transform(input,{families:['$controlProbe$']});}catch(e){error={name:e.name,message:e.message};}
  report.refusals.push({name:c.name,input:identity(inputFile),prerequisiteAccepted:prerequisite,accepted:!!candidate,error,pass:!candidate&&!!error});save();
 }
 report.inputs.forEach(verifyIdentity);report.inputsVerified=true;report.complete=true;report.pass=report.rows.every(r=>r.pass)&&report.refusals.every(r=>r.pass);if(!report.pass)process.exitCode=1;
}catch(e){report.error=e.stack;process.exitCode=1;}save();console.log(encode({complete:report.complete,pass:report.pass,rows:report.rows.length,comparisons:report.rows.reduce((n,r)=>n+r.observations.length,0),refusals:report.refusals.length,failures:[...report.rows,...report.refusals].filter(r=>!r.pass),error:report.error}));

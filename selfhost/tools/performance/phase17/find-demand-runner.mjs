// Internal actual-helper controls. The append-only probe drives generated $JMPs.
import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
import {isDeepStrictEqual} from 'node:util';
const [probeFile,casesFile,resultFile]=process.argv.slice(2);
const {__findDemandProbe:find}=await import(pathToFileURL(probeFile));
const cases=JSON.parse(fs.readFileSync(casesFile,'utf8')).cases;
const getterInfo=new WeakMap();
function describe(value) {
  if(value===undefined)return {primitive:'undefined'};
  if(value===null||typeof value!=='object')return value;
  return {object:Object.getPrototypeOf(value)===null?'null-prototype':Array.isArray(value)?'array':'plain',properties:Object.entries(Object.getOwnPropertyDescriptors(value)).map(([name,d])=>({name,enumerable:d.enumerable,configurable:d.configurable,...'value'in d?{writable:d.writable,value:describe(d.value)}:{get:d.get?getterInfo.get(d.get):null,set:d.set?'unexpected-setter':null}}))};
}
const nil=()=>({$: 'Nil'});
const absent=()=>({$: 'KTerm',tag:'Absent',name:'',id:0,quant:0,kids:nil(),removed:nil(),originBegin:0,originEnd:0});
const missing=name=>({$: 'KDef',name,kind:'Missing',arity:0,templates:0,typ:absent(),value:absent(),ctors:nil(),native:false,unsafe:false});
function run(c) {
  const events=[]; let nameReads=0,active=true;
  const tailError={kind:'raw-tail-poison',values:[17,null,'unchanged']};
  const headError={kind:'raw-head-poison',values:[23,false,'unchanged']};
  const names=c.names??Array.from({length:c.count},(_,i)=>'definition-'+i);
  const log=event=>{if(active&&!c.count)events.push(event);};
  function getter(object,key,label,value,fail=false) {
    const get=()=>{log(label);if(key==='name'&&active)nameReads++;if(fail)throw value;return value;};
    getterInfo.set(get,{label,...fail?{throws:describe(value)}:{returns:key==='name'?value:'reference'}});
    Object.defineProperty(object,key,{get,enumerable:true,configurable:true});
  }
  const defs=names.map((name,i)=>{
    const d=missing(name); d.kind=c.kinds?.[i]??'Def';d.arity=i;d.templates=i%3;d.value={...absent(),name:'payload-'+i};
    getter(d,'name',`def[${i}].name`,c.throwNameAt===i?'raw-name-poison-'+i:name,c.throwNameAt===i);
    if(c.poisonPayload)for(const key of ['kind','arity','templates','typ','value','ctors','native','unsafe'])getter(d,key,`def[${i}].${key}`,'unused-'+key,true);
    return d;
  });
  let book={};getter(book,'$','end.tag','Nil');
  if(c.poisonTail){book={};getter(book,'$','tail.poison-tag',tailError,true);}
  for(let i=defs.length-1;i>=0;i--){const node={};getter(node,'$',`list[${i}].tag`,'Con');getter(node,'head',`list[${i}].head`,c.throwHeadAt===i?headError:defs[i],c.throwHeadAt===i);getter(node,'tail',`list[${i}].tail`,book);book=node;}
  let result;
  try {const value=find(c.query,book);active=false;result={kind:'return',value:describe(value),referenceIndex:defs.indexOf(value)};}
  catch(value){active=false;result={kind:'throw',value:describe(value),isOriginalThrownObject:value===tailError||value===headError};}
  const expectedEvents=[];let visited;
  if(c.expectedThrow==='head'||c.expectedThrow==='name')visited=c.throwIndex+1;
  else visited=c.expectedIndex===null||c.expectedThrow==='tail'?defs.length:c.expectedIndex+1;
  if(!c.count)for(let i=0;i<visited;i++){
    expectedEvents.push(`list[${i}].tag`,`list[${i}].head`);
    if(c.expectedThrow==='head'&&i===c.throwIndex)break;
    expectedEvents.push(`list[${i}].tail`,`def[${i}].name`);
  }
  if(!c.count&&c.expectedThrow==='tail')expectedEvents.push('tail.poison-tag');
  else if(!c.count&&!c.expectedThrow&&c.expectedIndex===null)expectedEvents.push('end.tag');
  const expectedReads=visited-(c.expectedThrow==='head'?1:0);
  const expected=c.expectedThrow?{kind:'throw',value:describe(c.expectedThrow==='head'?headError:c.expectedThrow==='tail'?tailError:'raw-name-poison-'+c.throwIndex),isOriginalThrownObject:c.expectedThrow!=='name'}:{kind:'return',value:describe(c.expectedIndex===null?missing(c.query):defs[c.expectedIndex]),referenceIndex:c.expectedIndex===null?-1:c.expectedIndex};
  const actual={result,events,nameReads};const wanted={result:expected,events:expectedEvents,nameReads:expectedReads};
  return {name:c.name,pass:isDeepStrictEqual(actual,wanted),actual,expected:wanted};
}
const rows=cases.map(run);const report={kind:'phase17-internal-find-demand-lane',complete:true,pass:rows.every(r=>r.pass),execArgv:process.execArgv,rows};
fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\n',{flag:'wx'});
process.stdout.write(JSON.stringify({complete:true,pass:report.pass,cases:rows.length})+'\n');
process.exitCode=report.pass?0:1;

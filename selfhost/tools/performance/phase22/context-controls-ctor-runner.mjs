// Internal raw-data helper controls; semantic outcomes independent, access logs paired.
import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
import {isDeepStrictEqual} from 'node:util';
const [probeFile,casesFile,resultFile]=process.argv.slice(2);
const {__ctorDemandProbe:lookup}=await import(pathToFileURL(probeFile));
const cases=JSON.parse(fs.readFileSync(casesFile)).cases,getterInfo=new WeakMap();
function describe(value){
 if(value===undefined)return {primitive:'undefined'};
 if(value===null||typeof value!=='object')return value;
 return {object:Object.getPrototypeOf(value)===null?'null-prototype':Array.isArray(value)?'array':'plain',properties:Object.entries(Object.getOwnPropertyDescriptors(value)).map(([name,d])=>({name,enumerable:d.enumerable,configurable:d.configurable,...'value'in d?{writable:d.writable,value:describe(d.value)}:{get:d.get?getterInfo.get(d.get):null,set:d.set?'unexpected-setter':null}}))};
}
const nil=()=>({$: 'Nil'}),absent=()=>({$: 'KTerm',tag:'Absent',name:'',id:0,quant:0,kids:nil(),removed:nil(),originBegin:0,originEnd:0});
const missing=name=>({$: 'KDef',name,kind:'Missing',arity:0,templates:0,typ:absent(),value:absent(),ctors:nil(),native:false,unsafe:false});
function run(c){
 let events=[],reads=0,active=true;const refs=new Map(),poisons=new Map();
 const poison=label=>{if(!poisons.has(label))poisons.set(label,{poison:label,payload:[17,false,null]});return poisons.get(label);};
 function getter(object,key,label,value,fail=false,failAfter=null){
  let calls=0;const get=()=>{if(active){reads++;if(!c.width&&!c.depth)events.push(label);}calls++;if(fail||failAfter!==null&&calls>failAfter)throw poison(label);return value;};
  getterInfo.set(get,{label,fail,failAfter,returns:typeof value==='object'?'reference':value});Object.defineProperty(object,key,{get,enumerable:true,configurable:true});
 }
 function list(defs,label,tailPoison=false,tagAfter=null){
  let rest={};getter(rest,'$',label+'.end.$','Nil',tailPoison);
  for(let i=defs.length-1;i>=0;i--){const x={};getter(x,'$',`${label}[${i}].$`,'Con',false,i===0?tagAfter:null);getter(x,'head',`${label}[${i}].head`,defs[i]);getter(x,'tail',`${label}[${i}].tail`,rest);rest=x;}return rest;
 }
 function make(spec){
  const d=missing(spec.name);d.kind=spec.kind;d.arity=refs.size;d.templates=refs.size%3;refs.set(spec.id,d);
  const children=list((spec.children??[]).map(make),spec.id+'.children',false,spec.childrenTagAfter??null);
  for(const [key,value] of [['kind',spec.kind],['name',spec.name],['ctors',children]])getter(d,key,spec.id+'.'+key,value,spec.poison?.includes(key));
  if(spec.poisonPayload)for(const key of ['arity','templates','typ','value','native','unsafe'])getter(d,key,spec.id+'.'+key,d[key],true);
  return d;
 }
 let forest=c.forest;
 if(c.width)forest=Array.from({length:c.width},(_,i)=>({id:'wide'+i,name:'N'+i,kind:'Def',children:[]}));
 if(c.depth){let s={id:'deep-hit',name:'X',kind:'Ctr',children:[]};for(let i=0;i<c.depth;i++)s={id:'deep'+i,name:'N'+i,kind:'ADT',children:[s]};forest=[s];}
 const book=list(forest.map(make),'root',!!c.tailPoison),observations=[];
 for(const request of c.queries??[{query:c.query,expected:c.expectedDeep?'deep-hit':c.expected,expectedThrow:c.expectedThrow}]){
  active=true;events=[];reads=0;let result;
  try{const value=lookup(request.query,book);active=false;result={kind:'return',value:describe(value),referenceId:[...refs].find(([,v])=>v===value)?.[0]??null};}
  catch(value){active=false;result={kind:'throw',value:describe(value),isOriginalThrownObject:[...poisons.values()].includes(value)};}
  const expected=request.expectedThrow?{kind:'throw',value:describe(poison(request.expectedThrow)),isOriginalThrownObject:true}:{kind:'return',value:describe(request.expected==null?missing(request.query):refs.get(request.expected)),referenceId:request.expected??null};
  observations.push({query:request.query,pass:isDeepStrictEqual(result,expected),actual:{result,events,reads},expected});
 }
 return {name:c.name,pass:observations.every(x=>x.pass),actual:observations.map(x=>x.actual),observations};
}
const rows=cases.map(run),report={kind:'phase22-internal-constructor-lane',complete:true,pass:rows.every(r=>r.pass),scope:'Expected preorder winner/reference and raw thrown outcome; exact access-order logs compared between actual helpers separately.',execArgv:process.execArgv,rows};
fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:true,pass:report.pass,cases:rows.length,failed:rows.filter(r=>!r.pass).map(r=>r.name)}));process.exitCode=report.pass?0:1;

// Independent JavaScript scope/name/order controls for the disposable Let edit.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {derive} from './review-tail-let-derive.mjs';
const [outArg]=process.argv.slice(2),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const report={kind:'phase30-general-tail-let-independent-controls',complete:false,pass:false,
  inputs:[import.meta.filename,path.join(import.meta.dirname,'review-tail-let-derive.mjs'),process.execPath].map(identity),observations:[],refusals:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'),fs.constants.COPYFILE_EXCL);
const cases=[
  {name:'parallel-shadow',code:'function f(x1,x2){return ((x1,x2)=>[x1,x2])(mark("left",x2),mark("right",x1))} const value=f(11,22);',value:[22,11],events:[['left',22],['right',11]]},
  {name:'nested-shadow',code:'function f(x1,x2){return ((x1)=>((x1,x2)=>[x1,x2])(mark("inner",x1+1),mark("outer",x2)))(mark("start",x1+2))} const value=f(3,7);',value:[6,7],events:[['start',5],['inner',6],['outer',7]]},
  {name:'parallel-nested-shadow',code:'function f(x1){return ((x1,x2)=>((x1)=>[x1,x2])(x1+1))(1,x1)} const value=f(10);',value:[2,10]},
  {name:'later-rhs-throw',code:'function f(){return ((x1,x2)=>mark("body",x1+x2))(mark("first",22),boom("later"))} let value;try{f()}catch(e){value=[e.name,e.message]}',value:['Error','later'],events:[['first',22],['throw','later']]},
  {name:'getter-order',code:'const object={get a(){return mark("a",3)},get b(){return mark("b",4)}};function f(){return ((x1,x2)=>mark("body",x1+x2))(object.a,object.b)}const value=f();',value:7,events:[['a',3],['b',4],['body',7]]},
  {name:'escaped-fresh-bindings',code:'function f(x1){return ((x1)=>()=>x1)(x1+1)} const a=f(2),b=f(8);const value=[a(),b(),a()];',value:[3,9,3]},
  {name:'escaped-loop-bindings',code:'function f(x1){return ((x1)=>()=>x1)(x1+1)}const saved=[];for(let i=0;i<4;i++)saved.push(f(i));const value=saved.map(fn=>fn());',value:[1,2,3,4]},
  {name:'escaped-rhs-outer-scope',code:'function f(x1){return ((x1,x2)=>[()=>x1,x2])(1,()=>x1)}const a=f(10),b=f(20);const value=[a[0](),a[1](),b[0](),b[1]()];',value:[1,10,1,20]},
  {name:'nested-return-rounds',code:'function f(x1){return ((x1)=>function(){return ((x2)=>x1+x2)(3)})(x1+1)}const a=f(2),b=f(8);const value=[a(),b(),a()];',value:[6,12,6],minRounds:2},
  {name:'anonymous-function-name',code:'function f(){return ((x1)=>[x1.name,x1.length,Object.hasOwn(x1,"prototype")])(function(a,b){return a+b})}const value=f();',value:['',2,true]},
  {name:'anonymous-arrow-name',code:'function f(){return ((x1)=>[x1.name,x1.length,Object.hasOwn(x1,"prototype")])((a,b)=>a+b)}const value=f();',value:['',2,false]},
  {name:'anonymous-class-name',code:'function f(){return ((x1)=>[x1.name,x1.seen])(class {static seen=this.name})}const value=f();',value:['','']},
  {name:'named-function-class',code:'function f(){return ((x1,x2)=>[x1.name,x2.name])(function named(){},class Named{})}const value=f();',value:['named','Named']},
  {name:'lexical-this-arguments',code:'function f(x1){return ((x1)=>[this.tag,arguments[0],x1])(7)}const value=f.call({tag:"receiver"},3);',value:['receiver',3,7]},
  {name:'lexical-new-target',code:'function F(){return ((x1)=>({value:[new.target?.name??null,x1]}))(4)}const value=[F().value,new F().value];',value:[[null,4],['F',4]]},
  {name:'object-literal-terminal',code:'function f(){return ((x1)=>({answer:x1}))(42)}const value=f();',value:{answer:42}},
  {name:'delayed-field',code:'function f(){return ((x1)=>({field:()=>mark("field",x1)}))(mark("bind",5))}const r=f();mark("after",0);const value=r.field();',value:5,events:[['bind',5],['after',0],['field',5]]},
  {name:'finally-before-escape-use',code:'function f(){try{return ((x1)=>()=>mark("use",x1))(mark("bind",6))}finally{mark("finally",0)}}const r=f();const value=r();',value:6,events:[['bind',6],['finally',0],['use',6]]},
  {name:'terminal-throws',code:'function f(){return ((x1,x2)=>boom("body"))(mark("first",1),mark("second",2))}let value;try{f()}catch(e){value=[e.name,e.message]}',value:['Error','body'],events:[['first',1],['second',2],['throw','body']]},
  {name:'rhs-function-remains-deferred',code:'function f(){return ((x1)=>x1)(()=>boom("deferred"))}const r=f();mark("after",0);let value;try{r()}catch(e){value=[e.name,e.message]}',value:['Error','deferred'],events:[['after',0],['throw','deferred']]},
  {name:'rhs-sequence-function-name',code:'function f(){return ((x1)=>x1.name)((mark("before",0),function(){}))}const value=f();',value:'',events:[['before',0]]},
  {name:'primitive-iife-preserved',code:'function f(){return ((x1)=>((a,b)=>Math.imul(a,b)>>>0)(x1,3))(4294967295)}const value=f();',value:4294967293},
  {name:'separate-sibling-return-scopes',code:'function f(flag){if(flag){return ((x1)=>()=>x1)(1)}return ((x1)=>()=>x1)(2)}const a=f(true),b=f(false);const value=[a(),b(),a()];',value:[1,2,1]},
  {name:'negative-zero-nan',code:'function f(){return ((x1,x2)=>[Object.is(x1,-0),Number.isNaN(x2)])(-0,NaN)}const value=f();',value:[true,true]},
  {name:'fresh-administrative-name',code:'const $tailLet0=9;function f(){return ((x1)=>x1+$tailLet0)(2)}const value=f();',value:11},
];
const wrap=code=>'export default function(){const events=[];const mark=(name,value)=>(events.push([name,value]),value);const boom=message=>{events.push(["throw",message]);throw Error(message)};'+code+'return {value,events};}\n';
try{
  for(const row of cases){
    const original=wrap(row.code),lowered=derive(original);assert.ok(lowered.evidence.tailLets>0,row.name);
    if(row.minRounds)assert.ok(lowered.evidence.rounds.length>=row.minRounds);
    const observation={name:row.name,evidence:lowered.evidence,modules:{},values:{}};
    for(const [side,text]of [['baseline',original],['candidate',lowered.source]]){
      const file=path.join(out,row.name+'-'+side+'.mjs');fs.writeFileSync(file,text,{flag:'wx'});
      observation.modules[side]=identity(file);const module=await import(pathToFileURL(file));
      const value=module.default();observation.values[side]=value;
      assert.deepEqual(value,{value:row.value,events:row.events??[]},row.name+' '+side);
    }
    report.observations.push(observation);
  }
  for(const expression of [
    '((x1)=>x1=2)(1)','((x1)=>++x1)(1)','((x1)=>()=>x1++)(1)',
    '((x1)=>({x1}=object))(1)','((x1)=>()=>{for(x1 of [1]){};return x1})(1)',
    '((x1=1)=>x1)(1)','(({x1})=>x1)({x1:1})','((...x1)=>x1)(1)',
    '((x1)=>x1)(...[1])','(async(x1)=>x1)(1)','((x1)=>{return x1})(1)',
    '((x1,x2)=>x1)(1)','(()=>1)()','((other)=>other)(1)',
  ]){
    const source='export default function(){return '+expression+';}\n',result=derive(source);
    assert.equal(result.evidence.tailLets,0,expression);assert.equal(result.source,source);
    report.refusals.push({expression,reason:'Not an immutable exact generated Let',unchanged:true});
  }
  const evalSource='export default function(){return ((x1)=>eval("x1"))(1)}';
  let evalError;try{derive(evalSource)}catch(error){evalError={name:error.name,message:error.message}}
  assert.ok(evalError);report.refusals.push({expression:evalSource,error:evalError});
  const prefix='function untouched(){return ((x1)=>x1)(99)}\n';
  const full=prefix+'export default function(){return ((x1)=>x1)(1)}\n',prefixResult=derive(full,prefix);
  assert.ok(prefixResult.source.startsWith(prefix));assert.equal(prefixResult.evidence.tailLets,1);
  report.runtimePrefix={unchanged:true,evidence:prefixResult.evidence};
  for(const item of report.inputs)assert.deepEqual(identity(item.file),item);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,refusals:report.refusals.length}));

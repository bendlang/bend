import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
const [baseArg,candidateArg,outArg]=process.argv.slice(2);
const identity=file=>({file:path.resolve(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const base=(await import(pathToFileURL(path.resolve(baseArg)))).default;
const candidate=(await import(pathToFileURL(path.resolve(candidateArg)))).default;
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const term={$:'KTerm',tag:'Absent',name:'',id:0,quant:0,kids:nil,removed:nil};
const def=(kind,arity=0,templates=0,ctors=nil,name='')=>({$:'KDef',name,kind,arity,templates,typ:term,value:term,ctors,native:true,unsafe:false});
const target=def('Def',17,0,nil,'wanted');
const cases=[
 ['absent does not inspect invalid children',k=>k.index_find(def('Absent',null,null,null),'wanted',0,32)],
 ['hash miss does not inspect invalid bucket',k=>k.index_find(def('Other',7,0,null),'wanted',8,32)],
 ['hash hit malformed bucket',k=>k.index_find(def('Other',7,0,null),'wanted',7,32)],
 ['empty unknown-kind leaf',k=>k.index_find(def('Other',7,0),'wanted',7,32)],
 ['wrong-tag list',k=>k.index_find(def('IndexLeaf',7,0,{$:'Wrong',head:target,tail:nil}),'wanted',7,32)],
 ['null tree',k=>k.index_find(null,'wanted',7,32)],
 ['undefined tree',k=>k.index_find(undefined,'wanted',7,32)],
 ['empty child left',k=>k.index_child_list(nil,false)],
 ['empty child right',k=>k.index_child_list(nil,true)],
 ['one child left',k=>k.index_child_list(list([target]),false)],
 ['one child right',k=>k.index_child_list(list([target]),true)],
 ['two children left',k=>k.index_child_list(list([target,null]),false)],
 ['two children right',k=>k.index_child_list(list([null,target]),true)],
 ['noncanonical bool truthy',k=>k.index_child_list(list([null,target]),{$:'True'})],
 ['noncanonical bool falsy',k=>k.index_child_list(list([target,null]),0)],
 ['null child list',k=>k.index_child_list(null,false)],
 ['absent kind getter leaves mask undemanded',k=>{const t=def('Absent');Object.defineProperty(t,'templates',{get(){throw Error('mask forced')}});return k.index_find(t,'wanted',0,32)}],
 ['leaf hash miss leaves children undemanded',k=>{const t=def('IndexLeaf',7);Object.defineProperty(t,'ctors',{get(){throw Error('children forced')}});return k.index_find(t,'wanted',8,32)}],
 ['left branch leaves right node undemanded',k=>{const t=def('IndexNode',0,1,list([def('IndexLeaf',0,0,list([target])),null]));return k.index_find(t,'wanted',0,32)}],
 ['right branch leaves left node undemanded',k=>{const t=def('IndexNode',0,1,list([null,def('IndexLeaf',1,0,list([target]))]));return k.index_find(t,'wanted',1,32)}],
 ['malformed deep 10000-level tree remains stack safe',k=>{let t=def('IndexLeaf',0,0,list([target]));for(let i=0;i<10000;i++)t=def('IndexNode',0,1,list([t,null]));return k.index_find(t,'wanted',0,32)}]
];
const observe=fn=>{try{return {ok:true,value:fn()}}catch(e){return {ok:false,name:e.name,message:e.message}}};
const rows=cases.map(([name,run])=>{const before=observe(()=>run(base)),after=observe(()=>run(candidate));let pass=true;try{assert.deepEqual(after,before)}catch{pass=false}return{name,before,after,pass}});
const report={kind:'phase10-index-demand-boundaries',inputs:[identity(import.meta.filename),identity(baseArg),identity(candidateArg)],checks:rows.length,pass:rows.every(x=>x.pass),rows};
fs.writeFileSync(path.resolve(outArg),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({pass:report.pass,checks:report.checks,failures:rows.filter(x=>!x.pass).map(x=>x.name)}));if(!report.pass)process.exitCode=1;

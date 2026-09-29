// Invocation-local contextual completion must preserve the full raw-source graph.
// Dependency order is explicit in these small fixtures; no second loader is built.
import assert from 'node:assert/strict';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const project=path.resolve(import.meta.dirname,'../..');
const {default:api}=await import(pathToFileURL(path.resolve(process.env.BEND_FRONT_API||path.join(project,'dist/typed-api.mjs'))));
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const source=(name,text)=>({$:'FSource',name,path:name,text});
const main='/test/main.bend',child='/test/child.bend';
const cases=[
 ['simple',[source(main,'type Bit is Data:\n  On{}\ndef main() -> Bit:\n  On{}\n')]],
 ['aliases',[source(child,'type Bit is Data:\n  On{}\n'),source(main,'import ./child.bend as C\ndef main() -> C.Bit:\n  C.On{}\n')]],
 ['contextual beta',[source(child,'type Bit is Data:\n  On{}\n'),source(main,'import ./child.bend as C\ndef main() -> C.Bit:\n  (x => x)(C.On{})\n')]],
 ['parse error',[source(main,'def main(\n')]],
 ['cycle',[source(child,'import ./main.bend as M\n'),source(main,'import ./child.bend as C\n')]],
 ['missing source',[source(main,'import ./missing.bend as M\n')]],
 ['repeated import',[source(child,'type Bit is Data:\n  On{}\n'),source(main,'import ./child.bend as C\nimport ./child.bend as C\n')]],
 ['parallel bindings',[source(main,'type Bit is Data:\n  On{}\ndef main() -> Bit:\n  a b = On{} On{}\n  a\n')]],
];
for(const [name,sources] of cases){
 const all=list(sources),completed=[];
 let graph={$:'FGraph',book:nil,error:'',done:nil};
 for(const s of sources){
  const ns=s.path===main?'':'child';
  const result=api.f_complete_source(s,ns,api.f_source_header(s),all,graph,'/test');
  graph=result.graph;
  completed.push(api.f_source_completed(s.name,s.path,s.text,result.parsed));
 }
 const cached=list(completed),plain=api.f_load_graph(main,all);
 assert.deepEqual(api.f_load_graph(main,cached),plain,name);
 assert.deepEqual(api.f_load_graph_seed(main,cached,'/wrong','wrong',nil),plain,name+' seed fallback');
 console.log('PASS completed source '+name);
}

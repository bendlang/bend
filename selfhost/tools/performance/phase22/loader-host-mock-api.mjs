// Host protocol fixture only: this is not a Bend compiler or language oracle.
import path from 'node:path';
export const events=[];
export const completed=new WeakSet();
export let lastSources=null;
const nil=()=>({$: 'Nil'}),list=xs=>xs.reduceRight((tail,head)=>({$: 'Con',head,tail}),nil());
const raw=s=>s.$==='FLocatedSource'?raw(s.source):s;
const empty=()=>({$: 'FResult',book:nil(),error:'',imports:nil()});
export function makeApi(){return {
  compiler_load_abi:()=>2,compiler_span_abi:()=>3,compiler_term_abi:()=>1,
  f_source_located:(source,begin,end)=>({$: 'FLocatedSource',source,begin,end}),
  f_source_completed:(name,file,text,parsed)=>{if(!completed.has(parsed))throw Error('Unowned completed result');events.push(['retain',path.basename(file)]);return {$:'FCompletedSource',name,path:file,text,parsed};},
  f_source_header:source=>{const s=raw(source);events.push(['header',path.basename(s.path)]);return {$:'FHeader',imports:list(s.text.split('\n').flatMap(line=>{const m=/^# mock-import (\S+) (\w+)$/.exec(line);return m?[{$:'KTerm',tag:'Import',name:m[1],id:0,quant:0,kids:list([{$:'KTerm',tag:'Alias',name:m[2],kids:nil()}]),removed:nil(),originBegin:0,originEnd:0}]:[];})),error:'',body:s.text,line:1,offset:0};},
  f_complete_source:(source,ns,header,sources,graph)=>{const s=raw(source);events.push(['complete',path.basename(s.path)]);const parsed=empty();completed.add(parsed);return {$:'FCompletion',parsed,graph:{$:'FGraph',book:nil(),error:s.text.includes('# mock-reject')?'mock earlier failure':'',done:graph.done}};},
  f_complete_seed:(source,graph)=>({$:'FCompletion',graph,parsed:empty()}),
  f_import_namespace_at:(item)=>item.name,
  f_graph_trace:(graph,sources)=>{lastSources=sources;return {$:'FLoadTrace',result:{$:'FResult',book:graph.book,error:graph.error,imports:nil()},done:graph.done,sources};},
  f_load_graph:(name)=>{events.push(['load-graph',name]);return empty();},
  f_import_failure:(_text,_item,_path,cycle)=>cycle?'mock cycle':'mock missing source',
  check_book:()=>'',compiler_check_result_abi:()=>2,
  check_program_diagnostic:book=>({error:'',book,diagnostic:{}}),
  driver_has_main:()=>true,driver_is_io:()=>false,driver_interpret:()=> '41n',
  f_parse:()=>{throw Error('Forbidden raw f_parse');},
  f_parse_indexed:()=>{throw Error('Forbidden raw f_parse_indexed');},
  f_source_parsed:()=>{throw Error('Forbidden raw parsed factory');},
  f_load:()=>{throw Error('Forbidden legacy f_load');},
};}
export default makeApi();

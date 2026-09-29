#!/usr/bin/env python3
"""Connect the checked contextual completion to the existing host IO traversal."""
import hashlib,json,shutil
from pathlib import Path
repo=Path(__file__).resolve().parents[4]
parent=repo/'selfhost/build/phase16/spans-context-source-02/project'
out=repo/'selfhost/build/phase16/spans-context-source-03';assert not out.exists()
p=out/'project';shutil.copytree(parent,p)
f=p/'src/load/modules.bend';s=f.read_text()
s=s.replace('f_graph_aliases(f_header_imports(header), source, sources, root), book)', 'f_graph_aliases(f_header_imports(header), source, sources, root), book, sources)')
s=s.replace('+aliases: List<&2,KTerm>, +prior: List<&2,KDef>) -> FCompletion:', '+aliases: List<&2,KTerm>, +prior: List<&2,KDef>, +sources: List<&2,FSource>) -> FCompletion:')
s=s.replace('f_source_body(source, header, prior, ns, aliases, 0))', 'f_source_body(source, header, prior, ns, aliases, 0), sources)')
s=s.replace('+graph: FGraph, +parsed: FResult) -> FCompletion:', '+graph: FGraph, +parsed: FResult, +sources: List<&2,FSource>) -> FCompletion:')
s=s.replace('f_graph_finish(source, ns, book, aliases, graph)', 'f_graph_finish(source, ns, book, aliases, graph, sources)')
s+='''
# The host has already checked the immutable cache identity. Bind the supplied
# source again here; a seed cannot inject definitions for a different file.
@unsafe
def f_complete_seed(+source: FSource, +graph: FGraph, +path: String, +text: String, +book: List<&2,KDef>) -> FCompletion:
  match graph:
    case FGraph{prior, error, done}:
      f_choose(FCompletion, String.is_empty(error),
        u => f_choose(FCompletion, f_seed_matches(source, path, text),
          u => FCompletion{fs_inject(graph, FSeed{path, book, ""}), FResult{Nil{}, "", Nil{}}},
          u => FCompletion{f_graph_error(graph, "Base seed source mismatch"), FResult{Nil{}, "Base seed source mismatch", Nil{}}}),
        u => FCompletion{graph, FResult{Nil{}, error, Nil{}}})
''';f.write_text(s)
f=p/'src/load/graph.bend';s=f.read_text()
for name in ['f_graph_finish','f_graph_finish_alias']:
 a=s.index('law '+name+':');b=s.index('\n\n',a);block=s[a:b];block=block.replace('\n  FGraph','\n  for +sources: List<&2,FSource>\n  FGraph');s=s[:a]+block+s[b:]
s=s.replace('def f_graph_finish(s, ns, book, imports, g):','def f_graph_finish(s, ns, book, imports, g, sources):')
s=s.replace('u => err), done)\n\n@unsafe\ndef f_graph_finish_alias', 'u => err), done, sources)\n\n@unsafe\ndef f_graph_finish_alias')
old='''def f_graph_finish_alias(s, ns, book, imports, prior, err, done):
  FGraph{norm_defs_join(prior, f_path_defs(f_module_defs(book, book, f_family_book(prior), ns, imports), f_path_dir(f_source_path(s)), f_eq(f_source_name(s), "Base"))), err, Con{kt("Loaded", f_source_path(s), f_graph_count_defs(book, 0), 0, Con{ref(ns), imports}), done}}'''
new='''def f_graph_finish_alias(s, ns, book, imports, prior, err, done, sources):
  f_graph_finish_module(s, prior, err, Con{kt("Loaded", f_source_path(s), f_graph_count_defs(book, 0), 0, Con{ref(ns), imports}), done}, f_path_defs(f_module_defs(book, book, f_family_book(prior), ns, imports), f_path_dir(f_source_path(s)), f_eq(f_source_name(s), "Base")), sources)

# Dependency completion checks only its new fragment, never cached prior terms.
@unsafe
def f_graph_finish_module(+source: FSource, +prior: List<&2,KDef>, +error: String, +done: List<&2,KTerm>, +book: List<&2,KDef>, +sources: List<&2,FSource>) -> FGraph:
  FGraph{norm_defs_join(prior, book), f_choose(String, String.is_empty(error), u => f_graph_module_error(source, fpe_defs(book), sources), u => error), done}

@unsafe
def f_graph_module_error(+source: FSource, +error: KTerm, +sources: List<&2,FSource>) -> String:
  fpe_source_render(nm(error), error, f_choose(KTerm, U32.is_gt(kb(error), 0), u => fpe_located_source(error, sources), u => kt("ParseSource", f_source_text(source), 0, 0, Nil{})))'''
assert s.count(old)==1;s=s.replace(old,new);f.write_text(s)
f=p/'tools/typed-driver.mjs';s=f.read_text()
s=s.replace("'f_complete_source','f_graph_trace'", "'f_complete_source','f_complete_seed','f_import_namespace_at','f_graph_trace'")
a=s.index('export function discoverSources(');b=s.index('\nfunction baseCacheInfo(',a)
s=s[:a]+'''export function discoverSources(api,input,{seed=null}={}) {
  const sources=[],seen=new Map(),physical=new Map(),foreign=new Map(),active=new Set();
  const loadAbi=api.compiler_load_abi?.(),contextual=loadAbi===1;
  if(api.compiler_load_abi!==undefined&&!contextual)throw Error('Unknown compiler load ABI: '+loadAbi);
  if(contextual)for(const name of ['f_source_header','f_complete_source','f_complete_seed','f_import_namespace_at','f_graph_trace'])
    if(typeof api[name]!=='function')throw Error('Missing contextual compiler source API: '+name);
  const located=api.compiler_span_abi?.()===SPAN_ABI;
  if(located&&(!api.f_parse_indexed||!api.f_source_located))throw Error('Missing indexed compiler source API');
  const baseCanonical=located?fs.realpathSync(basePath):null;
  const baseText=located?fs.readFileSync(baseCanonical,'utf8'):null;
  const baseRange=located?interval(1,baseText):null;
  let next=baseRange?.end??0,root=null,completed={$:'FGraph',book:list([]),error:'',done:list([])};
  const graphMode=typeof api.f_load_graph==='function';
  const wrap=(source,range)=>located?api.f_source_located(source,range.begin,range.end):source;
  const visit=(name,file,edge=null)=>{
    const absolute=fs.realpathSync(file);
    if(root===null)root=path.dirname(absolute);
    // Finish each dependency before requesting a later sibling file.
    if(active.has(absolute)&&api.f_import_failure)
      throw Object.assign(Error('Import traversal reentry'),{code:'BEND_IMPORT_CYCLE',importPath:absolute});
    if(seen.has(name)) {
      if(seen.get(name)!==absolute) throw Object.assign(Error('Module import path collision: '+name),{phase:'load'});
      return;
    }
    seen.set(name,absolute);
    const source=fs.readFileSync(absolute,'utf8'),prior=physical.get(absolute);
    trace('parse '+absolute);
    const seeded=name==='Base'&&seed&&seed.sourcePath===absolute&&seed.sourceText===source;
    if(prior&&prior.source!==source)throw Object.assign(Error('Source alias bytes changed'),{phase:'load'});
    if(located&&absolute===baseCanonical&&source!==baseText)throw Object.assign(Error('Base source bytes changed'),{phase:'load'});
    const range=located?(prior?.range??(absolute===baseCanonical?baseRange:interval(next,source))):null;
    if(located&&!prior&&absolute!==baseCanonical)next=range.end;
    if(seeded&&located&&(seed.spanAbi!==SPAN_ABI||seed.sourceBegin!==range.begin||seed.sourceEnd!==range.end))throw Error('Stale Base source interval');
    let parsed=prior?.parsed||(seeded?{book:list([]),imports:list([]),error:''}:contextual?null:located?api.f_parse_indexed(range.begin,source):api.f_parse(source));
    const raw=wrap({$:'FSource',name,path:absolute,text:source},range),slot=sources.length;
    sources.push(raw);
    const retain=()=>{if(parsed&&api.f_source_parsed&&!seeded)sources[slot]=wrap(api.f_source_parsed(name,absolute,source,parsed),range);};
    if(prior){retain();return;}
    const record={parsed,source,range};physical.set(absolute,record);active.add(absolute);
    const header=contextual&&!seeded?api.f_source_header(raw):null;
    const imports=header?.imports??parsed.imports;
    if(located&&!contextual&&!seeded&&!parsed.error)validateSpanBook(parsed.book,[range]);
    for(const item of array(imports)) {
      const imported=item.name,importedFile=imported==='Base'?basePath:path.resolve(path.dirname(absolute),imported);
      try {visit(graphMode&&imported!=='Base'?importedFile:imported,importedFile,{item,source:raw});}
      catch(error) {
        if(!error.phase&&api.f_import_failure&&(error.code==='ENOENT'||error.code==='BEND_IMPORT_CYCLE'))
          throw Object.assign(Error(api.f_import_failure(source,item,error.code==='BEND_IMPORT_CYCLE'?error.importPath:importedFile,error.code==='BEND_IMPORT_CYCLE')),{phase:'parse',sourceFile:absolute});
        throw error;
      }
    }
    if(contextual) {
      const supplied=list(sources),ns=edge?api.f_import_namespace_at(edge.item,edge.source,supplied,root):'';
      const result=seeded?api.f_complete_seed(raw,completed,seed.sourcePath,seed.sourceText,seed.book):api.f_complete_source(raw,ns,header,supplied,completed,root);
      parsed=result.parsed;completed=result.graph;record.parsed=parsed;
      if(located&&!seeded&&!parsed.error)validateSpanBook(parsed.book,[...physical.values()].map(x=>x.range));
    }
    retain();
    if(name!=='Base'&&api.f_path_join) for(const definition of array(parsed.book)) {
      if(definition.value.tag!=='Foreign')continue;
      for(const imported of array(definition.value.kids)) {
        const qualified=api.f_path_join(api.f_path_dir(absolute),imported.name);
        foreign.set(qualified,{name:qualified,path:qualified});
      }
    }
    active.delete(absolute);
    const error=contextual?completed.error:parsed.error;
    if(error)throw Object.assign(Error(error),{phase:'parse',sourceFile:absolute});
  };
  const main=graphMode?path.resolve(input):'__main__';
  visit(main,path.resolve(input));
  const supplied=list(sources);
  return {main,sources:supplied,files:[...physical.keys()],foreign:[...foreign.values()],hasBase:seen.has('Base'),
    ...(contextual?{loadTrace:api.f_graph_trace(completed,supplied)}:{})};
}
''' + s[b:]
old="const loadTrace=seed&&api.f_load_graph_seed_trace?api.f_load_graph_seed_trace(graph.main,graph.sources,seed.sourcePath,seed.sourceText,seed.book):\n      !seed&&api.f_load_graph_trace?api.f_load_graph_trace(graph.main,graph.sources):null;"
new="const loadTrace=graph.loadTrace??(seed&&api.f_load_graph_seed_trace?api.f_load_graph_seed_trace(graph.main,graph.sources,seed.sourcePath,seed.sourceText,seed.book):\n      !seed&&api.f_load_graph_trace?api.f_load_graph_trace(graph.main,graph.sources):null);"
assert s.count(old)==1;s=s.replace(old,new);f.write_text(s)
changed=[]
for f in p.rglob('*'):
 if f.is_file() and f.relative_to(p).parts[0] in ['src','tools']:
  old=parent/f.relative_to(p)
  if not old.exists() or old.read_bytes()!=f.read_bytes():changed.append({'path':str(f.relative_to(p)),'sha256':hashlib.sha256(f.read_bytes()).hexdigest()})
(out/'manifest.json').write_text(json.dumps({'parent':str(parent),'project':str(p),'changes':changed,'checkpoint':'B; ordered IO completion'},indent=2)+'\n')
c=json.loads((parent.parent/'workflow.json').read_text());c['project']=str(p);(out/'workflow.json').write_text(json.dumps(c,indent=2)+'\n');print(out)

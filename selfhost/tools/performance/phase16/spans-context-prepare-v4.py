#!/usr/bin/env python3
"""Preserve earlier completed frontend failures only on a failed-parser path."""
import hashlib,json,shutil
from pathlib import Path
repo=Path(__file__).resolve().parents[4]
parent=repo/'selfhost/build/phase16/spans-context-source-03/project'
out=repo/'selfhost/build/phase16/spans-context-source-04';assert not out.exists();p=out/'project';shutil.copytree(parent,p)
f=p/'src/load/modules.bend';s=f.read_text();old='FCompletion{f_choose(FGraph, String.is_empty(error), u => f_graph_finish(source, ns, book, aliases, graph, sources), u => f_graph_error(graph, error)), parsed}';new='FCompletion{f_graph_finish(source, ns, book, aliases, graph, sources, error), parsed}';assert s.count(old)==1;s=s.replace(old,new);f.write_text(s)
f=p/'src/load/graph.bend';s=f.read_text()
for name in ['f_graph_finish','f_graph_finish_alias']:
 a=s.index('law '+name+':');b=s.index('\n\n',a);block=s[a:b].replace('\n  FGraph','\n  for +fallback: String\n  FGraph');s=s[:a]+block+s[b:]
s=s.replace('def f_graph_finish(s, ns, book, imports, g, sources):','def f_graph_finish(s, ns, book, imports, g, sources, fallback):')
s=s.replace('f_choose(String, String.is_empty(err), u => f_graph_fresh_names(book, index_build(List.reverse(&2,KDef,prior))), u => err), done, sources)', 'f_choose(String, String.is_empty(err) && String.is_empty(fallback), u => f_graph_fresh_names(book, index_build(List.reverse(&2,KDef,prior))), u => err), done, sources, fallback)')
s=s.replace('def f_graph_finish_alias(s, ns, book, imports, prior, err, done, sources):','def f_graph_finish_alias(s, ns, book, imports, prior, err, done, sources, fallback):')
s=s.replace('f_eq(f_source_name(s), "Base")), sources)', 'f_eq(f_source_name(s), "Base")), sources, fallback)')
s=s.replace('+book: List<&2,KDef>, +sources: List<&2,FSource>) -> FGraph:', '+book: List<&2,KDef>, +sources: List<&2,FSource>, +fallback: String) -> FGraph:')
s=s.replace('f_graph_module_error(source, fpe_defs(book), sources)', 'f_graph_module_error(source, fpe_defs(book), sources, fallback)')
s=s.replace('def f_graph_module_error(+source: FSource, +error: KTerm, +sources: List<&2,FSource>) -> String:\n  fpe_source_render(nm(error), error, f_choose(KTerm, U32.is_gt(kb(error), 0), u => fpe_located_source(error, sources), u => kt("ParseSource", f_source_text(source), 0, 0, Nil{})))', 'def f_graph_module_error(+source: FSource, +error: KTerm, +sources: List<&2,FSource>, +fallback: String) -> String:\n  f_choose(String, f_eq(tg(error), "Absent"), u => fallback, u => fpe_source_render(nm(error), error, f_choose(KTerm, U32.is_gt(kb(error), 0), u => fpe_located_source(error, sources), u => kt("ParseSource", f_source_text(source), 0, 0, Nil{}))))')
f.write_text(s)
changed=[]
for f in p.rglob('*'):
 if f.is_file() and f.relative_to(p).parts[0] in ['src','tools']:
  old=parent/f.relative_to(p)
  if f.read_bytes()!=old.read_bytes():changed.append({'path':str(f.relative_to(p)),'sha256':hashlib.sha256(f.read_bytes()).hexdigest()})
(out/'manifest.json').write_text(json.dumps({'parent':str(parent),'project':str(p),'changes':changed,'checkpoint':'B plus completed-prefix failure ordering'},indent=2)+'\n');c=json.loads((parent.parent/'workflow.json').read_text());c['project']=str(p);(out/'workflow.json').write_text(json.dumps(c,indent=2)+'\n');print(out)

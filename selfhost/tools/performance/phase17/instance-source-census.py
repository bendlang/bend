#!/usr/bin/env python3
"""Read-only lexical scope census; not a call-graph proof or achieved reduction."""
import hashlib, json, re, sys
from pathlib import Path
root=Path(__file__).resolve().parents[4]
out=Path(sys.argv[1]).resolve(); out.mkdir()
def ident(p):
 b=p.read_bytes(); return {"file":str(p),"bytes":len(b),"sha256":hashlib.sha256(b).hexdigest()}
def blocks(s,kind):
 starts=list(re.finditer(r"^(def|law|type) (\w+)",s,re.M)); result={}
 for i,m in enumerate(starts):
  if m.group(1)!=kind: continue
  end=starts[i+1].start() if i+1<len(starts) else len(s)
  text=s[m.start():end]; text=re.sub(r"(?m)^@unsafe\n", "",text).rstrip()+"\n"
  result[m.group(2)]={"line":s[:m.start()].count("\n")+1,"lines":len(text.splitlines()),"text":text}
 return result
sources={str(p.relative_to(root)):p.read_text() for p in (root/'selfhost/src').rglob('*.bend')}
summary={}
for name in ['selfhost/src/check/kernel.bend','selfhost/src/check/specialize.bend']:
 s=sources[name];summary[name]={"identity":ident(root/name),"physicalLines":len(s.splitlines()),"definitions":len(blocks(s,'def')),"laws":len(blocks(s,'law'))}
k=blocks(sources['selfhost/src/check/kernel.bend'],'def')
# Strip comments/strings before collecting literal call spellings; higher-order
# flows and calls through another module are not represented by this census.
def calls(s):
 s=re.sub(r'"(?:[^"\\]|\\.)*"|#[^\n]*','',s)
 return set(re.findall(r'\b(\w+)\s*\(',s))
graph={n:calls(v['text'].split(':',1)[-1])&k.keys() for n,v in k.items()}
reaches={'infer_template'}
while True:
 new=reaches|{n for n,vs in graph.items() if vs&reaches}
 if new==reaches:break
 reaches=new
ctors={c:{n:len(re.findall(r'\b'+c+r'\s*\{',s)) for n,s in sources.items() if re.search(r'\b'+c+r'\s*\{',s)} for c in ['KChecked','KEnv','KSpecState']}
removable='sp_type sp_term sp_annotation sp_lambda sp_single sp_constructor sp_ctor_done sp_args sp_arg_head sp_arg_done sp_cons sp_spine sp_head sp_regular_head sp_regular_done sp_apply_result sp_match sp_match_type sp_match_ctor sp_match_hit sp_pair sp_let sp_let_binding sp_let_bound sp_let_body sp_let_result sp_rewrite sp_rewrite_type sp_rewrite_done'.split()
sp=sources['selfhost/src/check/specialize.bend']; defs=blocks(sp,'def');laws=blocks(sp,'law')
assert all(n in defs for n in removable)
candidate={kind:[{k:v for k,v in table[n].items() if k!='text'}|{"name":n} for n in removable if n in table] for kind,table in [('definitions',defs),('laws',laws)]}
report={"kind":"phase17-instance-source-census","scope":"Lexical counts on installed source; removable visitor family is a proposal, excludes unsafe markers and every replacement cost.","tool":ident(Path(__file__)),"source":summary,"kernelOnlyReachInferTemplate":sorted(reaches),"kernelOnlyReachCount":len(reaches),"constructorPatternAndDeclarationOccurrences":ctors,"proposedVisitorRetirement":candidate,"proposedVisitorBlockLines":sum(x['lines'] for xs in candidate.values() for x in xs)}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({"reach":len(reaches),"visitorDefs":len(candidate['definitions']),"visitorLaws":len(candidate['laws']),"visitorBlockLines":report['proposedVisitorBlockLines'],"constructors":ctors}))

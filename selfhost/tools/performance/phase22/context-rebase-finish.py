"""Resolve explicit cursor-transfer overlaps and remove research-only APIs."""
from pathlib import Path
import re,json,hashlib,difflib
R=Path(__file__).resolve().parents[4];O=R/'selfhost/build/phase22/context-source-02';N=O/'project';P=R/'selfhost/build/phase21/group-range-source-02/project';A=R/'selfhost/build/phase17/find-worker-source-01/project';X=R/'selfhost/build/phase19/context-row-source-05/project'
for name in['declarations','parallel']:
 p=N/f'src/front/{name}.bend';s=p.read_text()
 def merge(m):
  theirs=m.group(2)
  if name=='parallel':theirs=theirs.replace('f_let_ann(ty, f_expr(f_tl(ts), 0))','f_let_ann(ty, f_expr(f_tl(ts), 0), begin)')
  return theirs
 s=re.sub(r'^<<<<<<<[^\n]*\n(.*?)^=======\n(.*?)^>>>>>>>[^\n]*\n',merge,s,flags=re.M|re.S)
 s=s.replace('f_statement_existing(p)))','f_statement_existing(p, begin)))').replace('def f_statement_existing(+p: FParsed)','def f_statement_existing(+p: FParsed, +begin: U32)')
 s=s.replace('+ts: List<&2,FToken>','+ts: FInput')
 p.write_text(s)
for rel in['src/load/imports.bend','src/load/modules.bend']:
 assert(P/rel).read_bytes()==(A/rel).read_bytes(),rel
 (N/rel).write_bytes((X/rel).read_bytes())
p=N/'src/front/contextual.bend';s=p.read_text();removed=[]
names=['f_context_probe','f_context_probe_start','f_context_probe_first','f_context_probe_opened','f_context_probe_inner','f_context_probe_after','f_context_start','f_context_syntax_done','f_context_term','f_context_body_syntax','f_context_finish','f_context_block','f_context_block_done']
for name in names:
 pat=r'@unsafe\ndef '+name+r'\([^\n]*(?:\n(?!@unsafe)[^\n]*)*?(?=\n@unsafe|\Z)'
 m=re.search(pat,s);assert m,name;removed.append({'name':name,'lines':len(m.group().splitlines())});s=s[:m.start()]+s[m.end():]
for name in['FContextSeed','FContextProbe','FContextSyntax']:
 s,n=re.subn(r'type '+name+r' is Data:\n(?:  [^\n]*\n)+','',s);assert n==1,name
s=s.replace('# Private Stage19 names/state primitives. No contextual body grammar yet.','# Contextual parser primitives retained for the pending production migration.').replace('# Private names-stage route through the existing expression grammar; never Core.','# Raw compatibility branches remain until the production migration closes.')
s += '\n@unsafe\ndef f_context_value(+term: KTerm, +input: FInput) -> KTerm:\n  f_context_call_head(term)\n';p.write_text(s)
p=N/'src/compiler.json';m=json.loads(p.read_text());m['modules'].insert(m['modules'].index('src/front/lexer.bend')+1,'src/front/contextual.bend');p.write_text(json.dumps(m,indent=2)+'\n')
identity=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
members=lambda root:[{'path':str(p.relative_to(root)),**identity(p)}for p in sorted(root.rglob('*'))if p.is_file()]
changes=[]
for p in sorted(N.rglob('*')):
 if not p.is_file():continue
 rel=p.relative_to(N);old=P/rel
 if not old.exists()or old.read_bytes()!=p.read_bytes():
  before=old.read_text()if old.exists()else'';after=p.read_text();changes.append({'path':str(rel),'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(p.read_bytes())-(len(old.read_bytes())if old.exists()else0)});(O/(str(rel).replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='a/'+str(rel),tofile='b/'+str(rel))))
(O/'manifest.json').write_text(json.dumps({'complete':True,'stage':'rebased staging barrier, production contextual entry not yet enabled','parent':str(P),'parentMembership':members(P),'candidateMembership':members(N),'removedProbeDefinitions':removed,'removedProbeTypes':['FContextSeed','FContextProbe','FContextSyntax'],'changes':changes,'inputs':[identity(Path(__file__)),identity(O/'transfer.json'),identity(R/'design/phase22/context-production-boundary.md')]},indent=2)+'\n')
(O/'workflow.json').write_text(json.dumps({'project':str(N),'upstream':str(R/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'3','jobs':1,'strictExact':True},indent=2)+'\n');print(json.dumps({'changed':len(changes),'removedProbeDefs':len(removed),'removedProbeLines':sum(x['lines']for x in removed),'physicalLineDelta':sum(x['physicalLineDelta']for x in changes)}))

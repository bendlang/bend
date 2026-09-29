#!/usr/bin/env python3
from pathlib import Path
import os,json,hashlib,shutil,difflib,stat
r=Path(__file__).resolve().parents[4];attempt=r/'selfhost/build/phase16/compact-final-build-01';m=json.loads((attempt/'attempt.json').read_text());base=Path(m['config']['project']);assert base==r/'selfhost/build/phase16/compact-final-source-01/project';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();assert m['api']['sha256']=='35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315';assert sha(Path(m['api']['file']))==m['api']['sha256']
for row in m['snapshot']['sources']:
 for name in ['original','frozen']:assert sha(Path(row[name]['file']))==row[name]['sha256'],row[name]['file']
def inventory(p):
 out=[]
 for root,dirs,files in os.walk(p,followlinks=False):
  for name in dirs+files:
   x=Path(root)/name;s=x.lstat();rel=str(x.relative_to(p))
   if x.is_symlink():out.append({'file':rel,'kind':'symlink','target':os.readlink(x),'mode':stat.S_IMODE(s.st_mode)})
   elif x.is_file():out.append({'file':rel,'kind':'file','bytes':s.st_size,'sha256':sha(x),'mode':stat.S_IMODE(s.st_mode)})
 return sorted(out,key=lambda x:x['file'])
before=inventory(base);o=r/'selfhost/build/phase17/group-source-01';o.mkdir();p=o/'project';shutil.copytree(base,p,symlinks=True);assert inventory(p)==before
x=p/'src/front/parser.bend';s=x.read_text();a='''def f_group(p):
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_eq(f_tx(ts), ","), u => f_tuple(n, f_group(f_body(f_tl(ts)))), u => f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_group_namespace(n, f_expect(f_expr(f_tl(ts), 0), ")")), u => f_expect(FParsed{n, ts}, ")")))''';b='''def f_group(p):
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_eq(f_tx(ts), ","), u => f_tuple(n, f_group(f_body(f_tl(ts)))), u => f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_group_finish(f_group_namespace(n, f_expect(f_expr(f_tl(ts), 0), ")"))), u => f_group_finish(f_expect(FParsed{n, ts}, ")"))))

# A completed grouped body crosses the term-level flattening checkpoint.
@unsafe
def f_group_finish(+parsed: FParsed) -> FParsed:
  match parsed:
    case FParsed{body, rest}:
      FParsed{f_choose(KTerm, f_eq(tg(body), "Local") || f_eq(tg(body), "Match") || f_eq(tg(body), "Parallel"),
        u => kt_span("FGroup", "", 0, 1, [body], kb(body), ke(body)), u => body), rest}''';assert s.count(a)==1;s=s.replace(a,b);x.write_text(s)
x=p/'src/front/elaborate.bend';s=x.read_text();a='u => f_scope_lower(t, env, book)';b='u => f_choose(KTerm, f_eq(tg(t), "FGroup"), u => f_scope(kid(t, 0), env, book), u => f_scope_lower(t, env, book))';assert s.count(a)==1;s=s.replace(a,b);x.write_text(s)
after=inventory(p);old={x['file']:x for x in before};new={x['file']:x for x in after};assert old.keys()==new.keys();changed=[x for x in old if old[x]!=new[x]];assert sorted(changed)==['src/front/elaborate.bend','src/front/parser.bend'];changes=[]
for rel in changed:
 a=base/rel;b=p/rel;xs=a.read_text();ys=b.read_text();(o/(rel.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(xs.splitlines(True),ys.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)));changes.append({'file':rel,'beforeSha256':sha(a),'afterSha256':sha(b),'lineDelta':len(ys.splitlines())-len(xs.splitlines()),'byteDelta':len(b.read_bytes())-len(a.read_bytes()),'definitionDelta':ys.count('\ndef ')-xs.count('\ndef '),'typeDelta':ys.count('\ntype ')-xs.count('\ntype ')})
assert inventory(base)==before
ident=lambda q:{'file':str(q),'sha256':sha(q)};(o/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(base),'checkedParent':ident(attempt/'attempt.json'),'plan':ident(r/'design/phase17/group-boundary.md'),'tool':ident(Path(__file__)),'parentMembership':before,'candidateMembership':after,'changes':changes,'conceptDelta':{'rawTags':['FGroup'],'newHelper':['f_group_finish'],'newSemanticCoreTypes':0,'hostChanges':0}},indent=2)+'\n');(o/'workflow.json').write_text(json.dumps({'project':str(p),'upstream':str(r/'selfhost/.bootstrap/upstream-phase8'),'cpu':'3','jobs':1,'profile':'equality','timeoutMs':30000},indent=2)+'\n');shutil.copy2(__file__,o/'consumed-tool.py');print(o)

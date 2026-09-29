#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil,difflib
r=Path(__file__).resolve().parents[4];b=r/'selfhost/build/phase16/empty-call-pattern-source-01/project';o=r/'selfhost/build/phase16/marked-pattern-source-01';o.mkdir();shutil.copytree(b,o/'project');p=o/'project/src/front/elaborate.bend';s=p.read_text();a='''def f_patterns(
  +xs: List<&2, KTerm>,
  +env: List<&2,KTerm>,
)''';assert s.count(a)==1;s=s.replace(a,a.replace('  +env: List<&2,KTerm>,','  +env: List<&2,KTerm>,\n  +book: List<&2,KDef>,'));a='''      Con{f_choose(KTerm, f_eq(tg(x), "Ref") || f_eq(tg(x), "FAliasRef"),''';assert s.count(a)==1;s=s.replace(a,'''      Con{f_choose(KTerm, U32.is_eq(qt(x), 2) && (f_eq(tg(x), "Ref") || f_eq(tg(x), "FAliasRef") || (f_eq(tg(x), "Call") && U32.is_eq(terms_len(ks(x)), 1))), u => f_pattern_marked(x, f_scope(x, env, book)), u => f_choose(KTerm, f_eq(tg(x), "Ref") || f_eq(tg(x), "FAliasRef"),''');a='u => x)))), f_patterns(xt, env)}';assert s.count(a)==1;s=s.replace(a,'u => x))))), f_patterns(xt, env, book)}');s=s.replace('f_patterns(ks(x), env)','f_patterns(ks(x), env, book)').replace('f_patterns([kid(t, 0)], env)','f_patterns([kid(t, 0)], env, book)').replace('f_patterns(ks(kid(r, 0)), env)','f_patterns(ks(kid(r, 0)), env, book)');at=s.index('# Empty ordinary calls');s=s[:at]+'''# parse_bind turns the marked-variable sentinel into a Many binder.
@unsafe
def f_pattern_marked(+origin: KTerm, +scoped: KTerm) -> KTerm:
  f_choose(KTerm, f_eq(tg(scoped), "FUnboundVar"),
    u => kt_span("Var", nm(scoped), ix(scoped), 2, Nil{}, kb(origin), ke(origin)),
    u => scoped)

'''+s[at:];p.write_text(s);p=o/'project/src/front/parallel.bend';s=p.read_text();a='f_patterns(ks(kid(t, 0)), env)';assert s.count(a)==1;s=s.replace(a,'f_patterns(ks(kid(t, 0)), env, book)');p.write_text(s);changes=[]
for rel in ['src/front/elaborate.bend','src/front/parallel.bend']:
 a=b/rel;p=o/'project'/rel;x=a.read_text();s=p.read_text();(o/(rel.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(x.splitlines(True),s.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)));changes.append({'file':rel,'beforeSha256':hashlib.sha256(a.read_bytes()).hexdigest(),'afterSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lineDelta':len(s.splitlines())-len(x.splitlines()),'byteDelta':len(p.read_bytes())-len(a.read_bytes())})
(o/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(b),'plan':'experiments/phase16/P16-marked-pattern-quantity.md','changes':changes},indent=2)+'\n');cfg=json.loads((b.parent/'workflow.json').read_text());cfg['project']=str(o/'project');(o/'workflow.json').write_text(json.dumps(cfg,indent=2)+'\n');shutil.copy2(__file__,o/'consumed-tool.py');print(o)

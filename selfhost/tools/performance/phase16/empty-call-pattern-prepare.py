#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil,difflib
root=Path(__file__).resolve().parents[4];base=root/'selfhost/build/phase16/wave9-source-01/project';out=root/'selfhost/build/phase16/empty-call-pattern-source-01';out.mkdir();shutil.copytree(base,out/'project');p=out/'project/src/front/elaborate.bend';s=p.read_text();a='u => k_with_children(x, f_patterns(ks(x), env)), u => x))), f_patterns(xt, env)}';b='u => k_with_children(x, f_patterns(ks(x), env)), u => f_choose(KTerm, f_eq(tg(x), "Call") && U32.is_eq(qt(x), 1) && U32.is_eq(terms_len(ks(x)), 1), u => f_pattern_empty_call(x, kid(x, 0), env), u => x)))), f_patterns(xt, env)}';assert s.count(a)==1;s=s.replace(a,b);at=s.index('@unsafe\ndef f_penv(');s=s[:at]+'''# Empty ordinary calls keep a bound name a binder; unbound calls keep scope validation.
@unsafe
def f_pattern_empty_call(+original: KTerm, +head: KTerm, +env: List<&2,KTerm>) -> KTerm:
  f_choose(KTerm, f_eq(tg(head), "Call") && U32.is_eq(qt(head), 1) && U32.is_eq(terms_len(ks(head)), 1),
    u => f_pattern_empty_call(original, kid(head, 0), env),
    u => f_choose(KTerm, (f_eq(tg(head), "Ref") || f_eq(tg(head), "FAliasRef")) && U32.is_eq(qt(head), 1),
      u => f_choose(KTerm, f_eq(tg(f_env(nm(head), env)), "Absent"),
        u => k_with_span(original, kb(head), ke(head)),
        u => kt_span("Var", nm(head), ix(head), qt(head), Nil{}, kb(head), ke(head))),
      u => original))

'''+s[at:];p.write_text(s);old=base/'src/front/elaborate.bend';x=old.read_text();(out/'elaborate.patch').write_text(''.join(difflib.unified_diff(x.splitlines(True),s.splitlines(True),fromfile='parent/src/front/elaborate.bend',tofile='candidate/src/front/elaborate.bend')));(out/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(base),'plan':'experiments/phase16/P16-empty-call-patterns.md','changes':[{'file':'src/front/elaborate.bend','beforeSha256':hashlib.sha256(old.read_bytes()).hexdigest(),'afterSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lineDelta':len(s.splitlines())-len(x.splitlines()),'byteDelta':len(p.read_bytes())-len(old.read_bytes())}]},indent=2)+'\n');(out/'workflow.json').write_text(json.dumps({'project':str(out/'project'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'cpu':'3','jobs':1,'profile':'equality','timeoutMs':30000},indent=2)+'\n');shutil.copy2(__file__,out/'consumed-tool.py');print(out)

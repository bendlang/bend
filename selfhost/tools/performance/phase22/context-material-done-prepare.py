#!/usr/bin/env python3
from pathlib import Path
import shutil,json,hashlib
R=Path(__file__).resolve().parents[4];p=R/'selfhost/build/phase22/context-source-08';n=R/'selfhost/build/phase22/context-source-09'
assert not n.exists();n.mkdir();shutil.copytree(p/'project',n/'project')
f=n/'project/src/front/literals_arrays.bend';s=f.read_text()
a='''  f_choose(KTerm, Bool.not(lower) && f_eq(tg(term), "App") && f_eq(tg(kid(term, 0)), "Lam"),
    u => f_context_higher(f_scope_app_span(kid(term, 0), kid(term, 1), kb(term), ke(term))), u => term)'''
b='''  f_choose(KTerm, Bool.not(lower) && f_eq(tg(term), "App"),
    u => f_choose(KTerm, f_eq(tg(kid(term, 0)), "Lam"),
      u => f_context_higher(f_scope_app_span(kid(term, 0), kid(term, 1), kb(term), ke(term))), u => term),
    u => term)'''
assert s.count(a)==1;s=s.replace(a,b);f.write_text(s)
(n/'parent.json').write_text(json.dumps({'parent':str(p),'parentManifestSha256':hashlib.sha256((p/'manifest.json').read_bytes()).hexdigest(),'correction':'Guard the App constructor before accessing its head during materialization; removes an undemanded deferred-child lookup and preserves eager beta semantics.','witness':'selfhost/build/phase22/completion-beta-controls-02/report.json','toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')

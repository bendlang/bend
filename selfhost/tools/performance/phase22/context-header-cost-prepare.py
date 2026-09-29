#!/usr/bin/env python3
from pathlib import Path
import shutil,json,hashlib
R=Path(__file__).resolve().parents[4];p=R/'selfhost/build/phase22/context-source-10';n=R/'selfhost/build/phase22/context-source-11'
assert not n.exists();n.mkdir();shutil.copytree(p/'project',n/'project')
f=n/'project/src/front/declarations.bend';s=f.read_text()
a='f_choose(FRawResult, Bool.not(f_eq(alias, name)) && f_declared(alias, prior) && f_declared(name, prior),'
b='f_choose(FRawResult, f_choose(Bool, Bool.not(f_eq(alias, name)), u => f_declared(alias, prior) && f_declared(name, prior), u => False{}),'
assert s.count(a)==1;s=s.replace(a,b);f.write_text(s)
paths=[p/'manifest.json',R/'design/phase22/context-header-cost.md',Path(__file__)]
(n/'parent.json').write_text(json.dumps({'parent':str(p),'correction':'Guard both alias membership scans behind the actual changed-spelling condition; preserve alias branch semantics.','inputs':[{'file':str(x),'sha256':hashlib.sha256(x.read_bytes()).hexdigest()}for x in paths]},indent=2)+'\n')

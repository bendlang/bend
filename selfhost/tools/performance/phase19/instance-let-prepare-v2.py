"""Extend frozen controls with do-assignment range boundaries."""
from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parents[4];OLD=ROOT/'selfhost/build/phase19/instance-let-controls-01';OUT=ROOT/'selfhost/build/phase19/instance-let-controls-02';OUT.mkdir();(OUT/'fixtures').mkdir()
cases=json.loads((OLD/'selection.json').read_text())['cases']
base='import Base\ndef consume4(a: Unit, b: Unit, c: Unit, d: Unit) -> Unit:\n  a\ndef main() -> IO(Unit):\n  do IO<Unit>:\n    a: Unit = Unit{}\n'
for name,body,accept in [('do-invalid','    return consume4(a, a, Unit{}, Unit{})\n',False),('do-valid','    return consume4(a, Unit{}, Unit{}, Unit{})\n',True)]:
 p=OUT/'fixtures'/(name+'.bend');p.write_text(base+body);c={'id':'p19-let/'+name,'file':str(p),'lanes':['check'],'accept':accept}
 if not accept:c['rejectPhase']='check'
 cases.append(c)
(OUT/'selection.json').write_text(json.dumps({'cases':cases},indent=2)+'\n')
inputs=[Path(__file__),OLD/'manifest.json',ROOT/'design/phase19/instance-let-observations.md',*[Path(c['file']) for c in cases],OUT/'selection.json']
(OUT/'manifest.json').write_text(json.dumps({'kind':'phase19-let-closure-do-controls','frozen':True,'inputs':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in inputs]},indent=2)+'\n');print(OUT)

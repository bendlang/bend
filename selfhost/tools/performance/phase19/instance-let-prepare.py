"""Freeze let-closure precedence witnesses before compiler mutation."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[4]
OUT=ROOT/'selfhost/build/phase19/instance-let-controls-01';OUT.mkdir();(OUT/'fixtures').mkdir()
base='type Unit is Data:\n  Unit{}\ndef unit() -> Unit:\n  Unit{}\ndef consume4(a: Unit, b: Unit, c: Unit, d: Unit) -> Unit:\n  a\n'
rows=[('body-before-closure','def main() -> Unit -> Unit:\n  a: Unit = Unit{}\n  y => consume4(a, a, y, y)\n',False),('parallel-first','def main() -> Unit:\n  a b = unit() unit()\n  consume4(a, a, b, b)\n',False),('parallel-second-only','def main() -> Unit:\n  a b = unit() unit()\n  consume4(a, unit(), b, b)\n',False),('parallel-valid','def main() -> Unit:\n  a b = unit() unit()\n  consume4(a, unit(), b, unit())\n',True)]
cases=[]
for name,body,accept in rows:
 p=OUT/'fixtures'/(name+'.bend');p.write_text(base+body)
 c={'id':'p19-let/'+name,'file':str(p),'lanes':['check'],'accept':accept}
 if not accept:c['rejectPhase']='check'
 cases.append(c)
(OUT/'selection.json').write_text(json.dumps({'cases':cases},indent=2)+'\n')
inputs=[Path(__file__),ROOT/'design/phase19/instance-let-closure.md',*[Path(c['file']) for c in cases],OUT/'selection.json']
(OUT/'manifest.json').write_text(json.dumps({'kind':'phase19-let-closure-witnesses','frozen':True,'parent':'instance-source-03','inputs':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in inputs]},indent=2)+'\n')
print(OUT)

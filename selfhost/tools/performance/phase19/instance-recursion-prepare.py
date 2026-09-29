"""Freeze checker-only recursive template controls before either oracle."""
from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parents[4];OUT=ROOT/'selfhost/build/phase19/instance-recursion-controls-01';OUT.mkdir();(OUT/'fixtures').mkdir()
base='type Bit is Data:\n  Zero{}\ntype Count is Data:\n  Done{}\n'
loop='def loop(~key: Bit, n: Count) -> Count:\n  loop(~key, n)\ndef main() -> Count:\n  loop(~Zero{}, Done{})\n'
cycle=ROOT/'selfhost/.bootstrap/upstream-phase8/tests/check/template_inst_cycle.bend';positive=ROOT/'selfhost/build/phase17/instance-controls-02/fixtures/decreasing-reuse.bend'
text='\n'.join(l for l in cycle.read_text().splitlines() if not l.startswith('#|'))+'\n';text=text.replace('def bounce(', '@unsafe\ndef bounce(').replace('def loop(', '@unsafe\ndef loop(')
rows=[('safe-unchanged',base+loop,False),('unsafe-unchanged',base+'@unsafe\n'+loop,True),('unsafe-cross-cycle',text,False),('safe-decreasing',positive.read_text(),True)]
cases=[]
for name,text,accept in rows:
 p=OUT/'fixtures'/(name+'.bend');p.write_text(text);c={'id':'p19-recursion/'+name,'file':str(p),'lanes':['check'],'accept':accept}
 if not accept:c['rejectPhase']='check'
 cases.append(c)
(OUT/'selection.json').write_text(json.dumps({'cases':cases},indent=2)+'\n');inputs=[Path(__file__),ROOT/'design/phase19/instance-recursion-boundaries.md',cycle,positive,OUT/'selection.json',*[Path(c['file'])for c in cases]]
(OUT/'manifest.json').write_text(json.dumps({'kind':'phase19-recursion-controls','frozen':True,'inputs':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in inputs]},indent=2)+'\n');print(OUT)

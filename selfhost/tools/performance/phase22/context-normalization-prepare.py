#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];O=R/'selfhost/build/phase22/context-normalization-controls-01';O.mkdir();F=O/'fixtures';F.mkdir()
sources={
 'identity-beta':('import Base\ndef run()->U32:\n  (x => x)(0)\n',True),
 'capture-beta':('import Base\ndef run()->U32:\n  (x => (y => x))(1)(2)\n',True),
 'discarded-lambda-operator':('import Base\ndef run()->U32:\n  (x => 0)(y => (1 + 2))\n',True),
 'strict-argument-operator':('import Base\ndef run()->U32:\n  (x => 0)(1 + 2)\n',False),
 'parenthesized-comparison':('import Base\ndef run(a:U32,b:U32)->Bool:\n  (a < b : U32)\n',True),
 'header-beta':('import Base\ndef run()->(x => x)(U32):\n  0\n',True),
}
cases=[]
for name,(src,accept) in sources.items():
 p=F/(name+'.bend');p.write_text(src);cases.append({'id':'context-normalization/'+name,'file':str(p),'lanes':['parse','check'],'accept':accept})
h=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(O/'selection.json').write_text(json.dumps({'cases':cases},indent=2)+'\n');(O/'manifest.json').write_text(json.dumps({'complete':True,'intent':'Freeze parser-completion beta normalization, strict arguments versus deferred lambda body, capture and actual annotated comparison before further canonicalization changes. Labels are hypotheses; strict oracle failures retained.','inputs':[h(Path(__file__)),*[h(p)for p in sorted(F.iterdir())]],'observations':12},indent=2)+'\n')

#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];O=R/'selfhost/build/phase22/context-header-controls-01';O.mkdir();F=O/'fixtures';F.mkdir()
sources={
 'law-self':('import Base\nlaw same:\n  for ~A: Type\n  for x: A\n  A\n@unsafe\ndef same(A,x):\n  same(~A,x)\n',True),
 'template-self':('import Base\n@unsafe\ndef same(~A:Type,x:A)->A:\n  same(~A,x)\n',True),
 'lower-family':('import Base\ntype lower<-A:Type> is Data:\n  Wrap{+x:A}\ndef run()->lower<U32>:\n  Wrap{0}\n',True),
 'comparison':('import Base\ndef run(a:U32,b:U32)->Bool:\n  {a < b : U32}\n',True),
 'nonfamily-head':('import Base\ndef run()->Type:\n  (0)<U32>\n',False),
 'compound-family':('import Base\ndef run()->Type:\n  List<U32 & U32>\n',False),
}
cases=[]
for name,(src,accept) in sources.items():
 p=F/(name+'.bend');p.write_text(src);cases.append({'id':'context-header/'+name,'file':str(p),'lanes':['parse','check'],'accept':accept})
identity=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(O/'selection.json').write_text(json.dumps({'cases':cases},indent=2)+'\n');(O/'manifest.json').write_text(json.dumps({'complete':True,'intent':'Freeze law-fill template metadata and actual family/operator checkpoint neighbors before comparing source05 and source06; retain any oracle-label disagreement.','inputs':[identity(Path(__file__)),*[identity(p)for p in sorted(F.iterdir())]],'observations':12},indent=2)+'\n')

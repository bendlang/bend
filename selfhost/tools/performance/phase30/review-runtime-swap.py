#!/usr/bin/env python3
"""Diagnostic only: replace one exact runtime component in emitted JS bytes."""
from pathlib import Path
import hashlib,json,sys
source,old,new,out=map(Path,sys.argv[1:])
def identity(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
inputs=[identity(p) for p in [Path(__file__),source,old,new]]
a,b,c=source.read_bytes(),old.read_bytes(),new.read_bytes()
assert a.count(b)==1,'old component must occur exactly once'
out.parent.mkdir(parents=True,exist_ok=True)
with out.open('xb') as f:f.write(a.replace(b,c))
with out.with_suffix(out.suffix+'.json').open('x') as f:json.dump({'kind':'phase30-diagnostic-runtime-component-swap','complete':True,'checkedCompilerClaim':False,'inputs':inputs,'output':identity(out)},f,indent=2)
assert inputs==[identity(p) for p in [Path(__file__),source,old,new]]
print(json.dumps({'complete':True,'output':identity(out)}))

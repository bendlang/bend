#!/usr/bin/env python3
"""Freeze separate exact-arm versus private-call comparison; no timing."""
from pathlib import Path
import hashlib,json,shutil,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
base,out=map(lambda x:Path(x).resolve(),sys.argv[1:])
assert (out/'exact.mjs').is_file() and not (out/'plan.json').exists()
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
for side in ['unchanged','private','upstream']:shutil.copyfile(base/(side+'.mjs'),out/(side+'.mjs'))
inputs=[ident(p) for p in [Path(__file__),out/'report.json',out/'check.stdout',out/'points.json',ROOT/'design/phase30/exact-constructor-arms.md']]
modules={side:str(out/(side+'.mjs')) for side in ['unchanged','exact','private','upstream']}
point=next(p for p in json.loads((out/'points.json').read_text()) if p['args']==[32,17])
for protocol in ['screen','confirm']:save(out/(protocol+'.json'),{'protocol':protocol,'inputs':inputs,'cases':[{'id':'exact-edit-row-32','point':point,'modules':modules}]})
save(out/'plan.json',{'complete':True,'kind':'phase30-exact-arm-plan','scope':'Same frozen whole-row oracle; isolated exact arm versus isolated private entry, no combination. No timing.','inputs':inputs,'modules':[ident(Path(p)) for p in modules.values()]})

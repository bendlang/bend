#!/usr/bin/env python3
"""Isolate two literal Nat shifts inside a frozen private scalar helper."""
from pathlib import Path
import hashlib,json,re,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
parent=ROOT/'selfhost/build/phase30/counter-01'
plan=ROOT/'design/phase30/constant-native-shifts.md'
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
inputs=[ident(p)for p in [parent/'derive.json',parent/'baseline.mjs',parent/'bigint.mjs',parent/'upstream.mjs',plan,Path(__file__)]]
source=(parent/'bigint.mjs').read_text();lines=source.splitlines(keepends=True)
indices=[i for i,l in enumerate(lines)if l.startswith('function $p30_region_asr8(')]
assert len(indices)==1;i=indices[0]
pattern=r'\(\(a,n\)=>n>=32n\?0:\(a>>>Number\(n\)\)>>>0\)\(\((x\d+)\),\((8|31)n\)\)'
hits=re.findall(pattern,lines[i]);assert [n for _,n in hits]==['8','31']
lines[i]=re.sub(pattern,lambda m:'('+m[1]+'>>>'+m[2]+')',lines[i])
candidate=''.join(lines)
for name,file in [('baseline','baseline.mjs'),('region','bigint.mjs'),('upstream','upstream.mjs')]:
 (out/(name+'.mjs')).write_bytes((parent/file).read_bytes())
(out/'constant.mjs').write_text(candidate)
for name,p in [('plan.md',plan),('derive.py',Path(__file__))]:(out/name).write_bytes(p.read_bytes())
report={'kind':'phase30-private-literal-native-shifts','complete':True,'inputs':inputs,'outputs':{n:ident(out/(n+'.mjs'))for n in ['baseline','region','constant','upstream']},'changedSites':hits,'onlyChange':'Two constant right shifts in private helper; native BigInt counter unchanged','compilerChanged':False,'correctness':'pending','measurement':'pending'}
save(out/'derive.json',report)
for protocol in ['screen','confirm']:
 save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(out/'derive.json'),*inputs],'cases':[{'id':'private-literal-shifts','point':{'args':[128,524800],'expected':128},'modules':{k:v['file']for k,v in report['outputs'].items()}}]})
assert inputs==[ident(Path(x['file']))for x in inputs]
print(json.dumps({'complete':True,'out':str(out),'changedSites':hits}))

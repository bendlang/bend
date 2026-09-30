#!/usr/bin/env python3
"""Separate private counter representation from scalar-region call lowering."""
from pathlib import Path
import hashlib, importlib.util, json, re, sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
source=ROOT/'selfhost/build/phase29/fixture-candidate-04/candidate.mjs'
upstream=ROOT/'selfhost/build/phase29/prototype-01/upstream.mjs'
plan=ROOT/'design/phase30/private-counter-representation.md'
spec=importlib.util.spec_from_file_location('region',HERE/'inspect-pure-region.py')
region=importlib.util.module_from_spec(spec);spec.loader.exec_module(region)
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):
 return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
inputs=[ident(p)for p in [source,upstream,plan,Path(__file__),HERE/'inspect-pure-region.py',HERE/'inspect-direct-lambda.py']]
original=source.read_text();big=region.derive(original)
mark='function $p30_region_loop($s0,$s1,$s2,$s3,$s4,$s5,$s6){'
assert big.count(mark)==1
start=big.index(mark)+len(mark);end=big.index('\nexport {G,call,list,ctor};',start)
body=big[start:end]
alias=re.search(r'^for\(;;\)\{const (x\d+)=\$s0;',body).group(1)
assert len(re.findall(r'\b'+alias+r'\b',body))==2
assert body.count('const $n0='+alias+';')==1
assert body.count('if($n0===0n)')==1 and body.count('$s0=$n0-1n;')==1
assert len(re.findall(r'\$n0\b',body))==3
number=big[:start]+'$s0=Number($s0);'+body.replace('if($n0===0n)','if($n0===0)').replace('$s0=$n0-1n;','$s0=$n0-1;')+big[end:]
for name,s in [('baseline',original),('bigint',big),('number',number),('upstream',upstream.read_text())]:
 (out/(name+'.mjs')).write_text(s)
for name,p in [('plan.md',plan),('derive.py',Path(__file__)),('region-derive.py',HERE/'inspect-pure-region.py'),('lambda-derive.py',HERE/'inspect-direct-lambda.py')]:
 (out/name).write_bytes(p.read_bytes())
report={'kind':'phase30-private-countdown-representation','complete':True,'inputs':inputs,'outputs':{n:ident(out/(n+'.mjs'))for n in ['baseline','bigint','number','upstream']},'proof':{'predecessorAlias':alias,'aliasUses':2,'nextCounterUses':3,'counterGuard':'native 48-bit nonnegative predecessor','onlyChanges':['private initial Number conversion','zero comparison','predecessor subtraction']},'compilerChanged':False,'correctness':'pending','measurement':'pending'}
save(out/'derive.json',report)
for protocol in ['screen','confirm']:
 save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(out/'derive.json'),*inputs],'cases':[{'id':'private-counter-mandelbrot','point':{'args':[128,524800],'expected':128},'modules':{k:v['file']for k,v in report['outputs'].items()}}]})
assert inputs==[ident(Path(x['file']))for x in inputs]
print(json.dumps({'complete':True,'out':str(out),'outputs':report['outputs']}))

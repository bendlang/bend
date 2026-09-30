#!/usr/bin/env python3
"""Separate actual scalar guard cost from cold fallback placement."""
from pathlib import Path
import hashlib,json,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
source=ROOT/'selfhost/build/phase30/fixture-region-07/candidate.mjs'
upstream=ROOT/'selfhost/build/phase29/prototype-01/upstream.mjs'
plan=ROOT/'design/phase30/scalar-region-residual-cost.md'
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
def closing(text,at):
 assert text[at]=='{';depth=0;quote=None;escape=False
 for i in range(at,len(text)):
  c=text[i]
  if quote:
   if escape:escape=False
   elif c=='\\':escape=True
   elif c==quote:quote=None
  elif c in ['"',"'"]:quote=c
  elif c=='{':depth+=1
  elif c=='}':
   depth-=1
   if depth==0:return i
 raise AssertionError('unclosed generated block')
inputs=[ident(p)for p in [source,Path(str(source)+'.json'),upstream,plan,Path(__file__),ROOT/'selfhost/build/phase30/attempt-07/attempt.json']]
text=source.read_text();lines=text.splitlines(keepends=True);indices=[i for i,l in enumerate(lines)if l.startswith('G["mit"]=scalarCapture(')]
assert len(indices)==1;index=indices[0];line=lines[index]
guard='scalarGuard($guards)';assert line.count(guard)==1
callback='exactCode(function(a,$entered){/* private Nat loop */';assert line.count(callback)==1
body_open=line.index(callback)+len('exactCode(function(a,$entered)');body_close=closing(line,body_open)
fast_marker=guard+'){/* private scalar region */';assert line.count(fast_marker)==1
fast_open=line.index(fast_marker)+len(guard)+1;fast_close=closing(line,fast_open)
fallback=line[fast_close+1:body_close]
assert fallback.startswith('const x') and 'return 'in fallback and 'jump('in fallback
slots=[f'$s{i}'for i in range(7)];args=','.join(slots)
assert all(f'a[{i}]'in line[body_open:fast_open]for i in range(7))
outlined=line[:fast_close+1]+'return $fallback('+args+');'+line[body_close:]
assert outlined.count('const $guards=')==1
outlined=outlined.replace('const $guards=','const $fallback=function('+args+'){'+fallback+'};const $guards=',1)
variants={'actual':line,'unguarded_diagnostic':line.replace(guard,'true',1),'outlined':outlined}
for name,replacement in variants.items():
 changed=lines.copy();changed[index]=replacement;(out/(name+'.mjs')).write_text(''.join(changed))
(out/'upstream.mjs').write_bytes(upstream.read_bytes())
(out/'plan.md').write_bytes(plan.read_bytes());(out/'derive.py').write_bytes(Path(__file__).read_bytes())
points=ROOT/'selfhost/tools/performance/phase29/fixture-points.json';inputs.append(ident(points));p=json.loads(points.read_text());p['points'].append({'exportName':'point','args':[50000,0,0,0,0,0,0],'expected':50000});save(out/'points.json',p)
report={'kind':'phase30-actual-region-residual-ablation','complete':True,'inputs':inputs,'outputs':{n:ident(out/(n+'.mjs'))for n in [*variants,'upstream']},'fallbackBytes':len(fallback.encode()),'scope':'Unguarded variant only diagnoses unchanged descriptors and is never eligible for promotion. Outlined variant awaits full ABI controls.','compilerChanged':False,'correctness':'pending','measurement':'pending'}
save(out/'derive.json',report)
for protocol in ['screen','confirm']:
 save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(out/'derive.json'),*inputs],'cases':[{'id':'actual-region-residual','point':{'args':[128,524800],'expected':128},'modules':{n:i['file']for n,i in report['outputs'].items()}}]})
assert all(ident(Path(i['file']))==i for i in inputs)
print(json.dumps({'complete':True,'out':str(out),'fallbackBytes':report['fallbackBytes']}))

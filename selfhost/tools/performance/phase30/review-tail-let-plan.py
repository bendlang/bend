#!/usr/bin/env python3
"""Adapt unchanged semantic controls and freeze the separate general-Let screen."""
from pathlib import Path
import hashlib,json,shutil,sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
BUILD=ROOT/'selfhost/build/phase30'
out=Path(sys.argv[1]).resolve();out.mkdir(exist_ok=False)
def ident(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
def edit(s,old,new):
 assert s.count(old)==1,(old,s.count(old));return s.replace(old,new)
inputs=[ident(Path(__file__))]
for name in ['mandel','row','editdist']:
 d=BUILD/f'review-tail-let-{name}-01';r=json.loads((d/'derive.json').read_text());assert r['complete'] and r['reconstructedOriginal']
 inputs.extend([ident(d/'derive.json'),*r['inputs'],*r['outputs'].values()])
synthetic=BUILD/'review-tail-let-synthetic-01/report.json';assert json.loads(synthetic.read_text())['pass'];inputs.append(ident(synthetic))
mandel=BUILD/'review-tail-let-mandel-01'
save(out/'mandel.json',dict(baseline=str(mandel/'baseline.mjs'),candidate=str(mandel/'candidate.mjs')))
save(out/'tree.json',dict(variants={s:str(mandel/(s+'.mjs')) for s in ['baseline','candidate']},inputs=[str(mandel/'derive.json')]))
rowdir=out/'row';rowdir.mkdir()
suffix='export default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));'
replacement='const $TailLetExports=Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));\nexport default {...$TailLetExports,bench:(n,seed)=>{const st=$TailLetExports["row.probe"](n,seed);return JSON.stringify(st.a.map(x=>x.array));}};'
for side in ['baseline','candidate']:
 source=(BUILD/'review-tail-let-row-01'/(side+'.mjs')).read_text();(rowdir/(side+'.mjs')).write_text(edit(source,suffix,replacement))
for source,name in [(BUILD/'review-tail-let-row-01/derive.json','derive.json'),(BUILD/'prototype-owned-01/points.json','points.json'),(BUILD/'prototype-owned-01/typescript.mjs','typescript.mjs')]:
 inputs.append(ident(source));shutil.copyfile(source,rowdir/name)
owned=HERE/'prototype-owned-controls.mjs';deferred=HERE/'review-owned-row-controls.mjs'
inputs.extend(map(ident,[owned,deferred]))
s=edit(owned.read_text(),"const variants=['baseline','private_cell','private_scalar','private_row'];","const variants=['baseline','candidate'];")
s=s.replace('modules.slice(0,4)','modules.slice(0,variants.length)').replace('files.slice(0,4)','files.slice(0,variants.length)')
s=edit(s,'for(let i=0;i<4;i++)','for(let i=0;i<variants.length;i++)')
start=s.index(' // Post-guard sentinels');end=s.index(' for(const row of report.inputs)',start)
s=s[:start]+' // This experiment changes no admission predicate; private-region sentinels do not apply.\n'+s[end:]
(rowdir/'controls.mjs').write_text(s)
(rowdir/'deferred.mjs').write_text(edit(deferred.read_text(),"const variants=['baseline','private_cell','private_scalar','private_row'];","const variants=['baseline','candidate'];"))
ordinary=HERE/'prototype-lambda-region-controls.mjs';inputs.append(ident(ordinary))
s=edit(ordinary.read_text(),"const variants=['baseline','pix','rpix','both'];","const variants=['baseline','candidate'];")
(out/'ordinary.mjs').write_text(s)
plan={'kind':'phase30-general-tail-let-controls-plan','complete':True,'inputs':inputs,
 'scope':'Checked actual13 Mandel/editdist plus newly checked identical owned-row source. Only generated tail Let returns change; identical row JSON adapter on both sides.',
 'commands':[
  ['review-scalar-compiler-run.mjs',str(out/'mandel.json'),'review-tail-let-scalar-01'],
  ['review-scalar-entry.mjs',str(out/'mandel.json'),'review-tail-let-entry-01'],
  ['review-tree-boundaries.mjs',str(out/'tree.json'),'review-tail-let-tree-01'],
  [str(out/'ordinary.mjs'),str(mandel),'review-tail-let-ordinary-01'],
  [str(rowdir/'controls.mjs'),str(rowdir),'review-tail-let-owned-01'],
  [str(rowdir/'deferred.mjs'),str(rowdir),'review-tail-let-deferred-01']]}
plan['outputs']=[ident(p) for p in sorted(out.rglob('*')) if p.is_file()]
for row in inputs:assert ident(row['file'])==row
save(out/'plan.json',plan)
print(json.dumps({'complete':True,'out':str(out)}))

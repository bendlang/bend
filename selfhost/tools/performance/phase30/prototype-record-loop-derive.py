#!/usr/bin/env python3
"""Disposable opaque-state row loop; no production compiler changes or timing."""
from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[4]
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
base=ROOT/'selfhost/build/phase30/prototype-02'
design=ROOT/'design/phase30/record-carrying-nat-loop.md'
amendment=ROOT/'design/phase30/record-loop-boundary-amendment.md'
report={'kind':'phase30-opaque-state-row-loop-acquisition','complete':False,
 'scope':'Generated-JS only; immutable recursive G.row descriptor and standard host intrinsics. Original public first-step demand and tail deferral retained. Cell/arrays/project/build unchanged.',
 'inputs':[ident(Path(__file__)),ident(design),ident(amendment),ident(base/'points.json')], 'variants':{},'rewrites':[]}
save(out/'report.json',report)
(out/'consumed-derive.py').write_bytes(Path(__file__).read_bytes())
(out/'prospective-design.md').write_bytes(design.read_bytes())
(out/'prospective-amendment.md').write_bytes(amendment.read_bytes())
(out/'points.json').write_bytes((base/'points.json').read_bytes())
inc='(/* primitive */(((x3530)+1)>>>0))'
prefix='call(call(call(get(G,"row"),[x3529]),['+inc+']),[x3531])'
cells={'unchanged':'call(call(get(G,"cell"),[x3530,x3531,]),[x3532])',
       'private':'force(P_cell(x3530,x3531,x3532))'}
for side in ['unchanged','private','upstream']:
    path=base/(side+'.mjs');text=path.read_text();report['inputs'].append(ident(path))
    (out/(side+'.mjs')).write_text(text);report['variants'][side]=ident(out/(side+'.mjs'))
    if side=='upstream':continue
    cell=cells[side]
    before='return jump('+prefix+',['+cell+']);'
    assert text.count(before)==1
    after='''const $prefix=call(get(G,"row"),[x3529]);
const $j='''+inc+''';
const $next=call(call($prefix,[$j]),[x3531]);
const $value='''+cell+''';
return typeof x3529!=="bigint"||x3529===0n?jump($next,[$value]):jump(R_row_loop,[x3529,$j,x3531,$value]);'''
    worker='''
// Disposable opaque-state loop. The public callback returns before later steps.
const R_row_loop=fn(4,function(a){
  let $n=a[0],$j=a[1],$ai=a[2],$state=a[3];
  for(;;){
    const x3529=$n-1n,x3530=$j,x3531=$ai,x3532=$state;
    const $zero=x3529===0n?call(get(G,"row"),[x3529]):null;
    const $nextj='''+inc+''';
    const $next=$zero===null?null:call(call($zero,[$nextj]),[x3531]);
    const $value='''+cell+''';
    if(x3529===0n)return jump($next,[$value]);
    $n=x3529;$j=$nextj;$ai=x3531;$state=$value;
  }
});
export {R_row_loop};
'''
    candidate=text.replace(before,after)+worker
    name='row-loop' if side=='unchanged' else 'private-row-loop'
    p=out/(name+'.mjs');p.write_text(candidate);report['variants'][name]=ident(p)
    report['rewrites'].append({'variant':name,'from':before,'to':after,'worker':worker})
    if side=='unchanged':
        # Deliberately rejected scheduling witness; never included in timing.
        eager=candidate.replace('jump(R_row_loop,[x3529,$j,x3531,$value])','call(R_row_loop,[x3529,$j,x3531,$value])')
        p=out/'row-loop-eager-rejected.mjs';p.write_text(eager);report['rejectedWitness']=ident(p)
save(out/'rewrites.json',report['rewrites'])
points=json.loads((out/'points.json').read_text());point=next(x for x in points if x['args']==[32,17])
modules={side:report['variants'][side]['file'] for side in ['unchanged','row-loop','private','private-row-loop','upstream']}
for protocol in ['screen','confirm']:
    save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(design),ident(amendment),ident(out/'points.json'),ident(out/'rewrites.json')],
      'cases':[{'id':'edit-row-32','point':point,'modules':modules}]})
for p in report['inputs']:assert ident(Path(p['file']))==p
report['complete']=True;save(out/'report.json',report)
print(json.dumps({'complete':True,'out':str(out),'variants':list(report['variants'])}))

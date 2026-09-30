#!/usr/bin/env python3
"""Attach the established complete-state row fixture to frozen runtime ablations."""
from pathlib import Path
import hashlib, json, sys

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / 'selfhost/build/phase30/inspection-exact-call-01/editdist'
ADAPTER = ROOT / 'selfhost/build/phase30/prototype-record-loop-guard-01/unchanged.mjs'
POINTS = ROOT / 'selfhost/build/phase30/prototype-02/points.json'
PLAN = ROOT / 'design/phase30/exact-entry-call-read-row.md'
EVIDENCE = [ROOT / ('selfhost/build/phase30/' + p + '/report.json') for p in
            ['inspection-exact-call-abi-01', 'inspection-exact-call-entry-01', 'inspection-exact-call-controls-01']]
CONTROLS = ROOT / 'selfhost/tools/performance/phase30/prototype-record-loop-controls.mjs'

def identity(p):
    raw=p.read_bytes()
    return {'file':str(p.resolve()),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}

out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
adapter=ADAPTER.read_text().split('const originalExports = ',1)[1]
adapter='const originalExports = '+adapter
assert adapter.count('function fixture(n,seed)')==1
assert 'JSON.stringify(st.a.map(x=>x.array))' in adapter
old='export default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));\n'
inputs=[identity(p) for p in [Path(__file__),PLAN,ADAPTER,POINTS,CONTROLS,SOURCE.parent/'derive.json',*EVIDENCE]]
modules={}
for side,expected in [('baseline','7b0d5eb670693d0940155a1e560da81c9d8b98e07f01376264bccb20ba67361c'),
                      ('actual-call','ef4c3dd6a91bdfd93a7cbca0691a289c2199c2c1541f541fb993ffae1a36455e')]:
    p=SOURCE/(side+'.mjs');assert identity(p)['sha256']==expected
    text=p.read_text();assert text.count(old)==1
    target=out/(side+'.mjs');target.write_text(text.replace(old,adapter))
    inputs.append(identity(p));modules[side.replace('-','_')]=str(target)
(out/'points.json').write_bytes(POINTS.read_bytes())
(out/'consumed-derive.py').write_bytes(Path(__file__).read_bytes())
(out/'plan.md').write_bytes(PLAN.read_bytes())
controls=CONTROLS.read_text()
controls=controls.replace("['unchanged',candidateName,'row-loop-eager-rejected']", "['baseline',candidateName]")
controls=controls.replace('modules.unchanged','modules.baseline')
start=controls.index(' for(const [name,variant,options]of [')
end=controls.index(' for(const x of report.inputs)',start)
controls=controls[:start]+controls[end:]
controls=controls.replace("kind:'phase30-opaque-record-loop-controls'", "kind:'phase30-actual-call-small-row-controls'")
controls=controls.replace('try{\n const cases=[];', '''try{
 report.points=[];
 const pointsFile=path.join(base,'points.json');report.inputs.push(ident(pointsFile));
 for(const point of JSON.parse(fs.readFileSync(pointsFile,'utf8'))){
   const values=Object.values(modules).map(m=>m.default.bench(...point.args));
   report.current={point,values};for(const value of values)assert.deepEqual(value,point.expected);
   report.points.push(point);delete report.current;
 }
 const cases=[];''')
assert 'row-loop-eager-rejected' not in controls
(out/'row-controls.mjs').write_text(controls)
point=next(p for p in json.loads(POINTS.read_text()) if p['args']==[32,17])
report={'kind':'phase30-actual-call-small-row','complete':True,'inputs':inputs,
        'outputs':[identity(Path(p)) for p in modules.values()],'adapter':adapter,
        'controls':identity(out/'row-controls.mjs'),
        'controlDerivation':'Retain original ordered run/cases; remove intentionally rejected unrelated loop witnesses; add independent complete-state points.',
        'correctness':'pending','timing':'pending'}
(out/'derive.json').write_text(json.dumps(report,indent=2)+'\n')
for protocol in ['screen','confirm']:
    (out/(protocol+'.json')).write_text(json.dumps({'protocol':protocol,'inputs':[identity(out/'derive.json'),*inputs],
       'cases':[{'id':'actual-call-small-row32','point':point,'modules':modules}]},indent=2)+'\n')
print(json.dumps({'complete':True,'out':str(out),'point':point}))

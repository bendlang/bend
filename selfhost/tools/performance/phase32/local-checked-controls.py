#!/usr/bin/env python3
"""Serial bounded controls over actual checked ablations, before timing."""
from pathlib import Path
import hashlib, json, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[4]; HERE=Path(__file__).resolve().parent
RAW=ROOT/'selfhost/build/phase32'; out=Path(sys.argv[1]).resolve()
out.mkdir(parents=True,exist_ok=False)
def ident(p):
    p=Path(p).resolve();return dict(file=str(p),sha256=hashlib.sha256(p.read_bytes()).hexdigest())
rows=[
 ('pair',HERE/'local-pair-controls-actual02.mjs',RAW/'local-checked-03/pair',out/'pair'),
 ('fold',HERE/'local-fold-controls-actual02.mjs',RAW/'local-checked-03/fold',out/'fold'),
 ('order',HERE/'local-order-controls-actual02.mjs',RAW/'emission-03/fold.mjs',out/'order'),
 ('scope',HERE/'local-scope-controls.mjs',out/'scope',RAW/'emission-02/scope.mjs',RAW/'emission-03/scope.mjs'),
 ('vectors',HERE/'review-local-vectors.mjs',out/'vectors',RAW/'emission-02/vectors.mjs',RAW/'emission-03/vectors.mjs'),
 ('types',HERE/'review-local-vector-types.mjs',RAW/'attempt-03',out/'types'),
]
report=dict(complete=False,inputs=[ident(__file__),ident(HERE/'bounded-run.py')],cases=[])
shutil.copyfile(__file__,out/'consumed-controls.py')
def save():(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
save()
try:
    for name,tool,*args in rows:
        report['inputs'].append(ident(tool))
        command=[sys.executable,HERE/'bounded-run.py','--seconds','90','--rss-mib','1600',out/(name+'-outer'),'--',
            'taskset','-c','4','/home/ai/.nvm/versions/node/v24.18.0/bin/node',
            '--stack-size=4096','--max-old-space-size=1024',tool,*args]
        rc=subprocess.run(list(map(str,command))).returncode
        row=dict(name=name,command=list(map(str,command)),returncode=rc);report['cases'].append(row);save()
        assert rc==0,name
        r=json.loads((out/name/'report.json').read_text());assert r['complete'] and r['pass'],name
        row['report']=ident(out/name/'report.json');save()
    for x in report['inputs']:assert ident(x['file'])==x
    report['complete']=True
except Exception as e:report['error']=repr(e);raise
finally:save()

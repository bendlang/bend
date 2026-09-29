#!/usr/bin/env python3
"""Bounded public CLI regression, retaining outputs and aggregate child peak RSS."""
from pathlib import Path
import hashlib, json, os, resource, subprocess, sys, time

attempt=Path(sys.argv[1]).resolve(); out=Path(sys.argv[2]).resolve(); out.mkdir()
m=json.loads((attempt/'attempt.json').read_text())
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ('NODE_OPTIONS','NODE_PATH')}
env.update(BEND_TYPED_API=m['api']['file'],BEND_TYPED_RUNTIME=m['runtime']['file'],BEND_BASE=m['base']['file'],BEND_UPSTREAM=m['config']['upstream'],BEND_TYPED_TRACE='')
driver=Path(m['snapshot']['root'])/'tools/typed-driver.mjs'
paths=[Path(m['api']['file']),Path(m['base']['file']),Path(m['runtime']['file']),driver,Path(__file__)]
rows=[]
for name in ['conversion_copy_before_unfold','conversion_shared_cells_once']:
    source=Path(m['config']['upstream'])/'tests/check'/(name+'.bend'); paths.append(source)
    cmd=['taskset','-c','1',m['node']['file'],'--stack-size=4096','--max-old-space-size=1024',str(driver),str(source),'--check-only']
    start=time.monotonic()
    try:
        p=subprocess.run(cmd,env=env,capture_output=True,text=True,timeout=10,preexec_fn=lambda:resource.setrlimit(resource.RLIMIT_CORE,(0,0)))
        row={'name':name,'command':cmd,'seconds':time.monotonic()-start,'exitCode':p.returncode,'stdout':p.stdout,'stderr':p.stderr,'pass':p.returncode==0 and p.stdout=='ALL PROOFS CHECK\nUse --verdict for mathematical validity.\n'}
    except subprocess.TimeoutExpired:
        row={'name':name,'command':cmd,'seconds':time.monotonic()-start,'error':'timeout10s','pass':False}
    rows.append(row); print(json.dumps(row),flush=True)
report={'kind':'phase23-public-depth32-resource-controls','complete':len(rows)==2,'pass':all(x['pass'] for x in rows),'api':m['api'],'heapMiB':1024,'stackKiB':4096,'deadlineSeconds':10,'rows':rows,'childrenMaxRssKiB':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,'inputs':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in paths],'scope':'Cold public CLI controls under the same1GiB heap cap as prior OOM assessment. Concurrent correctness run, not controlled speed comparison. RSS is the maximum over both child processes.'}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
sys.exit(0 if report['pass'] else 1)

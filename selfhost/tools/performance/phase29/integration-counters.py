#!/usr/bin/env python3
"""Count selected runtime operations in an immutable compiler-produced fixture.

Separate instrumented bytes only. Never treat acquisition times as speed claims.
"""
from pathlib import Path
import hashlib,json,os,subprocess,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
NODE=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
module,out=[Path(p).resolve() for p in sys.argv[1:]];out.mkdir(parents=True,exist_ok=False)
instrument=HERE/'prototype-instrument.py';checker=HERE/'prototype-count.mjs';points=HERE/'prototype-counter-point.json'
comparison=ROOT/'selfhost/build/phase29/prototype-diagnostic-01/report.json'
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
emission=module.with_suffix('.mjs.json');metadata=json.loads(emission.read_text())
assert metadata['complete'] and metadata['observation']['checked']
runtime=Path(metadata['runtime']['file'])
assert ident(runtime)['sha256']=='40823818afd57a6c37e055272dc332f461955a7cd225f67d66194f0d43ec823f'
assert module.read_bytes().startswith(runtime.read_bytes())
assert ident(module)['sha256']==metadata['output']['sha256']
report={'kind':'phase29-compiler-produced-fixture-counters','complete':False,'scope':'Named runtime operation counts only; not total allocations and not runtime timing.','inputs':[ident(p) for p in [Path(__file__),module,emission,runtime,instrument,checker,points,comparison,NODE]],'original':ident(module)}
(out/'tools').mkdir()
for p in [Path(__file__),instrument,checker,points]:(out/'tools'/p.name).write_bytes(p.read_bytes())
target=out/'candidate-counter.mjs'
derive=[sys.executable,str(instrument),str(module),str(target)]
process=subprocess.run(derive,cwd=ROOT,capture_output=True,text=True)
(out/'derive.stdout').write_text(process.stdout);(out/'derive.stderr').write_text(process.stderr)
report['derivation']={'command':derive,'exitCode':process.returncode}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
assert process.returncode==0,'instrumentation derivation failed'
command=['taskset','-c','6',str(NODE),'--stack-size=4096','--max-old-space-size=1024',str(checker),str(target),str(points)]
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
row={'command':command,'timeoutSeconds':60}
with (out/'stdout').open('w') as stdout,(out/'stderr').open('w') as stderr:
    try:row['exitCode']=subprocess.run(command,cwd=ROOT,env=env,stdout=stdout,stderr=stderr,timeout=60).returncode
    except subprocess.TimeoutExpired:row['timeout']=True
row['stdout']=ident(out/'stdout');row['stderr']=ident(out/'stderr')
try:row['result']=json.loads((out/'stdout').read_text())
except json.JSONDecodeError:pass
report['execution']=row;report['derived']=ident(target);report['derivationReceipt']=ident(target.with_suffix('.json'))
observations=row.get('result',{}).get('observations',[])
report['complete']=row.get('exitCode')==0 and row.get('result',{}).get('complete',False) and len(observations)==10
if report['complete']:
    report['totals']={k:sum(o['counters'][k] for o in observations) for k in observations[0]['counters']}
    old=json.loads(comparison.read_text());assert old['complete']
    report['prototypeCombinedTotals']=old['variants']['combined']['totals']
for p in report['inputs']:assert ident(Path(p['file']))==p,p['file']
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'complete':report['complete'],'totals':report.get('totals')}))
if not report['complete']:sys.exit(1)

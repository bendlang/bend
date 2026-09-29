"""Prepare selective frontend transfer onto the current214-source parent."""
from pathlib import Path
import subprocess,shutil,json,hashlib
R=Path(__file__).resolve().parents[4];P=R/'selfhost/build/phase21/group-range-source-02/project';A=R/'selfhost/build/phase17/find-worker-source-01/project';X=R/'selfhost/build/phase19/context-row-source-05/project';O=R/'selfhost/build/phase22/context-source-01';O.mkdir();N=O/'project';shutil.copytree(P,N)
identity=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
rows=[]
for p in sorted((X/'src/front').glob('*.bend')):
 rel=p.relative_to(X);old=A/rel;cur=P/rel;dst=N/rel
 if old.exists()and p.read_bytes()==old.read_bytes():continue
 if not old.exists():dst.write_bytes(p.read_bytes());status=0
 else:
  q=subprocess.run(['git','merge-file','-p',str(cur),str(old),str(p)],capture_output=True);assert q.returncode in[0,1],q.stderr
  dst.write_bytes(q.stdout);status=q.returncode
 rows.append({'path':str(rel),'conflicted':bool(status),'research':identity(p),'ancestor':identity(old)if old.exists()else None})
manifest=N/'src/compiler.json';m=json.loads(manifest.read_text());print('manifest keys',list(m))
(O/'transfer.json').write_text(json.dumps({'complete':True,'parent':str(P),'research':str(X),'ancestor':str(A),'rows':rows,'inputs':[identity(Path(__file__)),identity(R/'design/phase22/context-production-boundary.md'),identity(R/'design/phase22/contextual-conformance.md')]},indent=2)+'\n')
print(json.dumps({'root':str(O),'conflicts':[x['path']for x in rows if x['conflicted']]}))

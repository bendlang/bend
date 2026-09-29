#!/usr/bin/env python3
"""Tiny synthetic archives exercise the real independent recovery command."""
from pathlib import Path
import copy, difflib, hashlib, io, json, subprocess, sys, tarfile
ROOT=Path(__file__).resolve().parents[4]; OUT=Path(sys.argv[1]).resolve(); OUT.mkdir()
TOOL=ROOT/'selfhost/tools/performance/phase16/compact-recover.py'; COMMIT='a383163b821e38510967849fdb791ff914031b62'
sha=lambda b:hashlib.sha256(b).hexdigest(); write=lambda p,x:p.write_text(json.dumps(x,indent=2)+'\n')
old=subprocess.check_output(['git','show',COMMIT+':selfhost/src/core/term.bend'],cwd=ROOT); newer=old+b'\n# Synthetic recovery control only.\n'; prefix='selfhost/build/phase16/policy-source/project/'; source=prefix+'src/core/term.bend'
files={source:newer,'fixtures/leaf.bend':b'fixture\n'}
rows=[{'path':name,'type':'file','bytes':len(data),'sha256':sha(data),'mode':0o644} for name,data in files.items()]
rows.append({'path':'fixtures/a/link.bend','type':'symlink','target':'../leaf.bend','resolvedTarget':'fixtures/leaf.bend','targetSha256':sha(files['fixtures/leaf.bend']),'bytes':12,'sha256':sha(b'../leaf.bend'),'mode':0o777})
rows[-1]['bytes']=len(b'../leaf.bend')
results=[]
for label in ['valid-parent-link','absolute-member','escaping-link','absolute-link','unselected-target','symlink-ancestor','hardlink','changed-archive','wrong-mode']:
 folder=OUT/label;folder.mkdir();rs=copy.deepcopy(rows)
 if label=='absolute-member':rs[1]['path']='/absolute-escape'
 if label=='escaping-link':rs[-1]['target']='../../../escape';rs[-1]['resolvedTarget']='../escape'
 if label=='absolute-link':rs[-1]['target']='/escape'
 if label=='unselected-target':rs[-1]['target']='../missing';rs[-1]['resolvedTarget']='fixtures/missing'
 if label=='symlink-ancestor':rs[1]['path']='fixtures/a/link.bend/child'
 patch=''.join(difflib.unified_diff(old.decode().splitlines(True),newer.decode().splitlines(True),fromfile='a/src/core/term.bend',tofile='b/src/core/term.bend'));(folder/'source.patch').write_text(patch)
 inventory={'members':rs,'finalSource':prefix[:-1],'sourceBaseline':[{'path':'src/core/term.bend','exists':True,'sha256':sha(old)}],'baselineCommit':COMMIT,'patch':{'path':'source.patch','sha256':sha(patch.encode())}}
 write(folder/'inventory.json',inventory);archive=folder/'synthetic.tar.gz'
 with tarfile.open(archive,'w:gz') as tar:
  for index,row in enumerate(rs):
   t=tarfile.TarInfo(row['path']);t.mode=row['mode']
   if label=='wrong-mode' and index==0:t.mode=0o600
   if row['type']=='symlink':t.type=tarfile.SYMTYPE;t.linkname=row['target'];tar.addfile(t)
   elif label=='hardlink' and index==1:t.type=tarfile.LNKTYPE;t.linkname=source;tar.addfile(t)
   else:
    data=files[source] if index==0 else files['fixtures/leaf.bend'];t.size=len(data);tar.addfile(t,io.BytesIO(data))
 manifest={'complete':True,'captured':True,'inventory':{'path':'inventory.json','sha256':sha((folder/'inventory.json').read_bytes())},'archives':[{'path':archive.name,'bytes':archive.stat().st_size,'sha256':sha(archive.read_bytes()),'members':[r['path'] for r in rs]}]};write(folder/'manifest.json',manifest)
 if label=='changed-archive':archive.write_bytes(archive.read_bytes()+b'changed')
 result=subprocess.run([sys.executable,str(TOOL),str(folder),str(folder/'recovery.json')],cwd=ROOT,capture_output=True,text=True);(folder/'stdout').write_text(result.stdout);(folder/'stderr').write_text(result.stderr);r=json.loads((folder/'recovery.json').read_text());expected=label=='valid-parent-link';passed=(result.returncode==0)==expected and r['pass']==expected
 results.append({'name':label,'pass':passed,'expectedAccepted':expected,'exitCode':result.returncode,'recoveryPass':r['pass'],'error':r.get('error')})
report={'kind':'phase16-synthetic-recovery-policy-controls','complete':True,'pass':all(x['pass'] for x in results),'toolSha256':sha(TOOL.read_bytes()),'controlSha256':sha(Path(__file__).read_bytes()),'rows':results};write(OUT/'report.json',report);print(json.dumps(report));sys.exit(0 if report['pass'] else 1)

#!/usr/bin/env python3
"""Small synthetic capsules exercise the actual bounded recovery executable."""
from pathlib import Path
import copy,difflib,hashlib,io,json,subprocess,sys,tarfile
R=Path(__file__).resolve().parents[4];O=Path(sys.argv[1]).resolve();O.mkdir()
TOOL=R/'selfhost/tools/performance/phase22/context-recover.py';COMMIT='a784e0e1a0de1ee085cc188ca0f1f19038679bdb'
sha=lambda b:hashlib.sha256(b).hexdigest()
write=lambda p,x:p.write_text(json.dumps(x,indent=2)+'\n')
old=subprocess.check_output(['git','show',COMMIT+':selfhost/src/core/term.bend'],cwd=R);new=old+b'\n# Synthetic bounded-recovery control only.\n'
prefix='selfhost/build/phase22/policy-source/project/';source=prefix+'src/core/term.bend';attempt='selfhost/build/phase22/policy-build'
checked=b'// synthetic checked API\n';derived=b'// synthetic equality-derived API\n'
metadata={'artifactKind':'derived-b1','api':{'sha256':sha(derived)},'checkedApi':{'sha256':sha(checked)}}
files={source:new,'fixtures/leaf.bend':b'fixture\n',attempt+'/attempt.json':json.dumps(metadata).encode(),attempt+'/build.json':b'{"complete":true}\n',attempt+'/api.mjs':checked,attempt+'/equality/api.mjs':derived,attempt+'/validation-001/report.json':b'{"complete":true,"pass":true}\n'}
base_rows=[{'path':n,'type':'file','bytes':len(d),'sha256':sha(d),'mode':0o755 if n==source else 0o644}for n,d in files.items()]
link={'path':'fixtures/a/link.bend','type':'symlink','target':'../leaf.bend','resolvedTarget':'fixtures/leaf.bend','targetSha256':sha(files['fixtures/leaf.bend']),'bytes':len(b'../leaf.bend'),'sha256':sha(b'../leaf.bend'),'mode':0o777};base_rows.append(link)
labels=['valid-cross-part-link','absolute-member','escaping-link','absolute-link','unselected-target','symlink-ancestor','file-ancestor','hardlink','changed-archive','wrong-mode','wrong-content','duplicate-member','missing-member','derived-lineage','checked-lineage','oversized-member','part-bound','wrong-part-member','changed-source-patch']
results=[]
for label in labels:
 folder=O/label;folder.mkdir();rows=copy.deepcopy(base_rows);payload=dict(files)
 if label=='absolute-member':rows[1]['path']='/absolute-escape'
 if label=='escaping-link':rows[-1]['target']='../../../escape';rows[-1]['resolvedTarget']='../escape'
 if label=='absolute-link':rows[-1]['target']='/escape'
 if label=='unselected-target':rows[-1]['target']='../missing';rows[-1]['resolvedTarget']='fixtures/missing'
 if label=='symlink-ancestor':rows[1]['path']='fixtures/a/link.bend/child'
 if label=='file-ancestor':rows[1]['path']=source+'/child'
 if label in ['derived-lineage','checked-lineage']:
  bad=copy.deepcopy(metadata);bad['api' if label=='derived-lineage' else 'checkedApi']['sha256']='0'*64
  name=attempt+'/attempt.json';payload[name]=json.dumps(bad).encode();row=next(r for r in rows if r['path']==name);row.update(bytes=len(payload[name]),sha256=sha(payload[name]))
 patch=''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile='a/src/core/term.bend',tofile='b/src/core/term.bend'));(folder/'source.patch').write_text(patch)
 bound=1000000
 if label=='oversized-member':bound=rows[0]['bytes']
 if label=='part-bound':bound=sum(r['bytes']for r in rows[:4])-1
 inv={'members':rows,'finalSource':prefix[:-1],'finalAttempt':attempt,'finalApiSha256':sha(derived),'maxPartPayloadBytes':bound,'maxArchiveBytes':40000000,'sourceBaseline':[{'path':'src/core/term.bend','exists':True,'sha256':sha(old)}],'baselineCommit':COMMIT,'patch':{'path':'source.patch','sha256':sha(patch.encode())}}
 write(folder/'inventory.json',inv);archives=[]
 parts=[list(range(4)),list(range(4,len(rows)))]
 if label=='duplicate-member':parts[1].append(1)
 for number,indices in enumerate(parts,1):
  archive=folder/f'part-{number:02}.tar.gz'
  with tarfile.open(archive,'w:gz')as tar:
   actual_indices=([4]+indices if label=='wrong-part-member' and number==1 else indices)
   for index in actual_indices:
    row=rows[index]
    if label=='missing-member' and index==0:continue
    info=tarfile.TarInfo(row['path']);info.mode=0o600 if label=='wrong-mode' and index==0 else row['mode']
    if row['type']=='symlink':info.type=tarfile.SYMTYPE;info.linkname=row['target'];tar.addfile(info)
    elif label=='hardlink' and index==1:info.type=tarfile.LNKTYPE;info.linkname=source;tar.addfile(info)
    else:
     data=payload.get(row['path'],files['fixtures/leaf.bend'])
     if label=='wrong-content' and index==1:data=b'changed\n'
     info.size=len(data);tar.addfile(info,io.BytesIO(data))
  archives.append({'path':archive.name,'bytes':archive.stat().st_size,'sha256':sha(archive.read_bytes()),'members':[rows[i]['path']for i in indices]})
 write(folder/'manifest.json',{'complete':True,'captured':True,'inventory':{'path':'inventory.json','sha256':sha((folder/'inventory.json').read_bytes())},'archives':archives})
 if label=='changed-archive':(folder/'part-01.tar.gz').write_bytes((folder/'part-01.tar.gz').read_bytes()+b'changed')
 if label=='changed-source-patch':(folder/'source.patch').write_text(patch+'changed')
 run=subprocess.run([sys.executable,str(TOOL),str(folder),str(folder/'recovery.json')],cwd=R,capture_output=True,text=True);(folder/'stdout').write_text(run.stdout);(folder/'stderr').write_text(run.stderr);report=json.loads((folder/'recovery.json').read_text());expected=label=='valid-cross-part-link'
 passed=(run.returncode==0)==expected and report['pass']==expected
 if label=='part-bound':passed=passed and 'Declared part payload exceeds bound' in report.get('error','') and 'extraction' not in report
 if label=='wrong-part-member':passed=passed and 'Tar member belongs to another archive' in report.get('error','') and 'extraction' not in report
 if expected:passed=passed and report['extraction']['files']==len(rows) and len(report['extraction']['parts'])==2 and report['sourceReconstruction']['files']==1 and report['artifacts']['checkedApiSha256']!=report['artifacts']['derivedApiSha256']
 results.append({'name':label,'pass':passed,'expectedAccepted':expected,'exitCode':run.returncode,'recoveryPass':report['pass'],'error':report.get('error')})
summary={'kind':'phase22-synthetic-bounded-recovery-controls','complete':True,'pass':all(r['pass']for r in results),'toolSha256':sha(TOOL.read_bytes()),'controlSha256':sha(Path(__file__).read_bytes()),'rows':results};write(O/'report.json',summary);print(json.dumps(summary));sys.exit(0 if summary['pass'] else 1)

#!/usr/bin/env python3
"""Metadata/identity inventory; never creates or extracts an evidence archive.
Run from repository root, after producers close:
  python3 implementation/phase23/evidence/prerequisites-scan.py NEW_OUTPUT --verify-git
Full compiler replay and hermetic toolchain reconstruction are separate tasks.
"""
import argparse,collections,hashlib,json,os,re,subprocess
from pathlib import Path
R=Path(__file__).resolve().parents[3]
BUILD=R/'selfhost/build/phase23'
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('output');parser.add_argument('--verify-git',action='store_true');parser.add_argument('--producers-closed',action='store_true');parser.add_argument('--production-commit',help='Exact completed Phase23 production commit, when available')
args=parser.parse_args()
PINS={'upstream-phase8':'b2111cf43244e65f76ddc278ee695e669f720cbf','upstream-phase23':'018751270e800bc222a93dad7f257083ee53a5f7'}
FORK='fb4245719005f3c84000a4ff710ddfd180179e01'
SKIP_DIRS={'snapshot','snapshots','project','relocated','node_modules','cache','harness','bootstrap','equality'}
# Attempt identities already bind source snapshots; do not interpret old fixture
# JSON in those snapshots as newly consumed experiment records.
SKIP_JSON={'request.json','response.json','worker.done'}
HEX=re.compile(r'^[0-9a-f]{64}$')
def digest(raw):return hashlib.sha256(raw).hexdigest()
def ident(p):
 raw=p.read_bytes();return {'file':str(p.relative_to(R)) if p.is_relative_to(R) else str(p),'sha256':digest(raw),'bytes':len(raw)}
def git(argv,input=None,text=False):return subprocess.run(['git','-C',str(R),*argv],input=input,capture_output=True,check=True,text=text).stdout
refs={};internal={};reports=[];unparsed=[]
def add(file,sha,source,pointer):
 if not isinstance(file,str) or not isinstance(sha,str) or not HEX.fullmatch(sha):return
 p=Path(file);p=p if p.is_absolute() else R/p
 rel=str(p.relative_to(R)) if p.is_relative_to(R) else str(p)
 target=internal if rel.startswith('selfhost/build/phase23/') else refs
 row=target.setdefault((str(p),sha),{'relative':rel,'sha256':sha,'observedIn':[]})
 row['observedOnlyInHistoricalReplay']=row.get('observedOnlyInHistoricalReplay',True) and '/history-' in source and source.endswith('/phase12-replay.json')
 entry={'file':source,'pointer':pointer}
 if len(row['observedIn'])<4 and entry not in row['observedIn']:row['observedIn'].append(entry)
def walk(x,source,pointer=''):
 if isinstance(x,dict):
  add(x.get('file',x.get('path')),x.get('sha256'),source,pointer)
  for key,value in x.items():
   if key.startswith('/') and isinstance(value,str):add(key,value,source,pointer+'/'+key)
   walk(value,source,pointer+'/'+key)
 elif isinstance(x,list):
  for i,value in enumerate(x):walk(value,source,pointer+'/'+str(i))
for directory,dirs,files in os.walk(BUILD):
 dirs[:]=[d for d in dirs if d not in SKIP_DIRS]
 for name in files:
  if not name.endswith('.json') or name in SKIP_JSON or name.startswith('session-') or name.endswith('.map.json'):continue
  p=Path(directory)/name;raw=p.read_bytes();rel=str(p.relative_to(R))
  try:x=json.loads(raw)
  except ValueError:unparsed.append(rel);continue
  reports.append({'file':rel,'bytes':len(raw),'sha256':digest(raw)});walk(x,rel)
reports.sort(key=lambda x:x['file'])
registry={};caps=[];historical_omissions={}
for n,stem in [(22,'context-evidence'),(21,'group-evidence'),(12,'evidence')]:
 d=R/f'implementation/phase{n}/{stem}/capsule-01';m=json.loads((d/'manifest.json').read_text());key='phase'+str(n)
 if n in [21,22]:
  inv=json.loads((d/'inventory.json').read_text());archive_by_path={p:a['path'] for a in m['archives'] for p in a['members']}
  index={(r['path'],r.get('sha256')):{'member':r['path'],'archive':archive_by_path[r['path']]} for r in inv['members']}
  rec=d.parent/('recovery-final-01.json' if n==22 else 'recovery-01.json')
  registry[key]={'manifest':ident(d/'manifest.json'),'inventory':ident(d/'inventory.json'),'receipt':ident(d.parent/'preservation.json'),'successfulHistoricalRecovery':ident(rec),'archives':[{k:a[k] for k in ['path','bytes','sha256']} for a in m['archives']],'sourceBaselineCommit':inv['baselineCommit'],'restoration':'Verify metadata and bound archive checksums before extracting selected members into a fresh confined destination; preserve inventory modes and link policy. Existing bounded recovery verifies all parts but deletes scratch, so it is not a persistent tree exporter.','independentRecoveryCommand':['python3','selfhost/tools/performance/'+('phase22/context-recover-v3.py' if n==22 else 'phase16/compact-recover.py'),str(d.relative_to(R)),'/tmp/phase'+str(n)+'-independent-NEW.json']}
 else:
  index={(r['file'],r.get('sha256')):{'member':r['file'],'store':r.get('store'),'type':r['type']} for r in m['files']}
  historical_omissions={(r['file'],r.get('sha256')):r for r in m['omitted'] if '/cache/base-' in r['file']}
  registry[key]={'manifest':ident(d/'manifest.json'),'receipt':ident(d.parent/'publication.json'),'successfulHistoricalRecovery':ident(d.parent/'recovery-01.json'),'archive':m['archive'],'externalCapsules':m['externalCapsules'],'restoration':'Generic collector materializes content-addressed objects using this capsule and all eight bound predecessor capsules.','materializeCommand':['python3','implementation/phase8/migration-evidence/collect.py','materialize',str(d.relative_to(R)),'/tmp/phase12-prerequisite-NEW']}
 caps.append((key,index))
# Small preserved tool and original-fixture copies often have no separate file
# identity row. Hash those bounded copies explicitly to find historical aliases.
by_sha={}
for row in internal.values():by_sha.setdefault(row['sha256'],[]).append({'file':row['relative'],'bytesVerifiedNow':False})
for d in BUILD.iterdir():
 if not d.is_dir():continue
 candidates=list(d.rglob('*')) if 'originals' in d.name else list(d.iterdir())
 if 'originals' not in d.name:
  for sub in ['selfhost/tools','selfhost/tests','tests']:
   if (d/sub).is_dir():candidates.extend((d/sub).rglob('*'))
 for p in candidates:
  if not p.is_file() or p.is_symlink() or p.stat().st_size>2*1024*1024:continue
  nested_copy=any(p.is_relative_to(d/sub) for sub in ['selfhost/tools','selfhost/tests','tests'])
  if 'originals' not in d.name and not nested_copy and not p.name.startswith(('consumed','selection','target','snapshot')):continue
  by_sha.setdefault(digest(p.read_bytes()),[]).append({'file':str(p.relative_to(R)),'bytesVerifiedNow':True})
result=[];git_rows=[]
tracked=set(git(['ls-files','-z'],text=True).split('\0'))
explicit_capture={'selfhost/build/phase16/wave6-backend-environment-01.json':'db973a862955df917132ee67dd7d7c79efbba6d3732e808ee300ef1f6f925e23'}
for old in sorted(refs.values(),key=lambda x:(x['relative'],x['sha256'])):
 row=dict(old);name=row['relative'];sha=row['sha256'];matches=[]
 for key,index in caps:
  if (name,sha) in index:matches.append({'capsule':key,**index[name,sha]})
 pin=next((k for k in PINS if name.startswith('selfhost/.bootstrap/'+k+'/')),None)
 if pin:
  row['restoration']={'kind':'pinned-upstream-git','revision':PINS[pin],'path':name.split('selfhost/.bootstrap/'+pin+'/',1)[1]};git_rows.append(row)
 elif name.startswith('bend2/'):
  row['restoration']={'kind':'pinned-upstream-git','revision':PINS['upstream-phase23'],'path':name};git_rows.append(row)
 elif matches:row['restoration']={'kind':'durable-capsule','matches':matches}
 elif (name,sha) in historical_omissions and row['observedOnlyInHistoricalReplay']:
  row['restoration']={'kind':'historical-metadata-only-omission','capsule':'phase12','originalOmission':historical_omissions[name,sha],'notConsumedByPhase23':True,'reason':'Referenced only by copied historical Phase12 replay reports. Phase23 history-inputs.mjs prepareVariant creates and validates its own new cache from each frozen API/Base; these old caches are not opened.'}
 elif sha in by_sha:
  alias=sorted(by_sha[sha],key=lambda x:(not x['bytesVerifiedNow'],len(x['file'])))[0]
  p=R/alias['file'];verified=p.is_file() and digest(p.read_bytes())==sha
  row['restoration']={'kind':'planned-phase23-byte-alias' if verified else 'unresolved-historical-source','copyFrom':alias['file'],'aliasBytesVerifiedNow':verified,'note':'Captured alias must also pass independent recovery before restoring the historical path.'}
 elif name.startswith(('selfhost/build/phase1/clang/','/home/ai/.nvm/','/usr/','/lib/')):
  row['restoration']={'kind':'external-toolchain','bundled':False}
 elif name.startswith(('selfhost/tools/performance/phase23/','selfhost/tests/phase23-backend/')):
  p=R/name;matches_live=p.is_file() and digest(p.read_bytes())==sha
  row['restoration']={'kind':'planned-phase23-owned-source' if matches_live else 'unresolved-historical-source','currentBytesVerifiedNow':matches_live}
 elif explicit_capture.get(name)==sha:
  row['restoration']={'kind':'planned-phase23-explicit-capture','currentBytesVerifiedNow':digest((R/name).read_bytes())==sha,'originalPathPreserved':True}
 elif args.production_commit and name in tracked and (R/name).is_file() and digest((R/name).read_bytes())==sha:
  row['restoration']={'kind':'phase23-production-git','revision':args.production_commit,'path':name};git_rows.append(row)
 elif not name.startswith('/'):
  row['restoration']={'kind':'fixed-fork-git','revision':FORK,'path':name};git_rows.append(row)
 else:row['restoration']={'kind':'unresolved','reason':'No reviewed capsule, Git or Phase23 byte alias found.'}
 result.append(row)
queries=[row['restoration']['revision']+':'+row['restoration']['path'] for row in git_rows]
response=git(['cat-file','--batch-check=%(objectname) %(objecttype) %(objectsize)'],input='\n'.join(queries)+'\n',text=True).splitlines();assert len(response)==len(git_rows)
content_rows=[]
for row,line in zip(git_rows,response):
 if line.endswith(' missing'):
  row['restoration']={'kind':'requires-explicit-capture','reason':'No exact reviewed capsule/alias and absent from fixed Git revision.'};continue
 oid,typ,size=line.split();assert typ=='blob';row['restoration'].update(gitObject=oid,bytes=int(size),contentHashVerifiedNow=False);content_rows.append(row)
if args.verify_git and content_rows:
 data=git(['cat-file','--batch'],input=('\n'.join(row['restoration']['gitObject'] for row in content_rows)+'\n').encode());offset=0
 for row in content_rows:
  end=data.index(b'\n',offset);oid,typ,size=data[offset:end].decode().split();size=int(size);raw=data[end+1:end+1+size];assert len(raw)==size and data[end+1+size:end+2+size]==b'\n';offset=end+2+size
  assert oid==row['restoration']['gitObject'] and typ=='blob';actual=digest(raw)
  if actual!=row['sha256']:row['restoration']={'kind':'git-content-mismatch','revision':row['restoration']['revision'],'path':row['restoration']['path'],'actualSha256':actual,'expectedSha256':row['sha256']}
  else:row['restoration']['contentHashVerifiedNow']=True
 assert offset==len(data)
# Any owned live file with matching bytes is a concrete extra capture candidate;
# it is never silently relabeled as already stored in the old Git checkpoint.
for row in result:
 if row['restoration']['kind'] not in ['requires-explicit-capture','git-content-mismatch']:continue
 p=R/row['relative'];row['restoration']['currentExists']=p.is_file()
 if p.is_file() and p.stat().st_size<=2*1024*1024:row['restoration']['currentMatches']=digest(p.read_bytes())==row['sha256']
 if row['restoration'].get('currentMatches') and row['relative'] in tracked:
  row['restoration']={'kind':'planned-phase23-production-commit','currentBytesVerifiedNow':True,'reason':'Tracked production/test helper has changed since the old fork checkpoint. Exact final production commit must be supplied or these bytes explicitly captured.'}
counts=collections.Counter(row['restoration']['kind'] for row in result)
gaps=[row for row in result if row['restoration']['kind'] in ['requires-explicit-capture','unresolved','unresolved-historical-source','git-content-mismatch']]
report={'kind':'phase23-evidence-prerequisites','complete':False,'producersDeclaredClosed':args.producers_closed,'phase23ArchiveCreated':False,'archivesHashedDuringThisInventory':False,'method':{'script':ident(Path(__file__).resolve()),'command':['python3','implementation/phase23/evidence/prerequisites-scan.py','NEW_OUTPUT',*(['--verify-git'] if args.verify_git else []),*(['--producers-closed'] if args.producers_closed else [])],'discovery':'Recursively parse Phase23 JSON outside frozen source/project/cache/harness/bootstrap/equality trees; skip request/response/session-per-generation and source-map JSON. Selected result and identity reports retain complete source/artifact hash registries. Scan small consumed/original snapshot copies for byte aliases. Identity-shaped references are restoration candidates, not proof each historical artifact executed during Phase23.','gitVerification':'Exact blob SHA256 checked' if args.verify_git else 'Existence/type/size only','archiveVerification':'Not performed; exact hashes imported from immutable metadata and historical successful recovery receipts.','limitations':['No hermetic external toolchain reconstruction.','Unhashed paths embedded only in prose, argv strings or intentionally invalid synthetic fixtures need human review.','A complete archive closure requires the final selected capture inventory and independent actual-byte recovery; this report alone cannot establish it.']},'repositoryRoot':str(R),'scannedReports':reports,'unparsedReports':unparsed,'registry':registry,'referenceCounts':dict(counts),'references':result,'explicitCaptureRequired':gaps,'upstreamCheckouts':[{'historicalRoot':'selfhost/.bootstrap/'+name,'revision':rev,'source':'https://github.com/bendlang/bend','neverModifyExistingCheckout':True} for name,rev in PINS.items()],'toolchain':{}}
if args.production_commit:report['method']['command'].extend(['--production-commit',args.production_commit])
report['productionCommit']=args.production_commit
p=BUILD/'release-cli-01/checks/report.json'
if p.exists():
 x=json.loads(p.read_text());report['toolchain']={'source':ident(p),'node':x['node'],'clang':x['toolchain'],'environment':x['environment'],'bundled':False,'requirements':['Recorded Linux, executable/header/shared-library identities and CC/CPATH/LIBRARY_PATH/LD_LIBRARY_PATH.','No supplied Bun, usable TSan runtime or GPU/device claim.']}
out=Path(args.output);out=out if out.is_absolute() else R/out
with out.open('x') as stream:json.dump(report,stream,indent=2);stream.write('\n')
print(json.dumps({'output':str(out),'reports':len(reports),'references':len(result),'counts':dict(counts),'gaps':[{'file':r['relative'],'sha256':r['sha256'],'restoration':r['restoration']} for r in gaps]},indent=1))

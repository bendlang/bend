"""Read stable identities for exact, never-consumed Phase6 source-copy exclusions."""
import json
import os
from pathlib import Path
here=Path(__file__).resolve().parent;root=here.parents[2];build=root/'selfhost/build/phase15'
prefixes=[f'selfhost/build/phase15/behavior-source-0{i}/project/tools/performance/phase6/' for i in [1,2,3]]
copies=[]
for prefix in prefixes:
 p=root/prefix;assert p.is_dir(),p
 copies.append({'prefix':prefix,'files':len([f for f in p.rglob('*') if f.is_file()])})
attempts=[]
for p in sorted(build.glob('*/attempt.json')):
 x=json.loads(p.read_text());snapshot=Path(x['snapshot']['root']);assert not (snapshot/'tools/performance/phase6').exists()
 attempts.append(str(p.relative_to(root)))
pairs=[('sha256',('file','path','canonicalPath','source','target','snapshot')),('apiSha256',('api','apiPath','apiFile')),('baseSha256',('base','basePath')),('runtimeSha256',('runtime','runtimePath')),('checkedApiSha256',('checkedApi','checkedApiFile'))]
hit=[];scanned=[];vanished=[]
for directory,dirs,files in os.walk(build):
 dirs[:]=[name for name in dirs if name!='project' and not name.endswith('.artifacts') and not (name=='cache' and str(directory).endswith('/build/typed'))]
 for name in files:
  if not name.endswith('.json'):continue
  p=Path(directory)/name
  try:x=json.loads(p.read_text())
  except FileNotFoundError:vanished.append(str(p.relative_to(root)));continue
  except (ValueError,UnicodeError):continue
  scanned.append(str(p.relative_to(root)));pending=[('',x)]
  while pending:
   at,node=pending.pop()
   if isinstance(node,dict):
    for hkey,pkeys in pairs:
     if not isinstance(node.get(hkey),str) or len(node[hkey])!=64:continue
     for k in pkeys:
      value=node.get(k)
      if isinstance(value,str) and any(prefix in value for prefix in prefixes):hit.append({'report':str(p.relative_to(root)),'pointer':at+'/'+k,'path':value,'sha256':node[hkey]})
    pending.extend((at+'/'+str(k),v) for k,v in node.items())
   elif isinstance(node,list):pending.extend((at+'/'+str(i),v) for i,v in enumerate(node))
assert not hit,hit
report={'kind':'phase15-incidental-phase6-source-copy-review','complete':True,'pass':True,'scope':'Stable JSON hash/path identities and all completed checked-attempt snapshot directories at review time. Project copies, transient conformance .artifacts trees and derived Base caches excluded from reference scan. Producers may still run; final root freeze/preflight remains required. No evidence inventory/archive performed.','sourceOnlyCopies':copies,'checkedAttempts':attempts,'checkedSnapshotHasPhase6Directory':False,'scannedJsonReports':scanned,'vanishedDuringRead':vanished,'consumedHashPathReferences':hit,'rootAuthorizedExactSourceOnlyExclusions':True}
with (here/'incidental-source-review.json').open('x') as f:json.dump(report,f,indent=2);f.write('\n')
print(json.dumps({'complete':True,'pass':True,'copies':len(copies),'checkedAttempts':len(attempts),'scannedReports':len(scanned),'vanishedDuringRead':len(vanished),'consumedReferences':len(hit)}))

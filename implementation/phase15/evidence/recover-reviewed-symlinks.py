"""Recover only the byte-pinned Phase15 capsule, preserving four reviewed fixture links."""
import copy
import importlib.util
import json
from pathlib import Path, PurePosixPath
import posixpath
import sys
import tarfile
sys.dont_write_bytecode=True
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
spec=importlib.util.spec_from_file_location('unchanged_collector',ROOT/'implementation/phase8/migration-evidence/collect.py')
legacy=importlib.util.module_from_spec(spec);spec.loader.exec_module(legacy)
MANIFEST_SHA256='70b99f29a3e7adc5d5c31f2e324a79d9e93ed7a9e1e1d288220a82ecad384c26'
ALLOWED={
 'selfhost/build/phase15/behavior-cycles-01/fixtures/alias-same-physical/sub/link.bend':{'target':'../leaf.bend','sha256':'c2d034805de52aedf5565c81b1ff6f98cff7d6487f6abb38af784a46bb7bb6c2','bytes':12,'mode':511},
 'selfhost/build/phase15/behavior-cycles-02/fixtures/alias-same-physical/sub/link.bend':{'target':'../leaf.bend','sha256':'c2d034805de52aedf5565c81b1ff6f98cff7d6487f6abb38af784a46bb7bb6c2','bytes':12,'mode':511},
 'selfhost/build/phase15/behavior-cycles-02/fixtures/cycle-canonical/sub/link.bend':{'target':'../a.bend','sha256':'3b1f6cb9c325816f81340c03aff55494a70c021f5eebdee82a22116f1b51d52d','bytes':9,'mode':511},
 'selfhost/build/phase15/behavior-cycles-02/fixtures/diamond/sub/link.bend':{'target':'../leaf.bend','sha256':'c2d034805de52aedf5565c81b1ff6f98cff7d6487f6abb38af784a46bb7bb6c2','bytes':12,'mode':511},
}

def need(value,message):
 if not value:raise ValueError(message)

def validate_links(rows,destination):
 indexed={row['file']:row for row in rows};need(len(indexed)==len(rows),'Duplicate file path')
 symlinks={row['file'] for row in rows if row['type']=='symlink'};seen=set();links=[]
 for row in rows:
  legacy.safe_name(row['file'])
  need(not any(p.as_posix() in symlinks for p in PurePosixPath(row['file']).parents),'Selected symlink ancestor: '+row['file'])
  if row['type']!='symlink':continue
  target=PurePosixPath(row['target']);need(not target.is_absolute(),'Absolute link target')
  need(legacy.digest(row['target'].encode())==row['sha256'],'Changed link target bytes')
  if '..' in target.parts:
   need(row['file'] in ALLOWED,'Unreviewed parent-relative link')
   need({k:row[k] for k in ['target','sha256','bytes','mode']}==ALLOWED[row['file']],'Changed reviewed link tuple')
   seen.add(row['file'])
  normalized=posixpath.normpath(str(PurePosixPath(row['file']).parent/target))
  legacy.safe_name(normalized)
  need((destination/normalized).resolve().is_relative_to(destination.resolve()),'Link target escapes fresh recovery root')
  need(indexed.get(normalized,{}).get('type')=='file','Link target is not a captured regular file')
  links.append({'file':row['file'],'target':row['target'],'sha256':row['sha256'],'normalizedTarget':normalized,'targetSha256':indexed[normalized]['sha256'],'reviewedParentRelative':'..' in target.parts})
 need(seen==set(ALLOWED),'Missing reviewed fixture link')
 return links

def controls(rows,destination):
 indexed={r['file']:r for r in rows};links=validate_links(rows,destination)
 names={r['file'] for r in links}|{r['normalizedTarget'] for r in links}
 small=[copy.deepcopy(indexed[name]) for name in sorted(names)]
 validate_links(small,destination);checks=[{'name':'exact reviewed links and ordinary fifth link','pass':True}]
 def rejects(name,change):
  mutant=copy.deepcopy(small);change(mutant)
  try:validate_links(mutant,destination)
  except ValueError:checks.append({'name':name,'pass':True});return
  raise AssertionError('Policy admitted '+name)
 def edit_target(rows,text):
  row=next(r for r in rows if r['file'] in ALLOWED);row['target']=text;row['sha256']=legacy.digest(text.encode());row['bytes']=len(text.encode())
 rejects('absolute target',lambda rs:edit_target(rs,'/tmp/escape'))
 rejects('escaping target',lambda rs:edit_target(rs,'../../../../../../../../escape'))
 rejects('changed allowlisted target',lambda rs:edit_target(rs,'../different.bend'))
 def extra(rows):
  row=copy.deepcopy(next(r for r in rows if r['file'] in ALLOWED));row['file']=row['file'].replace('/link.bend','/unreviewed-link.bend');rows.append(row)
 rejects('unreviewed parent-relative link',extra)
 target=links[0]['normalizedTarget']
 rejects('uncaptured target',lambda rs:rs.__setitem__(slice(None),[r for r in rs if r['file']!=target]))
 def nonregular(rows):
  row=next(r for r in rows if r['file']==target);row.update({'type':'symlink','target':'leaf.bend','sha256':legacy.digest(b'leaf.bend'),'bytes':9,'mode':511})
 rejects('non-regular target',nonregular)
 def descendant(rows):
  rows.append({'file':links[0]['file']+'/child','type':'file','bytes':0,'sha256':legacy.digest(b''),'mode':420})
 rejects('selected symlink ancestor',descendant)
 return checks

def recover(capsule,destination,manifest):
 need(not destination.exists() and not destination.is_symlink(),'Recovery requires a fresh destination')
 links=validate_links(manifest['files'],destination)
 destination.mkdir(parents=True)
 by_hash={}
 for row in manifest['files']:by_hash.setdefault(row['sha256'],[]).append(row)
 pending_links=[]
 archives=[capsule/manifest['archive']['file']]+[ROOT/store['archive'] for store in manifest['externalCapsules']]
 for archive in archives:
  with tarfile.open(archive,'r:gz') as tar:
   for member in tar:
    key=member.name.split('/')[1]
    if key not in by_hash:continue
    blob=tar.extractfile(member).read();need(legacy.digest(blob)==key,'Recovered object hash mismatch')
    for row in by_hash.pop(key):
     need(len(blob)==row['bytes'],'Recovered object size mismatch')
     output=destination/row['file'];output.parent.mkdir(parents=True,exist_ok=True)
     if row['type']=='symlink':pending_links.append((output,row['target']))
     else:output.write_bytes(blob);output.chmod(row['mode'])
 need(not by_hash,'Missing archive object')
 for output,target in pending_links:output.symlink_to(target)
 return {'pass':True,'recoveredFiles':len(manifest['files']),'destination':str(destination),'links':links}

if __name__=='__main__':
 capsule,destination,report_file=map(lambda s:Path(s).absolute(),sys.argv[1:])
 need(not report_file.exists(),'Report destination already exists')
 report={'kind':'phase15-exact-capsule-reviewed-symlink-recovery','complete':False,'pass':False,'scope':'Exactly four byte-pinned parent-relative fixture links; fifth ordinary link unchanged. No archive, manifest, compiler source or legacy collector is modified.'}
 try:
  manifest_file=capsule/'manifest.json';manifest_bytes=manifest_file.read_bytes();need(legacy.digest(manifest_bytes)==MANIFEST_SHA256,'Unexpected capsule manifest')
  report['verification']=legacy.verify(capsule,ROOT)
  manifest_identity=legacy.identity(manifest_file);need(manifest_identity['sha256']==MANIFEST_SHA256,'Manifest changed during verification')
  manifest=json.loads(manifest_bytes);report['manifest']={'file':str(manifest_file),**manifest_identity}
  report['controls']=controls(manifest['files'],destination)
  report['materialization']=recover(capsule,destination,manifest)
  report['tool']={'file':str(Path(__file__).resolve()),**legacy.identity(Path(__file__))}
  report['complete']=True;report['pass']=True
 except BaseException as error:
  report['error']=repr(error);raise
 finally:
  with report_file.open('x') as stream:json.dump(report,stream,indent=2);stream.write('\n')
  print(json.dumps({'complete':report['complete'],'pass':report['pass'],'recoveredFiles':report.get('materialization',{}).get('recoveredFiles')}))

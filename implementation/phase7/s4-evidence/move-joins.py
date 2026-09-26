#!/usr/bin/env python3
"""Move exact generic helper blocks without any production-size credit."""
from pathlib import Path
import hashlib,json,shutil,difflib
root=Path(__file__).resolve().parents[3];area=root/'selfhost/build/phase7/s4';before=area/'candidate-b01-project';after=area/'candidate-b02-project'
assert not after.exists();after.mkdir()
for name in ['src','tools','tests']:shutil.copytree(before/name,after/name)
for name in ['cli.mjs','package.json']:
 if (before/name).exists():shutil.copyfile(before/name,after/name)
p=after/'src/core/normalize.bend';s=p.read_text();spans=[]
for start in ['@unsafe\ndef norm_join(','law norm_defs_join:','@unsafe\ndef norm_defs_join(']:
 a=s.index(start);b=s.index('@unsafe\n',a+len(start));spans.append((a,b,s[a:b]))
assert sum(len(x[2].splitlines()) for x in spans)==24
assert sum(len(x[2].encode()) for x in spans)==396
for a,b,_ in sorted(spans,reverse=True):s=s[:a]+s[b:]
p.write_text(s);p=after/'src/core/term.bend';t=p.read_text();assert t.endswith('\n\n');p.write_text(t+''.join(x[2] for x in spans))
manifest=json.loads((before/'src/compiler.json').read_text());report={'kind':'S4-D-module-ownership','complete':False,'movedPhysical':24,'movedNonblank':21,'movedBytes':396,'rows':[]};patch=''
for module in manifest['modules']:
 a=(before/module).read_bytes();b=(after/module).read_bytes()
 def count(x):return [len(x.decode().splitlines()),sum(bool(l.strip()) for l in x.decode().splitlines()),len(x)]
 report['rows'].append({'file':module,'before':count(a),'after':count(b),'beforeSha256':hashlib.sha256(a).hexdigest(),'afterSha256':hashlib.sha256(b).hexdigest()})
 if a!=b:patch+=''.join(difflib.unified_diff(a.decode().splitlines(True),b.decode().splitlines(True),fromfile='a/selfhost/'+module,tofile='b/selfhost/'+module))
report['before']=[sum(r['before'][i] for r in report['rows']) for i in range(3)];report['after']=[sum(r['after'][i] for r in report['rows']) for i in range(3)];assert report['before']==report['after']==[14667,12505,470062];report['complete']=True
out=root/'implementation/phase7/s4-evidence';(out/'b02-ownership-counts.json').write_text(json.dumps(report,indent=2)+'\n');(out/'b02-ownership.patch').write_text(patch)
config=json.loads((area/'candidate-b01-project.json').read_text());config['project']=str(after);(area/'candidate-b02-project.json').write_text(json.dumps(config,indent=2)+'\n');print(report['after'])

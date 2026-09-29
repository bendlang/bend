#!/usr/bin/env python3
"""Remove only unreachable frontend workers after the explicit loader ABI2 cutover."""
from pathlib import Path
import re,json,hashlib
R=Path('selfhost/build/phase22/context-source-08');S=R/'project/src';front=list((S/'front').glob('*.bend'));defs={};blocks={};before={}
for p in front:
 s=p.read_text();before[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
 matches=list(re.finditer(r'(?m)^(?:@unsafe\n)?(def|law|type) ([A-Za-z_][\w.]*)\b',s));blocks[p]=[(m.group(1),m.group(2),m.start(),matches[i+1].start() if i+1<len(matches) else len(s)) for i,m in enumerate(matches)]
 for kind,name,start,end in blocks[p]:
  if kind!='type':defs[name]=defs.get(name,'')+s[start:end]
refs=lambda s:set(re.findall(r'\b[A-Za-z_][\w.]*\b',s))&defs.keys()
roots=set()
for p in S.rglob('*.bend'):
 if p.parent.name!='front':roots|=refs(p.read_text())
roots|=refs((R/'project/tools/typed-driver.mjs').read_text())
for p in front:
 s=p.read_text()
 for kind,name,start,end in blocks[p]:
  if kind=='type':roots|=refs(s[start:end])
seen=set();todo=list(roots)
while todo:
 n=todo.pop()
 if n in seen:continue
 seen.add(n);todo.extend(refs(defs[n])-seen)
dead=sorted(defs.keys()-seen)
report={'kind':'phase22-frontend-worker-closure','roots':sorted(roots),'removed':dead,'beforeSha256':before,'blocks':{str(p):[n for k,n,_,_ in bs if k!='type' and n in dead] for p,bs in blocks.items()},'lines':sum(s[a:b].count('\n') for p,bs in blocks.items() for s in [p.read_text()] for k,n,a,b in bs if k!='type' and n in dead),'scope':'Conservative textual references; all nonfrontend Bend workers, frontend datatype blocks and advertised host roots count as roots. Remove unreachable frontend def/law blocks only. No inferred semantic dead-code elimination.'}
output=R/'frontend-retirement-closure.json';assert not output.exists();output.write_text(json.dumps(report,indent=2)+'\n')
for p,bs in blocks.items():
 s=p.read_text()
 for k,n,a,b in reversed(bs):
  if k!='type' and n in dead:s=s[:a]+s[b:]
 p.write_text(s)
print(json.dumps({'removedWorkers':len(dead),'removedLines':report['lines'],'removed':dead}))

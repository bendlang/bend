#!/usr/bin/env python3
"""Count frozen production membership and actual compiler modules separately."""
from pathlib import Path
import json,hashlib,re,sys
R=Path(__file__).resolve().parents[4]
parent=R/'selfhost/build/phase21/group-range-source-02/project';candidate=R/'selfhost/build/phase22/context-source-08/project';out=R/sys.argv[1]
assert not out.exists()
def ident(p):return {'file':str(p.relative_to(R)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def count(root):
 conf=json.loads((root/'src/compiler.json').read_text());paths=[root/p for p in conf['modules']];texts=[p.read_text()for p in paths]
 allfiles=[p for p in sorted((root/'src').rglob('*'))if p.is_file()]
 return {'sourceFiles':len(allfiles),'compilerModules':len(paths),'moduleLines':sum(len(t.splitlines())for t in texts),'moduleBytes':sum(p.stat().st_size for p in paths),'defs':sum(len(re.findall(r'(?m)^def ',t))for t in texts),'laws':sum(len(re.findall(r'(?m)^law ',t))for t in texts),'types':sum(len(re.findall(r'(?m)^type ',t))for t in texts),'sourceMembership':[ident(p)for p in allfiles]}
a,b=count(parent),count(candidate);manifest=json.loads((candidate.parent/'manifest.json').read_text());closure=json.loads((candidate.parent/'frontend-retirement-closure.json').read_text())
report={'kind':'phase22-context-production-census','complete':True,'parent':a,'candidate':b,'delta':{k:b[k]-a[k]for k in ['sourceFiles','compilerModules','moduleLines','moduleBytes','defs','laws','types']},'manifestChanges':manifest['changes'],'totalChangedPhysicalLines':sum(x['physicalLineDelta']for x in manifest['changes']),'removedUnreachableFrontendWorkers':len(closure['removed']),'removedFrontendDefLawBlockLines':closure['lines'],'removedFrontendWorkers':closure['removed'],'inputs':[ident(Path(__file__)),ident(candidate.parent/'manifest.json'),ident(candidate.parent/'frontend-retirement-closure.json')],'scope':'Net production snapshot delta includes the independently controlled index-remove worker (+8 lines) and ABI2 host routing. Worker closure records removed old implementations, not a runtime timing claim. Module counts exclude retained noncompiler files under src.'}
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report['delta']))

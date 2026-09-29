#!/usr/bin/env python3
import pathlib,json,hashlib,difflib
r=pathlib.Path(__file__).resolve().parents[4];parent=r/'selfhost/build/phase16/literal-context-source-04/project';project=r/'selfhost/build/phase16/spans-lambda-source-04/project';out=r/'selfhost/build/phase16/spans-lambda-handoff-01';out.mkdir();changes=[]
for f in sorted(project.rglob('*')):
 if f.is_file() and f.relative_to(project).parts[0] in ['src','tools']:
  rel=str(f.relative_to(project));before=parent/rel
  if f.read_bytes()!=before.read_bytes():
   patch=out/(rel.replace('/','_')+'.patch');patch.write_text(''.join(difflib.unified_diff(before.read_text().splitlines(True),f.read_text().splitlines(True),fromfile='a/'+rel,tofile='b/'+rel)));changes.append({'path':rel,'parentSha256':hashlib.sha256(before.read_bytes()).hexdigest(),'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'patch':str(patch),'lineDelta':len(f.read_text().splitlines())-len(before.read_text().splitlines()),'byteDelta':f.stat().st_size-before.stat().st_size})
manifest={'parent':str(parent),'project':str(project),'changes':changes,'netLines':sum(x['lineDelta'] for x in changes),'netBytes':sum(x['byteDelta'] for x in changes),'checkedAttempt':str(r/'selfhost/build/phase16/spans-lambda-build-03'),'representationControls':str(r/'selfhost/build/phase16/spans-lambda-direct-02/report.json'),'hostControls':str(r/'selfhost/build/phase16/spans-lambda-host-01/report.json'),'demandControls':str(r/'selfhost/build/phase16/spans-lambda-demand-02/report.json'),'probeExports':[]};(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print(json.dumps({'files':len(changes),'lines':manifest['netLines'],'bytes':manifest['netBytes'],'out':str(out)}))

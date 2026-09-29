"""Two existing error constructors, after the independently frozen baseline passes."""
from pathlib import Path
import json,hashlib,shutil,difflib
ROOT=Path(__file__).resolve().parents[4];P=ROOT/'selfhost/build/phase20';BASE=ROOT/'selfhost/build/phase19/instance-source-04/project';OUT=P/'import-diagnostic-source-01'
report=json.loads((P/'import-diagnostic-baseline-01/report.json').read_text());assert report['complete']and report['pass']and report['observations']==24
OUT.mkdir();C=OUT/'project';shutil.copytree(BASE,C);p=C/'src/front/declarations.bend';old=p.read_text();before='f_pn(f_err(ts, "expected def after @unsafe"))';after='f_pn(fpe_error(ts, "expected def after @unsafe", "\'def\' (@unsafe marks the def below it)"))';assert old.count(before)==2;new=old.replace(before,after);p.write_text(new)
(OUT/'declarations.patch').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='phase19/src/front/declarations.bend',tofile='phase20/src/front/declarations.bend')))
config=json.loads((BASE.parent/'workflow.json').read_text());config['project']=str(C);(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
inputs=[Path(__file__),ROOT/'design/phase20/import-diagnostic-checkpoint.md',P/'import-diagnostic-controls-01/plan.json',P/'import-diagnostic-baseline-01/report.json',BASE.parent/'manifest.json']
(OUT/'manifest.json').write_text(json.dumps({'kind':'phase20-shared-decorator-error-constructor','complete':True,'frozen':True,'parent':str(BASE),'project':str(C),'changedFiles':['src/front/declarations.bend'],'netPhysicalLines':len(new.splitlines())-len(old.splitlines()),'netBytes':len(new.encode())-len(old.encode()),'newDefinitions':0,'newLaws':0,'newTypes':0,'hostChanges':False,'inputs':[identity(p)for p in inputs],'members':{str(f.relative_to(C)):{'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'bytes':f.stat().st_size,'mode':f.stat().st_mode&0o777}for f in sorted(C.rglob('*'))if f.is_file()},'installed':False},indent=2)+'\n');print(OUT)

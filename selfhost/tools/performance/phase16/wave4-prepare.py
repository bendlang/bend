"""Three-way compose reviewed owner deltas, refusing every textual conflict."""
from pathlib import Path
import difflib
import hashlib
import json
import shutil
import subprocess
root=Path(__file__).resolve().parents[4]
phase=root/'selfhost/build/phase16'
base=phase/'range-cost-recovery-source-01/project'
out=phase/'wave4-source-01';out.mkdir();shutil.copytree(base,out/'project')
def identity(p):
    return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
semantic=json.loads((phase/'parser-semantic-source-05-handoff/manifest.json').read_text())
owners=[
 ('ascii-width-source-01','range-cost-recovery-source-01',['src/front/lexer.bend'],'ascii-width-controls-01/report.json'),
 ('parser-semantic-source-05','spans-integration-source-04',[r['file'] for r in semantic['changes']],'parser-semantic-wave3-audit-05.json'),
 ('parser-token-source-01','parser-semantic-source-05',['src/front/parser.bend','src/front/families.bend'],'parser-token-target-01/report.json'),
 ('parser-literal-source-01','parser-semantic-source-05',['src/front/elaborate.bend','src/front/unicode.bend'],'parser-literal-target-01/report.json'),
 ('checker-trace-source-09','spans-integration-source-04',['src/check/kernel.bend','src/diagnostic/trace.bend'],'checker-trace-checks-09/report.json'),
 ('quiet-todo-source-01','range-cost-recovery-source-01',['src/check/kernel.bend'],'quiet-todo-checks-01/report.json'),
 ('checker-source-05','checker-source-04',['src/check/specialize.bend'],'checker-audit-04/report.json'),
]
manifest={'parent':str(base),'tool':identity(Path(__file__)),'owners':[],'complete':False,
          'scope':'Only controlled owner deltas. Excludes unselected imports and rejected memo-identity source06. Cost selection remains pending.'}
def save(): (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
save()
for source,parent,files,control in owners:
    report=phase/control;assert report.is_file(),report
    data=json.loads(report.read_text());assert data.get('complete') is not False,control
    record={'source':source,'parent':parent,'controls':identity(report),'files':[]}
    manifest['owners'].append(record)
    for relative in files:
        previous=phase/parent/'project'/relative
        candidate=phase/source/'project'/relative
        current=out/'project'/relative
        assert previous.read_bytes()!=candidate.read_bytes(),(source,relative)
        before=current.read_bytes()
        if before==previous.read_bytes(): current.write_bytes(candidate.read_bytes())
        else:
            merge=subprocess.run(['git','merge-file','-p',str(current),str(previous),str(candidate)],capture_output=True)
            if merge.returncode:
                conflict=out/(source+'-'+relative.replace('/','_')+'.conflict')
                conflict.write_bytes(merge.stdout);save()
                raise RuntimeError(str(conflict)+' '+merge.stderr.decode())
            current.write_bytes(merge.stdout)
        patch=out/(source+'-'+relative.replace('/','_')+'.patch')
        patch.write_text(''.join(difflib.unified_diff(before.decode().splitlines(True),current.read_text().splitlines(True),fromfile=relative,tofile=relative)))
        record['files'].append({'relative':relative,'parent':identity(previous),'owner':identity(candidate),'merged':identity(current),'patch':identity(patch)})
        save()
manifest['complete']=True;save()
(out/'workflow.json').write_text(json.dumps({'project':str(out/'project'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'0','jobs':1},indent=2)+'\n')
shutil.copy2(__file__,out/'consumed-tool.py');print(out)

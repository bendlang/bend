"""Create the approved shared Phase19 source; no implementation edits or builds."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[4]
PARENT=ROOT/'selfhost/build/phase18/instance-world-source-06/project'
OUT=ROOT/'selfhost/build/phase19/instance-source-01'
def members(root):
    return {str(p.relative_to(root)):{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,'mode':p.stat().st_mode&0o777} for p in sorted(root.rglob('*')) if p.is_file()}
before=members(PARENT);assert len(before)==214
OUT.mkdir();project=OUT/'project';shutil.copytree(PARENT,project)
assert members(project)==before
inputs=[Path(__file__),ROOT/'design/phase19/live-instance-checking.md',ROOT/'design/phase19/instance-interfaces.md',ROOT/'selfhost/build/phase18/instance-world-source-06/manifest.json',ROOT/'selfhost/build/phase18/instance-world-freeze-01/manifest.json']
report={'kind':'phase19-shared-parent-preparation','complete':True,'pass':True,'parent':str(PARENT),'project':str(project),'members':before,'inputs':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in inputs],'scope':'Initial byte/mode-exact parent copy only. Shared project becomes mutable during the approved two-owner implementation; final patches and manifest must bind the closed candidate.','installed':False}
(OUT/'parent-manifest.json').write_text(json.dumps(report,indent=2)+'\n')
(OUT/'workflow.json').write_text(json.dumps({'project':str(project),'upstream':str(ROOT/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n')
print(json.dumps({'complete':True,'pass':True,'files':len(before),'project':str(project)}))

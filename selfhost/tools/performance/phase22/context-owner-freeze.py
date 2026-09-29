#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];B=R/'selfhost/build/phase22'
files=['design/phase22/context-production-boundary.md','design/phase22/context-raw-retirement.md','implementation/phase22/contextual-parser.md','implementation/phase22/contextual-parser.json','implementation/phase22/context-source-census.json','implementation/phase22/context-source-census-final.json']
tools=['context-prepare.py','context-prepare-v2.py','context-rebase-finish.py','context-rebase-finish-v2.py','context-rebase-finish-v3.py','context-freeze.py','context-paired.mjs','context-delta.py','context-header-prepare.py','context-normalization-prepare.py','context-retire-front.py','context-retire-finish.py','context-retire-unused.py','context-material-done-prepare.py','context-census.py','context-census-v2.py','context-production-report.py','context-owner-freeze.py']
files+=['selfhost/tools/performance/phase22/'+p for p in tools]
roots=[f'context-source-{n:02}'for n in range(1,10)]+[f'context-build-{n:02}'for n in range(1,9)]+[f'context-group196-{n:02}'for n in range(1,5)]+['context-header-controls-01','context-header-parent-01']+[f'context-header-candidate-{n:02}'for n in range(1,4)]+['context-normalization-controls-01','context-normalization-parent-01']+[f'context-normalization-candidate-{n:02}'for n in range(1,3)]+['context-owner-preparations-01']
def ident(p):
 p=R/p;return {'path':str(p.relative_to(R)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
source=B/'context-source-09';manifest=json.loads((source/'manifest.json').read_text());report=json.loads((R/'implementation/phase22/contextual-parser.json').read_text());assert report['ownedCorrectnessPass']
summary=['manifest.json','parent.json','workflow.json']
artifacts=[ident('selfhost/build/phase22/context-source-09/'+s)for s in summary]
for name in ['context-build-08/build.json','context-build-08/attempt.json','context-build-08/validation-001/report.json','context-build-08/equality/api.mjs','context-group196-04/report.json','context-group196-04/delta.json','context-header-candidate-03/report.json','context-normalization-candidate-02/report.json']:
 artifacts.append(ident('selfhost/build/phase22/'+name))
changed=[ident('selfhost/build/phase22/context-source-09/project/'+x['path'])for x in manifest['changes']]
handoff={'kind':'phase22-context-parser-handoff','complete':True,'source':'selfhost/build/phase22/context-source-09/project','attempt':'selfhost/build/phase22/context-build-08','api':report['api'],'changedProductionFiles':changed,'ownedPaths':[ident(p)for p in files],'closedEvidenceRoots':['selfhost/build/phase22/'+n for n in roots],'closedEvidenceLogs':['selfhost/build/phase22/'+n+'.log'for n in roots if (B/(n+'.log')).exists()],'finalArtifacts':artifacts,'scope':'Owner implementation and focused gates closed. Root owns broader integration, performance, promotion, publication and independent preservation. Other-owner evidence is referenced separately; these exact owned files may be committed without waiting for further owner edits. Raw failures and superseded candidates remain retained.'}
out=B/'context-owner-freeze-01.json';assert not out.exists();out.write_text(json.dumps(handoff,indent=2)+'\n');print(json.dumps({'ownedPaths':len(files),'closedRoots':len(roots),'changedProductionFiles':len(changed),'sha256':hashlib.sha256(out.read_bytes()).hexdigest()}))

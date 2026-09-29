#!/usr/bin/env python3
"""Retain the existing Unicode-scalar boundary after the direct stage2 falsifier."""
from pathlib import Path
import difflib,hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[4]
BASE=ROOT/'selfhost/build/phase16/parser-source-02'
OUT=ROOT/'selfhost/build/phase16/parser-source-03';OUT.mkdir();shutil.copytree(BASE/'project',OUT/'project')
p=OUT/'project/src/front/parser.bend';before=p.read_text();s=before
a=s.index('@unsafe\ndef fpe_here(');b=s.index('@unsafe\ndef fpe_message(',a)
original=(ROOT/'selfhost/build/phase16/parser-source-01/project/src/front/parser.bend').read_text();c=original.index('@unsafe\ndef fpe_here(');d=original.index('@unsafe\ndef fpe_message(',c)
s=s[:a]+original[c:d]+s[b:]
a=s.index('@unsafe\ndef fpe_unit(');s=s[:a];p.write_text(s)
(OUT/'parser.bend.patch').write_text(''.join(difflib.unified_diff(before.splitlines(True),s.splitlines(True),fromfile='stage2/parser.bend',tofile='stage2-corrected/parser.bend')))
config=json.loads((BASE/'workflow.json').read_text());config['project']=str(OUT/'project');(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
identity=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
shutil.copy2(__file__,OUT/Path(__file__).name)
(OUT/'manifest.json').write_text(json.dumps({'complete':True,'reason':'Preserved parser-controls-02 counterexample: Bend Char construction rejects surrogate55357. Restore conservative existing astral/surrogate point fallback; do not introduce host or invalid-Char workaround.','inputs':[identity(Path(__file__)),identity(BASE/'manifest.json'),identity(ROOT/'selfhost/build/phase16/parser-controls-02/report.json')],'source':identity(p),'config':identity(OUT/'workflow.json')},indent=2)+'\n');print(OUT)

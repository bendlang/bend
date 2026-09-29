#!/usr/bin/env python3
"""Correct a read-only stage3 review finding before its first compiler probe."""
from pathlib import Path
import difflib,hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/parser-source-04';OUT=ROOT/'selfhost/build/phase16/parser-source-05'
OUT.mkdir();shutil.copytree(BASE/'project',OUT/'project');p=OUT/'project/src/front/parser.bend';before=p.read_text()
a='|| f_eq(f_tx(ts), "~"), u => fpe_name_error(f_unmark(ts))';b='|| f_eq(f_tx(ts), "~"), u => fpe_name_error(f_choose(List<&2,FToken>, f_eq(f_tx(ts), "~"), u => ts, u => f_unmark(ts)))';assert before.count(a)==1;s=before.replace(a,b);p.write_text(s)
(OUT/'parser.bend.patch').write_text(''.join(difflib.unified_diff(before.splitlines(True),s.splitlines(True),fromfile='stage3-review/parser.bend',tofile='stage3-corrected/parser.bend')))
config=json.loads((BASE/'workflow.json').read_text());config['project']=str(OUT/'project');(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
identity=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()};shutil.copy2(__file__,OUT/Path(__file__).name)
(OUT/'manifest.json').write_text(json.dumps({'complete':True,'reason':'Pre-probe review: forbidden quantified ~ is observed before any unmarking; preserve stage04 preparation but do not compile that known wrong cursor.','inputs':[identity(Path(__file__)),identity(BASE/'manifest.json')],'source':identity(p),'config':identity(OUT/'workflow.json')},indent=2)+'\n');print(OUT)

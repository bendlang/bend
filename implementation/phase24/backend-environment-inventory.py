#!/usr/bin/env python3
"""Inventory only the closed Phase24 environment evidence; never archive/delete."""
import hashlib,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
NAMES=['backend-environment-01','backend-tcp-bun-01','backend-tcp-supported-01','backend-tsan-capability-01','backend-tsan-programs-01','backend-tsan-shared-01','backend-tsan-parallel-01']
def identity(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 return {'file':str(p.relative_to(ROOT)),'bytes':p.stat().st_size,'sha256':h.hexdigest()}
rows=[]
for name in NAMES:
 for p in sorted((ROOT/'selfhost/build/phase24'/name).rglob('*')):
  if not p.is_file():continue
  row=identity(p)
  external=name=='backend-environment-01' and (p.name.endswith('.deb') or p.name=='bun') or name=='backend-tsan-capability-01' and 'runtime' in p.parts
  row['preservation']='external-pinned-toolchain' if external else 'capture-new-evidence'
  rows.append(row)
out=Path(sys.argv[1]);out=out if out.is_absolute() else ROOT/out
record={'kind':'phase24-environment-evidence-selection','closed':True,'script':identity(Path(__file__).resolve()),'roots':['selfhost/build/phase24/'+n for n in NAMES],'files':rows,'fileBytes':sum(r['bytes'] for r in rows),'captureBytes':sum(r['bytes'] for r in rows if r['preservation']=='capture-new-evidence'),'externalBytes':sum(r['bytes'] for r in rows if r['preservation']=='external-pinned-toolchain'),'externalRecipe':'backend-environment.md documents exact official Bun/Debian URLs and SHA256; extraction members and compiler resource paths are in captured records. Prior Phase23 compiler/fixture/C/JS artifacts use its existing immutable capsule and pinned Git checkout. Do not nest old archives or external toolchain payloads.','sourceTools':'selfhost/tools/performance/phase24/environment-*.py and design/phase24/backend-environment*.md, backend-tsan*.md are owned tracked sources. Python __pycache__ is reproducible and excluded.','archiveCreatedByThisInventory':False}
with out.open('x') as f:json.dump(record,f,indent=2);f.write('\n')
print(json.dumps({k:record[k] for k in ['fileBytes','captureBytes','externalBytes']},indent=2))

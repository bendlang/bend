#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, os, stat
r=Path(__file__).resolve().parents[4]
out=r/'selfhost/build/phase18/cursor-owner-receipt-01.json'
assert not out.exists()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
row=lambda p:{'file':str(p.relative_to(r)),'bytes':p.stat().st_size,'sha256':sha(p),'mode':stat.S_IMODE(p.stat().st_mode)}
docs=[r/'design/phase18/parser_state_options.md',r/'design/phase18/cursor-representation.md',r/'implementation/phase18/cursor-representation.md']
tools=sorted((r/'selfhost/tools/performance/phase18').glob('cursor-*'))
names=['cursor-controls-01','cursor-source-01','cursor-source-02','cursor-build-01','cursor-baseline-01','cursor-validation-01','cursor-direct-01','cursor-allocation-01','cursor-audit-01']
evidence=[]
for n in names:
 p=r/'selfhost/build/phase18'/n
 for base,dirs,files in os.walk(p,followlinks=False):
  for name in dirs+files:
   q=Path(base)/name
   if q.is_symlink():evidence.append({'file':str(q.relative_to(r)),'kind':'symlink','target':os.readlink(q),'mode':stat.S_IMODE(q.lstat().st_mode)})
   elif q.is_file():evidence.append({'kind':'file',**row(q)})
audit=json.loads((r/'selfhost/build/phase18/cursor-audit-01/report.json').read_text())
assert audit['complete'] and audit['pass'] and not audit['rawOraclePass']
report={'complete':True,'owner':'phase15_speed','allOwnerProducersClosed':True,
 'scope':'Phase18 inert cursor representation only; no installed compiler or Phase17 edits',
 'docsAndTools':[row(p)for p in docs+tools],
 'evidenceRoots':names,'evidenceMembership':sorted(evidence,key=lambda x:x['file']),
 'correctness':{'observations':196,'unchanged':196,'exact':128,'knownStrictDifferences':68,'rawSelectedPass':False,'noRegressionAuditPass':True,'directControls':194,'maintainedFocused':36},
 'costOwner':'root: implementation/phase18/cursor-cost.md and selfhost/build/phase18/cursor-matrix-01; intentionally not claimed as this owner output',
 'instrumentationMeaning':'wrapperAllocations counts executed generated constructor expressions, not physical V8 heap objects; JIT may eliminate constructions',
 'decision':'Private research prerequisite only; no semantic migration or production promotion',
 'preservation':'Exact local closure inventory; durable capture/recovery remains root-owned'}
out.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'receipt':row(out),'files':len(evidence),'docsAndTools':len(docs+tools)}))

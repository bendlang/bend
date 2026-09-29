#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,collections,shutil
r=Path(__file__).resolve().parents[4];out=r/'selfhost/build/phase19/context-frontier-census-02';out.mkdir();selection=r/'selfhost/build/phase18/cursor-controls-01/selection.json';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
# Manually reviewed owner inventory, not lexical detection or a claimed passing gate.
p={
'computed-before-continuation':'literal local call','rhs-before-computed':'literal local call','valid-binder-before-continuation':'literal local','empty-call-unbound':'literal local empty-call','empty-call-bound':'literal annotation local empty-call','literal-before-continuation':'literal literal-pattern local','constructor-before-continuation':'constructor-pattern literal local','qualified-before-continuation':'literal local qualified','type-before-continuation':'type-atom literal local','lambda-before-continuation':'group lambda literal local','computed-valid-continuation':'literal local call','parameter-frame':'literal local call','lambda-frame':'lambda literal local call','local-frame':'literal local call','parallel-frame':'parallel literal local call','match-frame':'row constructor-pattern literal local call','all-frame':'all group literal local call','bad-case-before-global-head':'row','global-head-after-good-case':'row literal block-flatten','inner-error-before-computed':'group row literal local call','bound-qualified-positive':'qualified annotation literal local','module-alias-frame':'alias-context literal local call','alias-shadow-frame':'alias-context literal local call','do-frame':'do family tuple constructor literal typed-local local'}
e={
'nested-bound':'empty-call annotation literal local','nested-unbound':'empty-call literal local','lambda-bound':'lambda empty-call annotation literal local','local-bound':'empty-call annotation literal local','field-bound':'row constructor-pattern empty-call','field-unbound':'row constructor-pattern empty-call literal','row-bound':'row empty-call','row-unbound':'row empty-call literal','qualified-bound':'qualified empty-call annotation literal local','qualified-unbound':'qualified empty-call literal local','alias-bound':'alias-context empty-call annotation literal local','alias-unbound':'alias-context empty-call literal local','nonempty-bound':'call literal local','nonempty-unbound':'call literal local','marked-bound':'marked empty-call annotation literal local','offload-bound':'offload literal local'}
m={
'bare-unbound':'marked annotation literal local call','bare-bound':'marked annotation literal local call','empty-bound':'marked empty-call annotation literal local call','nested-bound':'marked empty-call annotation literal local call','empty-unbound':'marked empty-call annotation literal local call','qualified-bound':'marked qualified empty-call annotation literal local call','qualified-unbound':'marked qualified empty-call annotation literal local','alias-bound':'marked alias-context empty-call annotation literal local call','alias-unbound':'marked alias-context empty-call annotation literal local','nonempty-bound':'marked call annotation literal local','datatype-shadow':'marked empty-call annotation literal local','datatype-bare':'marked family-fill annotation literal local','datatype-explicit':'marked family annotation literal local','term-remains-unbound-parse':'marked empty-call','term-remains-unbound':'marked empty-call','quantity-requires-data-parse':'marked empty-call constructor annotation local','quantity-requires-data':'marked empty-call constructor annotation local','ordinary-affine-control':'empty-call constructor annotation local'}
rows=[]
for row in json.loads(selection.read_text())['cases']:
 group,suffix=row['id'].split('/',1)
 if group=='group':continue
 if group=='rejected-stage':
  features='row constructor-pattern literal'
  if 'group' in suffix:features+=' group'
  if 'pattern' in suffix:features+=' type-atom'
  if 'local' in suffix:features+=' local'
  if suffix.startswith('completed'):features+=' block-flatten'
  if suffix=='prior-row-pattern-before-body-syntax':features='row type-atom'
 elif group=='parser-checkpoint':features=p[suffix]
 elif group=='empty-call-pattern':features=e[suffix]
 elif group=='marked-pattern':features=m[suffix]
 elif group=='check':features='do family type-operator tuple constructor literal typed-local local block-flatten'
 else:raise AssertionError(group)
 path=Path(row.get('file')or r/'selfhost/.bootstrap/upstream-phase8/tests'/row['id']);assert path.is_file()
 rows.append(dict(id=row['id'],lanes=row['lanes'],file=str(path),sha256=sha(path),requiredOwners=features.split(),inspection='manual source read; minimum required owner inventory, not execution coverage'))
assert len(rows)==67 and sum(len(x['lanes'])for x in rows)==130
counts=collections.Counter()
for x in rows:
 for owner in set(x['requiredOwners']):counts[owner]+=len(x['lanes'])
report=dict(complete=True,kind='read-only-manual-owner-census',sourceSelection=dict(file=str(selection),sha256=sha(selection)),entries=len(rows),physicalFiles=len(set(x['file']for x in rows)),observations=130,stageObservations=16,patternObservations=114,ownerObservationCounts=dict(sorted(counts.items())),rows=rows,limits=['Counts overlap across owners','No private-parser pass is inferred','Header/prior-book/alias seeds require later pinned parsing events','Monads require original full source, not simplified fixtures'])
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');shutil.copy2(__file__,out/'consumed-tool.py');print(json.dumps({k:v for k,v in report.items()if k!='rows'},indent=2))

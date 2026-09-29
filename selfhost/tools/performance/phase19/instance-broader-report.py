"""Compare original broader frozen observations; retain strict inherited gaps."""
from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parents[4];P=ROOT/'selfhost/build/phase19'
identity=lambda p:{'file':str(p.resolve()),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
configs=[('integration198',198,ROOT/'selfhost/build/phase16/wave9-source-01/selection.json',P/'instance-integration198-01',ROOT/'selfhost/build/phase16/compact-final-checks-01'),('group196',196,ROOT/'selfhost/build/phase17/group-controls-03/selection.json',P/'instance-group196-01',ROOT/'selfhost/build/phase17/group-baseline-03')]
record={'kind':'phase19-broader-frozen-regressions','complete':False,'allStrictExact':False,'selectionChanged':False,'scope':'Original selection bytes and immutable instance-paired runner. Historical strict gaps remain failures; regression comparison is a separate axis. No source or frozen owner-report edits.','inputs':[identity(Path(__file__)),identity(ROOT/'selfhost/tools/performance/phase19/instance-paired.mjs')],'groups':[]}
primitive=['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode']
for name,count,selection,current,parent in configs:
 report=json.loads((current/'report.json').read_text());cur=json.loads((current/'selected/paired.json').read_text());old=json.loads((parent/'selected/paired.json').read_text());assert cur['complete'] and not cur.get('error') and not cur.get('missing');assert len(cur['rows'])==len(old['rows'])==count
 for side in ['reference','candidate']:
  vector=json.loads((current/'selected'/(side+'.json')).read_text());assert len(vector['results'])==count
  assert all(not x['errors']for x in vector['workers'])
  assert all(r.get('result',{}).get('status')not in ['crash','timeout','unsupported']for r in vector['results'])
 key=lambda r:(r['id'],r['lane']);oldmap={key(r):r for r in old['rows']};assert set(oldmap)=={key(r)for r in cur['rows']}
 group={'name':name,'observations':count,'selection':identity(selection),'currentReport':identity(current/'report.json'),'parentReport':identity(parent/'report.json'),'currentPaired':identity(current/'selected/paired.json'),'parentPaired':identity(parent/'selected/paired.json'),'strictExactBefore':sum(r['exactAgreement']for r in old['rows']),'strictExactAfter':sum(r['exactAgreement']for r in cur['rows']),'rawAcquisitionComplete':cur['complete'],'rawRunnerComplete':report['complete'],'rawRunnerError':report.get('error'),'rawSelectedComplete':cur['selectedComplete'],'rawRunnerPass':report['pass'],'verdictCounts':{side:{verdict:sum(r[side+'Verdict']==verdict for r in cur['rows'])for verdict in sorted({r[side+'Verdict']for r in cur['rows']})}for side in ['reference','candidate']},'newExact':[],'lostExact':[],'referenceChanges':[],'candidateChanges':[],'primitiveChanges':[],'remainingStrictDifferences':[]}
 for row in cur['rows']:
  before=oldmap[key(row)];short={'id':row['id'],'lane':row['lane']}
  if row['reference']!=before['reference']:group['referenceChanges'].append(dict(short,before=before['reference'],after=row['reference']))
  if row['candidate']!=before['candidate']:group['candidateChanges'].append(dict(short,before=before['candidate'],after=row['candidate']))
  axes=[a for a in primitive if row['candidate'].get(a)!=before['candidate'].get(a)]
  if axes:group['primitiveChanges'].append(dict(short,axes=axes,before=before['candidate'],after=row['candidate']))
  if row['exactAgreement']and not before['exactAgreement']:group['newExact'].append(short)
  if before['exactAgreement']and not row['exactAgreement']:group['lostExact'].append(short)
  if not row['exactAgreement']:group['remainingStrictDifferences'].append(dict(short,reference=row['reference'],candidate=row['candidate']))
 group['regressionComparisonPass']=not(group['lostExact']or group['referenceChanges']or group['primitiveChanges'])
 record['groups'].append(group);record['inputs'].extend(identity(p)for p in [selection,current/'report.json',current/'selected/paired.json',parent/'report.json',parent/'selected/paired.json'])
# Preserve the second historical grouped comparison as an independent identity check.
g=record['groups'][1];other=ROOT/'selfhost/build/phase17/group-validation-01/selected/paired.json';a=json.loads(other.read_text());b=json.loads(Path(g['parentPaired']['file']).read_text());am={(r['id'],r['lane']):r['candidate']for r in a['rows']};bm={(r['id'],r['lane']):r['candidate']for r in b['rows']};record['groupHistoricalCandidateRecordsIdentical']=am==bm;record['inputs'].append(identity(other));assert am==bm
record['complete']=True;record['regressionComparisonPass']=all(g['regressionComparisonPass']for g in record['groups']);record['allStrictExact']=all(g['strictExactAfter']==g['observations']for g in record['groups'])
out=ROOT/'implementation/phase19/instance-broader-regressions.json';out.write_text(json.dumps(record,indent=2)+'\n')
lines=['# Original broader regressions after live-instance checking','', 'Original frozen selections were run without changing their bytes or strict oracle. The immutable Phase19 paired runner used final checked `instance-build-03` on CPU1. These are supplementary observations; the frozen owned compiler report remains unchanged.','', '| Selection | Previous exact | Final exact | Newly exact | Lost exact | Changed primitive records |','|---|---:|---:|---:|---:|---:|']
for g in record['groups']:lines.append(f"| {g['name']} | {g['strictExactBefore']}/{g['observations']} | {g['strictExactAfter']}/{g['observations']} | {len(g['newExact'])} | {len(g['lostExact'])} | {len(g['primitiveChanges'])} |")
lines+=['','The immutable runner overall flag also requires every verdict to be `pass`; negative parse lanes intentionally receive `observed`, even when every result byte matches the pin. The grouped run additionally stops at its strict selected-completion assertion after collecting all196 healthy rows, because nine inherited acceptance-contract failures remain. The raw incomplete/false gate flags and per-side verdict census remain in the machine report. They are not rewritten. A separate complete-acquisition audit verifies both vectors have all expected rows with no worker errors, timeout, crash or unsupported execution.','', 'The grouped historical baseline03 and validation01 candidate records are identical. Reference replay changes: '+str(sum(len(g['referenceChanges'])for g in record['groups']))+'.','', 'Full paired result changes and every remaining strict mismatch are retained in [the machine report](instance-broader-regressions.json). The broader regression comparison and strict conformance are distinct results; inherited mismatches are not waived or represented as passing.','', 'Newly exact observations:']
for g in record['groups']:
 for r in g['newExact']:lines.append(f"- `{r['id']}` ({r['lane']})")
if not any(g['newExact']for g in record['groups']):lines.append('- None.')
lines+=['','Evidence: `selfhost/build/phase19/instance-integration198-01/` and `instance-group196-01/`, each with original selection, checked API/cache identities, complete candidate/reference vectors and paired rows.','']
(ROOT/'implementation/phase19/instance-broader-regressions.md').write_text('\n'.join(lines));print(json.dumps({'complete':True,'regressionComparisonPass':record['regressionComparisonPass'],'allStrictExact':record['allStrictExact'],'groups':[{k:g[k]for k in ['name','observations','strictExactBefore','strictExactAfter','newExact','lostExact']}for g in record['groups']]}))

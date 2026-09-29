"""Close the owned Phase19 semantic candidate without installing or committing it."""
from pathlib import Path
import hashlib,json,re,difflib
ROOT=Path(__file__).resolve().parents[4];PHASE=ROOT/'selfhost/build/phase19';C=PHASE/'instance-source-04/project';W=ROOT/'selfhost/build/phase18/instance-world-source-06/project';I=ROOT/'selfhost';OUT=PHASE/'instance-handoff-01';OUT.mkdir()
identity=lambda p:{'file':str(p.resolve()),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
members=lambda p:{str(f.relative_to(p)):{'bytes':f.stat().st_size,'mode':f.stat().st_mode&0o777,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in sorted(p.rglob('*'))if f.is_file()}
cm=members(C);frozen=json.loads((PHASE/'instance-source-04/manifest.json').read_text());assert cm==frozen['members']
def census(p):
 mods=json.loads((p/'src/compiler.json').read_text())['modules'];texts=[(p/m).read_text()for m in mods]
 return {'modules':len(mods),'physicalLines':sum(len(s.splitlines())for s in texts),'nonblankLines':sum(sum(bool(l.strip())for l in s.splitlines())for s in texts),'bytes':sum(len(s.encode())for s in texts),'definitions':sum(len(re.findall(r'^def ',s,re.M))for s in texts),'laws':sum(len(re.findall(r'^law ',s,re.M))for s in texts),'types':sum(len(re.findall(r'^type ',s,re.M))for s in texts)}
counts={k:census(p)for k,p in [('installedPrefix',I),('world06',W),('candidate04',C)]};deltas={k:{x:counts['candidate04'][x]-counts[k][x]for x in counts[k]}for k in ['installedPrefix','world06']}
assert counts['candidate04']['physicalLines']==15880
changes={};baseids={}
for label,p in [('installedPrefix',I),('world06',W)]:
 mods=json.loads((C/'src/compiler.json').read_text())['modules'];baseids[label]=[identity(p/m)for m in mods];rows=[];patch=[]
 for name in mods:
  a=(p/name).read_text();b=(C/name).read_text()
  if a!=b:
   rows.append({'file':name,'before':identity(p/name),'after':identity(C/name),'deltaPhysicalLines':len(b.splitlines())-len(a.splitlines())});patch.extend(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile=label+'/'+name,tofile='candidate04/'+name))
 changes[label]=rows;(OUT/(label+'.patch')).write_text(''.join(patch))
attempt=json.loads((PHASE/'instance-build-03/attempt.json').read_text());api=Path(attempt['api']['file']);assert identity(api)['sha256']==attempt['api']['sha256']
gates={
 'checkedDefault36':'instance-build-03/validation-001/validation.json',
 'chronology22':'instance-paired-02/report.json','memo8':'instance-memo-02/report.json','let6':'instance-let-paired-03/report.json','parsed29':'instance-parsed29-01/report.json','key61':'instance-key61-01/report.json','direct40':'instance-direct-02/report.json','recursion4':'instance-recursion-paired-01/report.json','historicalPublic18':'instance-public18-01/report.json'}
# Validation filename is maintained-tool-owned; resolve its actual report conservatively.
if not (PHASE/gates['checkedDefault36']).exists():
 candidates=[p for p in (PHASE/'instance-build-03/validation-001').glob('*.json')if json.loads(p.read_text()).get('kind')=='bend-development-validation']
 assert len(candidates)==1;gates['checkedDefault36']=str(candidates[0].relative_to(PHASE))
gateRows={}
for name,file in gates.items():
 p=PHASE/file;r=json.loads(p.read_text());assert r.get('complete');rows=r.get('rows',[])
 if name=='historicalPublic18':assert not r['pass'] and len(rows)==18 and sum(x['pass']for x in rows)==12
 else:assert r['pass'],name
 gateRows[name]={'report':identity(p),'complete':r['complete'],'pass':r['pass'],'rows':len(rows)if isinstance(rows,list)and rows else None,'exactDifferences':r.get('selected',{}).get('exactDifferences'),'failureNames':[x['name']for x in rows if not x.get('pass',x.get('exact',True))]if isinstance(rows,list)else []}
failed=['instance-build-01/build.json','instance-source-02/preparation-failure.json','instance-let-paired-01/report.json','instance-let-paired-02/report.json','instance-let-ranges-01/report.json','instance-let-ranges-02/report.json','instance-direct-01/setup-failure.json','instance-public18-01/report.json']
prep=['instance-source-01/manifest.json','instance-source-03/manifest.json','instance-source-04/manifest.json','instance-world-edit-01/manifest.json','instance-sequencing-edit-01/manifest.json','instance-mint-edit-01/manifest.json','instance-static-edit-01/manifest.json']
record={'kind':'phase19-live-instance-owned-handoff','complete':True,'selectedForPromotion':False,'project':str(C),'checkedAttempt':identity(PHASE/'instance-build-03/attempt.json'),'productionAPI':identity(api),'candidateMembers':cm,'compilerCensus':counts,'censusDeltas':deltas,'comparisonSourceIdentities':baseids,'changedFiles':changes,'gates':gateRows,'preservedAttempts':[identity(PHASE/x)for x in failed+prep],'inputs':[identity(Path(__file__)),identity(ROOT/'implementation/phase19/instance-live-checking.md')],'scope':'Owner correctness and source handoff only. Root owns full frontend/history/backend/timing/promotion. Public18 is not an overall pass: six raw boundary-transition differences retained; nine historical projection/demand contracts pass. Direct helpers use separately hashed named wrapper modules.','compatibilityLimitations':['Materialized book order is now chronological completion order, not old reversed output order.','Bad instances now fail check_book at first live use rather than only specialization.','Internal unpublished generic owner requires prior owner declaration; tested unpublished high-ID owner is nongeneric.','No general immutable payload claim for stateful JavaScript getter read counts.'],'installedByOwner':False}
(OUT/'manifest.json').write_text(json.dumps(record,indent=2)+'\n')
summary={k:record[k]for k in ['kind','complete','project','checkedAttempt','productionAPI','compilerCensus','censusDeltas','changedFiles','gates','preservedAttempts','scope','compatibilityLimitations','installedByOwner']};summary['handoff']=identity(OUT/'manifest.json');summary['report']=identity(ROOT/'implementation/phase19/instance-live-checking.md')
(ROOT/'implementation/phase19/instance-live-checking.json').write_text(json.dumps(summary,indent=2)+'\n')
ownerTools=sorted((ROOT/'selfhost/tools/performance/phase19').glob('instance-*'));ownerTools=[p for p in ownerTools if not p.name.startswith('instance-boundary')]
ownerDesigns=[p for p in (ROOT/'design/phase19').glob('instance-*.md')]+[ROOT/'design/phase19/live-instance-checking.md']
reports=[ROOT/'implementation/phase19/instance-live-checking.md',ROOT/'implementation/phase19/instance-live-checking.json']
closed=[p for p in PHASE.glob('instance-*')if p.is_dir()and not p.name.startswith('instance-boundary')and not p.name.startswith('instance-frontend')and not p.name.startswith('instance-backend')and not p.name.startswith('instance-literal')and not p.name.startswith('instance-history')and not p.name.startswith('instance-matrix')]
(OUT/'owner-freeze.json').write_text(json.dumps({'kind':'phase19-instance-owner-freeze','complete':True,'readOnlyAfterClosure':True,'trackedFiles':[identity(p)for p in ownerTools+ownerDesigns+reports if p.is_file()],'closedBuildDirectories':[str(p)for p in sorted(closed)],'rootOwnedEvidenceExcluded':True,'handoff':identity(OUT/'manifest.json')},indent=2)+'\n')
print(json.dumps({'complete':True,'api':identity(api)['sha256'],'census':counts['candidate04'],'handoff':str(OUT/'manifest.json')}))

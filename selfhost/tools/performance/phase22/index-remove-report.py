"""Close owner evidence after healthy correctness and exclusive cost screen."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[4]
phase=root/'selfhost/build/phase22'
def read(p):return json.loads((root/p).read_text())
def ident(p):
 p=p.resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
matrix=read('selfhost/build/phase22/index-remove-matrix-01/report.json')
controls=read('selfhost/build/phase22/index-remove-controls-01/report.json')
full=read('selfhost/build/phase22/index-remove-fullcheck-01/report.json')
attempt=read('selfhost/build/phase22/index-remove-build-01/attempt.json')
source=read('selfhost/build/phase22/index-remove-source-01/manifest.json')
assert matrix['complete'] and len(matrix['rows'])==6 and matrix['unsafeDefinitionSetsAgree']
assert controls['complete'] and controls['pass'] and len(controls['comparisons'])==51
assert all(x['exact'] for x in controls['comparisons'])
assert full['complete'] and full['exactObservation']
assert all(r['observation']['pass'] and r['execution']['exitCode']==0 and not r['execution'].get('signal') and not r['execution'].get('error') for r in matrix['rows'])
files=[
 'design/phase22/installed-compiler-profile.md','design/phase22/index-remove-census.md',
 'design/phase22/index-remove-census-correction.md','design/phase22/index-remove-worker.md',
 'implementation/phase22/installed-profile.md','implementation/phase22/installed-profile.json',
 'implementation/phase22/index-remove-worker.md',
 *['selfhost/tools/performance/phase22/'+n for n in ['profile-owners.py','profile-hash-callers.py','index-remove-census.mjs','index-remove-census-v2.mjs','index-remove-count-worker.mjs','index-remove-count-worker-v2.mjs','index-remove-source.py','index-remove-controls-cases.json','index-remove-controls.mjs','index-remove-controls-worker.mjs','index-remove-fullcheck.mjs','index-remove-matrix-prepare.py','index-remove-report.py']]]
roots=['installed-profile-plan-01.json','installed-profile-01','installed-profile-callers-01','installed-profile-hash-callers-01','index-remove-census-01','index-remove-census-02','index-remove-source-01','index-remove-build-01','index-remove-controls-01','index-remove-fullcheck-01','index-remove-matrix-inputs-01','index-remove-matrix-01']
bind=['index-remove-source-01/manifest.json','index-remove-source-01/candidate.patch','index-remove-build-01/attempt.json','index-remove-build-01/validation-001/report.json','index-remove-controls-01/report.json','index-remove-fullcheck-01/report.json','index-remove-matrix-inputs-01/freeze.json','index-remove-matrix-01/report.json']
report={'kind':'phase22-index-remove-owner-receipt','complete':True,'boundedCorrectnessPass':True,'costScreenPass':True,'installed':False,'sourceDelta':source['delta'],'sourceMembership':len(source['members']),'changedFiles':source['changedFiles'],'api':attempt['api'],'controls':{'paired':51,'allExact':True,'longMaximum':20000,'stackKiB':4096,'publicFocused':36,'fullSourceObservationExact':True},'statistics':matrix['statistics'],'ratios':matrix['ratios'],'rssReduction':1-matrix['statistics']['candidate']['maxRssKiB']/matrix['statistics']['baseline']['maxRssKiB'],'timingWindow':{'started':matrix['started'],'finished':matrix['finished'],'otherOwnersIdleConfirmed':True,'order':matrix['order']},'limits':['Two timing samples per image and one fixed checking workload; no emission or edit-loop speed claim.','Finite direct raw-object/stack coverage; broader integration and promotion remain root-owned.','Constructor-site counts are not physical V8 allocations; no allocation reduction measured.'],'failedAttempts':['index-remove-census-01: wrong ES namespace injection, preserved; corrected v2 passes.'],'ownedFiles':[ident(root/p) for p in files],'evidence':[ident(phase/p) for p in bind],'closedRoots':[str(phase/p) for p in roots]}
dest=root/'implementation/phase22/index-remove-worker.json';dest.write_text(json.dumps(report,indent=2)+'\n')
owned=phase/'index-remove-owner-freeze-01.json'
owned.write_text(json.dumps({'complete':True,'producerClosed':True,'ownedFiles':[ident(root/p) for p in files]+[ident(dest)],'closedRoots':report['closedRoots'],'receipt':ident(dest)},indent=2)+'\n')
print(json.dumps({'receipt':ident(dest),'ownerFreeze':ident(owned),'files':len(files)+1,'closedRoots':len(roots)}))

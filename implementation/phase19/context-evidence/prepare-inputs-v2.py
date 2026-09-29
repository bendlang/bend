#!/usr/bin/env python3
"""Correct only the reviewed part bound and retain the entire old preparation."""
from pathlib import Path
import datetime,difflib,hashlib,json,stat
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def read(p):return json.loads(Path(p).read_text())
def write(name,obj):
 with (HERE/name).open('x') as f:json.dump(obj,f,indent=2);f.write('\n')
def text(path,value):
 with path.open('x') as f:f.write(value)
oldplan=read(HERE/'selection-proposal.json');oldfreeze=read(HERE/'root-freeze.json')
for r in oldfreeze['inputs']:assert sha(ROOT/r['path'])==r['sha256'],r['path']
original=ROOT/'selfhost/tools/performance/phase19/context-preserve.py'
collector=ROOT/'selfhost/tools/performance/phase19/context-preserve-v2.py'
before=original.read_text();after=before.replace("context-evidence/selection-proposal.json'","context-evidence/selection-proposal-v2.json'").replace("context-evidence/root-freeze.json'","context-evidence/root-freeze-v2.json'").replace('Usage: context-preserve.py','Usage: context-preserve-v2.py')
assert before!=after
text(collector,after);collector.chmod(stat.S_IMODE(original.stat().st_mode))
text(HERE/'collector-adaptation-v2.patch',''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='a/'+str(original.relative_to(ROOT)),tofile='b/'+str(collector.relative_to(ROOT)))))
write('adaptation-v2.json',{'complete':True,'original':{'path':str(original.relative_to(ROOT)),'sha256':sha(original)},'collector':{'path':str(collector.relative_to(ROOT)),'sha256':sha(collector)},'changesOnly':['v2 plan/freeze paths','usage label'],'collectorPolicyChanged':False,'rootApprovedConfigChange':{'maxPartPayloadBytes':{'before':64000000,'after':384000000},'maxArchiveBytes':99000000}})
write('preparation-01-blocker.json',{'complete':True,'captureExecuted':False,'recoveryExecuted':False,
 'reason':'Unchanged collector refuses member bytes >= maxPartPayloadBytes; original 343793779-byte report exceeds64000000.',
 'ownerInterpretationIncorrect':True,'caughtBy':'independent read-only reviewer phase15_carets before launch',
 'rootApprovedCorrection':'New384000000 uncompressed part bound, same99000000 compressed bound and all other policies unchanged.',
 'inventory':{'path':'implementation/phase19/context-evidence/capsule-01/inventory.json','sha256':sha(HERE/'capsule-01/inventory.json')}})

audit=(HERE/'audit-selection.py').read_text()
audit=audit.replace("selection-proposal.json'","selection-proposal-v2.json'").replace("root-freeze.json'","root-freeze-v2.json'").replace("capsule-01/","capsule-02/").replace("selection-review.json'","selection-review-v2.json'")
audit=audit.replace("assert len(selected)==len(rows)","assert len(selected)==len(rows)\nassert inv['maxPartPayloadBytes']==384000000 and inv['maxArchiveBytes']==99000000\nassert max(r['bytes'] for r in rows)<inv['maxPartPayloadBytes']\nold=read(HERE/'capsule-01/inventory.json')\nfor row in old['members']: assert selected.get(row['path'])==row,row['path']")
audit=audit.replace("'symlinks':0,","'symlinks':0,'oldMembersPreservedExactly':7310,'partBoundFeasible':True,")
text(HERE/'audit-selection-v2.py',audit)
runner=(HERE/'run-preservation.py').read_text().replace('selection-review.json','selection-review-v2.json').replace('capsule-01/','capsule-02/').replace("context-evidence/capsule-01'","context-evidence/capsule-02'").replace('context-preserve.py','context-preserve-v2.py').replace('recovery-01.json','recovery-02.json').replace('processes-01.json','processes-02.json')
text(HERE/'run-preservation-v2.py',runner)
finish=(HERE/'finish-preservation.py').read_text().replace('selection-proposal.json','selection-proposal-v2.json').replace('root-freeze.json','root-freeze-v2.json').replace('capsule-01','capsule-02').replace('recovery-01.json','recovery-02.json').replace('processes-01.json','processes-02.json').replace('selection-review.json','selection-review-v2.json').replace('context-preserve.py','context-preserve-v2.py')
finish=finish.replace("assert len(inv['members'])==manifest['files']==7310","assert len(inv['members'])==manifest['files'] and manifest['files']>7310")
finish=finish.replace("assert manifest['bytes']==608493045","assert manifest['bytes']>608493045")
finish=finish.replace('The capsule contains7,310 files,608,493,045 uncompressed bytes,',"The capsule contains{manifest['files']:,} files,{manifest['bytes']:,} uncompressed bytes,")
finish=finish.replace('and104 frozen inputs',"and{len(freeze['inputs'])} frozen inputs")
finish=finish.replace('the64MB uncompressed part target and is\nkept intact; the compressed archive size limit still passed.', 'the original64MB uncompressed member bound. Independent review blocked that\nunexecuted preparation; capsule02 uses the root-approved384MB bound and retains\nthe original metadata. The report is intact and the compressed99MB cap passed.')
finish=finish.replace("'frozenInputsUnchanged':104","'frozenInputsUnchanged':len(freeze['inputs'])")
finish=finish.replace("'consumedContextTools':66,","'consumedContextTools':66,'retainedBlockedPreparation':'capsule-01, never captured; oversized member under original64MB bound',")
finish=finish.replace("files=sorted([p for p in HERE.rglob('*') if p.is_file()]+[ROOT/'selfhost/tools/performance/phase19/context-preserve-v2.py'])", "files=sorted([p for p in HERE.rglob('*') if p.is_file()]+[ROOT/'selfhost/tools/performance/phase19/context-preserve.py',ROOT/'selfhost/tools/performance/phase19/context-preserve-v2.py'])")
text(HERE/'finish-preservation-v2.py',finish)

plan=dict(oldplan);plan['kind']='phase19-context-preservation-selection-v2'
plan['maxPartPayloadBytes']=384000000
plan['retainedUnexecutedPreparation']='implementation/phase19/context-evidence/capsule-01'
metadata=[str(p.relative_to(ROOT)) for p in HERE.rglob('*') if p.is_file()]
plan['extraFiles']={'final':sorted(set(oldplan['extraFiles']['final']+metadata+[str(collector.relative_to(ROOT))]))}
write('selection-proposal-v2.json',plan)
paths=sorted(set(r['path'] for r in oldfreeze['inputs'])|set(plan['extraFiles']['final'])|{'implementation/phase19/context-evidence/selection-proposal-v2.json'})
freeze=dict(oldfreeze);freeze['created']=datetime.datetime.now(datetime.timezone.utc).isoformat()
freeze['authorization']='Root explicitly approved new384000000 uncompressed part bound for capsule02; same99000000 compressed bound and all other policies unchanged. Original preparation retained.'
freeze['inputs']=[{'path':p,'sha256':sha(ROOT/p)} for p in paths]
write('root-freeze-v2.json',freeze)
print(json.dumps({'prepared':True,'roots':80,'sourceMembers':215,'frozenInputs':len(paths),'oldPreparationRetained':True,'uncompressedPartBound':384000000,'compressedArchiveBound':99000000}))

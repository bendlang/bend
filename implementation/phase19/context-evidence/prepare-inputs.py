#!/usr/bin/env python3
"""Freeze explicit closed parser inputs; no compiler/source/capture mutations."""
from pathlib import Path
import datetime, difflib, hashlib, json, os, stat, subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
BASELINE = 'fddfc84b3f48aecc77c2424ddc8227cd7f63251f'
STATUS = 'private-contextual-stage4-experiment'
SOURCE = 'selfhost/build/phase19/context-row-source-05/project'
ATTEMPT = 'selfhost/build/phase19/context-row-build-05'
API = '681bf1bcc748a2a184cd9fa4d53ff78292809711d529ff36bd46c53922f379cf'
GENUINE = 'caf20ce299ca5a390935dec1be355e8929e3b424047cfbe8bf3137ceda572e87'

def need(ok, text):
    if not ok: raise ValueError(text)

def sha(file):
    h = hashlib.sha256()
    with Path(file).open('rb') as stream:
        for data in iter(lambda: stream.read(1024*1024), b''): h.update(data)
    return h.hexdigest()

def write(name, value):
    with (HERE/name).open('x') as stream: json.dump(value, stream, indent=2); stream.write('\n')

def rel(file): return Path(file).relative_to(ROOT).as_posix()

phase = ROOT/'selfhost/build/phase19'
roots = sorted(rel(p) for p in phase.iterdir() if p.name.startswith('context') and p.is_dir())
tools = sorted(rel(p) for p in (ROOT/'selfhost/tools/performance/phase19').glob('context*'))
need(len(roots) == 80 and len(tools) == 66, 'Unexpected root/tool frontier')
receipt = json.loads((phase/'context-row-owner-receipt-01.json').read_text())
need(receipt['complete'] and receipt['allProducersClosed'], 'Stage4 owner not closed')
need(set(receipt['closedRoots']).issubset(roots) and len(receipt['closedRoots']) == 40, 'Stage4 roots differ')
reports = ['implementation/phase19/'+n+'.md' for n in [
    'names-state-stage1', 'names-grammar-routing', 'body-pattern-checkpoints', 'saved-row-group-frontier']]
designs = ['design/phase19/'+n+'.md' for n in [
    'contextual-parser-slice', 'names-state-stage1', 'names-grammar-routing',
    'body-pattern-checkpoints', 'body-pattern-stage3-interface',
    'context-free-reference-materialization', 'saved-row-group-frontier',
    'shared-flatten-checkpoints', 'scoped-block-equivalence']]
audits = ['selfhost/build/phase19/'+n+'/report.json' for n in [
    'context-stage1-audit-01', 'context-grammar-audit-01', 'context-body-audit-01', 'context-row-audit-02']]
for p in audits:
    d = json.loads((ROOT/p).read_text()); need(d['complete'] and d['pass'], 'Final owner audit not passing: '+p)
for row in receipt['closedTrackedFiles']:
    need(sha(ROOT/row['file']) == row['sha256'], 'Frozen Stage4 input changed: '+row['file'])
need(subprocess.check_output(['git','rev-parse',BASELINE],cwd=ROOT).decode().strip() == BASELINE, 'Missing baseline')
source_manifest = json.loads((ROOT/SOURCE).parent.joinpath('manifest.json').read_text())
members = source_manifest['candidateMembership']
actual = {p.relative_to(ROOT/SOURCE).as_posix(): p for p in (ROOT/SOURCE).rglob('*') if p.is_file()}
need(len(actual) == 215 and set(actual) == {r['file'] for r in members}, 'Source membership mismatch')
parent = ROOT/'selfhost/build/phase18/cursor-source-02/project'
parent_names = {p.relative_to(parent).as_posix() for p in parent.rglob('*') if p.is_file()}
need(len(parent_names) == 214 and set(actual) - parent_names == {'src/front/contextual.bend'} and parent_names.issubset(actual), 'Unexpected source addition/deletion')
for row in members:
    p = actual[row['file']]; st = p.lstat()
    need(stat.S_ISREG(st.st_mode) and st.st_size == row['bytes'] and stat.S_IMODE(st.st_mode) == row['mode'] and sha(p) == row['sha256'], 'Source identity mismatch: '+row['file'])
write('source-membership.json', {'complete':True,'source':SOURCE,'baselineCommit':BASELINE,
    'members':members,'memberCount':215,'priorProjectMembers':214,'addedPaths':['src/front/contextual.bend']})
attempt = json.loads((ROOT/ATTEMPT/'attempt.json').read_text())
need(attempt['checked'] and attempt['api']['sha256'] == API and sha(attempt['api']['file']) == API, 'Selected checked API mismatch')
need(receipt['genuineApiSha256'] == GENUINE and receipt['selectedApiSha256'] == API, 'Owner API identity mismatch')

old = ROOT/'implementation/phase18/evidence/phase6-start-state.json'
protected = json.loads(old.read_text())['unrelatedPhase6']; need(len(protected) == 75, 'Protected scope changed')
raw = subprocess.check_output(['git','status','--porcelain=v1','--untracked-files=all','--',*[r['path'] for r in protected]],cwd=ROOT).decode()
statuses = {line[3:]:line[:2] for line in raw.splitlines()}
for row in protected:
    need(sha(ROOT/row['path']) == row['sha256'] and statuses.get(row['path'],'') == row['status'], 'Protected Phase6 changed: '+row['path'])
with (HERE/'phase6-start-state.json').open('xb') as stream: stream.write(old.read_bytes())

original = ROOT/'selfhost/tools/performance/phase19/instance-preserve.py'
collector = ROOT/'selfhost/tools/performance/phase19/context-preserve.py'
before = original.read_text(); after = before
replacements = [
    ('implementation/phase19/instance-evidence/', 'implementation/phase19/context-evidence/'),
    ('installed-live-checker-release', STATUS),
    ('Explicit installed live checker release freeze required', 'Explicit private contextual experiment freeze required'),
    ('prefix-to-anchor.patch', 'phase17-to-context-anchor.patch'),
    ('phase19-instance-scoped-', 'phase19-context-scoped-'),
    ('Selected closed Phase19 live checker release and its checker experiments/gates only; active contextual parser work and previously preserved prefix originals remain outside this capsule.',
     'Closed private Phase19 contextual parser stages1-4 and failed attempts only; no installed release or whole-compiler conformance claim, and excluded experiments remain outside this capsule.'),
    ('Usage: instance-preserve.py', 'Usage: context-preserve.py')]
for a,b in replacements:
    need(a in after, 'Adaptation target missing: '+a); after = after.replace(a,b)
with collector.open('x') as stream: stream.write(after)
collector.chmod(stat.S_IMODE(original.stat().st_mode))
patch = ''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),
    fromfile='a/'+rel(original),tofile='b/'+rel(collector)))
with (HERE/'collector-adaptation.patch').open('x') as stream: stream.write(patch)
recover = ROOT/'selfhost/tools/performance/phase16/compact-recover.py'
need(sha(recover) == '654bcf4435c7b02d329299aa3f4a71aed46c122b556ecd06bfbccece15972234', 'Recovery tool changed')
write('adaptation.json', {'complete':True,'original':{'path':rel(original),'sha256':sha(original)},
    'collector':{'path':rel(collector),'sha256':sha(collector)},'patch':{'path':rel(HERE/'collector-adaptation.patch'),'sha256':sha(HERE/'collector-adaptation.patch')},
    'unchangedRecovery':{'path':rel(recover),'sha256':sha(recover)},
    'changesOnly':['metadata paths','private experiment anchor status','scope/kind labels','source patch filename','usage label'],
    'memberArchiveFixtureAndPathPoliciesChanged':False})

external = [
    {'kind':'committed-source','commit':BASELINE,'scope':'All215 contextual source members reconstructed, including214 inherited paths and one new module.'},
    {'kind':'previous-phase-capsule','path':'implementation/phase18/evidence/preservation.json','manifest':'implementation/phase18/evidence/capsule-01/manifest.json','scope':'Complete parent cursor source02/build01, raw controls/selection and baseline validation01, with earlier prerequisite chain.'},
    {'kind':'previous-phase-capsule','path':'implementation/phase17/evidence/preservation.json','manifest':'implementation/phase17/evidence/capsule-02/manifest.json','scope':'Prior group-stage evidence and original group fixtures; exact referenced fixture siblings may be recaptured.'},
    {'kind':'upstream-checkout','path':'selfhost/.bootstrap/upstream-phase8','commit':'b2111cf43244e65f76ddc278ee695e669f720cbf','scope':'Pinned TypeScript compiler, Base and upstream fixtures.'},
    {'kind':'external-toolchain','scope':'Recorded Node24.18 and any other executable toolchains are not vendored.'}]
extras = reports + designs + tools + [
    'selfhost/build/phase19/context-row-owner-receipt-01.json',
    'selfhost/tools/performance/phase18/cursor-direct-run.mjs',
    'selfhost/tools/performance/phase18/cursor-direct-controls.mjs',
    'selfhost/tools/performance/phase16/compact-recover.py',
    'selfhost/tools/performance/phase19/instance-preserve.py',
    'selfhost/tools/performance/phase19/context-preserve.py',
    'implementation/phase18/evidence/preservation.json',
    'implementation/phase18/evidence/capsule-01/manifest.json',
    'implementation/phase17/evidence/preservation.json',
    'implementation/phase17/evidence/capsule-02/manifest.json',
    'selfhost/build/phase16/compact-final-evidence-policy-01/report.json',
    'implementation/phase19/context-evidence/prepare-inputs.py',
    'implementation/phase19/context-evidence/phase6-start-state.json',
    'implementation/phase19/context-evidence/source-membership.json',
    'implementation/phase19/context-evidence/collector-adaptation.patch',
    'implementation/phase19/context-evidence/adaptation.json']
excludes = sorted(rel(p) for p in phase.iterdir() if rel(p) not in roots and p.name != 'context-row-owner-receipt-01.json')
excludes += ['selfhost/dist','selfhost/src','selfhost/tools/performance/phase6']
for ph in ['phase20','phase21']:
    excludes += ['selfhost/build/'+ph,'selfhost/tools/performance/'+ph,'design/'+ph,'implementation/'+ph]
plan = {'kind':'phase19-context-preservation-selection','status':'frozen-before-inventory-capture',
    'anchorStatus':STATUS,'baselineCommit':BASELINE,'finalSource':SOURCE,'finalAttempt':ATTEMPT,
    'finalApiSha256':API,'genuineApiSha256':GENUINE,'phaseRoot':'selfhost/build/phase19',
    'topics':{'context':[],'final':[]},'extraTrees':{'context':roots},'extraFiles':{'final':sorted(extras)},
    'closedDocumentationDirectories':[],'excludedTrees':excludes,
    'excludedTopLevelReason':'Outside closed contextual stages1-4; production/checker/prefix and later phases are not selected.',
    'maxPartPayloadBytes':64000000,'maxArchiveBytes':99000000,'externalPrerequisites':external,
    'expectedClosedRoots':80,'expectedConsumedContextTools':66,'expectedSourceMembers':215}
write('selection-proposal.json',plan)
frozen = sorted(set(extras + audits + ['implementation/phase19/context-evidence/PLAN.md',
    'implementation/phase19/context-evidence/selection-proposal.json',ATTEMPT+'/attempt.json',
    rel(Path(attempt['api']['file'])),rel((ROOT/SOURCE).parent/'manifest.json')]))
freeze = {'authorized':True,'authorization':'Root task explicitly authorizes preserve and independent recovery after released timing hold; no compiler or live-source changes.',
    'created':datetime.datetime.now(datetime.timezone.utc).isoformat(),'allProducersClosed':True,
    'closureScope':'Exactly80 named contextual experiment roots; other team work is outside this freeze.',
    'anchorStatus':STATUS,'finalAttempt':ATTEMPT,'finalApiSha256':API,'genuineApiSha256':GENUINE,
    'source':SOURCE,'sourceMemberCount':215,'selectedRoots':roots,
    'inputs':[{'path':p,'sha256':sha(ROOT/p)} for p in frozen], 'additionalFiles':[]}
write('root-freeze.json',freeze)
print(json.dumps({'prepared':True,'roots':len(roots),'contextTools':len(tools),'sourceMembers':215,
    'frozenInputs':len(frozen),'protectedPhase6':75,'collector':rel(collector)}))

#!/usr/bin/env python3
"""Freeze Phase35 final-image gates; run no compiler, gate, timing or install."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
PRIOR = ROOT/'selfhost/build/phase32/final-plan-03'
FROZEN = ROOT/'selfhost/build/phase30/final-integration-plan-17/launchers'
NODE = Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
BASELINE = ROOT/'selfhost/build/phase32/attempt-03'
ADDITIONS = {'src/back/js/jpure.bend': 'src/back/js/local.bend',
             'src/back/js/fold.bend': 'src/back/js/region.bend'}
ap = argparse.ArgumentParser(description=__doc__)
ap.add_argument('attempt', type=Path)
ap.add_argument('out', type=Path)
ap.add_argument('--added-module', action='append', choices=ADDITIONS, default=[])
ap.add_argument('--prepared', type=Path, help='Reuse a completed candidate bundle emitted by this exact final API; owner-only fixtures remain fresh')
args = ap.parse_args()
attempt, out = args.attempt.resolve(), args.out.resolve()
manifest = json.loads((attempt/'attempt.json').read_text())
assert manifest['checked'] and manifest['config']['strictExact']
assert str(manifest['config']['cpu']) == '3' and manifest['config']['jobs'] == 1
assert 0 < manifest['config']['heapMb'] <= 1024
assert len(set(args.added_module)) == len(args.added_module)
out.mkdir(parents=True, exist_ok=False)
(tools := out/'tools').mkdir()
inputs, derivations, commands = {}, [], []

def ident(file):
    file = Path(file).resolve(); digest = hashlib.sha256()
    with file.open('rb') as stream:
        for chunk in iter(lambda: stream.read(2**20), b''):
            digest.update(chunk)
    return dict(file=str(file), sha256=digest.hexdigest(), bytes=file.stat().st_size)

def keep(file, digest=None):
    row = ident(file)
    if digest is not None:
        assert row['sha256'] == digest, row['file']
    inputs[row['file']] = row
    return row

def save(file, value):
    file.write_text(json.dumps(value, indent=2)+'\n')

def frozen(source, digest, name=None, changes=()):
    keep(source, digest); original = tools/('original-'+(name or source.name))
    shutil.copyfile(source, original); keep(original)
    target = tools/(name or source.name); text = source.read_text(); applied = []
    for before, after, count in changes:
        assert text.count(before) == count, (source, before, text.count(before), count)
        text = text.replace(before, after); applied.append(dict(before=before, after=after, count=count))
    target.write_text(text)
    derivations.append(dict(parent=keep(source), original=keep(original), derived=keep(target), changes=applied))
    return target

def command(name, argv, seconds, scope, environment=None, stage='preinstall', self_supervised=False):
    # Parent affinity and the preserved inner launchers all bind CPU3.
    argv = ['taskset', '-c', '3', *map(str, argv)]
    if environment:
        argv = ['env', *[k+'='+v for k,v in environment.items()], *argv]
    wrapper = [sys.executable, str(HERE.parent/'phase32/bounded-run.py'), '--seconds', str(seconds),
               '--rss-mib', '2048', '--available-mib', '2048', str(out/('run-'+name)), '--', *argv]
    commands.append(dict(name=name, command=argv, supervisedCommand=argv if self_supervised else wrapper, selfSupervised=self_supervised, cpu=3,
        outerTimeoutSeconds=seconds, treeRssMiB=2048, availableFloorMiB=2048,
        scope=scope, stage=stage, executed=False))

keep(__file__)
keep(HERE/'final-gate-audit.py')
keep(ROOT/'design/phase35/prospective-admission.md')
keep(attempt/'attempt.json'); keep(BASELINE/'attempt.json')
keep(HERE.parent/'phase32/bounded-run.py')
for key in ['api','checkedApi','runtime','base','node','bootstrapReport']:
    keep(manifest[key]['file'], manifest[key]['sha256'])
for source in manifest['snapshot']['sources']:
    keep(source['frozen']['file'], source['frozen']['sha256'])
assert ident(NODE)['sha256'] == manifest['node']['sha256']

# Retain Phase32's exact frontend comparator/health assertions unchanged.
gate = frozen(PRIOR/'tools/frontend-gate.mjs', '8e118b47b8652425be8f7583c0b9a80721e4c000e2cd2e27bb3e2e716b59b666')
prior_layout = json.loads((PRIOR/'frontend-layout.json').read_text())
keep(PRIOR/'frontend-layout.json')
old_file = BASELINE/'snapshot/src/compiler.json'
new_file = Path(manifest['snapshot']['root'])/'src/compiler.json'
old, new = (json.loads(p.read_text()) for p in [old_file,new_file])
non = lambda value: {k:v for k,v in value.items() if k != 'modules'}
assert non(old) == non(new) == prior_layout['expectedNonModules']
assert old['modules'] == prior_layout['after']['modules'] and len(old['modules']) == 66
expected = list(old['modules'])
for added, after in ADDITIONS.items():
    if added in args.added_module:
        assert added not in expected
        expected.insert(expected.index(after)+1, added)
assert new['modules'] == expected, 'Only explicitly selected named modules at their declared positions are admitted'
assert len(expected) == len(set(expected)) == 66+len(args.added_module)
layout = dict(kind='explicit-compiler-module-layout-migration', expectedNonModules=non(new),
              before=prior_layout['before'], after=dict(sha256=keep(new_file)['sha256'], modules=expected))
save(out/'frontend-layout.json', layout)
save(out/'frontend-layout-audit.json', dict(complete=True, baseline=keep(old_file), candidate=keep(new_file),
    baselineModules=old['modules'], expectedModules=expected, added=args.added_module,
    allowedPositions=ADDITIONS, priorOrderPreserved=True, unchangedNonModules=non(new)))
selection = ROOT/'selfhost/build/phase22/context-group196-05/selection.json'; keep(selection)
for scope in ['main','broader']:
    reference = ROOT/('selfhost/build/phase23/frontend-'+scope+'-01')
    keep(reference/'report.json')
    command('frontend-'+scope, [NODE,'--stack-size=4096','--max-old-space-size=1024',gate,
        attempt,out/('frontend-'+scope),scope,reference,selection if scope=='broader' else '',out/'frontend-layout.json'],
        1800,'Fresh candidate; exact 3026/196 historic observations, explicit frozen layout.', {'PHASE23_FRONTEND_CPU':'3'})

# Pilot selection and comparison code remain byte-identical. Rebind structured
# candidate/output fields only; historical failed/N/A observations stay intact.
runner = frozen(PRIOR/'tools/backend-run.py','739a392b91dd2566169f8cdb516276610f9a75e6fb7afac212a19a8ef87fcc0d')
census = frozen(PRIOR/'tools/backend-census.py','2dc3fe206f950841181e3673bd43c7d7dc42e99a00160522314b2333677deb72')
old_pilot_file = PRIOR/'backend/pilot.json'; p = json.loads(old_pilot_file.read_text()); keep(old_pilot_file)
assert p['expectedRows'] == 81 and p['expectedCounts'] == {'pass':69,'not-applicable':8,'fail':4}
backend = out/'backend'; backend.mkdir()
rows_source = Path(p['historicalRows']['file']); keep(rows_source,p['historicalRows']['sha256'])
shutil.copyfile(rows_source,backend/'historical-rows.json')
rows = json.loads(rows_source.read_text()); assert len(rows) == len({(r['id'],r['lane']) for r in rows}) == 81
backend_inputs = [keep(i['file'],i['sha256']) for i in p['inputs']]
backend_inputs += [keep(attempt/'attempt.json'),keep(runner),keep(census),keep(backend/'historical-rows.json')]
backend_inputs += [keep(manifest[k]['file'],manifest[k]['sha256']) for k in ['api','checkedApi','runtime','base','node','bootstrapReport']]
backend_inputs += [keep(e['frozen']['file'],e['frozen']['sha256']) for e in manifest['snapshot']['sources']]
batches=[]
for batch in p['batches']:
    row=dict(batch); row['output']=str(backend/'pilot'/row['name'])
    argv=list(row['command']); assert argv[1].endswith('/backend-census.py')
    argv[1]=str(census); argv[-2:]=[row['output'],str(attempt)]; row['command']=argv; batches.append(row)
assert {(r['id'],r['lanes'][0]) for b in batches for r in b['cases']} == {(r['id'],r['lane']) for r in rows}
new_pilot={**p,'attempt':keep(attempt/'attempt.json'),'inputs':backend_inputs,'batches':batches,
    'historicalRows':keep(backend/'historical-rows.json'),'cpu':'3','jobs':1}
save(backend/'pilot.json',new_pilot)
command('backend-pilot',[sys.executable,runner,backend/'pilot.json'],900,
    '81 fresh rows: exact prior evidence including 69 passes, 8 N/A and 4 shared check failures.')

inherited = frozen(FROZEN/'prototype-inherited-controls.py','0be71d01f5bbf8e9210c5e80fe93a828dad668a05a205a113f67103d4054e7a3',changes=[
    ("['taskset','-c','7'","['taskset','-c','3'",1),('CPU7 acquisition only','CPU3 acquisition only',1)])
for mode in ['primitive','worker','nested','primitive-guards']:
    command(mode,[sys.executable,inherited,attempt,mode,out/mode],300,'Unchanged maintained assertion and oracle bodies.')
upstream = frozen(HERE.parent/'phase29/integration-upstream.py','6da6e0aa25c23109348ba702d00624e7c93061f8e773c16166ae9026ccbd8553',changes=[
    ("HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]",'HERE=Path('+repr(str(HERE.parent/'phase29'))+');ROOT=HERE.parents[3]',1),
    ("config['cpu']=='4'","config['cpu']=='3'",1)])
command('upstream-selected',[sys.executable,upstream,attempt,out/'upstream'],180,'Unchanged 15 exact upstream JS probes.')
corpus=HERE.parent/'phase26/corpus.py'; keep(corpus,'2c472579b37623b603cb487a669e3b788a63ec03e2af19020ba28cb2931ca460')
keep(HERE.parent/'phase25/campaign.py')
command('corpus',[sys.executable,corpus,attempt,ROOT/'selfhost/build/phase25/corpus-01',out/'corpus'],300,
    'Original CPU3/1024MiB corpus producer, identical 23 libraries and 127 points.')

# Bind normal additional gates directly instead of generating another planner.
additional=out/'additional'; additional.mkdir()
bindings={k:manifest[k]['file'] for k in ['api','runtime','base']}
bindings['driver']=str(Path(manifest['snapshot']['root'])/'tools/typed-driver.mjs')
for file in bindings.values(): keep(file)
save(additional/'worker-config.json',bindings)
worker=ROOT/'selfhost/build/phase30/worker-admission-plan-07/controls.mjs'; keep(worker)
command('worker-admission',[NODE,'--stack-size=4096','--max-old-space-size=1024',worker,
    additional/'worker-config.json',additional/'worker-admission'],120,'Retained 40 refusal guards and two execution witnesses.')
component=frozen(FROZEN/'integration-acquire.py','5d4b9bb076f8077612759b073ae3816ccd8f1d11b3cd943f427862ac3e7fdc21',changes=[
    ("['taskset','-c','7'","['taskset','-c','3'",1),('CPU7','CPU3',1)])
command('component-and-hvm',[sys.executable,component,attempt,additional/'component',additional/'hvm'],300,
    '22 component observations and complete exact 42-byte HVM program stdout.')

# Installation remains after correctness and separate performance admission.
release=ROOT/'selfhost/tools/development/release.mjs'; keep(release)
command('release-install',[NODE,'--max-old-space-size=1024',release,'--install-attempt',attempt],180,
    'Root only, after complete preinstall audit and performance admission.',stage='postinstall')
command('release-verify',[NODE,'--max-old-space-size=1024',release,'--verify'],120,
    'Root only; installed release must equal selected API.',stage='postinstall')
smoke=frozen(PRIOR/'tools/release-smoke.mjs','b598f413ae1168ff13723067a80c729c6961c3d6ae39f834dcbbbdff2cc09b92',changes=[
    ('CPU1','CPU3',2),("actualCpu!=='1'","actualCpu!=='3'",1),('cpu:1,actualCpu','cpu:3,actualCpu',1)])
launch=frozen(PRIOR/'tools/release-smoke-launch.mjs','5327f8cb6e9f4d9de94748bb3ede0b2c6cf11801b24569a82fc4fb96bf57794b',changes=[
    (json.dumps(str(PRIOR/'tools/release-smoke.mjs')),json.dumps(str(smoke)),1),('cpu:1','cpu:3',1),("['-c','1'","['-c','3'",1)])
command('release-smoke',[NODE,'--max-old-space-size=1024',launch,ROOT/'selfhost',out/'release-smoke',manifest['api']['sha256']],
    1200,'Unchanged 42 ordinary/relocated CLI assertions with Clang16.',stage='postinstall')
from final_owner import append_owner
keep(HERE/'final_owner.py'); keep(HERE/'final-integration-run.py')
owner=append_owner(ROOT,HERE,attempt,out,manifest,args.added_module,command,keep,save,args.prepared)
for row in inputs.values(): assert ident(row['file']) == row
save(out/'derivations.json',dict(complete=True,derivations=derivations))
save(out/'plan.json',dict(kind='phase35-final-integration-plan',complete=True,executed=False,
    attempt=keep(attempt/'attempt.json'),api=manifest['api'],inputs=list(inputs.values()),commands=commands,
    ownerGates=owner,layout=keep(out/'frontend-layout-audit.json'),
    ownerPolicy='Each mandatory owner group needs complete passing receipts whose hashed provenance reaches the final checked API or its checked emission. Old-API mechanisms never discharge final gates.',
    performanceAdmission='Separate: maintained generated-program confirmation and normal checked compiler requests on pair/Mandelbrot plus symreg/ray. No timing is run or admitted by this correctness plan.',
    cpuPolicy='All processes serial on CPU3, Node heaps <=1024MiB, 2048MiB process-tree cap, 2048MiB available-memory floor, shared supervisor lock. No timing overlaps any producer.',
    limitations='Exact historic frontend and selected backend agreements; four shared check failures remain failures. Not full backend/GPU conformance or a fixed-point claim.'))
shutil.copyfile(__file__,out/'consumed-plan.py')
print(json.dumps(dict(complete=True,executed=False,out=str(out),commands=len(commands),ownerGates=owner,modules=len(expected))))

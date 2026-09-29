#!/usr/bin/env python3
"""Bind the installed Phase21 checkpoint to its scoped, immutable evidence."""
import hashlib
import json
from datetime import datetime
from pathlib import Path

repo = Path(__file__).resolve().parents[4]
phase = repo/'selfhost/build/phase21'
inputs = []

def identity(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}

def read(p):
    inputs.append(identity(p))
    return json.loads(Path(p).read_text())

inputs.append(identity(__file__))
attempt = read(phase/'group-range-build-02/attempt.json')
source = read(phase/'group-range-source-02/manifest.json')
integration = read(phase/'group-range-integration-audit-01/report.json')
matrix = read(phase/'group-range-matrix-01/report.json')
promotion = read(phase/'group-range-promotion-01/report.json')
smoke = read(phase/'group-range-smoke-01/launcher.json')
release = read(repo/'selfhost/dist/release.json')
census = read(phase/'group-range-census-02.json')
build = read(phase/'group-range-build-02/build.json')
focused = read(phase/'group-range-build-02/validation-001/report.json')
controls = read(repo/'implementation/phase21/group-range-controls-source02.json')
typed_error = read(repo/'implementation/phase21/group-range-controls-typed-error.json')
structure = read(repo/'implementation/phase21/group-range-structure.json')
review = read(repo/'implementation/phase21/group-range-review-source02.json')
programs = read(phase/'group-range-program-audit-02/report.json')
comma = read(repo/'implementation/phase21/group-comma.json')
for x in [integration, promotion, smoke, focused, controls, typed_error, programs]:
    assert x['complete'] and x['pass']
assert structure['complete'] and structure['boundedStructureGatePass']
assert review['complete'] and review['boundedGateApproved']
assert matrix['complete'] and not matrix.get('error')
assert smoke['steps'] == 42
assert len(promotion['copies']) == 3
assert integration['frontend']['changes'] == [] and integration['groups']['afterExact'] == 139
assert next(x['sha256'] for x in release['files'] if x['path']=='dist/typed-api.mjs') == attempt['api']['sha256']
for name in ['group-range-review-source01', 'group-range-structure-source01', 'group-range-controls-baseline']:
    read(repo/f'implementation/phase21/{name}.json')
for name in ['group-range-programs-01', 'group-range-program-audit-01', 'group-range-group196-01', 'group-range-group196-02']:
    old = read(phase/name/'report.json')
    assert old['pass'] is False
for name in ['range-execution.md','typed-annotation-origin.md','group-boundaries.md']:
    inputs.append(identity(repo/'design/phase21'/name))
inputs.append(identity(repo/'implementation/phase21/group-range-release.md'))
seconds = (datetime.fromisoformat(focused['finished'].replace('Z','+00:00'))-
           datetime.fromisoformat(build['started'].replace('Z','+00:00'))).total_seconds()
report = {
    'kind':'phase21-installed-local-origin-release', 'complete':True, 'pass':True,
    'passMeaning':'Reviewed bounded origin correction installed; scoped gates passed with all known raw failures retained. Not full conformance.',
    'api':attempt['api'], 'checkedApi':attempt['checkedApi'],
    'sourceSha256':release['sourceSha256'], 'upstream':release['lineage']['upstreamRevision'],
    'source':source['project'], 'sourceDelta':source['deltaPhase20'],
    'census':{k:v for k,v in census.items() if k!='inputs'},
    'frontend':{'observations':2996,'wholeResultChanges':0,'remainingExactDifferences':2},
    'broader':{'observations':196,'beforeExact':136,'afterExact':139,'newExact':3,'lostExact':0,'remainingDifferences':57,'rawSuitePass':False},
    'focused':{'maintainedStrictExact':36,'independent68BeforeExact':44,'independent68AfterExact':60,
               'gains':16,'lostExact':0,'primitiveChanges':0,'typedErrors':4,'typedErrorsExact':2},
    'structure':{'graphObservations':172,'exactPositiveAnnCoordinates':30,'legacyAbsent':80,'nonrangeChanges':0,'acceptanceChanges':0},
    'programs':{'observations':12,'exact':12,'successfulExecutions':9,'originalOutputOracleFailuresPerSide':9,'oracleRewritten':False},
    'installedCliSteps':42,'copiedSourceFiles':3,
    'performance':{'statistics':matrix['statistics'],'ratios':matrix['ratios'],
                   'rssReduction':1-matrix['statistics']['candidate']['maxRssKiB']/matrix['statistics']['baseline']['maxRssKiB'],
                   'classification':'Neutral cost screen; two samples/image; no emitted-code speed claim.'},
    'observedBuildAnd36Seconds':seconds,
    'remaining':'Main do-block chronology; broader57; new independent constructor acceptance and typed-error gaps; group completion/first-error transport; full-language conformance, proof-kernel/GPU and source-reduction goals.',
    'publication':'Local commit; earlier automatic approval review still blocks push.',
    'preservation':'Separate scoped capsule and independent recovery receipt indexed in experiments/PRESERVATION.md.',
    'inputs':inputs}
for x in inputs: assert identity(x['file']) == x
out = repo/'implementation/phase21/group-range-release.json'
with out.open('x') as f: json.dump(report,f,indent=2); f.write('\n')
print(json.dumps({'api':attempt['api']['sha256'],'complete':True,'observedLoopSeconds':seconds,'census':report['census']}))

"""Close the independently bounded source01 handoff; no compiler source writes."""
from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[4]; P=R/'selfhost/build/phase20'
read=lambda p:json.loads(p.read_text())
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
paths={
 'source':P/'import-diagnostic-source-01/manifest.json',
 'build':P/'import-diagnostic-build-01/build.json',
 'default':P/'import-diagnostic-build-01/validation-001/report.json',
 'paired':P/'import-diagnostic-build-01/validation-001/selected/paired.json',
 'baseline':P/'import-diagnostic-baseline-01/report.json',
 'focused':P/'import-diagnostic-focused-01/report.json',
 'supplied':P/'import-diagnostic-supplied-01/report.json',
 'host':P/'import-diagnostic-host-01/report.json',
 'parentPaired':R/'selfhost/build/phase19/instance-build-03/validation-001/selected/paired.json',
 'parentFrontend':R/'selfhost/build/phase19/instance-frontend-01/candidate.json',
}
j={k:read(v) for k,v in paths.items()}
for k in ['default','baseline','focused','supplied','host']:assert j[k]['complete']and j[k]['pass'],k
assert j['build']['artifactKind']=='derived-b1'
assert j['baseline']['exactPairs']==4 and j['focused']['exactPairs']==24
assert len(j['supplied']['controls'])==39 and not j['supplied']['strictDifferences']
assert len(j['host']['controls'])==43 and not j['host']['strictDifferences']
assert j['source']['changedFiles']==['src/front/declarations.bend']
assert j['source']['netPhysicalLines']==0 and j['source']['netBytes']==92
gaps=lambda rows:[{'id':x['id'],'lane':x['lane']}for x in rows if not x['exactAgreement']]
old=gaps(j['parentPaired']['rows']);new=gaps(j['paired']['rows'])
assert len(old)==2 and new==[{'id':'import-after-type','lane':'check'}]
frontend=j['parentFrontend']['results'];assert len(frontend)==2996
relevant=[x for x in frontend if 'expected def after @unsafe' in json.dumps(x)]
assert not relevant
report={
 'kind':'phase20-shared-decorator-diagnostic-handoff','complete':True,'pass':True,
 'source':str(P/'import-diagnostic-source-01/project'),'api':j['focused']['api'],
 'parentInstalledCommit':'fd9e8b2','parentSource':j['source']['parent'],
 'changedFiles':j['source']['changedFiles'],'physicalLines':0,'bytes':92,
 'newDefinitions':0,'newLaws':0,'newTypes':0,'hostOrABIChange':False,'installed':False,
 'default36':{'pass':True,'parentStrictDifferences':old,'strictDifferences':new},
 'focused24':{'baselineExact':4,'candidateExact':24,'newExact':20,'lostExact':0},
 'originalSupplied39':{'pass':True,'strictDifferences':0},
 'originalOrderedHost43':{'pass':True,'strictDifferences':0},
 'fullVectorPolicy':{'parentObservations':2996,'matchingLegacyDiagnostics':0,'expected':'No primitive or diagnostic changes; root owns the full gate.'},
 'limitations':[
  'No full conformance or performance claim. No timing was run.',
  'The datatype/import checkpoint is a separately investigated existing gap, not changed by source01.',
  'The astral-comment control covers an astral character before the ASCII error cursor. Existing astral/surrogate-at-cursor fallback is unchanged.',
  'Unknown-decorator and decorator whitespace grammar remain outside this candidate.',
 ],
 'attemptFailures':[],
 'inputs':[identity(v) for v in paths.values()]+[identity(Path(__file__)),identity(R/'design/phase20/import-diagnostic-checkpoint.md'),identity(P/'import-diagnostic-source-01/declarations.patch')],
}
out=R/'implementation/phase20';out.mkdir(exist_ok=True)
target=out/'import-diagnostic-checkpoint.json';assert not target.exists();target.write_text(json.dumps(report,indent=2)+'\n')
md=out/'import-diagnostic-checkpoint.md';assert not md.exists()
md.write_text('''# Shared decorator diagnostic: source01 handoff

The isolated candidate closes the inherited decorator/import diagnostic gap by
using the existing structured parser error constructor at the two pending-unsafe
guards. No loader ordering, parser acceptance, source record or host/cache ABI
changes. It adds **zero lines, definitions, laws or types**, and 92 bytes in one
source file. It is not installed by this experiment.

`@unsafe` followed by `import` previously bypassed the shared renderer and emitted
`line 2:0: expected def after @unsafe; got import`. Pinned `parse_book` reports the
expectation `'def' (@unsafe marks the def below it)`, the current character and a
source snippet. `f_top` and the existing `f_import_leading` unsafe fallback now
construct that same structured failure with `fpe_error`. The normal public route
reaches `f_top`; both branches retain their original rejection checkpoint.

The genuine checked B1 and maintained36 pass. Strict maintained differences fall
from two to one: import-after-decorator becomes exact; import-after-type remains
unchanged. The frozen12 fixtures exercise both supplied sources and the ordered
filesystem host: all24 observations are exact, improving20 while retaining4.
They include EOF, law/type/repeated decorator, comments, valid definitions, missing
or invalid later imports, and an earlier invalid dependency whose failure wins.
Exact read lists prove that imports after the decorator are never opened.

The original supplied39 and ordered-host43 tools were executed unchanged. Both
pass with **empty strictDifferences**, independently checked despite their
historical allowance for the decorator gap. The latter preserves seed/lifecycle,
source-range, compatibility and ordering controls. The astral-comment fixture
tests an astral character before an ASCII error cursor; inherited fallback when
the offending cursor itself is astral/surrogate is unchanged.

The frozen Phase19 full frontend has2996 observations and none contains the
changed legacy message. The prospective broad-gate policy is no primitive or
unrelated diagnostic delta; root owns that integration gate. No timing was run,
so this error-only change makes no speed claim. Unknown decorators, whitespace
inside the decorator spelling and the datatype constructor checkpoint remain
outside source01. The separate datatype investigation must not be counted as a
source01 improvement.

Source: `selfhost/build/phase20/import-diagnostic-source-01/project`.
Patch and all214 project identities: its `declarations.patch` and `manifest.json`.
Checked attempt: `selfhost/build/phase20/import-diagnostic-build-01`.
Baseline/focused/supplied/host reports are the corresponding Phase20
`import-diagnostic-*-01/report.json` files. No failed Phase20 preparation, build or
control attempt occurred before this handoff. The machine report binds the exact
API, inputs and raw results; original reports and sources are frozen.
''')
handoff=P/'import-diagnostic-handoff-01';handoff.mkdir()
files=[target,md,Path(__file__),R/'design/phase20/import-diagnostic-checkpoint.md']+[R/'selfhost/tools/performance/phase20'/n for n in ['import-diagnostic-prepare.py','import-diagnostic-probe.mjs','import-diagnostic-source.py']]
freeze={'kind':'phase20-import-diagnostic-source01-freeze','complete':True,'files':[identity(p)for p in files],'closedRoots':[str(P/n)for n in ['import-diagnostic-controls-01','import-diagnostic-baseline-01','import-diagnostic-source-01','import-diagnostic-build-01','import-diagnostic-focused-01','import-diagnostic-supplied-01','import-diagnostic-host-01']]}
(handoff/'owner-freeze.json').write_text(json.dumps(freeze,indent=2)+'\n')
print(json.dumps({'report':str(target),'freeze':identity(handoff/'owner-freeze.json'),'api':report['api'],'strictDifferences':new}))

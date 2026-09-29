"""Freeze the separate constructor correction and its exact bounded evidence."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];P=R/'selfhost/build/phase20';I=R/'implementation/phase20'
read=lambda p:json.loads(p.read_text())
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
paths={k:P/v for k,v in {
 'source':'import-diagnostic-source-02/manifest.json','build':'import-diagnostic-build-02/build.json',
 'default':'import-diagnostic-build-02/validation-001/report.json','paired':'import-diagnostic-build-02/validation-001/selected/paired.json',
 'baseline':'import-diagnostic-type-baseline-02/report.json','focused':'import-diagnostic-type-focused-02/report.json',
 'decorator':'import-diagnostic-focused-02/report.json','supplied':'import-diagnostic-supplied-02/report.json',
 'host':'import-diagnostic-host-02/report.json','census':'import-diagnostic-type-census-01/report.json',
}.items()}
j={k:read(p)for k,p in paths.items()}
for k in ['default','baseline','focused','decorator','supplied','host']:assert j[k]['complete']and j[k]['pass'],k
assert j['build']['artifactKind']=='derived-b1'
assert len(j['paired']['rows'])==36 and all(x['exactAgreement']for x in j['paired']['rows'])
assert j['focused']['count']==50 and j['focused']['exact']==50
assert j['baseline']['count']==50 and j['baseline']['exact']==18
assert j['decorator']['observations']==24 and j['decorator']['exactPairs']==24
assert len(j['supplied']['controls'])==39 and not j['supplied']['strictDifferences']
assert len(j['host']['controls'])==43 and not j['host']['strictDifferences']
rows=[]
for old,new in zip(j['baseline']['rows'],j['focused']['rows']):
 assert (old['name'],old['route'])==(new['name'],new['route'])and old['expected']==new['expected']
 if old['candidate']!=new['candidate']:
  rows.append({'name':new['name'],'route':new['route'],'acceptanceChanged':old['candidateAccept']!=new['candidateAccept'],'beforeAccept':old['candidateAccept'],'afterAccept':new['candidateAccept']})
assert len(rows)==32 and sum(x['acceptanceChanged']for x in rows)==12
report={
 'kind':'phase20-type-constructor-checkpoint-handoff','complete':True,'pass':True,
 'source':j['source']['project'],'api':j['focused']['api'],'changedFiles':j['source']['changedFiles'],
 'deltaParent01':j['source']['deltaParent01'],'deltaPhase19':j['source']['deltaPhase19'],
 'sameABI':True,'hostChanges':False,'installed':False,'timing':None,
 'raw30':{'baselineExact':10,'candidateExact':30},'loaded20':{'baselineExact':8,'candidateExact':20},
 'changedObservations':rows,'newExact':32,'lostExact':0,'acceptanceCorrections':12,'diagnosticOnlyCorrections':20,
 'default36':{'pass':True,'exact':36,'strictDifferences':0},
 'decorator24':{'pass':True,'exact':24},'originalSupplied39':{'pass':True,'strictDifferences':0},'originalOrderedHost43':{'pass':True,'strictDifferences':0},
 'scope':['Raw parser full diagnostics and successful constructor name/arity inventories.','Supplied and actual ordered-host load diagnostics, reference acceptance, and exact read order.','Root owns combined broad frontend/groups, timing, promotion and preservation.'],
 'fullVectorPolicy':'No unreviewed primitive or diagnostic regression. Intended custom acceptance corrections are listed explicitly; no corpus change is waived by these controls.',
 'attemptFailures':[],
 'inputs':[identity(p)for p in paths.values()]+[identity(Path(__file__)),identity(R/'design/phase20/import-diagnostic-type-correction.md'),identity(P/'import-diagnostic-source-02/declarations-parent01.patch'),identity(P/'import-diagnostic-source-02/declarations-phase19.patch')],
}
target=I/'import-diagnostic-type-checkpoint.json';assert not target.exists();target.write_text(json.dumps(report,indent=2)+'\n')
md=I/'import-diagnostic-type-checkpoint.md';assert not md.exists()
md.write_text('''# Datatype constructor checkpoint: source02 handoff

The isolated correction closes a real grammar gap at the constructor loop. All
50 frozen comparisons now match the pin exactly, improving 32 without losing an
exact result. Twelve observations correct acceptance (seven false rejections and
five false acceptances); the other 20 correct diagnostic checkpoints. Counts are
observations, not distinct corpus fixtures. No broad conformance claim follows.

Pinned `parse_book` (2521–2527) keeps parsing constructors while the next character
can start a name, except for the complete declaration keywords def/type/law. It
then validates the name, alias/duplicate freshness, and opening brace in that
order. Our previous `f_type_ctors` required positive indentation and an immediately
following brace before entering the constructor path. This both ended the type
body too early and bypassed name validation on accepted constructor shapes.

Source02 uses the pinned loop boundary and the existing f_valid_name/fpe_name_error
at the actual name checkpoint. A small named worker retains alias-before-duplicate
and both-before-brace ordering. Whitespace/comments can occur before the opening
brace, using the existing skip and telescope parser. EOF, punctuation, decorators
and legal declaration terminators retain their own paths. No loader, namespace,
host, public record, ABI or language-state mechanism changes.

The original read-only22 census is retained: only nine observations were exact,
and five changed acceptance. The frozen extension adds qualified names, dot
neighbors, missing/newline braces, keyword-prefix names and underscore names.
Raw30 improves from 10 to 30 exact, including matching constructor name/arity
inventories on successful programs. Ten loaded fixtures run on supplied and
ordered-host routes, improving from eight to 20 exact. These retain prior
dependency failures, alias/duplicate precedence, qualified constructors and
missing-import boundaries, with unchanged exact read lists.

The genuinely checked B1/default36 passes with **zero strict differences**.
The separately frozen decorator24 remains fully exact. Original supplied39 and
ordered-host43 tools and historical fixture bytes also pass with empty strict
differences. No preparation, build or control failure occurred in this source02
sequence. Baseline mismatches are preserved results, not hidden failures.

The change adds 17 physical lines and one function, zero laws/types, and 713 bytes
relative to source01. Including the independent decorator correction, the delta
from Phase19 is 17 lines, one function and 805 bytes in declarations.bend. The
helper makes the existing constructor checks readable; this is a correctness
improvement with small code growth, not a line-count reduction. No timing was run.

Authoritative source: `selfhost/build/phase20/import-diagnostic-source-02/project`.
Its manifest binds all 214 files and contains both parent-relative counts; patches
are `declarations-parent01.patch` and `declarations-phase19.patch`. The checked
image is `import-diagnostic-build-02`. All input/API identities, individual changed
observations and closed report paths are in the adjacent machine report. Source01
and its report remain immutable and independently eligible. Root owns any later
guard composition, broad frontend/groups, performance gate and promotion; no
unreviewed corpus regression is permitted by these custom expected changes.
''')
files=[target,md,Path(__file__),R/'design/phase20/import-diagnostic-type-checkpoint.md',R/'design/phase20/import-diagnostic-type-correction.md']+[R/'selfhost/tools/performance/phase20'/x for x in ['import-diagnostic-type-probe.mjs','import-diagnostic-type-prepare.py','import-diagnostic-type-gate.mjs','import-diagnostic-type-source.py']]
roots=['import-diagnostic-type-census-01','import-diagnostic-type-controls-01','import-diagnostic-type-baseline-02','import-diagnostic-source-02','import-diagnostic-build-02','import-diagnostic-type-focused-02','import-diagnostic-focused-02','import-diagnostic-supplied-02','import-diagnostic-host-02']
o=P/'import-diagnostic-handoff-02';o.mkdir();freeze=o/'owner-freeze.json';freeze.write_text(json.dumps({'kind':'phase20-constructor-checkpoint-source02-freeze','complete':True,'files':[identity(p)for p in files],'closedRoots':[str(P/x)for x in roots]},indent=2)+'\n');print(json.dumps({'report':str(target),'freeze':identity(freeze),'api':report['api']}))

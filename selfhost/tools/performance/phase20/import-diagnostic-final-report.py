"""Freeze final source04 and preserve the semicolon regression that rejected source02/03."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];P=R/'selfhost/build/phase20';I=R/'implementation/phase20'
read=lambda p:json.loads(p.read_text())
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
paths={k:P/v for k,v in {
 'source':'import-diagnostic-source-04/manifest.json','build':'import-diagnostic-build-04/build.json',
 'default':'import-diagnostic-build-04/validation-001/report.json','paired':'import-diagnostic-build-04/validation-001/selected/paired.json',
 'decoratorBaseline':'import-diagnostic-baseline-01/report.json','decorator':'import-diagnostic-focused-04/report.json',
 'typeBaseline':'import-diagnostic-type-baseline-02/report.json','type':'import-diagnostic-type-focused-04/report.json',
 'firstBaseline':'import-diagnostic-first-baseline-01/report.json','first':'import-diagnostic-first-focused-04/report.json',
 'braceParent':'import-diagnostic-brace-parent-02/report.json','braceRegression':'import-diagnostic-brace-regression-02/report.json','brace':'import-diagnostic-brace-focused-04/report.json',
 'supplied':'import-diagnostic-supplied-04/report.json','host':'import-diagnostic-host-04/report.json',
 'source03':'import-diagnostic-source-03/manifest.json','build03':'import-diagnostic-build-03/build.json',
}.items()}
j={k:read(p)for k,p in paths.items()}
for k in ['default','decorator','type','first','brace','supplied','host']:assert j[k]['complete']and j[k]['pass'],k
assert j['build']['artifactKind']=='derived-b1'and all(x['exactAgreement']for x in j['paired']['rows'])and len(j['paired']['rows'])==36
for name,count in [('type',50),('first',54),('brace',44)]:assert j[name]['count']==j[name]['exact']==count
assert j['decorator']['observations']==j['decorator']['exactPairs']==24
for name,count in [('supplied',39),('host',43)]:assert len(j[name]['controls'])==count and not j[name]['strictDifferences']
assert j['source']['changedFiles']==['src/front/declarations.bend']
assert j['source']['deltaPhase19']=={'physicalLines':17,'bytes':1110,'definitions':1,'laws':0,'types':0}
api=j['first']['api'];assert api['sha256']==j['type']['api']['sha256']==j['brace']['api']['sha256']==j['decorator']['api']['sha256']
def changes(before,after):
 out=[]
 for a,b in zip(before['rows'],after['rows']):
  assert(a['name'],a['route'])==(b['name'],b['route'])and a['expected']==b['expected']
  if a['candidate']!=b['candidate']:
   out.append({'name':b['name'],'route':b['route'],'acceptanceChanged':a['candidateAccept']!=b['candidateAccept'],'beforeAccept':a['candidateAccept'],'afterAccept':b['candidateAccept']})
 return out
first=changes(j['firstBaseline'],j['first']);typ=changes(j['typeBaseline'],j['type']);brace=changes(j['braceParent'],j['brace'])
assert len(first)==12 and sum(x['acceptanceChanged']for x in first)==9
assert len(typ)==32 and sum(x['acceptanceChanged']for x in typ)==12
newRegression=[];inheritedRegression=[]
for a,b in zip(j['braceParent']['rows'],j['braceRegression']['rows']):
 assert(a['name'],a['route'])==(b['name'],b['route'])and a['expected']==b['expected']
 if b['candidateAccept']and not b['referenceAccept']:
  (inheritedRegression if a['candidateAccept']else newRegression).append({'name':b['name'],'route':b['route']})
assert len(newRegression)==15 and len(inheritedRegression)==9
report={
 'kind':'phase20-final-declaration-checkpoints-handoff','complete':True,'pass':True,
 'source':j['source']['project'],'api':api,'changedFiles':j['source']['changedFiles'],'deltaPhase19':j['source']['deltaPhase19'],
 'hostOrABIChange':False,'newSemanticState':False,'installed':False,'timing':None,
 'default36':{'pass':True,'exact':36,'strictDifferences':0},
 'decorator24':{'baselineExact':4,'finalExact':24},
 'constructor50':{'baselineExact':18,'finalExact':50,'changes':typ},
 'firstElement54':{'baselineExact':42,'finalExact':54,'changes':first},
 'whitespace44':{'source01Exact':6,'source02Exact':20,'finalExact':44,'changesFromSource01':brace,'newSource02FalseAcceptances':newRegression,'inheritedFalseAcceptances':inheritedRegression},
 'supplied39':{'pass':True,'strictDifferences':0},'orderedHost43':{'pass':True,'strictDifferences':0},
 'superseded':[{'source':'import-diagnostic-source-02','reason':'Independent semicolon controls found 15 newly false-accepted observations after its original bounded controls passed.'},{'source':'import-diagnostic-source-03','reason':'Checked composition retains the unchanged defective datatype checkpoint from source02. Build/default36 passed, but final controls were reserved for corrected source04.'}],
 'buildFailures':[],
 'limits':['Suite counts are separate observations with overlapping grammar coverage; do not sum them into distinct conformance fixtures.','The immutable source02 report remains a historical bounded result; its promotion recommendation is superseded here.','Global statement and telescope semicolon policies are unchanged; this is the datatype checkpoint whitespace contract.','The original parser bodies are retained, with no contextual parser/FInput migration.','Root owns full frontend2996, original group196, controlled cost screen, promotion and preservation.'],
 'inputs':[identity(p)for p in paths.values()]+[identity(Path(__file__)),identity(P/'import-diagnostic-source-04/declarations-phase19.patch'),identity(P/'import-diagnostic-source-04/declarations-parent03.patch')],
}
target=I/'import-diagnostic-final.json';assert not target.exists();target.write_text(json.dumps(report,indent=2)+'\n')
md=I/'import-diagnostic-final.md';assert not md.exists();md.write_text('''# Final declaration checkpoint candidate: source04

Source04 is the final isolated candidate for root integration. It combines the
structured decorator error, the datatype constructor checkpoint, and two empty
first-element guards around the original match parser bodies. The datatype
whitespace correction below **supersedes source02 and source03 for promotion**.
Neither earlier source nor its bounded report was rewritten.

The final genuinely checked B1/default36 is fully exact. On this same image:

| Frozen suite | Earlier exact | Final exact |
| --- | ---: | ---: |
| Decorator, supplied and host | 4/24 | 24/24 |
| Constructor raw/loaded | 18/50 | 50/50 |
| First elements, raw/supplied/host | 42/54 | 54/54 |
| Datatype whitespace, source01 baseline | 6/44 | 44/44 |
| Original supplied-source controls | inherited one strict gap | 39 pass, zero strict gaps |
| Original ordered-host controls | inherited one strict gap | 43 pass, zero strict gaps |

These are separate suite observations with overlapping grammar coverage, not
distinct corpus fixtures or a full-language conformance claim. New focused reference
diagnostics were frozen before the final source change. Ordered-host suites also
assert actual read order and preserve earlier dependency failures.

The two first-element guards use List.is_empty before accepting an initial colon
or skipping an initial comma, then call existing fpe_error with `a term`. Original
f_match_heads/f_case_pats bodies are preserved byte-for-byte inside the wrappers;
no FInput, contextual case/body worker or parser-state migration is included.
They fix nine false-acceptance and three diagnostic observations. Valid multiple
heads/patterns with optional commas, trailing/double-comma rejection, EOF/newline
positions and a bound head with zero rows remain exact. List.is_empty avoids the
rejected prototype's repeated accumulator-length traversal.

Independent review found a real flaw in source02 after its initial focused gates:
f_skip consumed semicolons before `{` and around the datatype constructor loop.
For example, `type T is Data: C;{}` was newly accepted while the pin rejects at `;`.
The widened column-zero constructor admission also exposed before/between-loop
semicolon errors. Identical source01/source02/pin controls prove 15 newly false
accepted observations across five fixtures, plus nine inherited false acceptances
at neighboring datatype boundaries. Those raw reports and the checked source03
composition remain preserved. A passing earlier narrow gate is not evidence that
this counterexample is safe.

Source04 uses the existing newline-only f_space at the brace checkpoint and both
constructor-loop feeds. The loop exits through f_top on its already-spaced cursor,
preserving an offending semicolon for the ordinary top-level diagnostic. Name,
alias and duplicate checks still run before the opening-brace check. All 44 new
whitespace observations are exact, including comments/newlines, malformed and
reserved names, aliases, duplicates, and declaration exits. Global f_skip/f_tops
and telescope grammar remain unchanged; this is not a general semicolon audit.

The complete delta from installed Phase19 is one file, **17 additional physical
lines, one function, zero laws/types, and 1110 bytes**. No host, cache/public ABI,
semantic state, checker, backend or normalizer change is included. This adds a
small readable constructor-header worker and corrects shared existing grammar
checkpoints. It is not a line-count reduction. No timing was performed by this
owner; root's separate controlled screen must establish cost before promotion.

Authoritative project: `selfhost/build/phase20/import-diagnostic-source-04/project`.
The manifest binds all 214 project files; cumulative patch is
`declarations-phase19.patch`, and the final whitespace delta is
`declarations-parent03.patch`. Checked image: `import-diagnostic-build-04`.
Final closed gates are `import-diagnostic-{brace,first,type}-focused-04`,
`import-diagnostic-focused-04`, `import-diagnostic-supplied-04`, and
`import-diagnostic-host-04`. The machine report binds exact API/input identities,
all changed focused observations, rejected candidates, and scope limitations.
Root owns broad frontend/group checks, cost screening, installation and release.
''')
names=['import-diagnostic-first-prepare.py','import-diagnostic-first-source.py','import-diagnostic-brace-prepare.py','import-diagnostic-brace-prepare-v2.py','import-diagnostic-whitespace-source.py']
files=[target,md,Path(__file__)]+[R/'selfhost/tools/performance/phase20'/n for n in names]+[R/'design/phase20'/n for n in ['import-diagnostic-first-elements.md','import-diagnostic-brace-boundary.md','import-diagnostic-type-whitespace.md']]
roots=['import-diagnostic-first-controls-01','import-diagnostic-first-baseline-01','import-diagnostic-source-03','import-diagnostic-build-03','import-diagnostic-brace-controls-01','import-diagnostic-brace-parent-01','import-diagnostic-brace-controls-02','import-diagnostic-brace-parent-02','import-diagnostic-brace-regression-02','import-diagnostic-source-04','import-diagnostic-build-04','import-diagnostic-brace-focused-04','import-diagnostic-first-focused-04','import-diagnostic-type-focused-04','import-diagnostic-focused-04','import-diagnostic-supplied-04','import-diagnostic-host-04']
o=P/'import-diagnostic-handoff-04';o.mkdir();freeze=o/'owner-freeze.json';freeze.write_text(json.dumps({'kind':'phase20-final-declaration-checkpoint-owner-freeze','complete':True,'files':[identity(p)for p in files],'closedRoots':[str(P/n)for n in roots],'priorFrozenHandoffs':[identity(P/f'import-diagnostic-handoff-0{i}/owner-freeze.json')for i in [1,2]]},indent=2)+'\n');print(json.dumps({'report':str(target),'freeze':identity(freeze),'api':api}))

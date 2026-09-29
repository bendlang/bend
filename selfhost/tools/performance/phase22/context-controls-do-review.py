#!/usr/bin/env python3
"""Freeze the bounded Phase22 do review; does not execute compiler code."""
import hashlib,json
from pathlib import Path
root=Path.cwd()
out=root/'implementation/phase22/context-controls-do-review.json'
md=out.with_suffix('.md')
assert not out.exists() and not md.exists()
def load(s): return json.loads((root/s).read_text())
def ident(s):
 p=(root/s).resolve(); b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
public=load('selfhost/build/phase22/context-controls-do-raw-candidate-01/report.json')
direct=load('selfhost/build/phase22/context-controls-do-direct-02/report.json')
setup=load('selfhost/build/phase22/context-controls-do-direct-01/report.json')
assert public['complete'] and public['pass'] and public['selected']['exactDifferences']==1
assert not public['comparison']['lostExact'] and len(public['comparison']['gainedExact'])==2
assert direct['complete'] and direct['pass'] and direct['semanticMatches']==5 and direct['explicitUnsupported']==1
assert not setup['complete'] and not setup['pass'] and not setup['rows']
paths=[
 'selfhost/tools/performance/phase22/context-controls-do-review.py',
 'design/phase22/contextual-do.md',
 'selfhost/build/phase22/context-do-source-01/manifest.json',
 'selfhost/build/phase22/context-do-source-01/project/src/front/sugar.bend',
 'selfhost/build/phase22/context-do-source-01/project/src/front/contextual.bend',
 'selfhost/build/phase22/context-do-build-01/attempt.json',
 'selfhost/build/phase22/context-do-build-01/equality/api.mjs',
 'selfhost/.bootstrap/upstream-phase8/bend2/bend.ts',
 'selfhost/tools/performance/phase22/context-controls-do-direct.mjs',
 'selfhost/tools/performance/phase22/context-controls-do-direct-v2.mjs',
 'selfhost/build/phase22/context-controls-do-direct-01/report.json',
 'selfhost/build/phase22/context-controls-do-direct-02/report.json',
 'selfhost/build/phase22/context-controls-do-direct-02/frozen-cases.json',
 'selfhost/build/phase22/context-controls-do-inputs-01/selection.json',
 'selfhost/build/phase22/context-controls-do-baseline-01/report.json',
 'selfhost/build/phase22/context-controls-do-raw-candidate-01/report.json',
 'selfhost/build/phase22/context-controls-do-raw-candidate-01/selected/paired.json',
]
findings=[
 {'id':'ordering','status':'pass-by-inspection-and-controls','detail':'The do owner parses a RHS before opening its binder, stops on a shallow Error/Unsupported result, opens the binder for its continuation only, restores the outer lexical environment, then resolves the generated .bind/.pure call. The first returned failure is preserved.'},
 {'id':'header','status':'pass-by-inspection','detail':'The header resolves against the supplied declaration scope, fills leading datatype quantity arguments through the existing f_adt owner before the colon, and retains the written monad name for separately resolved generated calls. Terminal values retain their own range and ADT-versus-call annotation distinction.'},
 {'id':'locations','status':'pass-bounded','detail':'Five private helper controls compare canonical terms including source begin/end coordinates, final fresh counters and restored environments against pinned parse_term. Typed assignment/bind controls call the real f_do_value owner with pinned parsed prefix terms and a real FContextual seed; they do not claim that the unfinished full grammar route works.'},
 {'id':'raw-api','status':'pass-bounded','detail':'The unchanged public do20 selection improves 17 to 19 exact observations without loss. Both malformed-RHS observations now preserve the pinned parser error instead of failing host range validation. The old imported Box.Id check failure remains. Raw selectedComplete remains false.'},
 {'id':'unported-contextual-grammar','status':'integration-required','detail':'The frozen ablation retains the old contextual admission barriers, including <\u002d in f_context_grow. One direct control records this as Unsupported, not a semantic match. The private wrapper is an append-only derivative of the checked API and is not a public API.'},
 {'id':'marked-binder-quantity','status':'integration-required','detail':'Pinned parse_bind gives marked names Many. Frozen f_context_open returns quantity1, so enabling marked do syntax requires the shared opening owner to preserve quantity. Root reports that behavior has made that correction in mutable shared source03; this review neither rebinds the frozen ablation nor validates that later source.'},
 {'id':'setup-failure','status':'preserved','detail':'Private attempt01 failed before rows because the probe supplied FLocatedSource.inner instead of the actual generated field source. Fresh v2 fixes that field and the unconsumed f_do_value wrapper arity from8 to7. Original tool, extension and failure report remain unchanged.'},
]
report={'kind':'phase22-contextual-do-independent-review','complete':True,'pass':True,'promotionReady':False,'passMeaning':'Bounded isolated-owner review and specified controls passed; whole contextual grammar and marked-quantity integration remain pending.','pin':'b2111cf43244e65f76ddc278ee695e669f720cbf','api':public['api'],'publicControls':{'observations':20,'parentExact':17,'candidateExact':19,'gainedExact':public['comparison']['gainedExact'],'lostExact':[],'rawSelectedComplete':public['selected']['selectedComplete'],'remaining':'Actual imported Box.Id header check; parse is exact.'},'privateControls':{'rows':6,'semanticMatches':5,'explicitUnsupported':1,'rowsSummary':[{'id':x['id'],'pass':x['pass'],'unsupported':x.get('unsupported',False),'notConformance':x.get('notConformance',False)} for x in direct['rows']],'unchangedApiPrefix':direct['extension']['prefixUnchanged'],'setupFailurePreserved':True},'findings':findings,'inputs':[ident(x) for x in paths],'jobsClosed':True,'sourceEdits':False,'limitations':['Public do20 uses the retained raw production route and does not establish contextual parser conformance.','Three private owner cases seed their already-parsed prefix from pinned parsing to isolate the actual continuation/open/close owner.','No new backend executions, full main corpus, aliases in direct contextual mode, or marked-quantity integration were performed here.']}
out.write_text(json.dumps(report,indent=2)+'\n')
md.write_text('''# Phase22 contextual do review

The isolated do owner has no blocker within this bounded review. It is not ready for production activation until the surrounding contextual grammar and marked-binder quantity path are validated.

The frozen ablation is `context-do-source-01`, checked attempt `context-do-build-01`, API `5631e1072dadd4c1cd7548b5475803f578f8ac6ef1714b3683206057faca2f4a`. The oracle is pinned TypeScript `b2111cf43244e65f76ddc278ee695e669f720cbf`, especially `parse_term_do_stmt`, `parse_bind`, `parse_fill` and `parse_call`.

The owner follows the pinned order: parse RHS, open binder, parse continuation, close scope, resolve the generated call. It short-circuits returned errors. Header lookup uses the real declaration scope and existing datatype quantity filling. The terminal annotation retains the term's range and resolves the family/call distinction separately.

The unchanged public 20-observation selection improves from 17 to 19 exact matches, with no lost exact results or new primitive mismatch. Both malformed typed-RHS observations now preserve the pinned parser error rather than producing `Invalid compiler source range`. The imported `Box.Id` check remains different on the retained raw route. Its raw selected suite is still false; the acquisition/comparison wrapper passes.

Private direct attempt02 has five exact semantic matches: return, terminal constructor annotation, typed bind, typed assignment, and anonymous bind. It compares canonical pinned terms including retained source coordinates, final fresh counters and restored environment. The three continuation-owner cases use actual `FContextual` state and parsed prefix terms produced by the pin, then call the genuine generated `f_do_value` helper. This isolates the owner without claiming full parser admission. A sixth observation records the inherited `<-` grammar barrier as Unsupported and is not a conformance pass. The extension appends private exports to an unchanged checked API prefix.

Marked binders remain an integration requirement: pinned `parse_bind` selects Many while the frozen ablation's `f_context_open` produces quantity1. Root reports that the shared source03 already corrects that common owner; these controls do not validate or relabel that later source. Direct contextual alias handling and complete marked grammar need the subsequent integrated gate.

Private attempt01 failed during setup before any semantic rows because the harness used `FLocatedSource.inner` instead of generated field `source`. It is preserved. A fresh v2 also corrects the private wrapper arity from eight to seven before consuming it. No compiler source or checked API was edited. All owned probe processes are closed. The JSON companion binds the exact tools, inputs, attempts and result records.
''')
print(json.dumps({'complete':True,'pass':True,'report':ident(str(out.relative_to(root))),'markdown':ident(str(md.relative_to(root)))},indent=2))

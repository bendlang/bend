#!/usr/bin/env python3
"""Bind the completed Phase20 release gates without rewriting their raw statuses."""
import hashlib,json
from pathlib import Path
from datetime import datetime
R=Path(__file__).resolve().parents[4]; P=R/'selfhost/build/phase20'
inputs=[]
def identity(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def read(p):
 inputs.append(identity(p));return json.loads(Path(p).read_text())
owner=read(R/'implementation/phase20/import-diagnostic-final.json')
audit=read(P/'declaration-integration-audit-03/report.json')
census=read(P/'declaration-census-01.json')
matrix=read(P/'declaration-matrix-01/report.json')
promotion=read(P/'declaration-promotion-03/report.json')
smoke=read(P/'declaration-smoke-01/launcher.json')
review=read(R/'implementation/phase20/declaration-checkpoints-review.json')
programs=read(P/'declaration-programs-01/report.json')
release=read(R/'selfhost/dist/release.json')
build=read(P/'import-diagnostic-build-04/build.json')
validation=read(P/'import-diagnostic-build-04/validation-001/report.json')
for d in [owner,audit,promotion,smoke,review,programs,validation]:assert d['complete'] and d['pass']
api=owner['api']['sha256'];assert api=='40c8f7f3b7cd0e96aef57d7d574ebfd85607cd4e096909d083b450b4d973362c'
assert release['files'][0]['sha256']==api and smoke['expectedApi']==api
assert matrix['complete'] and not matrix.get('error') and matrix['unsafeDefinitionSetsAgree']
assert matrix['variants']['candidate']['api']['sha256']==api
checks=read(smoke['checks']['file'])
assert identity(smoke['checks']['file'])['sha256']==smoke['checks']['sha256']
assert smoke['steps']==42 and checks['pass'] and len(checks['steps'])==42
assert audit['frontend']['changes']==[] and audit['groups']['afterExact']==136
for n in ['declaration-integration-audit-01','declaration-integration-audit-02','declaration-promotion-01','declaration-promotion-02']:
 d=read(P/n/'report.json');assert d['pass'] is False
for n in ['matrix.json','host-review.json','readiness.json']:read(P/'declaration-matrix-inputs-01'/n)
inputs.append(identity(__file__))
seconds=lambda a,b:(datetime.fromisoformat(b.replace('Z','+00:00'))-datetime.fromisoformat(a.replace('Z','+00:00'))).total_seconds()
loop={'buildSeconds':seconds(build['started'],build['finished']),'validation36Seconds':seconds(validation['started'],validation['finished']),'elapsedBuildStartThroughValidationSeconds':seconds(build['started'],validation['finished']),'scope':'One observed checked B1/derived build and36-control edit loop, concurrent environment; not a controlled performance comparison or full self-reproduction.'}
report={'kind':'phase20-declaration-checkpoints-release','complete':True,'pass':True,'installedApi':api,'checkedParent':release['lineage']['checkedParentSha256'],'sourceSha256':release['sourceSha256'],'upstream':release['lineage']['upstreamRevision'],'sourceChanges':owner['changedFiles'],'delta':owner['deltaPhase19'],'census':{k:v for k,v in census.items()if k!='inputs'},'focused':{k:owner[k] for k in ['default36','decorator24','constructor50','firstElement54','whitespace44','supplied39','orderedHost43']},'frontend':audit['frontend'],'groups':audit['groups'],'programExecutionObservations':12,'cliChecks':42,'statistics':matrix['statistics'],'ratios':matrix['ratios'],'timingDecision':'Neutral cost screen; no measured slowdown or new speedup claim. Two samples perimage, not statistical evidence of a general gain.','observedEditLoop':loop,'retainedFailures':['Source02 semicolon regression; source03 superseded with same datatype checkpoint','Audit01 raw complete/health conflation','Audit02 candidate-only provenance compared with absent TS metadata','Promotion01 canonicalPath schema mismatch;0copied','Promotion02 supplied/host API lives in inputs;0copied','Original grouped raw runner incomplete/false with60 remaining strict differences'],'remaining':'Main2 do-block diagnostic observations; broader60 group/pattern/etc observations, including3 failed fixture verdicts. Suites overlap and must not be summed. No new fixedpoint, kernel, GPU or generated-program speed claim.','inputs':inputs}
out=R/'implementation/phase20/declaration-checkpoints-release.json';out.write_text(json.dumps(report,indent=2)+'\n')
s=matrix['statistics']; ratios=matrix['ratios'];fmt=lambda k:f"{s[k]['meanProcessWallMs']/1000:.4f}"
text=f'''# Declaration checkpoints release

Installed source04 / `import-diagnostic-build-04`, API `{api}`,
genuine checked parent `{report['checkedParent']}`, targets unchanged upstream
`{report['upstream']}`. The [machine report](declaration-checkpoints-release.json)
binds the installed source, review, complete result comparisons and cost window.

Only `src/front/declarations.bend` changes: **17 additional physical lines,
one function and1,110 bytes**, with no new law, datatype, semantic state, host,
runtime, cache ABI or transformation. Source totals **15,897 physical /13,543
nonblank lines,577,003 bytes,59 modules,1,660 definitions,719 laws and67 types**.
Phase19's single live checker and exact-prefix repair remain installed. The
larger contextual parser is still private.

## Behavior and independent challenge

Pending `@unsafe` reports the pinned structured expectation for `def`. A datatype
constructor begins at a name head, with `def`/`type`/`law` ending that loop;
indentation and immediate lookahead for `{{` no longer decide constructor admission.
The shared owner validates name, import alias, duplicate name and opening brace
in that order. Whitespace/comments are accepted there, semicolons are preserved
for rejection. The datatype loop hands its already-spaced cursor to `f_top`.
Global semicolon handling is unchanged.

Match heads and row patterns require their first term before accepting `:` or
skipping a comma. Two constant-time `List.is_empty` checks enforce that boundary.
Later optional commas keep the pinned behavior. No growing-list count, separate
parser or diagnostic rewrite is added.

Independent review caught an intermediate false acceptance: source02 used
`f_skip`, which also consumes semicolons. Its15 newly false-accepted observations
and9 inherited adjacent acceptance observations are retained across raw/supplied/
host routes. Source04 uses existing `f_space` at the brace and both datatype-loop
feeds, and calls `f_top` on loop exit. Source02/03 were never installed. See the
[owner report](import-diagnostic-final.md) and [review](declaration-checkpoints-review.md).

## Validation

| Selection | Earlier exact | Final exact |
|---|---:|---:|
| Maintained development controls |34/36|36/36|
| Decorator/import boundaries |4/24|24/24|
| Constructor name/brace boundaries |18/50|50/50|
| Match first-element boundaries |42/54|54/54|
| Expanded datatype whitespace boundaries (source01) |6/44|44/44|
| Original broader group selection |128/196|136/196|

These are overlapping observations and routes, not disjoint program counts.
Original supplied39 and ordered-host43 have zero strict differences. Three new
positive programs pass check/interpreter/JavaScript/native comparisons (**12/12**)
and produce41/42/43; see [execution evidence](declaration-programs.md).
All **42 installed/relocated CLI checks** pass.

The main2996-result vector is unchanged in its entirety; its two known do-block
first-diagnostic differences remain. The broader196 has exactly eight changed
parse/check observations across four saved empty-head fixtures, all newly exact,
with no lost match or changed reference result. Six also correct primitive
acceptance evidence. It retains60 strict differences and three failed fixture
verdicts (monad check and grouped body-comma parse/check).

Raw harness flags remain unchanged: the grouped runner is incomplete/false after
its strict selected-completion assertion, despite all196 observations collected
without worker failures/timeouts. The main raw vectors retain their same five
fixture verdict failures. Acquisition, pinned agreement and strict fixture
contracts are separate axes; the independent regression audit does not relabel
these reports. Earlier backend41, literal20, chronology22 and memo/history gates
remain evidence for Phase19; they were not all rerun or relabeled as Phase20.

## Controlled cost and iteration loop

Fresh CPU0 processes run serially TS/B/C/C/B/TS on identical final source, with
4 MiB stack/4 GiB heap and all other compiler/probe/hash/archive jobs held.
All35 host files, Base, runtime, pin and version5 transformation are unchanged.
Bend uses separate validated Base caches; TypeScript checks Base. OS caches were
not flushed. No program emission is timed; all six type/trust observations and
unsafe-definition sets agree.

| Image | Mean process seconds | Mean request seconds | Peak RSS KiB |
|---|---:|---:|---:|
| TypeScript |{fmt('typescript')}|{s['typescript']['meanRequestMs']/1000:.4f}|{s['typescript']['maxRssKiB']}|
| Installed Phase19 baseline |{fmt('baseline')}|{s['baseline']['meanRequestMs']/1000:.4f}|{s['baseline']['maxRssKiB']}|
| Phase20 candidate |{fmt('candidate')}|{s['candidate']['meanRequestMs']/1000:.4f}|{s['candidate']['maxRssKiB']}|

The process difference is **{ratios['candidateProcessReduction']*100:.2f}% lower**;
request difference **{ratios['candidateRequestReduction']*100:.2f}% lower**, peak RSS
**{(s['candidate']['maxRssKiB']/s['baseline']['maxRssKiB']-1)*100:.2f}% higher**. This is
**neutral**, not a new speedup claim. The same-window TypeScript gap is
**{ratios['baselineToTs']:.4f}→{ratios['candidateToTs']:.4f}×** (about3.17×).
Two samples per image do not establish a general performance improvement.

The final checked build took{loop['buildSeconds']:.2f}s and maintained36 validation
{loop['validation36Seconds']:.2f}s: **{loop['elapsedBuildStartThroughValidationSeconds']:.2f}s**
from build start through focused validation. That is one observed edit loop,
not a controlled benchmark; broad regression, execution and cost gates ran once
the candidate was coherent. No new full self-reproduction was required.

## Retained integration failures and next boundary

Audit01 wrongly equated the raw `complete` flag with acquisition health; audit02
compared candidate-only host metadata with absent TypeScript metadata. Audit03
checks the unchanged paired behavior protocol against raw data, plus complete
old/new candidate payloads and acquisition/identity health. No fixture or oracle
changed. Promotion01/02 copied zero files; their tooling assumed different
identity/API report schemas. Promotion03 verifies each actual schema and installs
one file. Original tools and reports remain alongside the successful attempts.

The next bounded [group-boundary design](../../design/phase21/group-boundaries.md)
tests a first-binder source-range correction for three remaining observations.
The two grouped-comma acceptance differences require preserving completed-group
and error order; a raw tag guard would reject a valid nested tuple. Do not add
flattener changes that have demonstrated no gain on the remaining60.

Root commits this usable release locally. Remote publication remains blocked by
the earlier automatic approval review; no push success is claimed. Full conformance,
independent proof-kernel/GPU coverage and a new self-hosted fixed point remain open.
'''
(R/'implementation/phase20/declaration-checkpoints-release.md').write_text(text)
print(json.dumps({'complete':True,'api':api,'groupsExact':136,'cli':42,'observedEditLoop':loop}))

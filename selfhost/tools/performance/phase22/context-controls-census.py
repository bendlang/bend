#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,collections
R=Path(__file__).resolve().parents[4];O=R/'selfhost/build/phase22/context-controls-census-01';O.mkdir()
def identity(p):
 p=Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
file=R/'selfhost/build/phase21/group-range-group196-02/selected/paired.json';d=json.loads(file.read_text());assert len(d['rows'])==196
categories=collections.defaultdict(list)
for row in d['rows']:
 if row['exactAgreement']:continue
 name=row['id']
 if name in ['check/monad_do_destructure.bend','parser-checkpoint/do-frame']:cat='do-completion-before-outer-pattern-and-orphan-return'
 elif name=='marked-pattern/term-remains-unbound':cat='marked-empty-call-source-range'
 elif name.startswith('marked-pattern/'):cat='marked-name-family-admission'
 elif name in ['empty-call-pattern/offload-bound','group/local-bang']:cat='offload-head-name-classification'
 elif name=='group/body-comma':cat='raw-body-vs-completed-group-comma'
 elif name=='group/match-error-before-close':cat='group-flatten-before-close'
 elif name.startswith('parser-checkpoint/'):cat='local-pattern-before-continuation-with-real-scope'
 elif name.startswith('rejected-stage/'):cat='row-body-and-group-flatten-checkpoint-order'
 else:raise AssertionError(name)
 categories[cat].append(row)
assert sum(map(len,categories.values()))==57 and len({r['id'] for rs in categories.values() for r in rs})==29
counts={c:len(v) for c,v in categories.items()};assert sorted(counts.values())==[1,2,2,4,4,8,10,26]
r={'kind':'phase22-remaining-production-census','complete':True,'pass':True,'scope':'Classification of the exact Phase21 broader196 vector; categories are source-based interpretations, not measured future gains.','observations':196,'exact':139,'remainingObservations':57,'remainingFixtures':29,'remainingPrimitiveDifferences':sum(not r['semanticAgreement'] for v in categories.values() for r in v),'categories':[{'category':c,'observations':len(v),'fixtures':sorted({r['id'] for r in v}),'rows':v} for c,v in categories.items()],'estimate':{'immediateLocalRowGroupOwnerCeiling':38,'requiresAdditionalMarkedOffloadDoOwners':18,'separateMarkedCallRange':1,'claim':'All57 are plausibly reachable by a complete correctly staged parser migration plus explicit call-range preservation; private Stage4 alone does not support all required owners. No conformance or performance promise. Main two do diagnostics overlap this collection; C1 and independent grouped-constructor acceptances add nonidentical boundaries. Full2996+broader196+C1+independent program/acceptance vectors must all close before claiming this observed frontier closed.'},'inputs':[identity(__file__),identity(file),identity(R/'design/phase19/saved-row-group-frontier.md'),identity(R/'design/phase21/group-boundaries.md'),identity(R/'implementation/phase21/group-comma.json')]}
(O/'report.json').write_text(json.dumps(r,indent=2)+'\n');(R/'implementation/phase22/context-controls-census.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps({'counts':counts,'primitiveDifferences':r['remainingPrimitiveDifferences'],'fixtures':29,'observations':57}))

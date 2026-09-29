#!/usr/bin/env python3
"""Close the immutable first production acquisition; keep failed oracle guards."""
from pathlib import Path
import json,hashlib
R=Path.cwd();O=R/'implementation/phase22/context-controls-production-01.json';assert not O.exists()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
parts={};inputs=[ident(__file__)];bound={};apis=set()
for name,count,parent in [('main',60,27),('do',20,17),('feature',40,29),('alias',4,0)]:
 d=R/f'selfhost/build/phase22/context-controls-production-{name}-01';r=json.loads((d/'report.json').read_text());p=json.loads((d/'selected/paired.json').read_text());assert len(p['rows'])==count and not p.get('missing') and not p.get('error');assert r['selected']['exactDifferences']==sum(not x['exactAgreement'] for x in p['rows']);assert r['comparison']
 for rec in [*r['inputs'],r['api'],r['attempt'],r['cache']]:
  old=bound.setdefault(rec['file'],rec);assert old['sha256']==rec['sha256']
 apis.add(r['api']['sha256']);inputs += [ident(d/'report.json'),ident(d/'selected/paired.json')]
 parts[name]={'observations':count,'baselineExact':parent,'candidateExact':count-r['selected']['exactDifferences'],'originalReportComplete':r['complete'],'originalReportPass':r['pass'],'rawSelectedComplete':p['selectedComplete'],'gainedExact':r['comparison']['gainedExact'],'lostExact':r['comparison']['lostExact'],'newPrimitiveMismatch':r['comparison']['newPrimitiveMismatch'],'strictDifferences':[x['id']+'@'+x['lane'] for x in p['rows'] if not x['exactAgreement']]}
assert len(apis)==1
for rec in bound.values():
 assert ident(rec['file'])['sha256']==rec['sha256'],rec['file']
 if 'canonicalPath' in rec:assert str(Path(rec['file']).resolve())==rec['canonicalPath']
report={'kind':'phase22-first-production-control-closure','complete':True,'pass':False,'acquisitionComplete':True,'candidateSelected':False,'passMeaning':'All124 frozen observations and exact reference/parent comparisons are captured; selection fails because the unchanged comparison guards found regressions. Failed component reports remain unchanged.','apiSha256':next(iter(apis)),'attempt':'selfhost/build/phase22/context-build-04','source':'selfhost/build/phase22/context-source-05/project','observations':124,'baselineExact':sum(x['baselineExact'] for x in parts.values()),'candidateExact':sum(x['candidateExact'] for x in parts.values()),'gainedExact':sum(len(x['gainedExact']) for x in parts.values()),'lostExact':sum(len(x['lostExact']) for x in parts.values()),'parts':parts,'findings':['Main monad_destructure both lanes and do-frame now exact; unfinished grouped body comma forms still accepted, with one newly changed check outcome violating the pin.','Do alias fixture regresses at return type Box.Id<U32>, before its do body: expected colon at final greater-than token. Both parse/check now fail parse.','All rewrite controls exact; Nat/U32/Succ and namespace-before-count fixed; written Array.set positive now parses/checks.','Nonvariable Array.set statement keeps inherited error cursor gap: semicolon consumed before reporting next-line0.','Real alias ambiguity now has structured exact expected/observed fields but retains wrong caret, at operator rather than completed delimiter checkpoint.'],'executionsHeld':'Unchanged24/12 execution controls are frozen with baselines but not run on this image because production acceptance boundaries and imported header regression remain unresolved.','postAcquisitionIdentityAudit':{'pass':True,'uniqueInputIdentities':len(bound)},'inputs':inputs}
O.write_text(json.dumps(report,indent=2)+'\n');O.with_suffix('.md').write_text('''# First Phase22 production controls

The first production candidate is withheld. All 124 frozen observations were acquired against `context-build-04` / source05; 108 are exact versus 73 on the installed baseline (36 gains, one lost exact match). The original main/do comparison reports remain failed. A separate read-only closing audit confirms all consumed input, API, attempt and cache hashes are unchanged.

| Cohort | Parent exact | Candidate exact | Outcome |
| --- | ---: | ---: | --- |
| Original60 | 27 | 52 | Guard fails on a changed false-acceptance outcome |
| Do20 | 17 | 18 | Imported return-type parse regression; one lost exact |
| Rewrite/array40 | 29 | 38 | No regression; two inherited diagnostic differences |
| Alias4 | 0 | 0 | Correct refusal, wrong caret |

Both maintained monad-destructuring observations are now exact. Scope checkpoints and constructor-pattern refusals improve. The remaining grouped raw local/parallel comma forms must still refuse; current candidate accepts them. Local-bang error wording also differs. The imported `Box.Id<U32>` return annotation now refuses at `>` expecting `:`, before entering the do body.

Rewrite controls all agree. U32 count refusal, explicit Succ count acceptance, namespace-before-count order and written Array.set binding now agree. Nonvariable Array.set followed by semicolon still points at the following statement instead of the semicolon. Alias ambiguity now has the correct expected/observed fields but points after the operator rather than after `]`.

The original prospective fixture assumptions and raw false statuses are preserved. The 24/12 program baselines remain frozen; candidate execution waits for these production acceptance boundaries to close. No compiler source or oracle was edited by this owner.
''');print(json.dumps({'complete':True,'pass':False,'observations':124,'exact':report['candidateExact'],'report':ident(O)}))

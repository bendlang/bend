#!/usr/bin/env python3
from pathlib import Path
import hashlib,json
R=Path.cwd();out=R/'implementation/phase22/context-controls-constructor-index.json';assert not out.exists()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
inputs=[ident(__file__)];dfile=R/'selfhost/build/phase22/context-controls-ctor-index-01/report.json';d=json.loads(dfile.read_text());assert d['complete'] and d['pass'];assert d['summary']['count']==42 and not d['summary']['failures'];inputs += [ident(dfile),ident(d['results']['file'])]
for item in d['inputs']:
 for record in item.values():assert ident(record['file'])['sha256']==record['sha256'];inputs.append(ident(record['file']))
for a in d['artifacts']:
 assert a['unchangedPrefix']
 for key in ['attempt','api','verifier','probe']:
  record=a[key];assert ident(record['file'])['sha256']==record['sha256'];inputs.append(ident(record['file']))
parts=[]
for label in ['parent','candidate']:
 p=R/f'selfhost/build/phase22/context-controls-ctor-index-public-{label}-01/report.json';r=json.loads(p.read_text());assert r['complete'] and r['pass'] and r['selected']['exactDifferences']==0;assert r['selected']['candidate']['probes']==24
 assert r['api']['sha256']==next(a['api']['sha256'] for a in d['artifacts'] if a['label']==label)
 for item in [*r['inputs'],r['api'],r['attempt'],r['cache']]:assert ident(item['file'])['sha256']==item['sha256'];inputs.append(ident(item['file']))
 inputs += [ident(p),ident(p.parent/'selected/paired.json')];parts.append({'label':label,'api':r['api'],'observations':24,'exact':24,'report':ident(p),'rawReferenceSummary':r['selected']['reference'],'rawCandidateSummary':r['selected']['candidate'],'referenceOracleFailures':r['selected']['referenceOracleFailures']})
 if label=='candidate':assert all(not r['comparison'][k] for k in ['lostExact','gainedExact','changedCandidatePrimitive','newPrimitiveMismatch'])
report={'kind':'phase22-independent-constructor-index-closure','complete':True,'pass':True,'direct':{'cases':42,'counts':d['summary']['counts'],'report':ident(dfile),'preservedOriginalReferenceIdentity':True,'exactMissingPayload':True,'scopedDemand':'Initial index construction intentionally traverses the finite immutable metadata forest once. Two demand controls establish no type/value payload reads and no later old-list traversal; no arbitrary effectful-getter or raw early-exit equivalence claim.'},'public':parts,'scope':'New constructor-only scope index factory/lookup and actual declaration publication, compared with source16 original recursive helpers and unchanged pinned public fixtures. Pure arbitrary nested KDef books preserve first-DFS constructor semantics. Incremental qualification/alias and partial/complete headers preserve old scopes. No proof-authentication, general index-consumer or performance claim.','inputs':inputs}
out.write_text(json.dumps(report,indent=2)+'\n');out.with_suffix('.md').write_text('''# Constructor-only contextual index controls

All42 independent compiled-helper controls pass against the authentic source16 recursive parent. All24 unchanged public parse/check observations match pinned TypeScript exactly on both parent and source17 candidate; no reference, primitive result or exact match changed.

The26 initial forests cover first-depth-first selection, duplicate reference identity and full payload, constructors nested under arbitrary kinds (including cache-like containers), constructor-head precedence over descendants, exact hash collisions, Unicode names,4096-wide and512-deep inputs. Six publication histories cover empty/complete ADTs, ordinary-header index reuse, newest-prefix duplicates, namespace/alias qualification and unchanged older scopes. Eight controls compare the complete existing pattern-owner Maybe/Error results and origins. Two demand controls confirm construction avoids term payloads and subsequent lookup avoids the original forest's list cells.

Construction intentionally reads the complete finite immutable metadata forest. This is not a claim of the recursive lookup's old early-exit getter behavior, arbitrary host-object safety or IR authentication. The candidate API prefix is unchanged by separately hashed append-only probe exports. Correctness and measured cost remain separate gates; this report does not select or promote the candidate.
''');print(json.dumps({'complete':True,'pass':True,'report':ident(out)}))

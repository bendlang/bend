#!/usr/bin/env python3
"""Classify retained exact differences; normalization is only descriptive."""
import collections, hashlib, json, pathlib, re, sys
ROOT=pathlib.Path(__file__).resolve().parents[4]
SRC=ROOT/'selfhost/build/phase12/frontend-03/reference-comparison.json'
OUT=pathlib.Path(sys.argv[1]).resolve()
if OUT.exists(): raise SystemExit('Refuse existing output')
obj=json.loads(SRC.read_text()); rows=obj['changes']
carets=lambda s: re.sub(r'\n *\|[ \t]*\^+', '', s or '')
snippet=lambda s: re.sub(r'\n(?: *\d+[ >]\|[^\n]*| *\|[^\n]*)', '', s or '')
ignore={'verdict','evidence','diagnostic'}
def group(r):
 a,b=r['before'],r['after']; ad,bd=a['diagnostic'] or '',b['diagnostic'] or ''
 if any(a[k]!=b[k] for k in a if k not in ignore): return 'non-diagnostic-result-axis'
 if ad!=bd and carets(ad)==carets(bd): return 'caret-line-only'
 if ad!=bd and snippet(ad)==snippet(bd): return 'source-snippet-only'
 if bd.startswith('SOME PROOFS FAIL\nError: match requires an unconsumed parameter') or bd.startswith('Error: match requires an unconsumed parameter'): return 'computed-match-legacy-message'
 if ad.split('\nLocation:')[0]==bd.split('\nLocation:')[0]: return 'location-or-span-difference'
 if '- observed :' in ad and '- observed :' in bd and ad.split('- observed :')[0]==bd.split('- observed :')[0]: return 'same-expectation-other-observation-or-detail'
 if bd.startswith('SOME PROOFS FAIL\nError:') and '\n- ' not in bd: return 'legacy-unstructured-check-error'
 return 'other-diagnostic-shape'
classified=[dict(r,cluster=group(r)) for r in rows]
groups=[]
for name,rs in __import__('itertools').groupby(sorted(classified,key=lambda r:r['cluster']),lambda r:r['cluster']):
 rs=list(rs); groups.append({'cluster':name,'observations':len(rs),'fixtures':len({r['id'] for r in rs}),'lane':dict(collections.Counter(r['lane'] for r in rs)),'phasePairs':[{'lane':k[0],'referencePhase':k[1],'candidatePhase':k[2],'count':v} for k,v in collections.Counter((r['lane'],r['before']['phase'],r['after']['phase']) for r in rs).items()],'examples':[{'id':r['id'],'lane':r['lane']} for r in rs[:8]]})
ident=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
report={'kind':'phase14-retained-exact-difference-census','complete':True,'comparison':ident(SRC),'reference':ident(pathlib.Path(obj['before']['file'])),'candidate':ident(pathlib.Path(obj['after']['file'])),'tool':ident(pathlib.Path(__file__).resolve()),'method':'Classify all original exact comparison changes. Caret/snippet normalization is clustering only; original strings, verdicts and every compared axis are retained below. No pass/fail expectation is modified. Clusters describe output shapes; causal attribution requires code inspection.','observations':len(rows),'fixtures':len({r['id'] for r in rows}),'lanes':dict(collections.Counter(r['lane'] for r in rows)),'groups':groups,'rows':classified}
assert len(rows)==730 and len({r['id'] for r in rows})==532
OUT.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'observations':report['observations'],'fixtures':report['fixtures'],'groups':groups},indent=2))

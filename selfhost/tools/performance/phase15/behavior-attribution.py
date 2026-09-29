"""Independent exact-output attribution from the three immutable frontend vectors."""
import pathlib,json,hashlib,collections,re
root=pathlib.Path(__file__).resolve().parents[4]
paths={'reference':root/'selfhost/build/phase8/reference-frontend-01/reference.json','baseline':root/'selfhost/build/phase14/frontend-audit-02/candidate.json','candidate':root/'selfhost/build/phase15/frontend-01/candidate.json'}
raw={k:json.loads(p.read_text()) for k,p in paths.items()}
fields=['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode']
def key(r):return r['id'],r['lane']
def observation(r):
 x=r['result'];return {'verdict':r['status'],'evidence':r.get('evidence'),**{k:x.get(k) for k in fields},'diagnostic':x.get('diagnostic'),'output':x.get('output',x.get('stdout'))}
vectors={label:{key(r):observation(r) for r in value['results']} for label,value in raw.items()}
assert all(len(x)==2996 for x in vectors.values()) and vectors['reference'].keys()==vectors['baseline'].keys()==vectors['candidate'].keys()
for r in raw.values():
 assert len(r['inventory']['tests'])==1498 and r['finished'] and not r['changedInputs'] and not r['identity']['changedArtifacts'] and not r['identity']['adapterChangedDuringRun']
 assert all(not w['errors'] and not w['stats']['failures'] and not w['stats']['timeouts'] for w in r['workers'])
 assert r['inventory']['revision']=='b2111cf43244e65f76ddc278ee695e669f720cbf'
assert [(t['id'],t['sha256']) for t in raw['reference']['inventory']['tests']]==[(t['id'],t['sha256']) for t in raw['candidate']['inventory']['tests']]
reference,baseline,candidate=(vectors[k] for k in ['reference','baseline','candidate'])
marker=lambda line:bool(re.fullmatch(r'[ \t]*\|[ \t]*\^+[ \t]*',line))
withoutCarets=lambda text:'\n'.join(line for line in (text or '').split('\n') if not marker(line))
withoutSnippet=lambda text:'\n'.join(line for line in (text or '').split('\n') if not re.match(r'^[ \t]*(?:\d+[ >]\||\|)',line))
semantic=fields+['output']
changed=lambda a,b:[k for k in a if a[k]!=b[k]]
missing={'import/cross_file_io.bend','import/cross_file_proof.bend','import/cycle_terminates.bend','import/diamond_dedup.bend','import/path_canonical.bend'}
invalidPaths={'import/dotted_path.bend','import/hub_head_local.bend','import/hub_head_path.bend','import/tilde_path.bend'}
new=[];lost=[];nonexact=[];remaining=[]
for k in sorted(reference):
 r,b,c=reference[k],baseline[k],candidate[k];row={'id':k[0],'lane':k[1]}
 if b!=r and c==r:
  if k[0] in missing:
   group='missing-import-context';assert b['phase']=='load' and c['phase']=='parse'
  elif k[0]=='parse/prefix_operator_dead.bend':
   group='erased-binder-plus-parser-caret';assert c['phase']=='parse' and c['status']=='error' and not c['checked']
  else:
   group='parser-caret-only';assert c['phase']=='parse' and all(b[x]==c[x] for x in semantic) and withoutCarets(b['diagnostic'])==withoutCarets(c['diagnostic'])
  new.append({**row,'group':group,'changedAxes':changed(b,c)})
 if b==r and c!=r:lost.append({**row,'changedAxes':changed(b,c)})
 if b!=c and c!=r:
  if k[0] in invalidPaths:
   group='illegal-local-path-correct-phase';assert b['phase']=='load' and c['phase']=='parse'
  else:
   group='parser-caret-added-existing-gap';assert c['phase']=='parse' and all(b[x]==c[x] for x in semantic) and withoutCarets(b['diagnostic'])==withoutCarets(c['diagnostic'])
  nonexact.append({**row,'group':group,'changedAxes':changed(b,c)})
 if c!=r:
  rd,cd=r['diagnostic'] or '',c['diagnostic'] or ''
  if any(r[x]!=c[x] for x in semantic):group='non-diagnostic-result-axis'
  elif withoutCarets(rd)==withoutCarets(cd):group='caret-width-or-position-only'
  elif withoutSnippet(rd)==withoutSnippet(cd):group='source-snippet-only'
  elif cd.startswith('SOME PROOFS FAIL\nError: match requires an unconsumed parameter') or cd.startswith('Error: match requires an unconsumed parameter'):group='computed-match-legacy-message'
  elif rd.split('\nLocation:')[0]==cd.split('\nLocation:')[0]:group='location-or-span-difference'
  elif '- observed :' in rd and '- observed :' in cd and rd.split('- observed :')[0]==cd.split('- observed :')[0]:group='same-expectation-other-observation-or-detail'
  elif cd.startswith('SOME PROOFS FAIL\nError:') and '\n- ' not in cd:group='legacy-unstructured-error'
  else:group='other-diagnostic-shape'
  remaining.append({**row,'group':group,'changedAxes':changed(r,c),'referencePhase':r['phase'],'candidatePhase':c['phase']})
counts=lambda rows:dict(collections.Counter(x['group'] for x in rows))
assert sum(baseline[k]!=reference[k] for k in reference)==603
assert len(new)==144 and not lost and len(remaining)==459 and len(nonexact)==74
assert counts(new)=={'parser-caret-only':132,'missing-import-context':10,'erased-binder-plus-parser-caret':2}
assert not any(x['group']=='non-diagnostic-result-axis' for x in remaining)
# Independently reconstructed observations must reproduce the maintained exact comparison.
comparison=json.loads((root/'selfhost/build/phase15/frontend-01/reference-comparison.json').read_text())
assert {(x['id'],x['lane']) for x in comparison['changes']}=={(x['id'],x['lane']) for x in remaining}
assert all(reference[(x['id'],x['lane'])]==x['before'] and candidate[(x['id'],x['lane'])]==x['after'] for x in comparison['changes'])
def summary(rows):return {'observations':len(rows),'fixtures':len({x['id'] for x in rows}),'lanes':dict(collections.Counter(x['lane'] for x in rows))}
report={'kind':'phase15-independent-exact-difference-attribution','complete':True,'pass':True,'inputs':[{'role':k,'file':str(p.relative_to(root)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for k,p in paths.items()]+[{'role':'tool','file':str(pathlib.Path(__file__).resolve().relative_to(root)),'sha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest()}],'method':'Reconstruct every compared observation directly from reference, baseline and final raw vectors; preserve exact strings/paths and all comparison fields. Cross-check the resulting difference set against the maintained strict comparison only after independent construction. Marker/snippet removal is used solely to classify causes/shapes, never to decide exact conformance.','exactBefore':603,'exactAfter':459,'newExact':{**summary(new),'groups':counts(new),'rows':new},'lostExact':lost,'changedStillNonexact':{**summary(nonexact),'groups':counts(nonexact),'rows':nonexact},'remaining':{**summary(remaining),'groups':[{'group':g,**summary([x for x in remaining if x['group']==g])} for g in sorted(counts(remaining))],'differingAxisCounts':dict(collections.Counter(a for x in remaining for a in x['changedAxes'])),'nonDiagnosticResultDifferences':0,'rows':remaining},'scope':['All2996 measured frontend observations agree on status, phase, checked/type-acceptance/trust/kernel metadata, unsafe-definition list, exit and output.','Diagnostic text and diagnostic-dependent harness verdict/evidence remain different; this does not prove identical rejection causes or universal language semantics.','The2 malformed-binder rows require both the binder fix and the independent caret renderer to become exact.','Cycle fixes are separately established by16 dedicated observations; no pinned-corpus cycle result is credited here.','No frontend gain is attributed to the lookup speed patch.']}
out=root/'implementation/phase15/exact-differences.json';assert not out.exists();out.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'new':report['newExact']['groups'],'nonexactChanged':report['changedStillNonexact']['groups'],'remaining':report['remaining']['groups'],'axes':report['remaining']['differingAxisCounts'],'remainingSummary':summary(remaining)},indent=2))

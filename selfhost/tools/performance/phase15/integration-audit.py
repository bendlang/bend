import hashlib,json,pathlib,sys
history_file,backend_dir,out=map(pathlib.Path,sys.argv[1:])
identity=lambda p:{'file':str(p.resolve()),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
read=lambda p:json.loads(p.read_text())
h=read(history_file);b=read(backend_dir/'report.json');pairs=read(backend_dir/'selected/paired.json');prior=read(pathlib.Path('selfhost/build/phase14/backend-01/selected/paired.json'))
assert h['complete'] and h['pass'] and h['inputsVerified'] and h['exactPairedCompleteResults']
assert b['complete'] and b['pass'] and b['selected']['selectedComplete']
assert len(pairs['rows'])==41 and pairs['selectedComplete']
rows=[]
for history in h['histories']:
 a,z=history['rows'];assert a['complete'] and z['complete'] and len(a['requests'])==len(z['requests'])
 for i,(x,y)in enumerate(zip(a['requests'],z['requests'])):
  assert x['result']==y['result'] and x['index']==i and y['index']==i
  assert x['worker']['generation']==1 and y['worker']['generation']==1
 changes=[]
 for x in a['changedFromPhase12']:
  old,new=x['oldResult'],x['currentResult'];fields=[k for k in sorted(set(old)|set(new)) if (k in old)!=(k in new) or old.get(k)!=new.get(k)]
  assert set(fields)<=set(['diagnostic','hostProvenance']),fields
  changes.append({'index':x['index'],'id':x['id'],'lane':x['lane'],'fields':fields})
 rows.append({'history':history['name'],'pairedObservations':2*len(a['requests']),'changedFromPhase12':changes,'diagnosticChanges':sum('diagnostic'in x['fields'] for x in changes)})
lookup=lambda r:(r['id'],r['lane'])
old={lookup(r):r for r in prior['rows']};assert len(old)==41
for r in pairs['rows']:
 assert r['referenceVerdict'] in ['pass','not-applicable'] and r['candidateVerdict'] in ['pass','not-applicable']
 assert not old[lookup(r)]['exactAgreement'] or r['exactAgreement'],'Lost exact backend match '+str(lookup(r))
imports=[r for r in pairs['rows'] if r['id']=='p14/imported-dependent-fill'];assert len(imports)==4
for r in imports:
 assert r['exactAgreement']
 if r['lane'] in ['interpreter','js','native']:assert r['candidate']['output'].strip()=='5n'
executed=[]
for variant in ['reference','candidate']:
 raw=read(backend_dir/'selected'/f'{variant}.json')
 for r in raw['results']:
  if r['lane']=='native' and r['result']['phase']=='runtime' and r['result']['status']=='ok':
   result=r['result'];assert result['nativeBuild']['compiler']['version']==16
   assert result['exitCode']==0 and result.get('signal') is None
   executed.append({'variant':variant,'id':r['id'],'output':result.get('output',result.get('stdout')),'nativeBuild':result['nativeBuild']})
assert executed and any(r['id']=='p14/imported-dependent-fill'for r in executed)
report={'kind':'phase15-final-history-and-backend-audit','complete':True,'pass':True,'scope':'Scoped current paired history identity and backend execution audit, not timing/full frontend or universal correctness. Historical comparison classifies changes without normalizing current paired results.','inputs':[identity(p)for p in [pathlib.Path(__file__),history_file,backend_dir/'report.json',backend_dir/'selected/paired.json',pathlib.Path('selfhost/build/phase14/backend-01/selected/paired.json'),backend_dir/'selected/reference.json',backend_dir/'selected/candidate.json']],'history':rows,'backend':{'pairedRows':len(pairs['rows']),'exactDifferences':[{'id':r['id'],'lane':r['lane']}for r in pairs['rows']if not r['exactAgreement']],'lostExactMatches':0,'nativeExecutions':executed,'importedDependentFillLanes':[r['lane'] for r in imports]}}
with out.open('x') as f:json.dump(report,f,indent=2);f.write('\n')
print(json.dumps({'complete':True,'pass':True,'historyPaired':sum(r['pairedObservations']for r in rows),'backendRows':len(pairs['rows']),'backendExactDifferences':len(report['backend']['exactDifferences']),'actualNativeExecutions':len(executed)}))

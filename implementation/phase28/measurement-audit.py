from pathlib import Path
import json,hashlib,math,statistics,sys,subprocess,datetime
ROOT=Path('/home/ai/bend2/build/publish/bend'); B=ROOT/'selfhost/build/phase28'; T=ROOT/'selfhost/tools/performance/phase28'
FINAL='--final' in sys.argv
LONG='--long' in sys.argv
WINDOW='timing-long-01' if LONG else 'timing-01'
CONFIG='timing-long-config.json' if LONG else 'timing-config.json'
WARM_CALLS,WARM_MS=(100,3000) if LONG else (3,1000)
fail=[];checks=0;identities={};artifacts={};intervals=[];processes=[];rawpaths=set()
def ck(condition,label):
 global checks
 checks+=1
 if not condition:fail.append(label)
def read(p):return json.loads(Path(p).read_text())
def ident(p):
 p=Path(p); data=p.read_bytes();v={'file':str(p),'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data)};artifacts[str(p)]=v;return v

def verify(v):
 p=Path(v['file']);key=str(p)
 if key not in identities:identities[key]=ident(p)
 now=identities[key];ck(now['sha256']==v['sha256'],'identity sha '+key)
 if 'bytes' in v:ck(now['bytes']==v['bytes'],'identity bytes '+key)
 return now

def close(a,b):return math.isclose(a,b,rel_tol=1e-12,abs_tol=1e-9)
def stats(a):return {'median':statistics.median(a),'min':min(a),'max':max(a),'values':a}
def dump(p,data):p.write_text(json.dumps(data,indent=2)+'\n')
sourceproof=[]
for name in ['six-cases.json','raytrace-retry.json','raytrace-typed-retry.json']:
 m=read(T/name)
 for c in m['cases']:
  origin=c['source'];b=subprocess.check_output(['git','show',origin['commit']+':'+origin['path']],cwd=ROOT);fixture=(ROOT/c['fixture']['path']).read_bytes()
  ck(hashlib.sha256(b).hexdigest()==origin['sha256'],'Git source SHA '+name+c['id'])
  ck(hashlib.sha1(b'blob '+str(len(b)).encode()+b'\x00'+b).hexdigest()==origin['gitBlob'],'Git blob identity '+name+c['id'])
  ck(fixture==b+c['wrapper'].encode(),'unchanged original plus wrapper '+name+c['id'])
  ck(hashlib.sha256(fixture).hexdigest()==c['fixture']['sha256'],'frozen fixture SHA '+name+c['id'])
  sourceproof.append({'manifest':name,'id':c['id'],'origin':origin,'fixture':c['fixture'],'unchangedPrefixAndExactWrapper':True})
for c in read(T/'application-cases.json')['cases']:
 origin=c['origin'];b=subprocess.check_output(['git','show',origin['commit']+':'+origin['path']],cwd=ROOT);fixture=(ROOT/c['source']).read_bytes()
 ck(fixture==b and hashlib.sha256(b).hexdigest()==origin['sha256'],'unchanged application source '+c['id'])
 sourceproof.append({'manifest':'application-cases.json','id':c['id'],'origin':origin,'unchangedSource':True})
acquisition_outcomes=[]
for name in ['runtime-01','runtime-02-raytrace','runtime-03-raytrace','applications-01']:
 a=read(B/name/'report.json');ck(a['complete'],'acquisition campaign recorded '+name)
 for c in a['cases']:
  for side,v in c['variants'].items():
   acquisition_outcomes.append({'attempt':name,'id':c['id'],'side':side,'emission':v['emission']['complete'],'execution':v.get('execution',{}).get('complete',False),'emissionError':v['emission'].get('result',{}).get('error'),'executionError':v.get('execution',{}).get('result',{}).get('error'),'module':v['emission'].get('result',{}).get('output')})
originalconfig=read(B/'timing-config.json');allcfgs={c['id']:c for c in originalconfig['cases']}
config=read(B/CONFIG); cfgs={c['id']:c for c in config['cases']}
for c in config['cases']:ck(c==allcfgs[c['id']],'unchanged config '+c['id'])
report=read(B/WINDOW/'report.json'); completed=[c for c in report['cases'] if c['complete']]
if FINAL:ck(report['complete'] and report['allCasesMeasured'],'library campaign complete');ck(len(completed)==len(config['cases'])==(4 if LONG else 10),'all planned library cases')
ck([c['id'] for c in report['cases']]==[c['id'] for c in config['cases'][:len(report['cases'])]],'case order')
for i in report['inputs']:verify(i)
prov=read(B/'library-provenance.json');ck(prov['complete'],'library provenance complete')
for v in prov['inputs']:verify(v)
ck([c['id'] for c in prov['cases']]==[c['id'] for c in originalconfig['cases']],'provenance cases exact')
for c in prov['cases']:
 cfg=allcfgs[c['id']];verify(c['source']);ck(c['source']['file']==cfg['source'],'source path '+c['id'])
 for k in ['args','expected','exportName','modules']:ck(c[k]==cfg[k],'provenance '+c['id']+' '+k)
 for side,v in c['receipts'].items():
  verify(v);e=read(v['file']);ck(e['complete'] and e.get('checked',e.get('observation',{}).get('checked')),'checked emission '+c['id']+side)
  verify(e['input']);verify(e['output']);ck(e['input']['sha256']==c['source']['sha256'],'identical source '+c['id']+side)
  ck(e['output']['file']==cfg['modules'][side],'output path '+c['id']+side)
  if side=='selfhost':
   for k in ['api','runtime','base','driver','attempt']:verify(e[k])
   ck(e['api']['sha256']=='5a89c775e903374341da4b4e32c29d26ffe687677f088c590046f748b69d81c5','candidate API '+c['id'])
   ck(e['runtime']['sha256']=='40823818afd57a6c37e055272dc332f461955a7cd225f67d66194f0d43ec823f','candidate runtime '+c['id'])
   ck(Path(e['output']['file']).read_bytes().startswith(Path(e['runtime']['file']).read_bytes()),'bundled runtime '+c['id'])

node='/home/ai/.nvm/versions/node/v24.18.0/bin/node';flags=['--stack-size=4096','--max-old-space-size=1024'];exe=str(B/(WINDOW+'.execute.mjs') if LONG else T/'execute.mjs')
if LONG:
 deriv=read(B/(WINDOW+'.derivation.json'))
 for k in ['originalRunner','originalLauncher','runner','launcher']:verify(deriv[k])
 orig=Path(deriv['originalRunner']['file']).read_text();actual=Path(deriv['runner']['file']).read_text()
 ck(actual==orig.replace('report.warmup<3||performance.now()-warm<1000','report.warmup<100||performance.now()-warm<3000'),'exact followup runner derivation')
 orig=Path(deriv['originalLauncher']['file']).read_text();actual=Path(deriv['launcher']['file']).read_text()
 derived=orig.replace('HERE=Path(__file__).resolve().parent','HERE=Path('+repr(str(T))+')').replace("HERE/'execute.mjs'",'Path('+repr(exe)+')').replace('then>=3 calls AND1000ms warmup','then>=100 calls AND3000ms warmup')
 ck(actual==derived,'exact followup launcher derivation')
def audit_block(r,value,label):
 n=r['repetitions'];ck(isinstance(n,int) and n>=1,'block reps '+label)
 ck(r['checksum']==(value*n)%(2**32),'block checksum '+label)
 ck(r['executionMs']>=0,'block nonnegative '+label)
 hs=r['halves'];ck([h['calls'] for h in hs]==([n//2,n-n//2] if n>1 else [n]),'half counts '+label)
 ck(all(h['ms']>=0 for h in hs),'half time positive '+label)
 ck(sum(h['ms'] for h in hs)<=r['executionMs']+1e-8,'halves contained '+label)

def audit_process(c,side,mode,embedded,directory):
 directory=Path(directory); label=f"{c['id']}/{side}/{mode}/{directory.name}"
 launch=read(directory/'launch.json');rawpaths.add(str(directory));ck({k:v for k,v in embedded.items() if k not in ['variant','repetition']}==launch,'embedded launch '+label)
 for f in ['launch.json','stdout.log','stderr.log']:ident(directory/f)
 raw=(directory/'stdout.log').read_text().splitlines();ck(len(raw)==1,'single JSON stdout '+label)
 result=json.loads(raw[-1]);ck(result==launch['result'],'raw stdout result '+label)
 ck((directory/'stderr.log').read_bytes()==b'','stderr empty '+label)
 ck(launch['exitCode']==0 and launch['complete'] and result['complete'],'successful process '+label)
 cp=B/WINDOW/c['id']/('point.json' if mode!='time' else side+'.json')
 expectedcmd=['taskset','-c','3',node,*flags,exe,mode,c['modules'][side],str(cp)]
 ck(launch['command']==expectedcmd,'command '+label);ck(launch['timeoutSeconds']==120,'deadline '+label)
 ck(result['mode']==mode and result['node']=='v24.18.0' and result['args']==flags,'runtime identity '+label)
 ck(result['affinity'].split(':')[1].strip()=='3','reported affinity '+label)
 cfg=read(cp);ck(result['config']==cfg,'config exact '+label);ck(result['configSha256']==ident(cp)['sha256'],'config hash '+label)
 ck(result['toolSha256']==identities[exe]['sha256'],'tool hash '+label)
 ck(result['module']['file']==c['modules'][side],'module path '+label);verify(result['module'])
 ck(result['firstResult']==c['expected'],'first output '+label)
 for k in ['args','expected','exportName']:ck(cfg[k]==c[k],'point '+label+' '+k)
 for k in ['firstCallMs','importMs']:ck(result[k]>=0,'time positive '+label+' '+k)
 accounted=result['firstCallMs']+result['importMs']
 if mode!='check':
  ck(result['warmup']>=WARM_CALLS and result['warmupMs']>=WARM_MS,'warm floors '+label);accounted+=result['warmupMs']
  value=len(c['expected'].encode('utf-16-le'))//2 if isinstance(c['expected'],str) else c['expected']
  audit_block(result,value,label)
  if mode=='calibrate':
   trials=result['trials'];ck([r['repetitions'] for r in trials]==[2**i for i in range(len(trials))],'calibration doubling '+label)
   for i,r in enumerate(trials):
    audit_block(r,value,label+f'/trial{i}')
    if i<len(trials)-1:ck(r['executionMs']<100 and r['repetitions']<65536,'calibration continuation '+label)
   last=trials[-1];ck(last['executionMs']>=100 or last['repetitions']>=65536,'calibration stop '+label)
   for k in ['repetitions','executionMs','checksum','halves']:ck(last[k]==result[k],'calibration final '+label+' '+k)
   accounted+=sum(x['executionMs'] for x in trials)
  else:ck(cfg['repetitions']==result['repetitions'],'fixed sample count '+label);accounted+=result['executionMs']
 ck(accounted<=launch['processSeconds']*1000+1,'process covers phases '+label)
 intervals.append({'label':label,'started':launch['started'],'finished':launch['started']+launch['processSeconds']})
 processes.append({'label':label,'directory':str(directory),'stdoutSha256':artifacts[str(directory/'stdout.log')]['sha256'],'processSeconds':launch['processSeconds']})
 return result
summaries=[];drifts=[]
for row in completed:
 c=cfgs[row['id']];d=B/WINDOW/c['id'];ck(row['point']=={k:c[k] for k in ['args','expected','exportName']},'row point '+c['id'])
 ck(set(row['checks'])==set(row['calibration'])=={'upstream','selfhost'},'two checks and calibrations '+c['id'])
 ck([(s['repetition'],s['variant']) for s in row['samples']]==[(i,s) for i in range(5) for s in (['upstream','selfhost'] if i%2==0 else ['selfhost','upstream'])],'sample rotation '+c['id'])
 sides={}
 for side in ['upstream','selfhost']:
  audit_process(c,side,'check',row['checks'][side],d/(side+'-check'))
  cal=audit_process(c,side,'calibrate',row['calibration'][side],d/(side+'-calibrate'))
  reps=max(1,min(1000000,math.ceil(300*cal['repetitions']/cal['executionMs'])))
  ck(read(d/(side+'.json'))['repetitions']==reps,'calibration target formula '+c['id']+side)
  rr=[audit_process(c,side,'time',s,d/f"{s['repetition']}-{side}") for s in row['samples'] if s['variant']==side]
  times=[r['executionMs']/r['repetitions'] for r in rr];first=[r['firstCallMs'] for r in rr]
  summary={'warmMsPerCall':stats(times),'firstCallMs':stats(first),'repetitions':reps,
   'warmupCalls':[r['warmup'] for r in rr],'warmupMs':[r['warmupMs'] for r in rr],
   'measuredBlockMs':[r['executionMs'] for r in rr],'importMs':[r['importMs'] for r in rr],
   'peakRssKiB':[r['peakRssKiB'] for r in rr],'halves':[]}
  for i,r in enumerate(rr):
   h=r['halves']
   if len(h)==2:
    ratio=(h[1]['ms']/h[1]['calls'])/(h[0]['ms']/h[0]['calls'])
    value={'sample':i,'secondOverFirstPerCall':ratio,'firstHalfMsPerCall':h[0]['ms']/h[0]['calls'],'secondHalfMsPerCall':h[1]['ms']/h[1]['calls']};summary['halves'].append(value)
    if ratio<.9 or ratio>1.1:drifts.append({'case':c['id'],'side':side,**value})
  stored=row['sides'][side]
  for key,val in [('medianMs',statistics.median(times)),('minMs',min(times)),('maxMs',max(times)),('firstCallMedianMs',statistics.median(first))]:ck(close(stored[key],val),'recomputed '+c['id']+side+key)
  ck(stored['samplesMs']==times and stored['firstCallSamplesMs']==first,'all samples retained '+c['id']+side)
  sides[side]=summary
 ratio=sides['selfhost']['warmMsPerCall']['median']/sides['upstream']['warmMsPerCall']['median'];cold=sides['selfhost']['firstCallMs']['median']/sides['upstream']['firstCallMs']['median']
 ck(close(row['ratio'],ratio) and close(row['firstCallRatio'],cold),'ratios '+c['id'])
 summaries.append({'id':c['id'],'category':c['category'],'args':c['args'],'expected':c['expected'],'sides':sides,'selfhostOverUpstreamWarmed':ratio,'selfhostOverUpstreamFirstCall':cold})
 if FINAL:ck(set(str(x.parent) for x in d.glob('*/launch.json'))==set(p for p in rawpaths if Path(p).parent==d),'no omitted process dirs '+c['id'])
# Complete application uses original emitted CJS/ESM modules and process wall time.
application=None;af=B/'application-timing-01/report.json'
if af.exists() and not LONG:
 ar=read(af);ac=read(B/'application-timing-config.json');ck(ar['config']==ac,'application frozen config')
 for v in ar['inputs']:verify(v)
 for side in ['upstream','selfhost']:
  v=ac['variants'][side];verify(v['program']);verify(v['original']);ck(Path(v['program']['file']).read_bytes()==Path(v['original']['file']).read_bytes(),'application output unchanged '+side)
 if ar['complete']:
  ck(ar['allSamplesValid'] and len(ar['samples'])==10,'all ten application samples')
  ck([(s['sample'],s['side']) for s in ar['samples']]==[(i,s) for i in range(5) for s in (['upstream','selfhost'] if i%2==0 else ['selfhost','upstream'])],'application rotation')
  for row in ar['samples']:
   side=row['side'];p=af.parent/f"{row['sample']:02}-{side}.json";ck(read(p)==row,'application raw launch '+str(p));ident(p)
   ck(row['command']==['taskset','-c','3',node,*flags,ac['variants'][side]['program']['file']],'application command '+str(p));ck(row['timeoutSeconds']==120,'application timeout')
   for k in ['stdout','stderr']:verify(row[k])
   ck(Path(row['stdout']['file']).read_bytes()==ac['expectedStdout'].encode(),'application exact stdout '+str(p));ck(Path(row['stderr']['file']).read_bytes()==b'','application empty stderr '+str(p))
   ck(row['complete'] and row['exactStdout'] and row['emptyStderr'] and row['returncode']==0 and not row.get('timeout',False),'application success '+str(p))
   ck(abs(row['finished']-row['started']-row['elapsedSeconds'])<.05,'application wall clocks '+str(p))
   intervals.append({'label':str(p),'started':row['started'],'finished':row['finished']});processes.append({'label':str(p),'processSeconds':row['elapsedSeconds']})
  application={'scope':ar['timingScope'],'sides':{}}
  for side in ['upstream','selfhost']:
   vals=[r['elapsedSeconds'] for r in ar['samples'] if r['side']==side];s=stats(vals);application['sides'][side]=s
   for k,a in [('medianSeconds',s['median']),('minSeconds',s['min']),('maxSeconds',s['max'])]:ck(close(ar['summary'][side][k],a),'application summary '+side+k)
  rat=application['sides']['selfhost']['median']/application['sides']['upstream']['median'];ck(close(ar['summary']['selfhostOverUpstream'],rat),'application ratio');application['selfhostOverUpstream']=rat
  if FINAL:ck(len(list(af.parent.glob('[0-9][0-9]-*.json')))==10,'no omitted application launches')
 if FINAL:ck(ar['complete'],'application campaign complete')
elif FINAL and not LONG:ck(False,'application campaign exists')
intervals.sort(key=lambda r:r['started']);overlap=[]
for a,b in zip(intervals,intervals[1:]):
 if a['finished']>b['started']+.005:overlap.append([a,b])
ck(not overlap,'no observed child overlap')
if FINAL:
 ident(B/WINDOW/'report.json');ident(B/'library-provenance.json');ident(B/CONFIG)
 if not LONG:ident(af);ident(B/'application-timing-config.json')
result={'kind':'phase28-independent-measurement-audit','complete':FINAL,'window':WINDOW,'warmupCallsFloor':WARM_CALLS,'warmupMsFloor':WARM_MS,'status':'PASS' if not fail else 'FAIL','auditedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'checks':checks,'failures':fail,'libraryCasesCompleted':len(completed),'libraryTimingSamples':10*len(completed),'libraryChecks':2*len(completed),'libraryCalibrations':2*len(completed),'applicationTimingSamples':10 if application else 0,'processCount':len(processes),'sourcePreservation':sourceproof,'acquisitionOutcomes':acquisition_outcomes,'library':summaries,'application':application,'halvesBeyondTenPercent':drifts,'observedOverlap':overlap,'identities':list(identities.values()),'rawArtifacts':list(artifacts.values()),'processes':processes,'limitations':['Five observations per variant; observed ranges, not statistical confidence intervals.','Same warmup rule does not prove JIT convergence; first calls, warmup and timed halves remain separately reported.','Single-repetition measurements cannot provide two timing halves.','No observed child overlap is not proof of physical-machine isolation.','Complete application wall time includes each emitted format native CommonJS/ESM startup; not pure evaluator throughput.','Library checksums are complete observable scalar outputs, not independent per-element verification.']}
p=Path('/tmp/phase28-audit-'+WINDOW+('-final' if FINAL else '-partial')+'.json');dump(p,result)
print(json.dumps({'status':result['status'],'checks':checks,'failures':fail,'cases':len(completed),'processes':len(processes),'ratios':[(r['id'],r['selfhostOverUpstreamWarmed'],r['selfhostOverUpstreamFirstCall']) for r in summaries],'drift':drifts,'application':application},indent=2))

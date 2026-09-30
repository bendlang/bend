#!/usr/bin/env python3
"""Independent audit of closed Phase29 timing campaigns; executes no programs."""
from pathlib import Path
import hashlib,json,math,statistics,sys
out=Path(sys.argv[1]).resolve()
assert not out.exists(),out
paths=[Path(p).resolve() for p in sys.argv[2:]]
assert paths
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
checked={}
checks=0
def require(condition,message):
    global checks
    checks+=1
    if not condition:raise AssertionError(message)
def verify(item):
    p=Path(item['file']);expected=item['sha256']
    require(p.exists(),str(p)+' exists')
    if str(p) not in checked:checked[str(p)]=sha(p)
    require(checked[str(p)]==expected,str(p)+' hash')
summary={'kind':'phase29-independent-measurement-audit','complete':False,'pass':False,'tool':{'file':str(Path(__file__).resolve()),'sha256':sha(__file__)},'campaigns':[],'warnings':[]}
all_intervals=[]
try:
  for filename in paths:
    report=json.loads(filename.read_text());root=filename.parent
    require(report['kind']=='phase29-paired-generated-execution',str(filename)+' kind')
    require(report['complete'] and report['allCasesMeasured'],str(filename)+' completed all cases')
    for item in report['inputs']:verify(item)
    protocol=report['protocol'];cfg=json.loads(Path(report['inputs'][0]['file']).read_text())
    require(len(cfg['cases'])==len(report['cases']),'all configured cases retained')
    campaign={'report':{'file':str(filename),'sha256':sha(filename)},'processes':0,'timedSamples':0,'wallSeconds':report['wallSeconds'],'cases':[]}
    summary['campaigns'].append(campaign)
    for c,definition in zip(report['cases'],cfg['cases']):
      require(c['id']==definition['id'],'case identity')
      require(c['complete'] and c['status']=='measured','case complete')
      sides=list(definition['modules']);require(set(c['sides'])==set(sides),'all sides retained')
      require(len(c['samples'])==protocol['samples']*len(sides),'exact sample count')
      require(c['point']['args']==definition['point']['args'],'same input arguments')
      require(c['point']['expected']==definition['point']['expected'],'same expected result')
      case={'id':c['id'],'sides':{},'halfDrift':[]};campaign['cases'].append(case)
      processes=[]
      for side in sides:
        for mode,key in [('check','checks'),('calibrate','calibration')]:processes.append((side,mode,c[key][side],root/c['id']/(side+'-'+mode)/'launch.json'))
      expected_order=[]
      for index in range(protocol['samples']):
        order=sides[index%len(sides):]+sides[:index%len(sides)]
        expected_order.extend((side,index) for side in order)
      require([(x['variant'],x['repetition']) for x in c['samples']]==expected_order,'rotating serial order')
      for sample in c['samples']:
        processes.append((sample['variant'],'time',sample,root/c['id']/(str(sample['repetition'])+'-'+sample['variant'])/'launch.json'))
      for side,mode,process,launch_file in processes:
        launch=json.loads(launch_file.read_text());result=process['result'];command=process['command']
        require({k:v for k,v in process.items() if k not in ['variant','repetition']}==launch,'launch report exact')
        require(json.loads((launch_file.parent/'stdout.log').read_text().splitlines()[-1])==result,'raw stdout exact')
        require(process['complete'] and process['exitCode']==0 and result['complete'],'child success')
        require(command[:3]==['taskset','-c','3'],'pinned launch CPU')
        require(result['affinity'].split(':')[1].strip()=='3','observed CPU')
        require(result['node']=='v24.18.0','Node version')
        require(result['args']==['--stack-size=4096','--max-old-space-size=1024'],'observed resource flags')
        require(process['timeoutSeconds']==protocol['timeout'],'deadline')
        require(result['mode']==mode and command[-3]==mode,'mode')
        require(result['module']['file']==str(Path(definition['modules'][side]).resolve()),'module identity')
        verify(result['module']);verify({'file':command[-1],'sha256':result['configSha256']});verify({'file':command[-4],'sha256':result['toolSha256']})
        require(result['config']==json.loads(Path(command[-1]).read_text()),'exact child configuration')
        require(result['config']['args']==c['point']['args'] and result['config']['expected']==c['point']['expected'],'child input/oracle')
        require(result['firstResult']==c['point']['expected'],'first complete output')
        require(result['firstCallMs']>=0 and result['importMs']>=0,'separate first/import measurement')
        if mode!='check':
          require(result['warmup']>=protocol['warmupCalls'] and result['warmupMs']>=protocol['warmupMs'],'both warmup floors')
          trials=result['trials'] if mode=='calibrate' else [result]
          for trial in trials:
            n=trial['repetitions'];expected=c['point']['expected'];v=len(expected) if isinstance(expected,str) else expected
            require(trial['checksum']==(n*v)%4294967296,'complete-call checksum')
            require(sum(h['calls'] for h in trial['halves'])==n,'half counts')
            require(0<sum(h['ms'] for h in trial['halves'])<=trial['executionMs']+0.001,'half timing containment')
          if mode=='calibrate':
            require([x['repetitions'] for x in trials]==[2**i for i in range(len(trials))],'calibration doubling')
            require(result['executionMs']>=protocol['calibrationMs'] or result['repetitions']>=65536,'calibration stopping rule')
          else:
            calibration=c['calibration'][side]['result'];n=max(1,min(1000000,math.ceil(protocol['targetMs']*calibration['repetitions']/calibration['executionMs'])))
            require(result['repetitions']==n,'fixed calibrated repetitions')
            campaign['timedSamples']+=1
            if len(result['halves'])==2:
              a,b=result['halves'];ratio=(b['ms']/b['calls'])/(a['ms']/a['calls'])
              if abs(ratio-1)>0.10:case['halfDrift'].append({'side':side,'sample':process['repetition'],'secondToFirst':ratio})
        all_intervals.append((process['started'],process['started']+process['processSeconds'],str(launch_file)))
        campaign['processes']+=1
      for side in sides:
        samples=[s['result'] for s in c['samples'] if s['variant']==side]
        times=[s['executionMs']/s['repetitions'] for s in samples];first=[s['firstCallMs'] for s in samples];reported=c['sides'][side]
        require(reported['samplesMs']==times,'all individual per-call samples')
        for name,value in [('medianMs',statistics.median(times)),('minMs',min(times)),('maxMs',max(times)),('firstCallMedianMs',statistics.median(first))]:require(reported[name]==value,'recomputed '+name)
        case['sides'][side]={'medianMs':statistics.median(times),'firstCallMedianMs':statistics.median(first),'minMs':min(times),'maxMs':max(times)}
      if case['halfDrift']:summary['warnings'].append({'campaign':str(filename),'case':c['id'],'reason':'Within-block drift over 10%; do not equate this warmup window with convergence.','observations':case['halfDrift']})
  all_intervals.sort()
  for a,b in zip(all_intervals,all_intervals[1:]):require(a[1]<=b[0]+0.002,'timing children do not overlap: '+a[2]+' / '+b[2])
  summary['complete']=True;summary['pass']=True
except Exception as error:
  summary['error']=repr(error)
summary['checks']=checks;summary['distinctHashedFiles']=len(checked)
out.write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({'complete':summary['complete'],'pass':summary['pass'],'checks':checks,'distinctHashedFiles':len(checked),'campaigns':len(summary['campaigns']),'error':summary.get('error')}))
sys.exit(0 if summary['pass'] else 1)

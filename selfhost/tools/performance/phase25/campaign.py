#!/usr/bin/env python3
"""Bounded, serial paired acquisition. Every attempt uses a new directory."""
from pathlib import Path
import hashlib, json, math, os, statistics, subprocess, sys, time

ROOT=Path(__file__).resolve().parents[4]
SH=ROOT/'selfhost'; TOOLS=Path(__file__).resolve().parent
NODE=Path(os.environ.get('PHASE25_NODE','/home/ai/.nvm/versions/node/v24.18.0/bin/node'))
PIN='018751270e800bc222a93dad7f257083ee53a5f7'
API='7b523bdffc0acde702dda1005a5e8201f7b65b2e432d1be95b07f2cfcc0346fa'
FLAGS=['--stack-size=4096','--max-old-space-size=1024']
ENV={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def ident(p):return {'file':str(Path(p).resolve()),'sha256':sha(p),'bytes':Path(p).stat().st_size}
def save(p,value):Path(p).write_text(json.dumps(value,indent=2)+'\n')
def git(*args,cwd=ROOT):return subprocess.check_output(['git',*args],cwd=cwd,text=True).strip()

def child(args,directory,timeout=15):
    directory.mkdir()
    command=['taskset','-c','3',str(NODE),*FLAGS,*map(str,args)]
    row={'command':command,'timeoutSeconds':timeout,'complete':False,'started':time.time()}
    save(directory/'launch.json',row);start=time.monotonic()
    try:
        with (directory/'stdout.log').open('w') as a,(directory/'stderr.log').open('w') as b:
            p=subprocess.run(command,cwd=SH,env=ENV,stdout=a,stderr=b,timeout=timeout)
        row['exitCode']=p.returncode
        text=(directory/'stdout.log').read_text().strip().splitlines()
        if text:
            try:row['result']=json.loads(text[-1])
            except ValueError:pass
        row['complete']=p.returncode==0 and row.get('result',{}).get('complete',False)
    except Exception as e:row['error']=str(e)
    row['processSeconds']=time.monotonic()-start;save(directory/'launch.json',row)
    return row

def verify(inputs):
    changed=[p for p in inputs if sha(p['file'])!=p['sha256']]
    assert not changed,changed

def acquire(out):
    out.mkdir(parents=True,exist_ok=False)
    upstream=SH/'.bootstrap/upstream-phase23'
    assert git('rev-parse','HEAD',cwd=upstream)==PIN
    assert not git('status','--porcelain',cwd=upstream)
    assert sha(SH/'dist/typed-api.mjs')==API
    cases=json.loads(subprocess.check_output([str(NODE),str(TOOLS/'corpus.mjs')],env=ENV,text=True))
    files=[NODE,Path(__file__),TOOLS/'emit.mjs',TOOLS/'execute.mjs',TOOLS/'corpus.mjs',TOOLS/'corpus/metadata.json',SH/'dist/release.json',ROOT/'design/phase25/generated-code-analysis.md']
    files += [TOOLS/c['relativeFile'] for c in cases]
    release=json.loads((SH/'dist/release.json').read_text())
    files += [SH/x['path'] for k in ['files','checkout'] for x in release[k]]
    files += list(sorted((upstream/'bend2').glob('*.ts')))+[upstream/'bend2/base.bend']
    inputs=[ident(p) for p in dict.fromkeys(files)]
    plan={'kind':'phase25-paired-generated-corpus','pin':PIN,'sourceHead':git('rev-parse','HEAD'),'api':API,'node':ident(NODE),'inputs':inputs,'cases':cases,'resourcePolicy':{'cpu':3,'nodeArgs':FLAGS,'emissionDeadlineSeconds':120,'runtimeDeadlineSeconds':15},'entries':[],'observations':[],'complete':False}
    save(out/'manifest.json',plan)
    for c in cases:
        case=out/c['id'];case.mkdir()
        combined={}
        # De-duplicate runtime probes; an independent expected checksum takes priority.
        points={}
        for p in c['inputs']+c.get('benchmarkInputs',[])+c.get('correctness',[]):points[(p['size'],p['seed'])]={**points.get((p['size'],p['seed']),{}),**p}
        save(case/'check-config.json',{'inputs':list(points.values()),'exportName':c.get('exportName','bench')})
        for side in ['upstream','selfhost']:
            module=case/(side+'.mjs')
            emission=child([TOOLS/'emit.mjs',side,c['file'],module],case/(side+'-emission'),120)
            entry={'id':c['id'],'variant':side,'family':side,'mode':'library','path':str(module.relative_to(out)),'runtimePath':str(SH/'src/runtime.mjs') if side=='selfhost' else None,'mechanismFamily':c['family'],'sourceSha256':sha(c['file'])}
            observation={'id':c['id'],'variant':side,'emission':emission}
            if emission['complete']:
                entry.update(sha256=sha(module),bytes=module.stat().st_size);plan['entries'].append(entry)
                checked=child([TOOLS/'execute.mjs','check',module,case/'check-config.json'],case/(side+'-check'))
                observation['execution']=checked
                if checked['complete']:combined[side]=checked['result']['results']
            plan['observations'].append(observation);save(out/'manifest.json',plan)
        exact=len(combined)==2 and combined['upstream']==combined['selfhost']
        paired={'id':c['id'],'exact':exact,'results':combined}
        save(case/'paired.json',paired)
        print(json.dumps({'id':c['id'],'exact':exact}),flush=True)
    verify(inputs)
    plan['inputsUnchanged']=True
    plan['complete']=all(json.loads((out/c['id']/'paired.json').read_text())['exact'] for c in cases)
    save(out/'manifest.json',plan)

def calibrate(corpus,out):
    out.mkdir(parents=True,exist_ok=False)
    m=json.loads((corpus/'manifest.json').read_text());verify(m['inputs'])
    assert m['complete'],'Fix/report correctness failures before comparative timing'
    plan={'kind':'phase25-frozen-runtime-schedule','corpus':ident(corpus/'manifest.json'),'harness':[ident(TOOLS/'execute.mjs'),ident(Path(__file__))],'samplesPerSide':5,'warmup':8,'cases':[],'complete':False,'calibration':[]}
    for c in m['cases']:
        checked=json.loads((corpus/c['id']/'paired.json').read_text())['results']['upstream']
        known={(p['size'],p['seed']):p['result'] for p in checked}
        # Inputs are explicitly selected by the corpus author, not fastest survivors.
        for i,p in enumerate(c.get('benchmarkInputs',c['inputs'])):
            key=f"{c['id']}-{i}";case=out/key;case.mkdir()
            config={**p,'expected':known[(p['size'],p['seed'])],'exportName':c.get('exportName','bench'),'warmup':8}
            save(case/'config.json',config);cost=[]
            for side in ['upstream','selfhost']:
                row=child([TOOLS/'execute.mjs','calibrate',corpus/c['id']/(side+'.mjs'),case/'config.json'],case/side)
                plan['calibration'].append({'key':key,'variant':side,**row});save(out/'schedule.json',plan)
                assert row['complete'],f'Calibration failed: {key}/{side}'
                r=row['result'];cost.append(r['executionMs']/r['repetitions'])
            config['repetitions']=max(1,min(1000000,math.ceil(150/max(cost))))
            config['repetitionsBySide']={side:max(1,min(1000000,math.ceil(150/ms))) for side,ms in zip(['upstream','selfhost'],cost)}
            item={'key':key,'id':c['id'],'family':c['family'],'config':config,'calibrationMsPerCall':dict(zip(['upstream','selfhost'],cost))}
            plan['cases'].append(item);save(out/'schedule.json',plan)
            print(json.dumps({'key':key,'repetitions':config['repetitions'],'calibrationMsPerCall':item['calibrationMsPerCall']}),flush=True)
    verify(m['inputs']);plan['complete']=True;save(out/'schedule.json',plan)

def measure(corpus,schedule,out):
    out.mkdir(parents=True,exist_ok=False)
    m=json.loads((corpus/'manifest.json').read_text());s=json.loads(schedule.read_text());assert s['complete'];verify(m['inputs']);verify(s['harness'])
    assert sha(corpus/'manifest.json')==s['corpus']['sha256']
    report={'kind':'phase25-serial-emitted-runtime-comparison','schedule':ident(schedule),'samples':[],'summary':[],'complete':False,'scope':'Warmed public-library calls with exact result checks; compilation excluded. Fresh process each sample; import and process time separate. No diagnostic instrumentation. Five samples per side, not a universal bound.'}
    save(out/'report.json',report)
    for c in s['cases']:
        case=out/c['key'];case.mkdir();save(case/'config.json',c['config'])
        for side in ['upstream','selfhost']:
            save(case/(side+'-config.json'),{**c['config'],'repetitions':c['config']['repetitionsBySide'][side]})
        samples={side:[] for side in ['upstream','selfhost']}
        for repetition in range(s['samplesPerSide']):
            for side in (['upstream','selfhost'] if repetition%2==0 else ['selfhost','upstream']):
                module=corpus/c['id']/(side+'.mjs')
                expected=next(x['sha256'] for x in m['entries'] if x['id']==c['id'] and x['variant']==side)
                assert sha(module)==expected
                row=child([TOOLS/'execute.mjs','time',module,case/(side+'-config.json')],case/f'{repetition}-{side}')
                row.update(key=c['key'],variant=side,repetition=repetition)
                report['samples'].append(row);save(out/'report.json',report)
                assert row['complete'],f'Failed sample retained: {c["key"]}/{side}'
                samples[side].append(row)
        summary={**c,'sides':{}}
        for side,rows in samples.items():
            times=[r['result']['executionMs'] for r in rows]
            summary['sides'][side]={'repetitions':c['config']['repetitionsBySide'][side],'executionMs':times,'medianMs':statistics.median(times),'minMs':min(times),'maxMs':max(times),'medianMsPerCall':statistics.median(times)/c['config']['repetitionsBySide'][side],'importMs':[r['result']['importMs'] for r in rows],'processSeconds':[r['processSeconds'] for r in rows],'peakRssKiB':[r['result']['peakRssKiB'] for r in rows]}
        summary['selfhostOverUpstream']=summary['sides']['selfhost']['medianMsPerCall']/summary['sides']['upstream']['medianMsPerCall']
        report['summary'].append(summary);save(out/'report.json',report)
        print(json.dumps({'key':c['key'],'ratio':summary['selfhostOverUpstream']}),flush=True)
    verify(m['inputs']);verify(s['harness']);report['complete']=True;report['inputsUnchanged']=True;save(out/'report.json',report)

if __name__=='__main__':
    command=sys.argv[1];args=[Path(p).resolve() for p in sys.argv[2:]]
    if command=='acquire':acquire(*args)
    elif command=='calibrate':calibrate(*args)
    elif command=='measure':measure(*args)
    else:raise ValueError('acquire OUT | calibrate CORPUS OUT | measure CORPUS SCHEDULE OUT')
